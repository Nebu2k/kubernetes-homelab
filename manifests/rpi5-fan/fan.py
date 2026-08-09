# Luefterregelung fuer den Raspberry Pi 5 unter Talos.
#
# WARUM ES DAS GIBT: der Official Active Cooler haengt am PWM des RP1, und
# der Talos-Kernel bringt CONFIG_PWM_RP1 nicht mit (auch nicht als Modul,
# der Treiber existiert nur im Fork raspberrypi/linux, nicht in Mainline).
# Ohne PWM-Provider findet pwm-fan nichts, an dem er haengen koennte:
#
#   platform cooling_fan: deferred probe pending: pwm-fan: Could not get PWM
#
# Es gibt dann kein cooling_device, also auch nichts zu regeln, und der
# Luefter laeuft ungeregelt auf voller Drehzahl. Bei 46 Grad.
#
# Dieses Programm ersetzt den fehlenden Treiber im Userspace: es
# programmiert die PWM-Register des RP1 direkt ueber das PCI-Resource-File
# und regelt in einer Schleife nach der Temperatur.
#
# Der Preis dafuer ist ein privilegierter Pod. Der Gegenwert ist, dass hier
# nichts an die Kernel-Version gebunden ist: eine Kernel-Modul-Extension
# muesste wegen CONFIG_MODVERSIONS vor JEDEM Talos-Upgrade neu gebaut sein,
# sonst haengt die Node zurueck. Dieses Programm ueberlebt Upgrades
# unveraendert.
#
# Register und Offsets stammen aus den Kernelquellen (drivers/pwm/pwm-rp1.c,
# drivers/clk/clk-rp1.c, arch/arm64/boot/dts/broadcom/rp1.dtsi) und aus dem
# Ansatz von Sung-jin Hong (0BSD), der das in
# https://github.com/siderolabs/sbc-raspberrypi/issues/90 als Einmal-Setzer
# gezeigt hat. Hier ist daraus ein Regelkreis mit Hysterese geworden.
#
# WENN MAINLINE DEN TREIBER BEKOMMT (der Patch von Andrea Porta liegt seit
# 2026-08 im Review), gehoert das hier ersatzlos geloescht: dann gibt es ein
# echtes cooling_device und der step_wise-Governor macht das von selbst.
# Beides gleichzeitig waere ein Kampf um dieselben Register.
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

# Kennlinie: (Einschaltschwelle in Grad, Drehzahl in Prozent).
#
# Unter 50 Grad bleibt er aus. Der Active Cooler haelt den Pi im Leerlauf
# passiv gut darunter, und "aus" ist die einzige wirklich lautlose Stufe.
#
# 30 Prozent ist die unterste Stufe, die noch dreht: darunter bleibt der
# Luefter je nach Exemplar stehen oder brummt, ohne Luft zu bewegen.
CURVE = [
    (78, 100),
    (70, 80),
    (60, 55),
    (50, 30),
    (0, 0),
]

# Hysterese in Grad. Ohne sie pendelt der Luefter an jeder Schwelle im
# Sekundentakt an und aus, und genau dieses Pumpen faellt mehr auf als eine
# konstante niedrige Drehzahl. Heruntergeschaltet wird deshalb erst, wenn
# die Temperatur die Schwelle um diesen Betrag unterschritten hat.
HYSTERESIS = 4

# --- RP1-Register ---------------------------------------------------------
# Taktgeber (clk-rp1.c). PWM1 haengt am xosc mit 50 MHz.
CLK_PWM1_CTRL = 0x18084
CLK_PWM1_DIV_INT = 0x18088
CLK_PWM1_DIV_FRAC = 0x1808C
CLK_PWM1_SEL = 0x18090
CLK_CTRL_ENABLE = 1 << 11
AUXSRC_XOSC = 2

# GPIO45 traegt den Luefter und muss auf die PWM-Funktion stehen
# (pinctrl-rp1.c: Bank 2, lokaler Pin 11, FUNCSEL 0 ist pwm1).
GPIO45_CTRL = 0xD0000 + 0x8000 + 11 * 8 + 4
PWM_FUNCSEL = 0

# PWM1, Kanal 3 (pwm-rp1.c).
PWM1 = 0x9C000
CH = 3
GLOB_CTRL = PWM1 + 0x000
CHAN_CTRL = PWM1 + 0x014 + CH * 16
RANGE_REG = PWM1 + 0x018 + CH * 16
DUTY_REG = PWM1 + 0x020 + CH * 16

# 41566 ns Periode (~24 kHz) laut Device-Tree, bei 50 MHz sind das 20 ns je
# Takt. Die Frequenz ist bewusst oberhalb des Hoerbaren.
RANGE_TICKS = 41566 // 20

# BIT(8) FIFO_POP_MASK | BIT(3) POLARITY_INV | BIT(0) M/S_MODE.
# Die Invertierung macht die Hardware, deshalb gilt hier geradeaus:
# duty=0 ist aus, duty=range ist volle Drehzahl.
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
        # Takt erst abschalten, dann die Quelle wechseln, dann einschalten.
        # Ein Quellwechsel im laufenden Betrieb kann den Teiler haengen
        # lassen.
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
        # SET_UPDATE muss in einem EIGENEN Schreibzugriff kommen, sonst
        # uebernimmt der Kanal die neuen Werte nicht.
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
            # Runter erst, wenn die Hysterese ueberschritten ist. Dafuer
            # zaehlt die Schwelle der AKTUELLEN Stufe, nicht der neuen.
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
            # Ein konstantes "up 1" waere hier wertlos: dieser Handler laeuft in
            # einem eigenen Thread und antwortet auch dann noch brav, wenn die
            # Regelschleife im Hauptthread haengt. Der Luefter waere dann
            # unreguliert, und Liveness-Probe wie Alert blieben gruen. Nur der
            # Zeitstempel des letzten Durchlaufs belegt, dass geregelt wird.
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

    # Volle Drehzahl beim Beenden. Wenn dieser Prozess weg ist, regelt
    # niemand mehr, und ein Luefter, der auf 30 Prozent stehenbleibt, ist
    # schlechter als einer, der laut ist. Das ist der sichere Zustand und
    # zugleich der, in dem die Node vorher war.
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

    # Start bei voller Drehzahl und nicht bei 0: bis die erste Messung
    # vorliegt, ist der sichere Zustand der laute. Der erste Schleifen-
    # durchlauf regelt sofort herunter, das dauert keine Sekunde.
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
            # Nur Aenderungen loggen. Eine Zeile alle 5 Sekunden waere in
            # einem Cluster mit zentralem Logging reine Last.
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
