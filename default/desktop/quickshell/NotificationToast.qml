import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: toastPanel
    required property var root

    anchors {
        top:    root.barEdge !== "bottom"
        bottom: root.barEdge === "bottom"
        right:  root.barEdge !== "left"
        left:   root.barEdge === "left"
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zanken-toast"
    WlrLayershell.margins {
        top:    root.barEdge === "top"    ? root.barHeight + 8 : 8
        right:  root.barEdge === "right"  ? root.barHeight + 8 : 8
        bottom: root.barEdge === "bottom" ? root.barHeight + 8 : 8
        left:   root.barEdge === "left"   ? root.barHeight + 8 : 8
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: 360
    implicitHeight: toastCol.implicitHeight + 16

    visible: root.toastItems.length > 0

    Column {
        id: toastCol
        anchors { top: parent.top; right: parent.right; left: parent.left; margins: 8 }
        spacing: 6

        Repeater {
            model: root.toastItems
            delegate: ToastCard {
                required property var modelData
                notif: modelData
                theme: root
                width: toastCol.width
            }
        }
    }

    component ToastCard: Item {
        required property var notif
        required property var theme
        implicitHeight: cardRect.implicitHeight

        Timer {
            interval: notif.expireTimeout > 0 ? notif.expireTimeout : 5000
            running: true
            onTriggered: toastPanel.root.removeFromToast(notif)
        }

        Rectangle {
            id: cardRect
            width: parent.width
            implicitHeight: cardCol.implicitHeight + 20
            radius: theme.cornerRadius
            color: theme.bg
            border.color: theme.sep
            border.width: 1

            Column {
                id: cardCol
                anchors {
                    left: parent.left
                    right: closeBtn.left
                    top: parent.top
                    leftMargin: 12; rightMargin: 4; topMargin: 10
                }
                spacing: 4

                Text {
                    text: notif.appName.toUpperCase()
                    color: theme.seal
                    font.family: theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                Text {
                    width: parent.width
                    text: notif.summary
                    color: theme.ink
                    font.family: theme.mono
                    font.pixelSize: 12
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    visible: notif.body.length > 0
                    width: parent.width
                    text: notif.body
                    color: theme.muted
                    font.family: theme.mono
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            Text {
                id: closeBtn
                anchors { right: parent.right; top: parent.top; rightMargin: 10; topMargin: 8 }
                text: "×"
                color: closeMa.containsMouse ? theme.seal : theme.muted
                font.pixelSize: 14
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    onClicked: toastPanel.root.removeFromToast(notif)
                }
            }
        }
    }
}
