pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// house rules: ~/.config/demonshot/rules.json — only source of truth for settings.
// Edit from Settings writes file (writeAdapter) and itself calls needed apply. applyAll called only by shell.qml on start:
// lock (lock.qml) also reads Theme → Rules, but applies nothing
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/demonshot"
    readonly property alias store: adapter

    // eight colors in Theme order: void crypt wine plum rose crimson ash bone
    readonly property var palettes: [
        { name: "Demon's Shot", what: "blood & bone", c: ["#0D0B0E", "#151116", "#2B1820", "#4A2236", "#B8487A", "#C7303D", "#7A6870", "#E9DFDD"] },
        { name: "Absinthe", what: "green fairy", c: ["#0B0D0B", "#121612", "#1E2A1F", "#2F4630", "#A9B85A", "#7CC24A", "#6E7A6C", "#E3E6D8"] },
        { name: "Nightshade", what: "poison bloom", c: ["#0C0B10", "#131119", "#221A30", "#3A2852", "#8E6BD8", "#B04BD6", "#706A80", "#E4DFEA"] },
        { name: "Holy Water", what: "cold blessing", c: ["#0A0C10", "#11151B", "#1A2433", "#263C57", "#5E9BD1", "#3F7FE0", "#687687", "#DDE4EA"] },
        { name: "Rust", what: "old iron", c: ["#0E0B09", "#17120F", "#2E1D14", "#4D2E1C", "#D08A3E", "#D1532A", "#7E6E62", "#EADFD3"] },
        { name: "Gilded", what: "altar gold", c: ["#0D0C0A", "#16140F", "#2E2716", "#4A3D1E", "#B88A4A", "#D9A43A", "#7A7262", "#EDE5D3"] },
        { name: "Ghost", what: "no color left", c: ["#0C0C0D", "#141416", "#26262A", "#3A3A40", "#9A9AA6", "#E9E9EE", "#6E6E76", "#E2E2E6"] }
    ]
    readonly property var pal: palettes[adapter.palette] ?? palettes[0]

    // wait for file on singleton creation: otherwise first to read store (glyph on start) would get defaults, not rules.json
    Component.onCompleted: file.waitForJob()

    FileView {
        id: file
        path: root.dir + "/rules.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
        // write — once at end of pass: writeAdapter() on each field in a row confuses neighbors (preset changes four at once)
        onAdapterUpdated: Qt.callLater(file.writeAdapter)
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) this.writeAdapter(); } // first run: file with defaults

        // defaults — as in hypr config now, so first run wouldn't shift anything
        JsonAdapter {
            id: adapter
            // Display
            property real monScale: 0      // 0 — auto, hypr decides
            property int refresh: 0        // 0 — highest screen hz, like mode = "highres" in hyprland.lua
            property string main: ""       // whose monScale and refresh (Rules.mon); empty — first monitor reading will decide
            // other screens, if turned in prefs, by Rules.key: { "TS2700-S6-1": { scale: 1, refresh: 144, pos: [-560, -1440] } };
            // pos — from main, then it's at 0x0
            property var outs: ({})
            property int brightness: 62
            property bool night: false
            property int warmth: 4300
            property int gapsIn: 6
            property int gapsOut: 14
            property int border: 2
            property int rounding: 0
            property bool blur: true
            property bool shadow: true
            property bool motion: true
            property bool ultra: false   // ultra mode (setMode 0): 60 Hz and no ornaments over settings
            property bool game: false    // game, like caelestia: no animations, blur, shadows, gaps and roundings, tearing (Theme.apply)
            // Colors
            property int palette: 0
            property bool paintHypr: true
            property bool paintKitty: true
            // Input — like in hyprland/input.lua
            property int kbSwitch: 0      // index in switches
            property int repeatDelay: 250
            property int repeatRate: 35
            property bool natural: true
            property bool tap: true
            property bool typingOff: false
            property int scroll: 30       // % — scroll_factor 0.3
            property int sens: 0          // -100…100 → sensitivity -1…1
            property bool flat: false
            // Idle: minutes, 0 — never
            property int lockAfter: 3
            property int dpmsAfter: 5
            property int sleepAfter: 10
            property bool hibernate: true // suspend-then-hibernate
            property bool caffeine: false
            // System
            property bool roman: true
            // Notices. Silence (set by oberegs): regular notifications are not shown, critical ones — always
            property bool dnd: false
            property int noteTime: 6      // s, if app didn't set its own; 0 — wait until swiped
            property int noteDeck: 5      // how many visible in deck
        }
    }

    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }

    // monitors from hyprctl monitors all — enabled and not mirrors: w × h and rates — current mode and its frequencies, x, y, lw × lh —
    // where it is and how many logical px in it (rotated — opposite)
    property var mons: []
    // main — monScale and refresh set it (demonshot reads them too): built-in, even off (lid in dock), if none —
    // first. Remembered in store.main by model (if none — port): on desktop screen order changes with connection, and cable
    // moves to another port or dock — scale shouldn't go to another. Old store.main — port name, we search it too
    property string first: ""
    readonly property var mon: mons.find(m => m.name === (store.main || first)) ?? mons.find(m => m.model && m.model === (store.main || first))
        ?? { name: "", w: 0, h: 0, x: 0, y: 0, lw: 0, lh: 0, transform: 0, scale: 1, hz: 0, rates: [] }
    property bool monWanted: false // monitor() called before hyprctl answer arrived
    property bool driving: false   // this process sets monitors (monitor() called shell.qml); lock only reads
    Process {
        id: monProc
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const all = JSON.parse(text);
                const f = all.find(m => /^(eDP|LVDS|DSI)/.test(m.name)) ?? all.find(m => !m.disabled);
                root.first = f ? f.model.trim() || f.name : "";
                root.mons = all.filter(m => !m.disabled && m.mirrorOf === "none").map(m => {
                    const rates = [...new Set(m.availableModes.map(s => /(\d+)x(\d+)@([\d.]+)/.exec(s))
                        .filter(r => r && +r[1] === m.width && +r[2] === m.height).map(r => Math.round(+r[3])))].sort((a, b) => a - b);
                    const t = m.transform % 2, lw = Math.round(m.width / m.scale), lh = Math.round(m.height / m.scale);
                    return { name: m.name, model: m.model.trim(), desc: m.description, w: m.width, h: m.height, x: m.x, y: m.y, lw: t ? lh : lw, lh: t ? lw : lh,
                             transform: m.transform, scale: m.scale, hz: Math.round(m.refreshRate), rates: rates.length ? rates : [Math.round(m.refreshRate)] };
                });
                if (root.monWanted) root.monitor();
                else root.settle();
            }
        }
    }
    // auto — hypr chooses scale; what came out, we learn by rereading monitors
    Timer { id: monReread; interval: 500; onTriggered: monProc.running = true }
    // how screen is recorded in outs: by model — it's the monitor itself, not port (plugged projector into same HDMI — it won't take place and
    // home hz; home in another port — with its own); two identical or without model — by port name. Like Theme.sid
    function key(m) { return m.model && mons.filter(x => x.model === m.model).length === 1 ? m.model : m.name; }
    // its own at screen; by name — record of double left alone (key became model)
    function out(m) { return store.outs[key(m)] ?? store.outs[m.name]; }
    // what's chosen at screen: scale (0 — auto) and refresh
    function want(m) {
        if (m.name === mon.name) return { scale: store.monScale, refresh: refreshHz };
        const o = out(m);
        return { scale: o?.scale ?? m.scale, refresh: o?.refresh ?? m.hz };
    }
    // hypr rule for screen. It replaces config rule entirely — mode (current resolution) and rotation we carry as is.
    // External stand by pos from main, main then at 0x0: on auto hypr would put it to right of explicit ones. Exit — like key():
    // desc: of monitor, not port — rule lives in hypr until reload, and projector in same port would take place and mode of this
    // ponytail: vrr, 10 bit and hdr from user.lua shell rule removes; if needed — carry from hyprctl, like transform
    function rule(m) {
        const own = m.name === mon.name, w = want(m), pos = out(m)?.pos;
        const at = own ? (mons.some(x => x.name !== m.name && out(x)?.pos) ? "0x0" : "auto") : pos ? `${pos[0]}x${pos[1]}` : "auto";
        const output = key(m) !== m.name && m.desc ? `desc:${m.desc}` : m.name;
        return `hl.monitor({ output = ${JSON.stringify(output)}, mode = "${m.w}x${m.h}@${own ? hz : w.refresh}", position = "${at}", `
             + `scale = ${w.scale || '"auto"'}, transform = ${m.transform} })`;
    }
    // main and external from outs — one eval, main first: others stand from it. fresh — first reread (connected
    // screen): screensChanged batch collapses into one read in 500 ms, and answer already with new screen. Called only by shell.qml
    function monitor(fresh) {
        driving = true;
        if (fresh || !mons.length) {
            monWanted = true;
            if (fresh) monReread.restart();
            return;
        }
        monWanted = false;
        if (!store.main && first) store.main = first;
        const ms = mons.filter(m => m.name === mon.name || out(m)).sort((a, b) => (b.name === mon.name) - (a.name === mon.name));
        if (ms.length) hypr(ms.map(rule).join("\n"));
        monReread.restart();
    }
    // prefs → display: scale (0 — auto) or refresh of screen name. For main — monScale and refresh, for external — outs (place). Scale
    // changes size — edge to neighbor will fix settle after reading
    function set(name, k, v) {
        const m = mons.find(x => x.name === name);
        if (!m) return;
        if (m.name !== mon.name) return place(name, m.x, m.y, { [k]: v });
        store[k === "scale" ? "monScale" : "refresh"] = v;
        monitor();
    }
    // screen name — to x, y (logical px hypr), extra — its fields in outs. All external nailed by explicit pos from main where
    // stand: rule without position hypr would set on auto, and neighbors would shift
    function place(name, x, y, extra) {
        const b = name === mon.name ? { x, y } : mon, o = Object.assign({}, store.outs);
        for (const m of mons) {
            if (m.name === mon.name) continue;
            const p = m.name === name ? { x, y } : m;
            // port record not erased: double would return — screen again searched by port
            o[key(m)] = Object.assign({}, out(m), m.name === name ? extra : null, { pos: [p.x - b.x, p.y - b.y] });
        }
        store.outs = o;
        monitor();
    }
    // prefs → display «reset»: forget places, scale and hz of external — again as in hypr config (user.lua). Shell rules live
    // in hypr until config reread — we ask it; rest will return configreloaded (shell.qml)
    function forget() {
        store.outs = {};
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    function hits(a, b) { return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h; }
    // where screen r ({ x, y, w, h }, logical px hypr) will stand if thrown like this: flush to neighbor side, without overlap,
    // common edge — not less than quarter of smaller of two; along edge — where thrown, but sticks to edges and center of neighbor closer near.
    // Of all such places — nearest; none — null
    function dock(r, others, near) {
        const stick = (v, lo, hi, to) => {
            v = Math.max(lo, Math.min(hi, v));
            return to.find(t => Math.abs(t - v) < near) ?? v;
        };
        let best = null, bd = Infinity;
        for (const o of others) {
            const kx = Math.min(r.w, o.w) / 4, ky = Math.min(r.h, o.h) / 4;
            const x = stick(r.x, o.x - r.w + kx, o.x + o.w - kx, [o.x, o.x + o.w - r.w, o.x + (o.w - r.w) / 2]);
            const y = stick(r.y, o.y - r.h + ky, o.y + o.h - ky, [o.y, o.y + o.h - r.h, o.y + (o.h - r.h) / 2]);
            for (const c of [{ x: o.x - r.w, y }, { x: o.x + o.w, y }, { x, y: o.y - r.h }, { x, y: o.y + o.h }]) {
                const p = { x: Math.round(c.x), y: Math.round(c.y), w: r.w, h: r.h }, d = Math.hypot(p.x - r.x, p.y - r.y);
                if (d < bd && !others.some(q => hits(p, q))) {
                    best = p;
                    bd = d;
                }
            }
        }
        return best;
    }
    // external with explicit pos stepped on neighbor or hung in air (scale changed, screen returned, neighbor taken away) — to nearest
    // free edge, one at a time per read. Already asked same there, hypr didn't set — don't insist, otherwise circle every half second.
    // Tolerance 2 px — logical size rounding
    function settle() {
        if (!driving || mons.length < 2) return;
        const box = m => ({ x: m.x, y: m.y, w: m.lw, h: m.lh }), near = (a, b) => Math.abs(a - b) <= 2;
        const touch = (a, b) => (near(a.x + a.w, b.x) || near(b.x + b.w, a.x)) && a.y < b.y + b.h && b.y < a.y + a.h
                             || (near(a.y + a.h, b.y) || near(b.y + b.h, a.y)) && a.x < b.x + b.w && b.x < a.x + a.w;
        for (const m of mons) {
            const pos = out(m)?.pos;
            if (m.name === mon.name || !pos) continue;
            const r = box(m), rest = mons.filter(x => x !== m).map(box);
            if (!rest.some(o => hits({ x: r.x + 2, y: r.y + 2, w: r.w - 4, h: r.h - 4 }, o)) && rest.some(o => touch(r, o))) continue;
            const d = dock(r, rest, 0);
            if (d && (d.x - mon.x !== pos[0] || d.y - mon.y !== pos[1])) return place(m.name, d.x, d.y);
        }
    }
    readonly property var rates: mon.rates.length ? mon.rates : [60, 120]
    readonly property int refreshHz: store.refresh ? rates.reduce((a, b) => Math.abs(b - store.refresh) < Math.abs(a - store.refresh) ? b : a) : rates[rates.length - 1]
    readonly property real scale: store.monScale || mon.scale || 1 // what actually stands, and at auto
    readonly property var scales: ["auto", "1", "1.25", "1.5", "2"]
    function windows() {
        const s = store;
        hypr(`hl.config({ general = { gaps_in = ${s.gapsIn}, gaps_out = ${s.gapsOut}, border_size = ${s.border} }, `
           + `decoration = { rounding = ${s.rounding}, blur = { enabled = ${blurOn} }, shadow = { enabled = ${shadowOn} } } })`);
    }
    // ponytail: only on/off; slam/snap — override curves from animations.lua
    function motion() { hypr(`hl.config({ animations = { enabled = ${moving} } })`); }
    readonly property var switches: [["alt+shift", "grp:alt_shift_toggle"], ["caps", "grp:caps_toggle"], ["ctrl+shift", "grp:ctrl_shift_toggle"]]
    function input() {
        const s = store;
        hypr(`hl.config({ input = { kb_options = "${switches[s.kbSwitch]?.[1] ?? switches[0][1]}", repeat_delay = ${s.repeatDelay}, repeat_rate = ${s.repeatRate}, `
           + `sensitivity = ${s.sens / 100}, accel_profile = "${s.flat ? "flat" : "adaptive"}", touchpad = { natural_scroll = ${s.natural}, `
           + `tap_to_click = ${s.tap}, disable_while_typing = ${s.typingOff}, scroll_factor = ${s.scroll / 100} } } })`);
    }
    // hibernation not everywhere (needs swap for resume, zram doesn't fit) — we ask logind. No — regular sleep, items
    // hibernation hidden. Answer came after idle() — rewrite config (lock idle() doesn't call, doesn't concern it)
    property bool canHibernate: false
    property bool idleDone: false
    readonly property bool hibernateOn: store.hibernate && canHibernate
    onCanHibernateChanged: if (idleDone) idle()
    Process {
        running: true
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanSuspendThenHibernate"]
        stdout: StdioCollector { onStreamFinished: root.canHibernate = text.includes('"yes"') }
    }
    // hypridle config doesn't reread on the fly: we write ours and restart. Same text and hypridle alive — don't touch,
    // so shell reload wouldn't reset idle counter. inhibit_sleep = 3 — sleep waits until lock rises (hypridle itself
    // waits only hyprlock): otherwise lock falls asleep under-raised, and on wake monitors blink — monitor, disappeared
    // in first ~0.5 s of lock life, drops qs (#5)
    function idle() {
        idleDone = true;
        const s = store, dpms = a => `hyprctl dispatch 'hl.dsp.dpms({action = "${a}"})'`;
        const at = (min, on, back) => (!s.caffeine && min) ? `\nlistener {\n    timeout = ${min * 60}\n    on-timeout = ${on}${back ? `\n    on-resume = ${back}` : ""}\n}\n` : "";
        const conf = "# demonshot: written by Rules.idle() from rules.json, do not edit by hand\n"
            + "general {\n    lock_cmd = ~/.config/quickshell/rice/rice lock\n    inhibit_sleep = 3\n"
            + `    before_sleep_cmd = loginctl lock-session\n    after_sleep_cmd = ${dpms("on")}\n}\n`
            + at(s.lockAfter, "loginctl lock-session") + at(s.dpmsAfter, dpms("off"), dpms("on"))
            + at(s.sleepAfter, hibernateOn ? "systemctl suspend-then-hibernate" : "systemctl suspend");
        Quickshell.execDetached(["sh", "-c", 'f="$1/hypridle.conf"; printf %s "$2" | cmp -s - "$f" && pgrep -x hypridle >/dev/null && exit; '
                                       + 'printf %s "$2" > "$f"; pkill -x hypridle; exec hypridle -c "$f"', "sh", dir, conf]);
    }
    function brightness() { Quickshell.execDetached(["brightnessctl", "-q", "set", store.brightness + "%"]); }
    function night() {
        Quickshell.execDetached(["sh", "-c", store.night ? `pkill -x hyprsunset; exec hyprsunset -t ${store.warmth}` : "pkill -x hyprsunset"]);
    }

    // palette: Theme repaints itself (bindings on pal), here — what lives outside shell
    function paint() {
        const c = pal.c;
        if (store.paintHypr) {
            const h = c.map(x => x.slice(1));
            hypr(`hl.config({ general = { col = { active_border = { colors = { "rgb(${h[5]})", "rgb(${h[4]})", "rgb(${h[5]})" }, angle = 135 }, `
               + `inactive_border = "rgb(${h[2]})" } }, decoration = { shadow = { color = "rgba(${h[5]}20)" } } })`);
        }
        if (store.paintKitty) {
            const kittyConf = Quickshell.env("HOME") + "/.config/demonshot/kitty.conf";
            Quickshell.writeFile(kittyConf,
                "# glyph: written by Rules.paint(), do not edit by hand\n" + [
                    ["foreground", c[7]], ["background", c[1]],
                    ["selection_foreground", c[7]], ["selection_background", c[3]],
                    ["cursor", c[7]], ["cursor_text_color", c[1]],
                    ["url_color", c[4]],
                    ["active_border_color", c[7]], ["inactive_border_color", c[3]],
                    ["active_tab_foreground", c[1]], ["active_tab_background", c[7]],
                    ["inactive_tab_foreground", c[5]], ["inactive_tab_background", c[1]],
                    ["tab_bar_background", c[1]]
                ].map(([k, v]) => `${k} ${v}`).join("\n") + "\n" +
                pal.ansi.map((c, i) => `color${i} ${c}`).join("\n") + "\n");
            Quickshell.execDetached(["pkill", "-USR1", "-x", "kitty"]);
        }
    }

    // power modes, like caelestia: power-profiles-daemon profile. ultra top — 60 Hz, no animations, blur and shadows,
    // over its own settings, not touching them: left — returned. 0 ultra · 1 saver · 2 balanced · 3 performance.
    // Windows (blur, shadows) applied by caller: demonshot — windows(), glyph — Theme.apply() (windows() would remove its rounding)
    readonly property var modes: [
        { name: "ultra", short: "ULT", what: `power saver · ${rates[0]} hz · still` },
        { name: "saver", short: "ECO", what: "power saver" },
        { name: "balanced", short: "BAL", what: "balanced" },
        { name: "performance", short: "MAX", what: "performance" }
    ]
    readonly property int mode: store.ultra ? 0 : PowerProfiles.profile + 1
    readonly property int modeCount: PowerProfiles.hasPerformanceProfile ? 4 : 3
    function setMode(i) {
        i = Math.max(0, Math.min(modeCount - 1, i));
        const hz0 = hz, moving0 = moving;
        store.ultra = i === 0;
        PowerProfiles.profile = i === 0 ? PowerProfile.PowerSaver : i - 1;
        // monitor — only built-in and if hz really different: output reconfiguration blinks screen and resets hover
        // (panels go out)
        if (hz !== hz0 && mon.name) {
            hypr(rule(mon));
            monReread.restart();
        }
        if (moving !== moving0) motion();
    }
    // what actually stands: ultra overrides settings — lowest screen hz, otherwise nearest to chosen
    readonly property int hz: store.ultra ? rates[0] : refreshHz
    readonly property bool moving: store.motion && !store.ultra && !store.game
    readonly property bool blurOn: store.blur && !store.ultra && !store.game
    readonly property bool shadowOn: store.shadow && !store.ultra && !store.game

    // shell start: everything except brightness (keys and OSD turn it, can't overwrite on every launch)
    function applyAll() {
        monitor(); windows(); motion(); night(); paint(); input(); idle();
    }
}
