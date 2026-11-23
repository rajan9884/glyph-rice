import QtQuick
import qs

// canvas in layout pixels 1920×1080: stretched to parent, everything inside measured as in concept.html
Item {
    width: parent.width / Theme.s
    height: parent.height / Theme.s
    scale: Theme.s
    transformOrigin: Item.TopLeft
}
