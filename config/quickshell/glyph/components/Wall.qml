import QtQuick
import qs

// wallpaper: image as dot matrix (look 0), gray photo in theme tone (1), colored (2) or colored dots (3) — see shaders/wall.frag.
// Two images: one on screen, one incoming. Arrived — wave from origin, at the end they swap roles, old unloads.
// Empty path — transparent: under wallpaper grid and orb. opaque — image covered everything, what's under it doesn't need drawing
Item {
    id: root

    property string path
    property int look: Theme.state.wallLook
    property real pitch: Theme.state.wallPitch
    property real bright: Theme.state.wallBright / 100
    property point origin: Qt.point(width / 2, height / 2)
    property bool animate: true // false — change instantly, without wave
    readonly property bool opaque: fx.hasA > 0 && !run.running

    property bool flip: false // who's on screen: false — ia, true — ib
    readonly property Image cur: flip ? ib : ia
    readonly property Image next: flip ? ia : ib

    function crop(img) {
        const ia = img.implicitWidth / Math.max(1, img.implicitHeight), sa = width / Math.max(1, height);
        return ia > sa ? Qt.size(sa / ia, 1) : Qt.size(1, ia / sa);
    }

    // ---- change: shown — path on screen, coming — in flight ----
    property string shown: ""
    property string coming: ""
    property bool pending: false
    readonly property bool sized: width > 0 && height > 0 // don't load until sized: sourceSize 0 — decode fully

    onSizedChanged: change()
    onPathChanged: change()
    function change() {
        if (!sized) return;
        if (run.running) { // they scroll faster than wave — current early to end
            run.stop();
            swap();
        }
        if (path === shown) {
            pending = false;
            next.source = "";
            return;
        }
        coming = path;
        pending = true;
        next.source = Theme.url(path);
        check();
    }
    function check() {
        if (!pending || next.status === Image.Loading) return;
        pending = false; // Error — goes transparent, like empty
        if (animate) run.restart();
        else swap();
    }
    function swap() {
        flip = !flip;
        shown = coming;
        fx.wave = 0;
        next.source = ""; // now it's old
    }

    NumberAnimation { id: run; target: fx; property: "wave"; from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine; onFinished: root.swap() }

    // texture sources — neighbors of effect, not children: effect without images we hide, and invisible Image scene doesn't update
    // texture. So opacity 0, not visible: false. sourceSize — in logical pixels: Qt multiplies by DPR itself
    Image { id: ia; opacity: 0; asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(root.width, root.height); onStatusChanged: if (root.next === ia) root.check() }
    Image { id: ib; opacity: 0; asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop; sourceSize: ia.sourceSize; onStatusChanged: if (root.next === ib) root.check() }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        visible: hasA > 0 || hasB > 0 || run.running // nothing to draw — no full-screen pass either

        // ---- uniforms ----
        readonly property size size: Qt.size(width, height)
        readonly property point origin: root.origin
        readonly property var srcA: root.cur
        readonly property var srcB: root.next
        readonly property size cropA: root.crop(root.cur)
        readonly property size cropB: root.crop(root.next)
        readonly property real hasA: root.cur.status === Image.Ready ? 1 : 0
        readonly property real hasB: root.next.status === Image.Ready ? 1 : 0
        readonly property color lo: Theme.light ? Theme.fg : Theme.bg
        readonly property color hi: Theme.light ? Theme.bg : Theme.fg
        readonly property color bg: Theme.bg
        readonly property real pitch: root.pitch
        readonly property real bright: root.bright
        property real dots: root.look === 0 || root.look === 3 ? 1 : 0
        property real mono: root.look < 2 ? 1 : 0
        property real wave: 0
        Behavior on dots { NumberAnimation { duration: 700; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Behavior on mono { NumberAnimation { duration: 700 } }

        fragmentShader: Qt.resolvedUrl("shaders/wall.frag.qsb")
    }
}
