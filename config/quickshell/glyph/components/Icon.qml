import QtQuick
import qs

// Nerd Font glyph (Material Design). 1em frame, like line-height: 1 in concept (NF line 1.32em)
Text {
    readonly property real lead: -0.16 * font.pixelSize
    font { family: Theme.nf; pixelSize: 19 }
    topPadding: lead
    bottomPadding: lead
    color: Theme.fg
}
