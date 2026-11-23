import QtQuick

// wheel by notches: notch(±1) every 120 angle. High-precision wheel sends 15 per click — accumulate, else 8 steps per notch.
// MouseArea, not WheelHandler: latter on bar pill didn't get wheel (also checks point against window geometry), MouseArea gets it.
// Touchpad not taken (scrollGestureEnabled) — swipe doesn't scroll; buttons and hover pass through
MouseArea {
    signal notch(int d) // +1 — wheel away from self
    property real acc: 0
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    scrollGestureEnabled: false
    onWheel: e => {
        const dy = (e.inverted ? -1 : 1) * (e.angleDelta.y || e.angleDelta.x); // natural scroll — wheel away still +1
        if (acc * dy < 0) acc = 0; // reversed midway through notch — leftover doesn't count
        acc += dy;
        while (Math.abs(acc) >= 120) {
            notch(Math.sign(acc));
            acc -= Math.sign(acc) * 120;
        }
    }
}
