import QtQuick
import qs.glyph

Shape {
  id: root
  property var borderSpec: Border.none()
  property real radius: 0
  antialiasing: true

  ShapePath {
    fillColor: "transparent"
    strokeColor: Border.color(root.borderSpec)
    strokeWidth: Border.uniformWidth(root.borderSpec)
    startX: root.radius
    startY: 0
    PathLine { x: root.width - root.radius; y: 0 }
    PathArc { x: root.width; y: root.radius; radiusX: root.radius; radiusY: root.radius; useLargeArc: false }
    PathLine { x: root.width; y: root.height - root.radius }
    PathArc { x: root.width - root.radius; y: root.height; radiusX: root.radius; radiusY: root.radius; useLargeArc: false }
    PathLine { x: root.radius; y: root.height }
    PathArc { x: 0; y: root.height - root.radius; radiusX: root.radius; radiusY: root.radius; useLargeArc: false }
    PathLine { x: 0; y: root.radius }
    PathArc { x: root.radius; y: 0; radiusX: root.radius; radiusY: root.radius; useLargeArc: false }
  }
}