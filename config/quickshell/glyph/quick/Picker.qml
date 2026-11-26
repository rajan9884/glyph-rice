import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Io
import qs
import qs.components

// list under pills (right click on Wi-Fi/Bluetooth). Networks: click connects and disconnects, new protected — password line.
// Devices: paired click connects/disconnects, foreign — pairs. Searches only while list open
Rectangle {
    id: root
    property string kind // "wifi" | "bt" | "" — closed
    signal touched       // any click inside — panel pinned
    signal portalRequested

    readonly property bool open: kind === "wifi" || kind === "bt"
    // what's shown: closed — remains while list compresses (Quick), otherwise it'd empty right away
    property string shown
    onVisibleChanged: if (!visible) shown = ""
    readonly property bool isWifi: shown === "wifi"
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool on: isWifi ? Networking.wifiEnabled : bt?.enabled ?? false
    // network with captive portal: clicking connected network opens the portal sign-in page
    readonly property bool portal: Networking.connectivity === NetworkConnectivity.Portal

    property var ask: null // network that needs a password
    readonly property bool isEnterprise: root.ask ? (
        root.ask.security === WifiSecurityType.Wpa2Eap ||
        root.ask.security === WifiSecurityType.WpaEap ||
        root.ask.security === WifiSecurityType.Wpa3SuiteB192 ||
        /enterprise|eap|802\.1x/i.test(WifiSecurityType.toString(root.ask.security)) ||
        /byod|univfi/i.test(root.ask.name || "")
    ) : false
    // trust — when pairing done, not before: trusted BlueZ lets incoming connections without ask, and cancelled
    // pairing with foreign "headphone" would leave it trusted. Trusted reconnects itself (headphones from case)
    property var pend: null
    Connections {
        target: root.pend
        function onPairedChanged() { if (root.pend.paired) { root.pend.trusted = true; root.pend = null; } }
    }
    property string err
    // kind, not open: binding open to this signal may not be recalculated yet, and first opening showed bluetooth
    onKindChanged: { if (kind === "wifi" || kind === "bt") shown = kind; ask = null; err = ""; fl.contentY = 0; }
    onAskChanged: {
        pw.clear();
        ident.clear();
        if (ask) {
            Qt.callLater(revealPassword);
            Qt.callLater(() => {
                if (root.isEnterprise) ident.forceActiveFocus();
                else pw.forceActiveFocus();
            });
        } else {
            fl.contentY = 0;
            if (pw.activeFocus || ident.activeFocus) root.forceActiveFocus();
        }
    }
    function revealPassword() {
        if (ask && visible) fl.contentY = Math.max(0, fl.contentHeight - fl.height);
    }

    Binding { when: root.kind === "wifi" && root.on; target: root.wifi; property: "scannerEnabled"; value: true }
    Binding { when: root.kind === "bt" && root.on; target: root.bt; property: "discovering"; value: true }

    // own at top, then saved, then by strength. While entering password — only that network: resort won't eat typed
    readonly property var nets: !isWifi || !wifi ? [] : wifi.networks.values.filter(n => n.name)
        .sort((a, b) => b.connected - a.connected || b.known - a.known || b.signalStrength - a.signalStrength).slice(0, 6)
    // unnamed (only address) — air noise
    readonly property var devs: shown !== "bt" || !bt ? [] : bt.devices.values.filter(d => d.paired || d.deviceName)
        .sort((a, b) => b.connected - a.connected || b.paired - a.paired).slice(0, 6)
    readonly property var rows: !on ? [] : ask ? [ask] : isWifi ? nets : devs

    function bars(n) {
        const lock = n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
        const i = Math.min(3, Math.floor(n.signalStrength * 4));
        return (lock ? ["\u{F0920}", "\u{F0923}", "\u{F0926}", "\u{F0929}"] : ["\u{F091F}", "\u{F0922}", "\u{F0925}", "\u{F0928}"])[i];
    }
    function btIcon(i) {
        return /audio|head/.test(i) ? "\u{F02CB}" : /mouse/.test(i) ? "\u{F037D}" : /keyboard/.test(i) ? "\u{F030C}" : /phone/.test(i) ? "\u{F03F2}" : "\u{F00AF}";
    }
    // Supports both WPA-Personal (PSK) and WPA-Enterprise (802.1X EAP-PEAP)
    function tap(o) {
        touched();
        err = "";
        if (!isWifi) {
            if (o.pairing) {
                if (pend === o) pend = null;
                return o.cancelPair();
            }
            if (!o.paired) { pend = o; return o.pair(); }
            return o.connected ? o.disconnect() : o.connect();
        }
        if (o.connected) return portal ? portalRequested() : o.disconnect();
        if (o.known || o.security === WifiSecurityType.Open || o.security === WifiSecurityType.Owe) return o.connect();
        ask = o;
    }

    // ceiling set by Quick: above — list scrolls, not pushes panel off screen
    property real max: Infinity
    height: Math.max(0, Math.min(list.height + 32, max))
    radius: Theme.corner(30)
    color: Theme.s2

    Flickable {
        id: fl
        x: 16
        y: 16
        width: parent.width - 32
        height: Math.max(0, parent.height - 32)
        contentHeight: list.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: fl.width
            spacing: 4

            Item {
                width: parent.width
                height: 24
                Lb {
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: !root.on ? `${root.isWifi ? "wi-fi" : "bluetooth"} · off`
                        : root.ask ? (root.isEnterprise ? "enterprise credentials" : "password")
                        : root.isWifi ? `networks · ${root.nets.length}` : `devices · ${root.bt?.discovering ? "searching" : root.devs.length}`
                }
                Lb {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    rightPadding: 4
                    width: Math.min(implicitWidth, parent.width * 0.6)
                    elide: Text.ElideRight
                    visible: !!root.err || !!root.ask
                    text: root.err || "cancel"
                    color: Theme.fg
                    TapHandler { onTapped: { root.touched(); root.err = ""; root.ask = null; } }
                }
            }

            Repeater {
                model: root.rows
                Rectangle {
                    id: row
                    required property var modelData
                    readonly property var o: modelData
                    readonly property bool on: o.connected
                    readonly property bool busy: root.isWifi ? o.stateChanging : o.pairing || o.state === BluetoothDeviceState.Connecting || o.state === BluetoothDeviceState.Disconnecting
                    width: list.width
                    height: 56
                    radius: Theme.corner(28)
                    color: hov.hovered ? Theme.s3 : "transparent"

                    Rectangle {
                        id: ic
                        x: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: row.on ? Theme.fg : Theme.s3
                        Icon {
                            anchors.centerIn: parent
                            text: root.isWifi ? root.bars(row.o) : root.btIcon(row.o.icon)
                            font.pixelSize: 19
                            color: row.on ? Theme.ink : Theme.fg
                            // connection in progress — icon breathes
                            SequentialAnimation on opacity {
                                running: row.busy
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) parent.opacity = 1
                                NumberAnimation { to: 0.25; duration: 450 }
                                NumberAnimation { to: 1; duration: 450 }
                            }
                        }
                    }
                    Column {
                        anchors { left: ic.right; leftMargin: 14; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        Text { textFormat: Text.PlainText; width: parent.width; elide: Text.ElideRight; text: row.o.name || row.o.address; font { family: Theme.ui; pixelSize: 15; weight: Font.DemiBold } color: Theme.fg }
                        Lb {
                            px: 10
                            text: root.isWifi
                                ? `${row.on ? (root.portal ? "sign in" : "connected") : row.busy ? "connecting" : row.o.known ? "saved" : WifiSecurityType.toString(row.o.security).toLowerCase()} · ${Math.round(row.o.signalStrength * 100)}%`
                                : (row.o.pairing ? "pairing" : row.o.state === BluetoothDeviceState.Connecting ? "connecting" : row.o.state === BluetoothDeviceState.Disconnecting ? "disconnecting"
                                   : row.on ? "connected" : row.o.paired ? "paired" : "pair") + (row.o.batteryAvailable ? ` · ${Math.round(row.o.battery * 100)}%` : "")
                        }
                    }
                    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.tap(row.o) }
                    // right click on saved — forget
                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: { root.touched(); if (row.o.known || row.o.paired) row.o.forget(); } }
                    // no password or wrong one — NM asks secret: password line again
                    Connections {
                        target: root.isWifi ? row.o : null
                        ignoreUnknownSignals: true
                        function onConnectionFailed(r) {
                            if (r === ConnectionFailReason.NoSecrets) root.ask = row.o;
                            else root.err = ConnectionFailReason.toString(r);
                        }
                    }
                }
            }

            Rectangle {
                visible: !!root.ask
                width: list.width
                height: root.isEnterprise ? 104 : 56
                radius: Theme.corner(28)
                color: Theme.s1
                border { width: 1; color: Theme.s3 }
                clip: true

                Column {
                    anchors.fill: parent

                    Item {
                        visible: root.isEnterprise
                        width: parent.width
                        height: root.isEnterprise ? 48 : 0
                        TextInput {
                            id: ident
                            anchors { left: parent.left; leftMargin: 22; right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                            font { family: Theme.mono; pixelSize: 14 }
                            color: Theme.fg
                            selectionColor: Theme.fg
                            selectedTextColor: Theme.ink
                            clip: true
                            onAccepted: pw.forceActiveFocus()
                            Lb { visible: !ident.text; anchors.verticalCenter: parent.verticalCenter; text: "identity / username"; color: Theme.mute }
                        }
                    }

                    Rectangle {
                        visible: root.isEnterprise
                        width: parent.width - 28
                        height: root.isEnterprise ? 1 : 0
                        color: Theme.s3
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item {
                        width: parent.width
                        height: root.isEnterprise ? 55 : 56
                        TextInput {
                            id: pw
                            anchors { left: parent.left; leftMargin: 22; right: go.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            font { family: Theme.mono; pixelSize: 16; letterSpacing: 2 }
                            color: Theme.fg
                            selectionColor: Theme.fg
                            selectedTextColor: Theme.ink
                            clip: true
                            onAccepted: if ((root.isEnterprise ? !!ident.text : true) && !!text) go.send()
                            Lb { visible: !pw.text; anchors.verticalCenter: parent.verticalCenter; text: "enter password"; color: Theme.mute }
                        }
                        Rectangle {
                            id: go
                            readonly property bool ready: root.isEnterprise ? (!!ident.text && !!pw.text) : !!pw.text
                            function send() {
                                root.touched();
                                if (root.isEnterprise) {
                                    connectEap.ssid = root.ask.name;
                                    connectEap.user = ident.text;
                                    connectEap.pass = pw.text;
                                    connectEap.running = true;
                                } else {
                                    root.ask.connectWithPsk(pw.text);
                                }
                                ident.text = "";
                                pw.text = "";
                                root.ask = null;
                            }
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            width: 44
                            height: 44
                            radius: 22
                            color: ready ? Theme.fg : Theme.s3
                            Icon { anchors.centerIn: parent; text: "\u{F0054}"; font.pixelSize: 19; color: go.ready ? Theme.ink : Theme.grey }
                            TapHandler { onTapped: if (go.ready) go.send() }
                        }
                    }
                }
            }

            Process {
                id: connectEap
                property string ssid: ""
                property string user: ""
                property string pass: ""
                command: [
                    "bash", "-c",
                    'con="$1"; usr="$2"; pass="$3"; ' +
                    'nmcli connection delete "$con" 2>/dev/null; ' +
                    'nmcli connection add type wifi ifname "*" con-name "$con" ssid "$con" ' +
                    'wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2 ' +
                    '802-1x.identity "$usr" 802-1x.password "$pass" && nmcli connection up "$con"',
                    "--", ssid, user, pass
                ]
                onExited: (code) => {
                    if (code !== 0) root.err = "connection failed";
                }
            }

            Lb {
                visible: root.on && !root.ask && !root.rows.length
                x: 4
                topPadding: 4
                bottomPadding: 4
                text: root.isWifi ? "scanning…" : "nothing nearby"
            }
        }
    }
}
