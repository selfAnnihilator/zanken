import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: powerPopup
    required property var root

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zanken-power"
    WlrLayershell.keyboardFocus: root.powerVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: root.powerVisible || _reveal > 0.001

    property real _reveal: root.powerVisible ? 1 : 0
    Behavior on _reveal {
        NumberAnimation {
            duration: powerPopup.root.powerVisible ? 220 : 140
            easing.type: powerPopup.root.powerVisible ? Easing.OutCubic : Easing.InCubic
        }
    }

    property int kbdIndex: 0

    readonly property var actions: [
        { glyph: "󰐥", label: "SHUTDOWN", cmd: "systemctl poweroff" },
        { glyph: "󰜉", label: "REBOOT",   cmd: "systemctl reboot"  },
        { glyph: "󰗽", label: "LOGOUT",   cmd: "zanken-system-logout" },
        { glyph: "󰤄", label: "SUSPEND",  cmd: "systemctl suspend" },
        { glyph: "󰌾", label: "LOCK",     cmd: "zanken-system-lock" },
    ]

    function _fire(a) {
        root.powerVisible = false;
        if (a && a.cmd) root.run(a.cmd);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.82 * powerPopup._reveal)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.powerVisible = false
    }

    Item {
        anchors.centerIn: parent
        width: buttonRow.implicitWidth
        height: buttonRow.implicitHeight
        focus: root.powerVisible

        Keys.onPressed: function(e) {
            const n = powerPopup.actions.length;
            if (e.key === Qt.Key_Escape) {
                root.powerVisible = false; e.accepted = true;
            } else if (e.key === Qt.Key_Left) {
                powerPopup.kbdIndex = (powerPopup.kbdIndex - 1 + n) % n; e.accepted = true;
            } else if (e.key === Qt.Key_Right) {
                powerPopup.kbdIndex = (powerPopup.kbdIndex + 1) % n; e.accepted = true;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                powerPopup._fire(powerPopup.actions[powerPopup.kbdIndex]); e.accepted = true;
            } else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5) {
                const i = e.key - Qt.Key_1;
                if (i < n) { powerPopup._fire(powerPopup.actions[i]); e.accepted = true; }
            }
        }

        Row {
            id: buttonRow
            spacing: 16

            Repeater {
                model: powerPopup.actions

                delegate: Item {
                    required property var modelData
                    required property int index
                    width: 90
                    height: 90

                    Rectangle {
                        anchors.fill: parent
                        radius: powerPopup.root.cornerRadius
                        opacity: powerPopup._reveal
                        color: powerPopup.kbdIndex === index
                               ? Qt.rgba(powerPopup.root.seal.r, powerPopup.root.seal.g, powerPopup.root.seal.b, 0.20)
                               : ma.containsMouse
                                 ? Qt.rgba(powerPopup.root.ink.r, powerPopup.root.ink.g, powerPopup.root.ink.b, 0.15)
                                 : Qt.rgba(powerPopup.root.ink.r, powerPopup.root.ink.g, powerPopup.root.ink.b, 0.06)
                        border.color: powerPopup.kbdIndex === index ? powerPopup.root.seal : powerPopup.root.sep
                        border.width: powerPopup.kbdIndex === index ? 2 : 1
                        Behavior on color        { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.glyph
                            color: powerPopup.kbdIndex === index ? powerPopup.root.seal : powerPopup.root.ink
                            font.family: powerPopup.root.mono
                            font.pixelSize: 28
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: powerPopup.kbdIndex === index ? powerPopup.root.seal : powerPopup.root.muted
                            font.family: powerPopup.root.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1.5
                            font.weight: Font.Medium
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Text {
                        anchors { top: parent.top; left: parent.left; topMargin: 7; leftMargin: 9 }
                        text: (index + 1).toString()
                        color: powerPopup.kbdIndex === index ? powerPopup.root.seal : powerPopup.root.muted
                        font.family: powerPopup.root.mono
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        opacity: powerPopup._reveal
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: powerPopup.kbdIndex = index
                        onClicked: function(mouse) { mouse.accepted = true; powerPopup._fire(modelData); }
                    }
                }
            }
        }
    }
}
