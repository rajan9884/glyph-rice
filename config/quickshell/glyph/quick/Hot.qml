import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// hot edge: cursor lingered at right edge — quick settings slide out (Quick.peek). 2px strip along bottom 80%:
// top corner and scrollbars at edge barely trigger
PanelWindow {
    id: root

    signal triggered

    visible: Theme.state.quickHover
    anchors { right: true; bottom: true }
    implicitWidth: 2
    implicitHeight: Math.round(screen.height * 0.8)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glyph-hot"

    HoverHandler { id: hov; onHoveredChanged: hovered ? dwell.restart() : dwell.stop() }
    Timer { id: dwell; interval: 150; onTriggered: if (hov.hovered) root.triggered() }
}
