import QtQuick
import qs

// bar: column at left edge, row at top (Theme.state.barAt); centered across. Only columns — rows Grid counts itself,
// otherwise when edge changes, columns and rows change one by one and briefly becomes 1×1 ("more visible items than rows*columns" in log).
// Separate file, not inline component: new inline component breaks hot reload ("is not a type") until qs restart.
Grid {
    readonly property bool vert: Theme.state.barAt !== "top"
    columns: vert ? 1 : 99
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
}
