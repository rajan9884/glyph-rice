pragma Singleton
import QtQuick
import qs.glyph

QtObject {
  id: root

  function none() {
    return flat("transparent", 0)
  }

  function flat(color, width) {
    return {
      color: color || "transparent",
      widths: parseWidthSpec(width, 0),
      gradient: { colors: [], angle: 0, enabled: false },
    }
  }

  function parseWidthSpec(raw, fallback) {
    var n = Number(raw)
    if (isFinite(n) && n >= 0) return { top: n, right: n, bottom: n, left: n }
    var parts = String(raw || "").split(/\s+/)
    if (parts.length >= 4) return { top: Number(parts[0]), right: Number(parts[1]), bottom: Number(parts[2]), left: Number(parts[3]) }
    if (parts.length === 3) return { top: Number(parts[0]), right: Number(parts[1]), bottom: Number(parts[2]), left: Number(parts[1]) }
    if (parts.length === 2) return { top: Number(parts[0]), right: Number(parts[1]), bottom: Number(parts[0]), left: Number(parts[1]) }
    return { top: fallback, right: fallback, bottom: fallback, left: fallback }
  }

  function maxWidth(spec) {
    if (!spec || !spec.widths) return 0
    return Math.max(spec.widths.top, spec.widths.right, spec.widths.bottom, spec.widths.left)
  }

  function needsOverlay(spec) {
    if (!spec) return false
    var w = spec.widths
    if (!w) return false
    if (w.top !== w.right || w.top !== w.bottom || w.top !== w.left) return true
    return spec.gradient && spec.gradient.enabled
  }

  function canUseNative(spec) {
    return !needsOverlay(spec)
  }

  function top(spec) { return spec && spec.widths ? spec.widths.top : 0 }
  function right(spec) { return spec && spec.widths ? spec.widths.right : 0 }
  function bottom(spec) { return spec && spec.widths ? spec.widths.bottom : 0 }
  function left(spec) { return spec && spec.widths ? spec.widths.left : 0 }
  function uniformWidth(spec) { return spec && spec.widths ? spec.widths.top : 0 }
  function color(spec) { return spec ? spec.color : "transparent" }

  function surfaceSpec(section, token, fallbackColor, fallbackWidth, alphaKey) {
    // For glyph-rice, we use Theme colors directly
    var opacity = 1.0
    return {
      color: fallbackColor,
      widths: parseWidthSpec(fallbackWidth, fallbackWidth),
      gradient: { colors: [], angle: 0, enabled: false },
    }
  }
}