# Counts the macb TX stalls on end0 and exports them as a metric.
#
# The stall itself is handled by the kernel: Talos carries the macb patch that
# catches a lost TSTART write and calls macb_tx_restart(). It leaves no trace
# anywhere except one line in the kernel ring:
#
#   macb 1f00100000.ethernet end0: TX stall detected on queue 0
#   (tail=9413385 head=9413387); re-kicking TSTART
#
# ethtool -S has no counter for it, /sys/class/net/end0/statistics stays at
# zero, and tx_errors never moves. Without this exporter the only visible
# symptom is etcd on raspi5 losing its leader, which needs six occurrences per
# hour before EtcdMemberLosesLeader fires. Everything below that is invisible.
#
# Two things the setup depends on:
#
# 1. privileged, not CAP_SYSLOG. kernel.dmesg_restrict is 1 on the node, and
#    although the capability arrives in CapEff, opening /dev/kmsg still fails
#    with EPERM.
# 2. Only records arriving after start are counted. Reading the ring from the
#    beginning would look nicer on the first scrape, but the ring drops old
#    entries, so after a pod restart the start value could be LOWER than
#    before and increase() would read the jump as a burst of fresh stalls.
import errno
import os
import re
import select
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

KMSG = "/dev/kmsg"
IFACE = os.environ.get("IFACE", "end0")
POLL_SECONDS = 5
METRICS_PORT = 9102

# The interface name sits directly in front of the message, the record prefix
# ("4,1133,22062376163,-;macb 1f00100000.ethernet ") is irrelevant here.
STALL = re.compile(r"(\S+): TX stall detected on queue")

# IFACE starts at 0 so the series exists before the first stall. Without it
# the metric would be missing for hours and every query over it would be
# empty rather than zero.
state = {"stalls": {IFACE: 0}, "last": 0.0, "poll": time.time()}


class Metrics(BaseHTTPRequestHandler):
    def do_GET(self):
        lines = [
            "# HELP rpi5_net_tx_stalls_total Vom Kernel abgefangene TX-Stalls seit Start dieses Prozesses.",
            "# TYPE rpi5_net_tx_stalls_total counter",
        ]
        for iface, count in sorted(state["stalls"].items()):
            lines.append(f'rpi5_net_tx_stalls_total{{interface="{iface}"}} {count}')
        lines += [
            "# HELP rpi5_net_last_stall_timestamp_seconds Zeitpunkt des letzten TX-Stalls, 0 wenn seit Start keiner auftrat.",
            "# TYPE rpi5_net_last_stall_timestamp_seconds gauge",
            f"rpi5_net_last_stall_timestamp_seconds {state['last']:.0f}",
            # Same reasoning as in rpi5-fan: this handler answers from its own
            # thread as long as Python lives, so a constant "up 1" would stay
            # green with a dead reader. Only the timestamp proves that
            # /dev/kmsg is still being read.
            "# HELP rpi5_net_reader_last_poll_timestamp_seconds Zeitpunkt des letzten Lesedurchlaufs auf /dev/kmsg.",
            "# TYPE rpi5_net_reader_last_poll_timestamp_seconds gauge",
            f"rpi5_net_reader_last_poll_timestamp_seconds {state['poll']:.0f}",
        ]
        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def ring_backlog(fd):
    """Stalls already in the ring, for the startup log only.

    Leaves the fd at the end of the ring, which is where reading is supposed
    to start. /dev/kmsg only accepts SEEK_SET, SEEK_DATA and SEEK_END, so the
    position cannot be saved and restored around this.
    """
    os.lseek(fd, 0, os.SEEK_SET)
    found = 0
    while True:
        try:
            rec = os.read(fd, 8192)
        except BlockingIOError:
            break
        except OSError as e:
            if e.errno in (errno.EPIPE, errno.EIO):
                continue
            raise
        if STALL.search(rec.decode("utf-8", "replace")):
            found += 1
    os.lseek(fd, 0, os.SEEK_END)
    return found


def drain(fd):
    # A read() returning EPIPE means records were dropped while we were away;
    # the fd then points at the oldest surviving one, so reading continues.
    # The counter guards against spinning at 100 percent CPU if that state
    # ever persists.
    skipped = 0
    while skipped < 100:
        try:
            rec = os.read(fd, 8192)
        except BlockingIOError:
            return
        except OSError as e:
            if e.errno in (errno.EPIPE, errno.EIO):
                skipped += 1
                continue
            raise
        # A read of zero means end of file. /dev/kmsg never gets there, but
        # without this the loop would spin at full CPU if it ever did.
        if not rec:
            return
        # /dev/kmsg hands out exactly one record per read; findall keeps the
        # count right anyway if several ever arrive together.
        for iface in STALL.findall(rec.decode("utf-8", "replace")):
            state["stalls"][iface] = state["stalls"].get(iface, 0) + 1
            state["last"] = time.time()
            print(
                f"TX-Stall auf {iface}, seit Start {state['stalls'][iface]}",
                flush=True,
            )


def main():
    fd = os.open(KMSG, os.O_RDONLY | os.O_NONBLOCK)

    threading.Thread(
        target=HTTPServer(("", METRICS_PORT), Metrics).serve_forever,
        daemon=True,
    ).start()

    backlog = ring_backlog(fd)
    print(
        f"Lese {KMSG} auf TX-Stalls, gezaehlt wird ab jetzt. "
        f"Im Ringpuffer stehen bereits {backlog} seit dem letzten Boot.",
        flush=True,
    )

    poller = select.poll()
    poller.register(fd, select.POLLIN)
    while True:
        # The timeout is what keeps the heartbeat honest: without it the
        # timestamp would only move when a stall arrives, and a quiet line
        # would look exactly like a dead reader.
        poller.poll(POLL_SECONDS * 1000)
        state["poll"] = time.time()
        drain(fd)


if __name__ == "__main__":
    main()
