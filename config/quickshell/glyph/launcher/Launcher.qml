import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs
import qs.components

// launcher: tap Super or Super+Space. Panel 860 centered, screen dims to 74%. Search pill with red caret,
// modes as chips (Tab): apps / style / tray / calc. Without query — «recent» and all apps grid of 6, alphabet on right.
// style — color, like scheme in caelestia: from where (nothing, wallpaper, palette), under it — wallpaper tones and variants (tonal spot…) or palettes
// (catppuccin, rosé pine…), theme (Theme.styles, same as STYLE in settings). Circles — samples, dot — what's set,
// ↵ sets and launcher doesn't close. With palettes search — also by group: «catppuccin».
// tray — background apps from tray (discord, telegram…): click — their window, hover — their menu as card under circle.
// Appears like Charms and Clip: lift by 24 and fade. Icons — theme icons as dots in circles; chosen — white circle
PanelWindow {
    id: root

    property int mode: 0
    property int sel: 0
    readonly property var modes: ["apps", "style", "tray", "calc"]
    readonly property string query: input.text
    property var uses: ({}) // app id → times opened

    // icon from theme or path from .desktop; if missing (or file) — generic app icon, not empty circle
    function icon(name) { return Quickshell.iconPath(name || "application-x-executable", "application-x-executable"); }

    // on start DesktopEntries adds entries one by one (~160 valuesChanged): binding would rebuild grid on each —
    // seconds of freeze. Collect once when list quiets down
    property var apps: []
    Timer {
        id: appsT
        interval: 300
        running: true
        onTriggered: root.apps = DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
            id: e.id, name: e.name, src: root.icon(e.icon),
            extra: `${e.id} ${e.genericName} ${(e.keywords ?? []).join(" ")}`.toLowerCase(), run: () => e.execute()
        })).sort((a, b) => a.name.localeCompare(b.name))
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { appsT.restart(); }
    }
    // tray — only while tray mode open: otherwise every new message (counter in telegram tooltip) would rebuild
    // list. Name — tooltip, discord has empty title. Only menu (onlyMenu) — click doesn't close launcher, menu is already under it
    readonly property var tray: !visible || mode !== 2 ? [] : SystemTray.items.values.map(i => ({
        name: i.tooltipTitle || i.title || i.id, src: i.icon, extra: i.id.toLowerCase(), tray: i,
        keep: i.onlyMenu, run: () => i.onlyMenu || i.activate()
    }))

    // subsequence: word start and consecutive — higher. hl — indices of matched letters
    function match(s, q) {
        if (!q) return { score: 1, hl: [] };
        const l = s.toLowerCase(), hl = [], at = l.indexOf(q);
        if (at >= 0) { for (let k = 0; k < q.length; k++) hl.push(at + k); return { score: (at === 0 ? 100 : 50) - at, hl }; }
        let i = 0;
        for (const c of q) {
            i = l.indexOf(c, i);
            if (i < 0) return null;
            hl.push(i++);
        }
        return { score: 10, hl };
    }
    function filter(src, q) {
        const out = [];
        for (const it of src) {
            const m = match(it.name, q);
            if (m) out.push(Object.assign({}, it, { hl: m.hl, score: m.score }));
            else if (it.extra.includes(q)) out.push(Object.assign({}, it, { hl: [], score: 1 }));
        }
        return out.sort((a, b) => b.score - a.score || (uses[b.id] ?? 0) - (uses[a.id] ?? 0));
    }

    // blocks: { head, sub, items }; each cell gets row/col, arrows move by them
    readonly property var blocks: {
        const q = query.trim().toLowerCase();
        let b;
        if (mode === 1) b = Theme.styles.map(x => ({ head: x.head, items: filter(x.items.map(it => Object.assign({ extra: "", keep: true }, it)), q) })).filter(x => x.items.length);
        else if (mode === 3) b = [];
        else if (mode === 2) b = [{ head: "tray", sub: String(tray.length), items: filter(tray, q) }];
        else if (q) {
            const r = filter(apps, q);
            b = [{ head: "results", sub: String(r.length), items: r }];
        } else {
            const recent = apps.filter(a => uses[a.id]).sort((a, b) => uses[b.id] - uses[a.id]).slice(0, 6);
            b = (recent.length ? [{ head: "recent", items: recent }] : []).concat([{ head: "all apps", sub: String(apps.length), all: true, items: apps }]);
        }
        let row = 0, k = 0;
        for (const x of b) {
            x.items = x.items.map((it, i) => Object.assign({}, it, { row: row + Math.floor(i / 6), col: i % 6, k: k++ }));
            row += Math.ceil(x.items.length / 6);
        }
        return b;
    }
    readonly property var flat: blocks.reduce((a, x) => a.concat(x.items), [])
    readonly property var cur: flat[sel] ?? null

    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function open() {
        input.text = "";
        menuOpen = false;
        mode = 0;
        sel = 0;
        flick.contentY = 0;
        shown = true;
        input.forceActiveFocus();
    }
    function close() { menuOpen = false; shown = false; }
    function toggle() { shown ? close() : open(); }
    function move(dr, dc) {
        if (!flat.length) return;
        if (dc) return sel = (sel + dc + flat.length) % flat.length;
        const c = cur, row = flat.filter(x => x.row === c.row + dr);
        if (row.length) sel = row.reduce((a, x) => Math.abs(x.col - c.col) < Math.abs(a.col - c.col) ? x : a).k;
    }
    function launch() {
        if (!shown) return; // Theme.t fades and still catches clicks: second click of double — second window
        if (mode === 3) {
            if (calcOut) Quickshell.execDetached(["wl-copy", "--", calcOut]);
            return close();
        }
        const it = cur;
        if (!it) return;
        if (it.keep) return it.run();
        close();
        if (it.id) {
            uses = Object.assign({}, uses, { [it.id]: (uses[it.id] ?? 0) + 1 });
            usesFile.setText(JSON.stringify(uses));
        }
        it.run();
    }

    FileView {
        id: usesFile
        path: Quickshell.statePath("launcher-uses.json")
        printErrors: false
        onLoaded: try { root.uses = JSON.parse(text()); } catch (e) {}
    }

    property string calcOut: ""
    Process { id: calc; stdout: StdioCollector { onStreamFinished: root.calcOut = text.trim() } }
    onQueryChanged: {
        sel = 0;
        if (mode === 3 && query.trim()) calc.exec(["qalc", "-t", query]); // exec kills previous calculation
        else calcOut = "";
    }
    onModeChanged: { sel = 0; flick.contentY = 0; menuOpen = false; if (mode === 3) queryChanged(); }
    // list shrank without new query (app left tray) — cursor past end, cur empty
    onFlatChanged: sel = Math.max(0, Math.min(sel, flat.length - 1))

    onVisibleChanged: if (visible) input.forceActiveFocus()

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-launcher"

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Stage {
        id: stage

        Rectangle {
            id: panel
            x: (stage.width - width) / 2
            y: 140 + 24 * (1 - root.t)
            width: 860
            height: Math.min(stage.height - 280, 30 + 66 + 20 + body.height + 34)
            opacity: root.t
            radius: Theme.corner(44)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            MouseArea { anchors.fill: parent }

            // search: pill, red caret, mode chips
            Rectangle {
                id: search
                x: 34
                y: 30
                width: parent.width - 68
                height: 66
                radius: Theme.corner(33)
                color: Theme.s2

                Icon { id: lens; x: 24; anchors.verticalCenter: parent.verticalCenter; text: "\u{F0349}"; color: Theme.grey; font.pixelSize: 22 }
                TextInput {
                    id: input
                    anchors { left: lens.right; leftMargin: 16; right: chips.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    font { family: Theme.ui; pixelSize: 22 }
                    color: Theme.fg
                    selectionColor: Theme.s3
                    clip: true
                    cursorDelegate: Rectangle {
                        width: 2
                        color: Theme.accent
                        Timer { running: input.activeFocus; interval: 500; repeat: true; onTriggered: parent.opacity = 1 - parent.opacity }
                    }
                    Text {
                        visible: !input.text
                        x: 6
                        text: ["Search apps", "Color from nothing, the wallpaper or a palette", "Apps running in the background", "2 + 2, 20 usd to eur…"][root.mode]
                        font: input.font
                        color: Theme.mute
                    }
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) root.close();
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.launch();
                        else if (e.key === Qt.Key_Tab) root.mode = (root.mode + 1) % 4;
                        else if (e.key === Qt.Key_Backtab) root.mode = (root.mode + 3) % 4;
                        else if (e.key === Qt.Key_Down) root.move(1, 0);
                        else if (e.key === Qt.Key_Up) root.move(-1, 0);
                        else if (e.key === Qt.Key_Right && (!input.text || input.cursorPosition === input.text.length) && root.flat.length) root.move(0, 1);
                        else if (e.key === Qt.Key_Left && (!input.text || input.cursorPosition === 0) && root.flat.length) root.move(0, -1);
                        else return;
                        e.accepted = true;
                    }
                }
                Row {
                    id: chips
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Repeater {
                        model: root.modes
                        Rectangle {
                            required property string modelData
                            required property int index
                            width: chip.width + 32
                            height: chip.height + 20
                            radius: height / 2
                            color: root.mode === index ? Theme.fg : "transparent"
                            Lb { id: chip; anchors.centerIn: parent; text: parent.modelData; px: 11; color: root.mode === parent.index ? Theme.ink : Theme.grey }
                            TapHandler { onTapped: { root.mode = parent.index; input.forceActiveFocus(); } }
                        }
                    }
                }
            }

            Flickable {
                id: flick
                anchors { left: parent.left; right: parent.right; top: search.bottom; bottom: parent.bottom; topMargin: 20; leftMargin: 34; rightMargin: 34; bottomMargin: 34 }
                contentHeight: body.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                function ensure(y, h) {
                    if (y < contentY) contentY = Math.max(0, y);
                    else if (y + h > contentY + height) contentY = y + h - height;
                }

                Column {
                    id: body
                    width: flick.width

                    // calc: answer large, Enter — copy
                    Column {
                        visible: root.mode === 3
                        topPadding: 10
                        spacing: 10
                        Lb { text: root.calcOut ? "↵ copy" : "qalc" }
                        Num { width: body.width; elide: Text.ElideRight; text: root.calcOut || "—"; font.pixelSize: 96 }
                    }

                    // by index, not by array: new blocks (letter in search, launch, recent) don't recreate ~160 cells
                    // with icons and layers — they only change data
                    Repeater {
                        id: blockRep
                        model: root.blocks.length

                        Column {
                            id: block
                            required property int index
                            readonly property var modelData: root.blocks[index] ?? ({ head: "", items: [] })
                            readonly property Item g: grid
                            width: body.width
                                topPadding: index ? 30 : 10 // +20 above flick: scrolled is cut with gap under search

                            Row {
                                spacing: 14
                                bottomPadding: 18
                                // alphabet letter group Doto: what letters are currently in window
                                Num { visible: !!block.modelData.all; anchors.baseline: blab.baseline; text: root.range; font.pixelSize: 34 }
                                Lb { id: blab; text: block.modelData.head + (block.modelData.sub ? ` · ${block.modelData.sub}` : "") }
                            }
                            Grid {
                                id: grid
                                columns: 6
                                rowSpacing: 22
                                Repeater {
                                    model: block.modelData.items.length
                                    Cell { items: block.modelData.items; gy: block.y + grid.y }
                                }
                            }
                        }
                    }
                }
            }

            // alphabet on right: letters in window — white, click — to first with this letter
            Column {
                visible: root.mode === 0 && !root.query && !!root.allGrid
                anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 130 }
                spacing: 3
                Repeater {
                    model: [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
                    Text {
                        required property string modelData
                        width: 12
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font { family: Theme.mono; pixelSize: 10 }
                        color: root.range.includes(modelData) ? Theme.fg : Theme.mute
                        TapHandler { onTapped: root.jump(parent.modelData) }
                    }
                }
            }
        }

        // tray app menu: under its circle, width — within panel; extends down past panel like popover
        Rectangle {
            id: menu
            property real mt: root.menuOpen && root.mode === 2 ? 1 : 0
            readonly property real below: (root.peek?.y ?? 0) + 14
            readonly property real above: (root.peek?.top ?? 0) - 14
            readonly property bool opensAbove: list.height + 20 > stage.height - below - 8 && above - 8 > stage.height - below - 8
            Behavior on mt { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
            visible: mt > 0 && height > 20 && (rows.count > 0 || root.sub.length > 0)
            x: Math.max(panel.x + 20, Math.min(panel.x + panel.width - width - 20, (root.peek?.x ?? 0) - width / 2))
            y: opensAbove ? above - height - 12 * (1 - mt) : below + 12 * (1 - mt)
            width: 320
            height: Math.max(0, Math.min(list.height + 20, (opensAbove ? above : stage.height - below) - 8))
            Behavior on x { enabled: menu.visible; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
            Behavior on height { enabled: menu.visible; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
            opacity: root.t * mt
            radius: Theme.corner(28)
            color: Theme.s2
            border { width: 1; color: Theme.s3 }
            clip: true
            MouseArea { anchors.fill: parent } // past items — not into scrim, it would close launcher
            HoverHandler { id: menuHov }
            // Root opener keeps DBusMenu and its items alive while second opener shows submenu.
            QsMenuOpener { id: opener; menu: menu.mt > 0 ? root.peek?.tray?.menu ?? null : null }
            QsMenuOpener { id: subOpener; menu: opener.menu && root.sub.length ? root.sub[root.sub.length - 1] : null }

            Flickable {
                id: menuList
                anchors { fill: parent; margins: 10 }
                clip: true
                contentHeight: list.height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
            }
            Column {
                id: list
                parent: menuList.contentItem
                width: menuList.width

                Item {
                    visible: root.sub.length > 0
                    width: list.width
                    height: 40
                    Rectangle { anchors.fill: parent; radius: Theme.corner(20); color: backHov.hovered ? Theme.s3 : "transparent" }
                    Icon { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "\u{F0141}"; color: Theme.grey }
                    Lb { x: 38; anchors.verticalCenter: parent.verticalCenter; text: "back"; px: 11 }
                    HoverHandler { id: backHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.sub = root.sub.slice(0, -1) }
                }
                Repeater {
                    id: rows
                    model: subOpener.menu ? subOpener.children : opener.children
                    Item {
                        id: row
                        required property QsMenuEntry modelData
                        readonly property bool sep: modelData.isSeparator
                        readonly property bool on: modelData.checkState === Qt.Checked
                        width: list.width
                        height: sep ? 13 : 40
                        Rectangle { visible: row.sep; anchors.centerIn: parent; width: parent.width - 28; height: 1; color: Theme.s3 }
                        Rectangle { visible: !row.sep; anchors.fill: parent; radius: Theme.corner(20); color: rowHov.hovered && row.modelData.enabled ? Theme.s3 : "transparent" }
                        Text {
                            visible: !row.sep
                            anchors { left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 40; verticalCenter: parent.verticalCenter }
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            text: row.modelData.text
                            font { family: Theme.ui; pixelSize: 15 }
                            color: row.modelData.enabled ? Theme.fg : Theme.mute
                        }
                        // right: submenu — chevron; check or radio — dot, checked — white, not — ring
                        Icon {
                            visible: row.modelData.hasChildren
                            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            text: "\u{F0142}"
                            color: Theme.grey
                        }
                        Rectangle {
                            visible: row.modelData.buttonType !== QsMenuButtonType.None && !row.modelData.hasChildren
                            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            width: 12
                            height: 12
                            radius: 6
                            color: row.on ? Theme.fg : "transparent"
                            border { width: 1.5; color: row.on ? Theme.fg : Theme.mute }
                        }
                        HoverHandler { id: rowHov; enabled: !row.sep; cursorShape: row.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
                        TapHandler {
                            enabled: !row.sep && row.modelData.enabled
                            onTapped: {
                                if (row.modelData.hasChildren) return root.sub = root.sub.concat([row.modelData]);
                                row.modelData.triggered();
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // letters of all apps whose rows are currently visible: «A–F»
    readonly property var allItems: blocks.find(b => b.all)?.items ?? []
    readonly property Item allGrid: { const i = blocks.findIndex(b => b.all); return blockRep.count > i && i >= 0 ? blockRep.itemAt(i)?.g ?? null : null; }
    readonly property string range: {
        if (!allGrid || !allItems.length) return "";
        const top = allGrid.mapToItem(body, 0, 0).y, rh = 88 + 10 + 20 + 22; // circle, offset, caption, gap
        const r0 = Math.max(0, Math.floor((flick.contentY - top) / rh)), r1 = Math.floor((flick.contentY + flick.height - top) / rh);
        const seen = allItems.slice(r0 * 6, (r1 + 1) * 6).map(a => a.name[0].toUpperCase());
        return seen.length ? seen[0] === seen[seen.length - 1] ? seen[0] : `${seen[0]}–${seen[seen.length - 1]}` : "";
    }
    function jump(l) {
        const i = allItems.findIndex(a => a.name[0].toUpperCase() >= l);
        if (i < 0) return;
        sel = allItems[i].k;
        flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), allGrid.mapToItem(body, 0, 0).y + Math.floor(i / 6) * (88 + 10 + 20 + 22));
    }

    // ---- tray app menu: hovered on circle — card under it with its menu items, like tray in caelestia bar.
    // Submenu — in place of list, «back» on top; item — do and close launcher. Left both circle and card — fades.
    // Note: tray menu is mouse-only for now; keyboard arrow navigation can be added later if needed ----
    property Item hotCell: null // circle under cursor
    property var peek: null // { tray, x, y }: whose menu and where bottom of its cell is; held until card fades
    property var sub: [] // open submenus, on screen — last one
    onSubChanged: menuList.contentY = 0
    property bool menuOpen: false
    readonly property bool menuHot: !!hotCell || menuHov.hovered
    onMenuHotChanged: if (!menuHot) menuT.restart()
    Timer { id: menuT; interval: 300; onTriggered: if (!root.menuHot) root.menuOpen = false }
    function hover(cell) {
        const p = cell.mapToItem(stage, cell.width / 2, cell.height);
        if (!menuOpen || peek?.tray !== cell.modelData.tray) sub = [];
        peek = { tray: cell.modelData.tray, x: p.x, y: p.y, top: cell.mapToItem(stage, 0, 0).y };
        hotCell = cell;
        sel = cell.modelData.k;
        menuOpen = true;
    }

    // app: circle 88 with glyph or icon as dots, caption — matched letters white
    component Cell: Column {
        id: cell
        required property int index
        property var items: []
        readonly property var modelData: items[index] ?? ({ name: "", hl: [] })
        readonly property bool on: root.sel === modelData.k
        // Quickshell layer-shell window recreates on each open, and Image loads texture even hidden: 160 icons —
        // ~60 ms first frame. Outside scroll (with row margin) cell empty and no icon, height holds itself
        property real gy // y of grid in body
        readonly property bool near: gy + y < flick.contentY + flick.height + 140 && gy + y + height > flick.contentY - 140
        width: body.width / 6
        height: 88 + spacing + label.implicitHeight
        spacing: 10
        onOnChanged: if (on) flick.ensure(mapToItem(body, 0, 0).y - 8, height + 8) // 8 — sample ring above circle
        HoverHandler {
            enabled: root.mode === 2
            onHoveredChanged: if (hovered) root.hover(cell); else if (root.hotCell === cell) root.hotCell = null
        }

        Rectangle {
            id: disc
            visible: cell.near
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88
            height: 88
            radius: 44
            color: cell.modelData.fill ?? (cell.on ? Theme.fg : Theme.s2)
            border { width: cell.modelData.fill ? 1 : 0; color: Theme.s3 } // black sample on panel
            // sample under cursor — ring around: fill white — color would disappear. dot — palette accent, what's set now — dot
            Rectangle { visible: cell.on && !!cell.modelData.fill; anchors.centerIn: parent; width: 104; height: 104; radius: 52; color: "transparent"; border { width: 2; color: Theme.fg } }
            Rectangle { id: inner; visible: !!cell.modelData.dot; anchors.centerIn: parent; width: 40; height: 40; radius: 20; color: cell.modelData.dot ?? "transparent" }
            Rectangle { visible: !!cell.modelData.now; anchors.centerIn: parent; width: 14; height: 14; radius: 7; color: Theme.on(inner.visible ? inner.color : disc.color) }
            Image {
                anchors.centerIn: parent
                visible: status === Image.Ready
                width: 44
                height: 44
                source: cell.near ? cell.modelData.src ?? "" : ""
                sourceSize: Qt.size(44, 44)
                asynchronous: true
                retainWhileLoading: true // cell changed app — old icon until new loads
                layer.enabled: cell.near // layer draws its own Image and hidden
                layer.effect: Dm { step: 2.5 }
            }
            TapHandler { onTapped: { root.sel = cell.modelData.k; root.launch(); } }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
        Text {
            id: label
            visible: cell.near
            width: parent.width - 8
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            textFormat: Text.StyledText
            readonly property var hl: cell.modelData.hl ?? []
            text: [...cell.modelData.name].map((c, i) => {
                const e = c === "<" ? "&lt;" : c === "&" ? "&amp;" : c;
                return hl.includes(i) ? `<font color="${Theme.fg}">${e}</font>` : e;
            }).join("")
            font { family: Theme.ui; pixelSize: 14 }
            color: cell.on ? Theme.fg : Theme.grey
        }
    }
}
