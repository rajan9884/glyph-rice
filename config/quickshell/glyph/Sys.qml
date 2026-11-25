pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.services
import qs.settings

// what bar, quick settings, Glyph and lock touch: sound, brightness, layout, recording, night light, airplane mode, caffeine, vpn
Singleton {
    id: root

    // deck (bottom panel) open — SysStats needs detailed polling, like on empty workspace (Home)
    property bool deckOpen: false
    // wallpaper picker open — home changes wallpaper immediately, no wave: picker already showed it
    property bool wallOpen: false

    // ---- sound ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.mic] }
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property bool headphones: {
        const s = sink;
        if (!s) return false;
        const p = s.properties ?? ({});
        const icon = String(p["device.icon-name"] || p["device.icon_name"] || p["media.icon-name"] || "").toLowerCase();
        const form = String(p["device.form-factor"] || "").toLowerCase();
        if (/headphone|headset|hands-?free|earbud/.test(icon) || /headphone|headset|hands-?free|earbud/.test(form)) return true;
        const meta = [s.name, s.description, s.nickname, p["device.profile.description"], p["device.profile.name"]]
            .filter(Boolean).join(" ").toLowerCase();
        if (/(?:^|[^a-z])(headphones?|headset|earphones?|earbuds?|airpods|buds)(?:$|[^a-z])/.test(meta)) return true;
        if (s.name?.startsWith("bluez_output.")) {
            if (buds) return true;
            const bt = Bluetooth.devices.values.find(d => d.connected && s.name.includes(d.address.replace(/:/g, "_")));
            if (bt && /head|ear|bud|pod/.test(`${bt.icon} ${bt.deviceName} ${bt.name}`.toLowerCase())) return true;
        }
        return false;
    }
    readonly property string volIcon: headphones ? (muted ? "\u{F07CE}" : "\u{F02CB}") : (muted ? "\u{F075F}" : "\u{F057E}")
    readonly property bool micOn: !(mic?.audio?.muted ?? true)
    function setVol(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    // someone listening to mic — center of icon in bar turns red
    PwNodeLinkTracker { id: micUse; node: root.mic }
    readonly property bool live: rec || micUse.linkGroups.length > 0

    // ---- brightness: shared with demonshot Backlight (device searches for brightnessctl) ----
    readonly property real bri: Backlight.value
    readonly property bool hasBri: !!Backlight.dev // no backlight (PC with monitor) — no brightness controls
    function setBri(v) { Backlight.set(v); }
    Binding { target: Backlight; property: "steps"; value: Theme.state.briSteps }

    // ---- layout: start — main keyboard from hyprctl, then activelayout event ----
    property string kbd: ""
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector { onStreamFinished: root.kbd = JSON.parse(this.text).keyboards.find(k => k.main)?.active_keymap ?? "" }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "activelayout") root.kbd = e.data.slice(e.data.lastIndexOf(",") + 1); }
    }
    readonly property string layout: kbd.slice(0, 2).toLowerCase() // "English (US)" → en

// ---- recording and airplane mode: same ones turned on by hypr binds, so polling. Night light — shared with demonshot, in its rules.json
// Caveat: polls via pgrep every 3s; if overhead becomes noticeable, watch processes via systemd-run --scope ----
    property bool rec: false
    readonly property bool night: Rules.store.night
    property bool air: false
    Process {
        id: poll
        command: ["sh", "-c", "pgrep -f '^gpu-screen-recorder' >/dev/null && echo rec; "
                            + "rfkill -rno SOFT | grep -qv '^blocked' || echo air"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.rec = text.includes("rec");
                root.air = text.includes("air");
            }
        }
    }
    Timer { running: true; repeat: true; interval: 3000; triggeredOnStart: true; onTriggered: poll.running = true }

    function sh(c) { Quickshell.execDetached(["sh", "-c", c]); }
    // recording settings from Theme.state (quick/Rec) → gpu-screen-recorder flags; screenshot tool takes them too
    readonly property var recFps: [30, 60, 120]
    function recArgs() {
        const st = Theme.state;
        const a = ["", "default_output", "default_input", "default_output|default_input"][st.recAudio];
        return `-f ${st.recFps} -q ${["medium", "high", "very_high", "ultra"][st.recQuality]} -cursor ${st.recCursor ? "yes" : "no"}` + (a ? ` -a "${a}"` : "");
    }
    // second time — stop. Area — slurp; cancelled selection — gsr won't start, notification isn't sent
    // LIBVA_DRIVER_NAME=iHD required for Intel Iris Xe hardware h264 encoding (intel-media-driver)
    Timer { id: recSync; interval: 1500; onTriggered: poll.running = true }
    function toggleRec() {
        const args = recArgs();
        if (Theme.state.recArea) {
            sh(`if pkill -INT -f '^gpu-screen-recorder'; then notify-send -a "recorder" -i video-x-generic "Recording saved" "Saved to $(xdg-user-dir VIDEOS)"; else sel=$(slurp -f %wx%h+%x+%y) && [ -n "$sel" ] && { notify-send -a "recorder" -i video-x-generic "Recording started" "Screen recording in progress"; exec env LIBVA_DRIVER_NAME=iHD gpu-screen-recorder -w region -region "$sel" ${args} -o "$(xdg-user-dir VIDEOS)/rec-$(date +%F_%H-%M-%S).mp4"; }; fi`);
            if (rec) rec = false;
            else recSync.restart();
            return;
        }
        const mon = Hyprland.focusedMonitor?.name ?? "screen";
        sh(`if pkill -INT -f '^gpu-screen-recorder'; then notify-send -a "recorder" -i video-x-generic "Recording saved" "Saved to $(xdg-user-dir VIDEOS)"; else notify-send -a "recorder" -i video-x-generic "Recording started" "Screen recording in progress"; exec env LIBVA_DRIVER_NAME=iHD gpu-screen-recorder -w ${mon} ${args} -o "$(xdg-user-dir VIDEOS)/rec-$(date +%F_%H-%M-%S).mp4"; fi`);
        rec = !rec;
    }
    function toggleNight() { Rules.store.night = !night; Rules.night(); }
    function toggleAir() { Quickshell.execDetached(["rfkill", air ? "unblock" : "block", "all"]); air = !air; }
    function toggleMic() { if (mic?.audio) mic.audio.muted = !mic.audio.muted; }

// ---- Nothing / CMF headphones: noise cancelling and charge via ./ear (their RFCOMM protocol). Ask when opening quick settings.
// Caveat: matched by device name like Gadgetbridge; non-Nothing earbuds won't respond so `ear` stays null ----
    readonly property var buds: Bluetooth.devices.values.find(d => d.connected && /^(nothing|cmf|ear)\b|^(buds|neckband) pro$/i.test(d.deviceName || d.name)) ?? null
    property var ear: null // {mode?, l, r, case?} or {mode?, bat} for full-size and neckband
    readonly property var earBat: ["bat", "l", "r", "case"].filter(k => ear?.[k] !== undefined)
    onBudsChanged: { ear = null; earNext = null; }
// Right after connecting the RFCOMM channel isn't ready yet — retry every 2s until it answers. Caveat: non-Nothing
// devices with a similar name will keep getting polled while connected
    Timer { interval: 2000; repeat: true; running: !!root.buds && !root.ear; onTriggered: root.earRun([]) }
    // modes by model — like BudsLink (deviceConfigs). Missing from list — full set: for others Ear, CMF, Headphone it's like this
    readonly property var ancModes: {
        const n = buds?.deviceName || buds?.name || "";
        if (/ear \(open\)$/i.test(n)) return [];
        if (/ear \(stick\)$/i.test(n)) return [[1, "off"], [4, "on"]];
        if (/^cmf buds( 2a| neo)?$/i.test(n)) return [[5, "off"], [7, "transp"], [4, "on"]];
        if (/ear \(1\)$/i.test(n)) return [[5, "off"], [7, "transp"], [3, "low"], [1, "high"]];
        if (/buds pro$/i.test(n)) return [[5, "off"], [7, "transp"], [3, "low"], [2, "mid"], [1, "high"]];
        return [[5, "off"], [7, "transp"], [3, "low"], [2, "mid"], [1, "high"], [4, "auto"]];
    }
    property var earNext: null
    function earRun(a) {
        if (!buds) return;
        const c = [Quickshell.shellPath("ear"), buds.address, ...a];
        if (earP.running) earNext = c;
        else { earP.command = c; earP.running = true; }
    }
    function setAnc(m) { ear = Object.assign({}, ear, { mode: m }); earRun(["mode", m]); }
    Process {
        id: earP
        stdout: StdioCollector {
            onStreamFinished: {
                if (earP.command[1] !== root.buds?.address) return;
                try { root.ear = JSON.parse(text); } catch (e) { root.ear = null; }
            }
        }
        onExited: {
            const next = root.earNext;
            root.earNext = null;
            if (next && next[1] === root.buds?.address) exec(next);
        }
    }

// ---- Bluetooth doesn't reconnect devices itself when adapter turned back on (pill, airplane mode, rfkill).
// BlueZ first breaks connections and only then turns off adapter (Connected:false 40–90ms before Powered:false), so
// snapshot at shutdown time is empty. That's why we write connected list with delay: shutdown cancels it, and in
// btResume stays what was before. Disconnected yourself or headphones put in case — in half a second list will accept it ----
    readonly property var btOn: Bluetooth.devices.values.filter(d => d.connected).map(d => d.address)
    property var btResume: []
    onBtOnChanged: btKeep.restart()
    Timer { id: btKeep; interval: 500; running: true; onTriggered: if (Bluetooth.defaultAdapter?.enabled && !btResumeT.running) root.btResume = root.btOn }
    Connections {
        target: Bluetooth.defaultAdapter
        function onEnabledChanged() { if (Bluetooth.defaultAdapter.enabled) btResumeT.restart(); else { btKeep.stop(); btResumeT.stop(); } }
    }
    // adapter needs time after turning on
    Timer { id: btResumeT; interval: 1500; onTriggered: { for (const d of Bluetooth.devices.values) if (root.btResume.includes(d.address) && !d.connected) d.connect(); } }

    // ---- caffeine: don't sleep or lock. Persisted in Rules.store, inhibits hypridle and systemd ----
    property bool caffeine: Rules.store.caffeine ?? false
    property string caffeineCookie: ""
    onCaffeineChanged: {
        if (Rules.store.caffeine !== caffeine) {
            Rules.store.caffeine = caffeine;
            Rules.idle();
        }
        if (caffeine) {
            caffeineInhibit.running = true;
        } else {
            caffeineUninhibit.running = true;
        }
    }
    Connections {
        target: Rules.store
        function onCaffeineChanged() {
            if (root.caffeine !== !!Rules.store.caffeine) root.caffeine = !!Rules.store.caffeine;
        }
    }
    function toggleCaffeine() { caffeine = !caffeine; }

    Process {
        id: caffeineProc
        running: root.caffeine
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=caffeine", "--why=Caffeine active", "sleep", "infinity"]
    }
    Process {
        id: caffeineInhibit
        command: ["busctl", "--user", "call", "org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver", "org.freedesktop.ScreenSaver", "Inhibit", "ss", "caffeine", "active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/\bu\s+(\d+)/);
                if (m) root.caffeineCookie = m[1];
            }
        }
    }
    Process {
        id: caffeineUninhibit
        command: ["sh", "-c", root.caffeineCookie ? `busctl --user call org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver org.freedesktop.ScreenSaver UnInhibit u ${root.caffeineCookie}` : "true"]
        onExited: root.caffeineCookie = ""
    }
    Component.onCompleted: {
        if (root.caffeine) caffeineInhibit.running = true;
    }
    IdleInhibitor {
        enabled: root.caffeine
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "glyph-caffeine"
            mask: Region {}
        }
    }

// ---- vpn: clash verge via its tray items, like agreement in demonshot.
// Caveat: expects English labels (language: en in Clash Verge); update strings if using another language ----
    readonly property var verge: SystemTray.items.values.find(i => i.title === "clash-verge" || i.id.includes("clash-verge")) ?? null
    QsMenuOpener { id: vmenu; menu: root.verge?.menu ?? null }
    readonly property var vpnItems: ["System Proxy", "TUN Mode"]
    function vpnItem(l) { return vmenu.children.values.find(e => e.text.startsWith(l)) ?? null; }
    readonly property bool vpn: vpnItems.some(l => vpnItem(l)?.checkState === Qt.Checked)
    property var queue: []
    function toggleVpn() {
        if (!verge) return Quickshell.execDetached(["clash-verge"]); // asleep — wake up
        queue = vpn ? vpnItems.filter(l => vpnItem(l)?.checkState === Qt.Checked) : vpnItems;
        presser.start();
    }
    // verge rebuilds menu after each press — one by one
    Timer {
        id: presser
        interval: 350
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const [l, ...rest] = root.queue;
            root.queue = rest;
            if (l) root.vpnItem(l)?.triggered();
            if (!rest.length) stop();
        }
    }
}
