import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components

// home backdrop, separate window on background layer: dot grid, halftone orb, wallpaper. Home itself (clock, bento) — layer
// above, transparent: it redraws often (colon, rings, spinning cover), and wallpaper — full-screen shader,
// in one window they'd be computed on every its frame. Here frame — only on wave, view change and orb breathing.
// Image covered everything — don't draw grid and orb, orb doesn't breathe: window stands still
PanelWindow {
    id: root

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "glyph-back"

    readonly property bool home: (Hyprland.monitorFor(screen)?.activeWorkspace?.toplevels.values.length ?? 0) === 0 // own screen empty
    property real phase: 0
    Timer { running: root.home && orb.visible; interval: 100; repeat: true; onTriggered: root.phase += 0.1 }

    Stage {
        id: stage
        Image {
            visible: Theme.state.grid && !wall.opaque
            anchors.fill: parent
            fillMode: Image.Tile
            source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="1.5" fill="#${Theme.hex(Theme.s2)}"/></svg>`)
        }
        Orb { id: orb; visible: Theme.state.orb && !wall.opaque; x: stage.width - 720; y: stage.height - 580; phase: root.phase }
        Wall { id: wall; anchors.fill: parent; path: Theme.wallSrc(Theme.scr(root.screen?.name, "wall")); animate: !Sys.wallOpen }
    }
}
