pragma Singleton
import QtQuick

QtObject {
  function alpha(color, a) {
    return Qt.rgba(color.r, color.g, color.b, a)
  }

  function clampAlpha(n) {
    if (!isFinite(n)) return 1
    if (n < 0) return 0
    if (n > 1) return 1
    return n
  }
}