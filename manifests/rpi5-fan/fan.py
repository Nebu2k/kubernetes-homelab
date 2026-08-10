# Fan control for the Raspberry Pi 5 under Talos.
#
# The Official Active Cooler hangs off the RP1's PWM, and the Talos kernel
# does not ship CONFIG_PWM_RP1 (not even as a module, the driver exists only
# in the raspberrypi/linux fork). Without a PWM provider pwm-fan finds nothing
# to attach to:
#
#   platform cooling_fan: deferred probe pending: pwm-fan: Could not get PWM
#
# There is then no cooling_device, nothing to control, and the fan runs
# unregulated at full speed even at idle temperatures.
#
# This program replaces the missing driver in userspace: it programs the RP1's
# PWM registers directly through the PCI resource file and controls the fan in
# a loop based on temperature.
#
# The price is a privileged pod. The return is that nothing here is bound to
# the kernel version: a kernel module extension would have to be rebuilt
# before EVERY Talos upgrade because of CONFIG_MODVERSIONS, or the node falls
# behind. This program survives upgrades unchanged.
#
# Registers and offsets come from the kernel sources (drivers/pwm/pwm-rp1.c,
# drivers/clk/clk-rp1.c, arch/arm64/boot/dts/broadcom/rp1.dtsi) and from
# Sung-jin Hong's approach (0BSD) in
# https://github.com/siderolabs/sbc-raspberrypi/issues/90, which set the
# registers once. This turns it into a control loop with hysteresis.
#
# Once mainline gains the driver this file should be deleted outright: there
# will be a real cooling_device and the step_wise governor handles it. Running
# both would be a fight over the same registers.
import mmap
import os
import signal
import struct
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

RESOURCE = "/host-sys/bus/pci/devices/0002:01:00.0/resource1"
THERMAL = "/host-sys/class/thermal/thermal_zone0/temp"
POLL_SECONDS = 5
METRICS_PORT = 9101

# Curve: (switch-on threshold in degrees, speed in percent).
#
# Below 50 degrees the fan stays off, the only truly silent step. 30 percent
# is the lowest step that still turns; below that the fan stalls or hums
# without moving air.
#
# The second step sits at 65 and not at 60 by measurement: at 30 percent the
# idle equilibrium is stable around 57-59 degrees. With the threshold at 60
# the node grazes it every few minutes and pumps up and down, which is far
# more noticeable than a constant low speed and is exactly what hysteresis
# cannot prevent when the resting point sits just below the threshold. 65 puts
# the next step above idle so it engages under real load. The Pi 5 does not
# throttle before 80.
CURVE = [
    (78, 100),
    (72, 80),
    (65, 55),
    (50, 30),
    (0, 0),
]

# Hysteresis in degrees. Without it the fan toggles at every threshold from
# second to second. Stepping down happens only once the temperature has
# dropped this far below the threshold.
HYSTERESIS = 4

# RP1 registers.
# Clock source (clk-rp1.c). PWM1 hangs off the 50 MHz xosc.
CLK_PWM1_CTRL = 0x18084
CLK_PWM1_DIV_INT = 0x18088
CLK_PWM1_DIV_FRAC = 0x1808C
CLK_PWM1_SEL = 0x18090
CLK_CTRL_ENABLE = 1 << 11
AUXSRC_XOSC = 2

# GPIO45 carries the fan and must be set to the PWM function
# (pinctrl-rp1.c: bank 2, local pin 11, FUNCSEL 0 is pwm1).
GPIO45_CTRL = 0xD0000 + 0x8000 + 11 * 8 + 4
PWM_FUNCSEL = 0

# PWM1, channel 3 (pwm-rp1.c).
PWM1 = 0x9C000
CH = 3
GLOB_CTRL = PWM1 + 0x000
CHAN_CTRL = PWM1 + 0x014 + CH * 16
RANGE_REG = PWM1 + 0x018 + CH * 16
DUTY_REG = PWM1 + 0x020 + CH * 16

# 41566 ns period (~24 kHz) per the device tree; at 50 MHz that is 20 ns per
# tick. The frequency is deliberately above the audible range.
RANGE_TICKS = 41566 // 20

# BIT(8) FIFO_POP_MASK | BIT(3) POLARITY_INV | BIT(0) M/S_MODE.
# The hardware does the inversion, so here it reads straight: duty=0 is off,
# duty=range is full speed.
CHAN_CTRL_INIT = 0x109


class Rp1Pwm:
    def __init__(self):
        self.fd = os.open(RESOURCE, os.O_RDWR | os.O_SYNC)
        self.mm = mmap.mmap(
            self.fd, 4 * 1024 * 1024, mmap.MAP_SHARED,
            mmap.PROT_READ | mmap.PROT_WRITE,
        )

    def read32(self, off):
        return struct.unpack_from("<I", self.mm, off)[0]

    def write32(self, off, val):
        struct.pack_into("<I", self.mm, off, val)

    def setup(self):
        # Disable the clock, switch the source, then enable: switching the
        # source while running can hang the divider.
        ctrl = self.read32(CLK_PWM1_CTRL)
        self.write32(CLK_PWM1_CTRL, ctrl & ~CLK_CTRL_ENABLE)
        self.write32(CLK_PWM1_DIV_INT, 1)
        self.write32(CLK_PWM1_DIV_FRAC, 0)
        ctrl = self.read32(CLK_PWM1_CTRL)
        ctrl &= ~0x3E1                 # AUXSRC [9:5] und SRC [0] loeschen
        ctrl |= AUXSRC_XOSC << 5
        ctrl |= 1                      # SRC = AUX_SEL
        ctrl |= CLK_CTRL_ENABLE
        self.write32(CLK_PWM1_CTRL, ctrl)
        self.write32(CLK_PWM1_SEL, 1 << 1)

        gpio = self.read32(GPIO45_CTRL)
        if (gpio & 0x1F) != PWM_FUNCSEL:
            self.write32(GPIO45_CTRL, (gpio & ~0x1F) | PWM_FUNCSEL)

        self.write32(CHAN_CTRL, CHAN_CTRL_INIT)
        self.write32(RANGE_REG, RANGE_TICKS)
        glob = self.read32(GLOB_CTRL)
        self.write32(GLOB_CTRL, glob | (1 << CH))

    def set_percent(self, percent):
        self.write32(DUTY_REG, RANGE_TICKS * percent // 100)
        # SET_UPDATE must come in its OWN write, otherwise the channel does
        # not pick up the new values.
        glob = self.read32(GLOB_CTRL)
        self.write32(GLOB_CTRL, glob | (1 << 31))


def read_temp():
    with open(THERMAL) as f:
        return int(f.read().strip()) / 1000.0


def target_percent(temp, current):
    for threshold, percent in CURVE:
        if temp >= threshold:
            if percent >= current:
                return percent
            # Step down only past the hysteresis, measured against the
            # CURRENT step's threshold rather than the new one.
            for t2, p2 in CURVE:
                if p2 == current:
                    return current if temp > t2 - HYSTERESIS else percent
            return percent
    return 0


state = {"temp": 0.0, "percent": 0, "since": time.time(), "loop": time.time()}


class Metrics(BaseHTTPRequestHandler):
    def do_GET(self):
        body = (
            "# HELP rpi5_fan_speed_percent Angesteuerte Luefterdrehzahl.\n"
            "# TYPE rpi5_fan_speed_percent gauge\n"
            f"rpi5_fan_speed_percent {state['percent']}\n"
            "# HELP rpi5_fan_temperature_celsius Temperatur, nach der geregelt wird.\n"
            "# TYPE rpi5_fan_temperature_celsius gauge\n"
            f"rpi5_fan_temperature_celsius {state['temp']:.1f}\n"
            # A constant "up 1" would be worthless: this handler runs in its
            # own thread and keeps answering even when the control loop in the
            # main thread is stuck, leaving the fan unregulated while probe
            # and alert stay green. Only the timestamp of the last iteration
            # proves that control is happening.
            "# HELP rpi5_fan_last_loop_timestamp_seconds Zeitpunkt des letzten Regeldurchlaufs.\n"
            "# TYPE rpi5_fan_last_loop_timestamp_seconds gauge\n"
            f"rpi5_fan_last_loop_timestamp_seconds {state['loop']:.0f}\n"
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def main():
    pwm = Rp1Pwm()
    pwm.setup()

    # Full speed on shutdown: with this process gone nobody controls the fan,
    # and one stuck at 30 percent is worse than a loud one.
    def on_signal(signum, frame):
        print("beende, setze Luefter auf 100 Prozent", flush=True)
        pwm.set_percent(100)
        sys.exit(0)

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    threading.Thread(
        target=HTTPServer(("", METRICS_PORT), Metrics).serve_forever,
        daemon=True,
    ).start()

    # Start at full speed rather than 0: until the first reading arrives the
    # safe state is the loud one. The first loop iteration turns it down.
    current = 100
    pwm.set_percent(current)
    state["percent"] = current
    print(f"Regler laeuft, Startdrehzahl {current} Prozent", flush=True)

    while True:
        temp = read_temp()
        want = target_percent(temp, current)
        state["temp"] = temp
        state["loop"] = time.time()
        if want != current:
            pwm.set_percent(want)
            # Log changes only. A line every 5 seconds would be pure load in
            # a cluster with central logging.
            print(
                f"{temp:.1f} C: {current} -> {want} Prozent "
                f"(nach {int(time.time() - state['since'])} s)",
                flush=True,
            )
            current = want
            state["percent"] = want
            state["since"] = time.time()
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
