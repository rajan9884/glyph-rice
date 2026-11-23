import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import "keys.js" as Data

// keys: Nothing OS aesthetic keybindings cheatsheet menu
// Search pill with red caret, category filter chips (Tab), scrollable list of key combos
// Key combos formatted with stylish badges/capsules. Esc closes.
PanelWindow {
    id: root

    readonly property var filters: ["all", "universal", "windows", "workspaces", "apps", "media & sys"]
    property int filter: 0
    property int sel: 0
    readonly property string query: input.text.trim().toLowerCase()

    readonly property var allItems: Data.KEYBINDINGS
    readonly property var view: allItems.filter(item => {
        const matchesCat = filter === 0 || item.cat === filters[filter];
        if (!matchesCat) return false;
        if (!query) return true;
        const q = query;
        return item.desc.toLowerCase().includes(q)
            || item.detail.toLowerCase().includes(q)
            || item.keys.join(" ").toLowerCase().includes(q);
    })
    readonly property var cur: view[sel] ?? null

    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function open() {
        input.text = "";
        filter = 0;
        sel = 0;
        shown = true;
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }
    function move(delta) {
        if (view.length > 0) {
            sel = Math.max(0, Math.min(sel + delta, view.length - 1));
        }
    }

    onQueryChanged: sel = 0
    onFilterChanged: { sel = 0; list.positionViewAtBeginning(); }
    onViewChanged: sel = Math.max(0, Math.min(sel, view.length - 1))
    onSelChanged: list.positionViewAtIndex(sel, ListView.Contain)
    onVisibleChanged: if (visible) input.forceActiveFocus()

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-keys"

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Stage {
        id: stage

        Rectangle {
            id: panel
            x: (stage.width - width) / 2
            y: 120 + 24 * (1 - root.t)
            width: 1040
            height: Math.min(stage.height - 200, 780)
            opacity: root.t
            radius: Theme.corner(44)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            MouseArea { anchors.fill: parent }

            // Search pill
            Rectangle {
                id: search
                x: 34
                y: 28
                width: parent.width - 68
                height: 66
                radius: Theme.corner(33)
                color: Theme.s2

                Icon {
                    id: lens
                    x: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0349}"
                    color: Theme.grey
                    font.pixelSize: 22
                }

                TextInput {
                    id: input
                    focus: true
                    anchors {
                        left: lens.right
                        leftMargin: 16
                        right: chips.left
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    font { family: Theme.ui; pixelSize: 20 }
                    color: Theme.fg
                    selectionColor: Theme.s3
                    clip: true
                    cursorDelegate: Rectangle {
                        width: 2
                        color: Theme.accent
                        Timer {
                            running: input.activeFocus
                            interval: 500
                            repeat: true
                            onTriggered: parent.opacity = 1 - parent.opacity
                        }
                    }

                    Text {
                        visible: !input.text
                        x: 2
                        text: "Search keybindings..."
                        font: input.font
                        color: Theme.mute
                    }

                    Keys.onPressed: e => {
                        const ctrl = e.modifiers & Qt.ControlModifier;
                        if (e.key === Qt.Key_Escape) root.close();
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.close();
                        else if (e.key === Qt.Key_Tab) root.filter = (root.filter + 1) % root.filters.length;
                        else if (e.key === Qt.Key_Backtab) root.filter = (root.filter + root.filters.length - 1) % root.filters.length;
                        else if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) root.move(1);
                        else if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) root.move(-1);
                        else return;
                        e.accepted = true;
                    }
                }

                Row {
                    id: chips
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Repeater {
                        model: root.filters
                        Rectangle {
                            required property string modelData
                            required property int index
                            width: chip.width + 24
                            height: chip.height + 16
                            radius: height / 2
                            color: root.filter === index ? Theme.fg : "transparent"
                            Lb {
                                id: chip
                                anchors.centerIn: parent
                                text: parent.modelData
                                px: 11
                                color: root.filter === parent.index ? Theme.ink : Theme.grey
                            }
                            TapHandler {
                                onTapped: {
                                    root.filter = parent.index;
                                    input.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            // Header info
            Row {
                id: head
                x: 42
                y: search.y + search.height + 22
                spacing: 14
                Num {
                    anchors.baseline: hlab.baseline
                    text: root.view.length
                    font.pixelSize: 28
                }
                Lb {
                    id: hlab
                    text: root.filters[root.filter]
                    px: 13
                }
            }

            // List of keybindings
            ListView {
                id: list
                anchors {
                    left: parent.left
                    leftMargin: 34
                    right: parent.right
                    rightMargin: 34
                    top: head.bottom
                    topMargin: 14
                    bottom: parent.bottom
                    bottomMargin: 28
                }
                clip: true
                model: root.view
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: d
                    required property var modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    width: list.width
                    height: 58

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.corner(16)
                        color: d.on ? Theme.fg : Theme.s2
                        border {
                            width: d.on ? 0 : 1
                            color: Theme.s3
                        }

                        // Left: Action Name & detail
                        Column {
                            anchors {
                                left: parent.left
                                leftMargin: 20
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 3

                            Text {
                                text: d.modelData.desc
                                font { family: Theme.ui; pixelSize: 15; bold: true }
                                color: d.on ? Theme.ink : Theme.fg
                            }

                            Text {
                                text: d.modelData.detail
                                font { family: Theme.mono; pixelSize: 11 }
                                color: d.on ? Theme.s3 : Theme.grey
                            }
                        }

                        // Right: Keys sequence pills
                        Row {
                            anchors {
                                right: parent.right
                                rightMargin: 18
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 6

                            Repeater {
                                model: d.modelData.keys
                                Row {
                                    required property string modelData
                                    required property int index
                                    spacing: 4

                                    Text {
                                        visible: parent.index > 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "+"
                                        font { family: Theme.mono; pixelSize: 12; bold: true }
                                        color: d.on ? Theme.s3 : Theme.grey
                                    }

                                    Rectangle {
                                        height: 28
                                        width: Math.max(30, kText.implicitWidth + 16)
                                        radius: 6
                                        color: d.on ? Theme.s2 : Theme.s3
                                        border {
                                            width: 1
                                            color: d.on ? Theme.s1 : Qt.rgba(1, 1, 1, 0.08)
                                        }

                                        Text {
                                            id: kText
                                            anchors.centerIn: parent
                                            text: parent.parent.modelData
                                            font { family: Theme.mono; pixelSize: 11; bold: true }
                                            color: d.on ? Theme.fg : Theme.fg
                                        }
                                    }
                                }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            root.sel = d.index;
                            input.forceActiveFocus();
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }

            // Footer prompt
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 18 }
                spacing: 34
                Repeater {
                    model: ["↑↓ navigate", "tab category", "esc close"]
                    Lb { required property string modelData; text: modelData; px: 11 }
                }
            }
        }
    }
}
