"""Keep the Ring push channel alive.

firebase-messaging 0.4.5 strips only "dh=" from the Crypto-Key header, so a
"dh=<unpadded>; p256ecdsa=..." push raises, is never acked and shuts the
client down for good; FCM replays it after every reconnect.
Upstream: sdb9696/firebase-messaging#44, fixed by the unmerged PR #43.

Independent of that, the client also gives up for good after a network outage
(three read errors on the dead stream during its own reset, or five failed
reconnects), and neither ring_doorbell nor HA notices: the event entities stay
available. The watchdog reloads the Ring entry once the channel stays down.
"""

from datetime import timedelta
import logging
from importlib.metadata import version

from firebase_messaging.fcmpushclient import FcmPushClient

from homeassistant.config_entries import ConfigEntryState
from homeassistant.core import callback
from homeassistant.helpers.event import async_track_time_interval

DOMAIN = "firebase_messaging_patch"
PATCHED_VERSION = "0.4.5"

CHECK_INTERVAL = timedelta(minutes=1)
# Longer than a reset with all its reconnect attempts takes.
DEAD_CHECKS = 6

_LOGGER = logging.getLogger(__name__)


def _b64_param(value: str) -> str:
    value = value.split(";")[0].strip()
    return value + "=" * (-len(value) % 4)


def _patch_client() -> None:
    decrypt = FcmPushClient._decrypt_raw_data
    handle = FcmPushClient._handle_data_message

    def patched_decrypt(credentials, crypto_key_str, salt_str, raw_data):
        return decrypt(
            credentials, _b64_param(crypto_key_str), _b64_param(salt_str), raw_data
        )

    # Any other bad message costs that one message, not the whole channel:
    # returning normally lets the caller ack it.
    def patched_handle(self, msg):
        try:
            handle(self, msg)
        except Exception:
            _LOGGER.exception("Dropped FCM message %s", msg.persistent_id)

    FcmPushClient._decrypt_raw_data = staticmethod(patched_decrypt)
    FcmPushClient._handle_data_message = patched_handle


def _channel_up(entry) -> bool:
    coordinator = entry.runtime_data.listen_coordinator
    if not coordinator._listeners:
        return True
    listener = coordinator.event_listener
    receiver = listener._receiver
    return listener.started and receiver is not None and receiver.is_started()


def _start_watchdog(hass) -> None:
    dead_checks: dict[str, int] = {}

    @callback
    def check(_now) -> None:
        for entry in hass.config_entries.async_entries("ring"):
            if entry.state is not ConfigEntryState.LOADED or _channel_up(entry):
                dead_checks.pop(entry.entry_id, None)
                continue
            dead_checks[entry.entry_id] = dead_checks.get(entry.entry_id, 0) + 1
            if dead_checks[entry.entry_id] >= DEAD_CHECKS:
                _LOGGER.warning("Ring push channel is down, reloading %s", entry.title)
                dead_checks.pop(entry.entry_id)
                hass.config_entries.async_schedule_reload(entry.entry_id)

    async_track_time_interval(hass, check, CHECK_INTERVAL)


async def async_setup(hass, config):
    _start_watchdog(hass)

    installed = await hass.async_add_executor_job(version, "firebase-messaging")
    if installed != PATCHED_VERSION:
        _LOGGER.warning(
            "firebase-messaging is %s, the decrypt patch targets %s and stays "
            "inactive. Check whether #44 is fixed upstream and remove it",
            installed,
            PATCHED_VERSION,
        )
        return True

    _patch_client()
    _LOGGER.info("Patched firebase-messaging %s", installed)
    return True
