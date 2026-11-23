//@ pragma IconTheme Rice
// own icon theme, not qtengine: not loaded — Qt searches only hicolor, and kcalc etc. empty circles (#11)
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar"
import "buds"
import "cal"
import "charms"
import "clip"
import "deck"
import "glyph"
import "home"
import "launcher"
import "power"
import "prefs"
import "quick"
import "settings"
import "shot"
import "vpn"
import "wall"
import "keys"

// glyph: rice in nothing os spirit. Home on wallpaper, bar, launcher, quick settings,
// Glyph bars at edges instead of OSD, notification island, power menu, settings, deck (dashboard bottom), clipboard, charms (emoji and symbols), screenshots, vpn, wallpaper. Lock — separate process (lock.qml).
// Switches with demonshot via `rice switch` / Rice app — hypr binds shared (shell:*), each shell takes its own
ShellRoot {
    id: shell

    Launcher { id: launcher }
    Quick {
        id: quick
        onPowerRequested: power.open()
        onSettingsRequested: prefs.open()
        onPortalRequested: vpn.requestSignIn()
    }
    Power { id: power }
    Prefs { id: prefs; onWallRequested: walls.open() }
    Glyph {}
    Buds {}
    Cal { id: cal }
    Clip { id: clip }
    Charms { id: charms }
    Deck { id: deck }
    Shot { id: shot }
    Vpn { id: vpn; wifiNetwork: quick.net }
    Walls { id: walls }
    Keys { id: keys }

    Variants {
        model: Quickshell.screens
        Scope {
            id: s
            required property var modelData
            Back { screen: s.modelData }
            // bar and home can be removed from screen (settings → display), wallpaper stays. Here, not in window: visible from own
            // screen — loop (window recreated, screen changes)
            Home { screen: s.modelData; visible: Theme.scr(s.modelData.name, "home") }
            Hot { screen: s.modelData; onTriggered: quick.peek() }
            Bar {
                screen: s.modelData
                visible: Theme.scr(s.modelData.name, "bar")
                onMarkClicked: launcher.toggle()
                onTrayClicked: quick.toggle()
                onPowerClicked: power.visible ? power.close() : power.open()
                onClockClicked: cal.toggle()
            }
        }
    }

// hypr like demonshot: its Rules (settings/Rules.qml, same ~/.config/demonshot/rules.json) sets monitor, input,
// motion, night and hypridle; on top Theme.apply — own border colors, rounding and kitty. We call it on theme change
    Component.onCompleted: {
        hypr();
        if (Theme.state.paint) Theme.apps(); // rice start sets links to term/ — color must be returned
        Rules.night();
        Rules.idle();
    }
    // what lives in hypr config. It re-reads it itself: saved any hypr file (live links — git pull and branch switch), hyprctl reload —
// branch), hyprctl reload — returns variables.lua defaults: demonshot borders, monitor, input, animations. Overlay ours again.
// hyprctl eval configreloaded doesn't send — no loop. Night and hypridle — own processes, reload doesn't touch them
    function hypr() {
        Rules.monitor();
        Rules.input();
        Rules.motion();
        Theme.apply();
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "configreloaded") shell.hypr(); }
    }
    // screen connected — its scale and hertz from prefs → display (Rules.store.outs)
    Connections {
        target: Quickshell
        function onScreensChanged() { Rules.monitor(true); }
    }
    Connections {
        target: Theme
        function onGreysChanged() { paint.restart(); }
    }
// theme or color changed (style, new wallpaper) — windows, kitty, gtk and qt. In 300 ms: new wallpaper tones don't come immediately,
// and gtk not worth poking twice
    Timer { id: paint; interval: 300; onTriggered: { Theme.apply(); Theme.apps(); } }
    // wallpaper tones (Theme.pick) — here, not in Theme: lock loads it, it has ready ones from glyph.json. Empty — wallpaper copy not
    // loaded (grays give 16 colors): old tones remain. New wallpaper — from first tone
    ColorQuantizer {
        source: Theme.url(Theme.wallSrc(Theme.wall))
        depth: 4
        rescaleSize: 64
        onColorsChanged: {
            if (!colors.length) return;
            const t = Theme.pick(colors);
            if (t.join() === Theme.state.tones.join()) return;
            Theme.state.tones = t;
            Theme.state.paintAt = 0;
        }
    }
    Connections {
        target: Theme.state
        function onRoundingChanged() { Theme.apply(); }
    }
    // ultra mode toggles blur and shadows over settings — windows repaint (hertz and motion set by Rules.setMode itself).
    // Game — same plus animations
    Connections {
        target: Rules.store
        function onUltraChanged() { Theme.apply(); }
        function onGameChanged() { Rules.motion(); Theme.apply(); }
    }

    // Launcher opens only on Super+Space (shell:menu). Super tap removed.
    // launcherArm/launcherInterrupt kept so demonshot shell compat stubs don't error
    Shortcut { name: "launcher"; description: "launcher (unused — use Super+Space)"; onPressed: {} }
    Shortcut { name: "launcherArm"; description: "stub — no-op"; onPressed: {} }
    Shortcut { name: "launcherInterrupt"; description: "stub — no-op"; onPressed: {} }
    // Super+Space → deck / bottom dashboard
    Shortcut { name: "altar"; description: "deck: bottom dashboard"; onPressed: deck.toggle() }
    Shortcut { name: "quick"; description: "quick settings"; onPressed: quick.toggle() }
    Shortcut { name: "ward"; description: "quick settings"; onPressed: quick.toggle() } // Super+N at demonshot — same toggles
    Shortcut { name: "settings"; description: "settings"; onPressed: prefs.toggle() }
    Shortcut { name: "power"; description: "power menu"; onPressed: power.visible ? power.close() : power.open() }
    Shortcut { name: "shot"; description: "screenshot"; onPressed: shot.open() }
    Shortcut { name: "pact"; description: "vpn: clash verge"; onPressed: vpn.toggle() }
    Shortcut { name: "clip"; description: "clipboard"; onPressed: clip.toggle() }
    Shortcut { name: "charms"; description: "emoji, kaomoji, symbols"; onPressed: charms.toggle() }
    Shortcut { name: "wall"; description: "wallpapers"; onPressed: walls.toggle() }
    Shortcut { name: "menu"; description: "app launcher menu"; onPressed: launcher.toggle() }
    Shortcut { name: "keys"; description: "keybindings cheatsheet"; onPressed: keys.toggle() }
    Shortcut { name: "game"; description: "game mode"; onPressed: Rules.store.game = !Rules.store.game }
    // screen recording shortcuts — keybinds call these so UI and keybinds share the same toggleRec() logic
    Shortcut { name: "rec";       description: "record full screen + audio"; onPressed: { Theme.state.recArea = 0; Theme.state.recAudio = 1; Sys.toggleRec(); } }
    Shortcut { name: "recSilent"; description: "record full screen, no audio"; onPressed: { Theme.state.recArea = 0; Theme.state.recAudio = 0; Sys.toggleRec(); } }
    Shortcut { name: "recRegion"; description: "record region, no audio";     onPressed: { Theme.state.recArea = 1; Theme.state.recAudio = 0; Sys.toggleRec(); } }

    component Shortcut: GlobalShortcut { appid: "shell" }
}
