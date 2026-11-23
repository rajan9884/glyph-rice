import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "lock"

// lock — separate process, like in demonshot: qs -p …/glyph/lock.qml (called by `rice lock`). Unlocked — exit.
// Shell crashed — lock lives; lock crashed — Hyprland keeps screen closed, SUPER+ALT+L raises it again
ShellRoot {
    id: shell
    // hot-reload recreates WlSessionLock: old dies, process hangs without screen
    settings.watchFiles: false

    QtObject {
        id: gate
        property string buffer: ""
        property bool fail: false
        property bool leaving: false // password accepted: surface plays exit, then unlockT removes lock
        property string note: ""     // what PAM said besides question: faillock — "account is locked… minutes left", else empty
        readonly property bool busy: pam.active
        function submit() {
            if (!buffer || pam.active || leaving) return;
            note = "";
            pam.start();
        }
    }

    PamContext {
        id: pam
        config: "lock"
        configDirectory: Quickshell.shellPath("pam")
        onResponseRequiredChanged: if (responseRequired) respond(gate.buffer)
        onPamMessage: if (!responseRequired) gate.note = (gate.note + " " + message).trim()
        onCompleted: res => {
            gate.buffer = "";
            if (res === PamResult.Success) {
                gate.leaving = true;
                unlockT.start();
            } else gate.fail = true;
        }
    }
    Timer { id: unlockT; interval: 470; onTriggered: lock.locked = false }

    property string layout: "en"
    function short(name) { return name.slice(0, 2).toLowerCase(); }
    Process {
        running: true
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap'"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) shell.layout = shell.short(text.trim()) }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "activelayout") shell.layout = shell.short(e.data.split(",").pop()); }
    }

    WlSessionLock {
        id: lock
        locked: true
        // ponytail: lockedChanged after locked = false doesn't come (quickshell 0.3.2), and secure drops — exit on it
        onSecureChanged: if (!secure) Qt.quit()

        LockSurface { auth: gate; layout: shell.layout }
    }
}
