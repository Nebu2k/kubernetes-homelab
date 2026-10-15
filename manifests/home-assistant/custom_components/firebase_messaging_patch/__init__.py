"""Keep the Ring push client alive on VAPID-signed messages.

firebase-messaging 0.4.5 strips only "dh=" from the Crypto-Key header, so a
"dh=<unpadded>; p256ecdsa=..." push raises, is never acked and shuts the
client down for good; FCM replays it after every reconnect.
Upstream: sdb9696/firebase-messaging#44, fixed by the unmerged PR #43.
"""

import logging
from importlib.metadata import version

from firebase_messaging.fcmpushclient import FcmPushClient

DOMAIN = "firebase_messaging_patch"
PATCHED_VERSION = "0.4.5"

_LOGGER = logging.getLogger(__name__)


def _b64_param(value: str) -> str:
    value = value.split(";")[0].strip()
    return value + "=" * (-len(value) % 4)


async def async_setup(hass, config):
    installed = await hass.async_add_executor_job(version, "firebase-messaging")
    if installed != PATCHED_VERSION:
        _LOGGER.warning(
            "firebase-messaging is %s, this patch targets %s and stays inactive. "
            "Check whether #44 is fixed upstream and remove the patch",
            installed,
            PATCHED_VERSION,
        )
        return True

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
    _LOGGER.info("Patched firebase-messaging %s", installed)
    return True
