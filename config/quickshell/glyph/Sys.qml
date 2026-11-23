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
// ponytail: pgrep every 3s; will become noticeable — watch processes via systemd-run --scope ----
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
    // second time — stop. Area — slurp; cancelled selection — gsr won't start, rec will fix polling
    function toggleRec() {
        const w = Theme.state.recArea ? `-w region -region "$(slurp -f %wx%h+%x+%y)"` : `-w ${Hyprland.focusedMonitor?.name ?? "screen"}`;
        sh(`pkill -INT -f '^gpu-screen-recorder' || exec gpu-screen-recorder ${w} ${recArgs()} -o "$(xdg-user-dir VIDEOS)/rec-$(date +%F_%H-%M-%S).mp4"`);
        rec = !rec;
    }
    function toggleNight() { Rules.store.night = !night; Rules.night(); }
    function toggleAir() { Quickshell.execDetached(["rfkill", air ? "unblock" : "block", "all"]); air = !air; }
    function toggleMic() { if (mic?.audio) mic.audio.muted = !mic.audio.muted; }

// ---- Nothing / CMF headphones: noise cancelling and charge via ./ear (their RFCOMM protocol). Ask when opening quick settings.
// ponytail: recognize by name, like Gadgetbridge; not Nothing — ear won't respond, ear stays null ----
    readonly property var buds: Bluetooth.devices.values.find(d => d.connected && /^(nothing|cmf|ear)\b|^(buds|neckband) pro$/i.test(d.deviceName || d.name)) ?? null
    property var ear: null // {mode?, l, r, case?} or {mode?, bat} for full-size and neckband
    readonly property var earBat: ["bat", "l", "r", "case"].filter(k => ear?.[k] !== undefined)
    onBudsChanged: { ear = null; earNext = null; }
// right after connection channel not ready yet — ask every 2s until they answer. ponytail: not Nothing with similar name
// will be polled like that while connected
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

    // ---- caffeine: don't sleep. Inhibitor needs live window — invisible 0×0, like in demonshot ----
    property bool caffeine: false
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
// ponytail: captions English (language: en in verge); other language — change strings ----
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
