pragma Singleton
import QtQuick
import qs.glyph

QtObject {
  id: root

  // Get gaps from Theme (similar to hypr gaps_out / 2)
  readonly property int gapsOut: Theme.corner(10)

  // Animation duration - respect reduce motion
  property bool reduceMotion: false

  function duration(ms) {
    return reduceMotion ? 0 : ms
  }

  // Typography
  readonly property QtObject font: QtObject {
    readonly property int iconSmall: Theme.font.bodySmall
    readonly property int icon: Theme.font.title
    readonly property int iconLarge: Theme.font.heading
    readonly property int bodySmall: Theme.font.bodySmall
    readonly property int body: Theme.font.body
    readonly property int title: Theme.font.title
    readonly property int heading: Theme.font.heading
    readonly property int display: Theme.font.display
  }

  // Spacing
  readonly property QtObject spacing: QtObject {
    readonly property int controlHeight: Theme.space(42)
    readonly property int controlGap: Theme.space(8)
    readonly property int controlPaddingX: Theme.space(10)
    readonly property int controlPaddingY: Theme.space(6)
    readonly property int inputPaddingY: Theme.space(7)
    readonly property int panelPadding: Theme.space(18)
    readonly property int popupPadding: Theme.space(14)
  }
}