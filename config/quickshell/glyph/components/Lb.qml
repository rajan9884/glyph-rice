import QtQuick
import qs

// label: Space Mono caps, tracking .14em, gray. Size — px (not font.pixelSize: tracking computed from it)
Text {
    textFormat: Text.PlainText // labels contain foreign strings (networks, devices, windows, tracks): AutoText would load <img src="http://…"> from them
    property real px: 12
    font { family: Theme.mono; pixelSize: px; letterSpacing: px * 0.14; capitalization: Font.AllUppercase }
    color: Theme.grey
}
