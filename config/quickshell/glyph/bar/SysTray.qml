import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs
import qs.components

// SNI system-tray strip for the bar pill. Mirrors workspace dot size (24×24 circles).
// Vertical bar — column below ws, top bar — row after ws. Left-click activates, right-click opens context menu.
// Hidden when no items; menu popup anchors to the clicked icon.
Item {
    id: root

    property bool vert: true  // matches Bar.vert

    // filter out apps handled natively by Quickshell: clash-verge (Vpn.qml), blueman (Quickshell.Bluetooth module)
    readonly property var items: SystemTray.items.values.filter(i =>
        !i.id.includes("clash-verge") &&
        !i.id.toLowerCase().includes("blueman") &&
        !i.id.toLowerCase().includes("bluetooth")
    )

    visible: items.length > 0

    // natural size: a column or row of 24-px circles, spacing 4 (same as ws Pile)
    implicitWidth:  vert ? 24 : items.length * 24 + Math.max(0, items.length - 1) * 4
    implicitHeight: vert ? items.length * 24 + Math.max(0, items.length - 1) * 4 : 24

    // ---- icon strip ----
    Repeater {
        id: rep
        model: root.items

        Item {
            id: cell
            required property SystemTrayItem modelData
            required property int index

            x: root.vert ? 0 : index * 28
            y: root.vert ? index * 28 : 0
            width:  24
            height: 24

            // circle background — matches workspace dot style
            Rectangle {
                id: bg
                anchors.fill: parent
                radius: 12
                color: cellHov.hovered ? Theme.s2 : "transparent"
                border { width: cellHov.hovered ? 1 : 0; color: Theme.s3 }
                Behavior on color { ColorAnimation { duration: Theme.t } }
            }

            // icon — theme icon path provided by Quickshell's SystemTrayItem
            Image {
                id: ico
                anchors.centerIn: parent
                width: 16
                height: 16
                source: cell.modelData.icon
                smooth: true
                mipmap: true
                // in light theme tray icons are often dark, so we don't invert; leave as-is like buds
            }

            HoverHandler { id: cellHov; cursorShape: Qt.PointingHandCursor }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    if (cell.modelData.onlyMenu) {
                        menuPopup.open(cell);
                    } else {
                        cell.modelData.activate();
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: menuPopup.open(cell)
            }
        }
    }

    // ---- context menu popup ----
    // Single shared popup: opens beside the tapped icon, fades in/out
    PopupWindow {
        id: menuPopup

        property Item src: null
        property real t: visible ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

        visible: opener.menu !== null && src !== null && _open
        property bool _open: false

        color: "transparent"
        implicitWidth:  Math.ceil(260 * Theme.s)
        implicitHeight: Math.ceil(card.height * Theme.s)

        // anchor beside the clicked cell; for vert bar → right side, for top bar → below
        anchor.item: menuPopup.src ?? root
        anchor.rect: src ? (root.vert
            ? Qt.rect(src.width + 8, 0, 1, 1)
            : Qt.rect(0, src.height + 8, 1, 1))
            : Qt.rect(0, 0, 1, 1)
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: root.vert ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Left

        function open(cell) {
            src = cell;
            _open = true;
        }
        function close() { _open = false; src = null; }

        // keep the DBusMenu alive while popup is shown
        QsMenuOpener {
            id: opener
            menu: menuPopup._open && menuPopup.src !== null ? menuPopup.src.modelData?.menu ?? null : null
        }

        Stage {
            Rectangle {
                id: card
                width: 260
                height: Math.max(0, menuItems.height + 20)
                radius: Theme.corner(28)
                color: Theme.s2
                border { width: 1; color: Theme.s3 }
                opacity: menuPopup.t
                transform: Translate {
                    x: root.vert ? -10 * (1 - menuPopup.t) : 0
                    y: root.vert ? 0 : -10 * (1 - menuPopup.t)
                }

                // click outside → close
                HoverHandler { id: cardHov }

                Column {
                    id: menuItems
                    x: 10
                    y: 10
                    width: parent.width - 20

                    Repeater {
                        model: opener.children

                        Item {
                            id: row
                            required property QsMenuEntry modelData
                            readonly property bool sep: modelData.isSeparator
                            readonly property bool on: modelData.checkState === Qt.Checked
                            width: menuItems.width
                            height: sep ? 13 : 36

                            // separator line
                            Rectangle {
                                visible: row.sep
                                anchors.centerIn: parent
                                width: parent.width - 16
                                height: 1
                                color: Theme.s3
                            }

                            // row background
                            Rectangle {
                                visible: !row.sep
                                anchors.fill: parent
                                radius: Theme.corner(18)
                                color: rowHov.hovered && row.modelData.enabled ? Theme.s3 : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.t } }
                            }

                            // label
                            Text {
                                visible: !row.sep
                                anchors {
                                    left: parent.left; leftMargin: 14
                                    right: row.modelData.buttonType !== QsMenuButtonType.None && !row.modelData.hasChildren
                                           ? checkDot.left : parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                text: row.modelData.text
                                font { family: Theme.ui; pixelSize: 13 }
                                color: row.modelData.enabled ? Theme.fg : Theme.mute
                            }

                            // submenu chevron
                            Icon {
                                visible: row.modelData.hasChildren
                                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: "\u{F0142}"
                                color: Theme.grey
                            }

                            // check/radio dot
                            Rectangle {
                                id: checkDot
                                visible: row.modelData.buttonType !== QsMenuButtonType.None && !row.modelData.hasChildren
                                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                width: 10; height: 10; radius: 5
                                color: row.on ? Theme.fg : "transparent"
                                border { width: 1.5; color: row.on ? Theme.fg : Theme.mute }
                            }

                            HoverHandler { id: rowHov; enabled: !row.sep; cursorShape: row.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
                            TapHandler {
                                enabled: !row.sep && row.modelData.enabled
                                onTapped: {
                                    row.modelData.triggered();
                                    menuPopup.close();
                                }
                            }
                        }
                    }
                }
            }
        }

        // close when cursor leaves card area
        Timer {
            interval: 400
            running: menuPopup.visible && !cardHov.hovered
            onTriggered: menuPopup.close()
        }
    }
}
