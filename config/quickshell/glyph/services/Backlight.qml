pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// screen backlight, like caelestia — device not hardcoded: what brightnessctl picks by default (first backlight).
// Value — from sysfs: inotify on it is silent, but writing to brightness sends uevent change — wait for it from udev, not poll.
// No backlight (desktop PC) — dev stays empty, value 0. Note: external DDC monitors (ddcutil) are not handled here
Singleton {
    id: root

    property string dev: ""       // /sys/class/backlight/<name>
    property real value: 0        // 0…1
    property int steps: 20        // scale divisions for keys; glyph sets from settings (Sys)
    signal moved()                // every uevent, even if value same (key at max) — for OSD

    function read() {
        cur.reload();
        const v = parseInt(cur.text());
        if (!isNaN(v)) value = v / (parseInt(max.text()) || 1);
    }
    // value set immediately, don't wait for brightnessctl and uevent; while our writes in path, their uevents not read — sync will check later
    // as raw number, not percent: rounding to % would break step() grid (81 % → up → 99, not 100)
    function set(v) {
        const m = parseInt(max.text()) || 0;
        if (!m) return;
        const raw = Math.round(Math.max(0.01, Math.min(1, v)) * m);
        value = raw / m;
        sync.restart();
        Quickshell.execDetached(["brightnessctl", "-q", "-d", dev.slice(dev.lastIndexOf("/") + 1), "set", String(raw)]);
    }
    // keys: steps divisions by 4th root (20 — like brightnessctl -e4 5%), finer at bottom of scale. Step from nearest division,
    // not from value: otherwise fractional error accumulates (up to 399998 instead of 400000)
    function step(d) {
        set(Math.pow(Math.max(0, Math.min(steps, Math.round(Math.pow(value, 0.25) * steps) + d)) / steps, 4));
        moved();
    }
    Timer { id: sync; interval: 300; onTriggered: root.read() }
    GlobalShortcut { appid: "shell"; name: "briUp"; description: "brightness +"; onPressed: root.step(1) }
    GlobalShortcut { appid: "shell"; name: "briDown"; description: "brightness −"; onPressed: root.step(-1) }

    FileView { id: cur; path: root.dev ? root.dev + "/brightness" : ""; blockAllReads: true; printErrors: false }
    FileView { id: max; path: root.dev ? root.dev + "/max_brightness" : ""; blockLoading: true; printErrors: false }

    // brightnessctl -m: "name,class,current,percent,max"
    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim().split(",")[0];
                if (!name) return;
                root.dev = "/sys/class/backlight/" + name;
                root.read();
            }
        }
    }
    Process {
        running: !!root.dev
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        stdout: SplitParser { onRead: l => { if (l.includes(" change ")) { if (!sync.running) root.read(); root.moved(); } } }
    }
}
