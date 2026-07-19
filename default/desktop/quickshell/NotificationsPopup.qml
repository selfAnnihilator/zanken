import QtQuick

CardWindow {
    id: notifPopup
    required property var root

    theme: root
    revealed: root.notificationsVisible
    cardWidth: 380
    layerNamespace: "zanken-notifications"

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    title: String.fromCodePoint(0xf0f3) + "  NOTIFICATIONS"
    subtitle: root.doNotDisturb
              ? "MUTED"
              : root.notificationCount > 0
                ? root.notificationCount + " ACTIVE"
                : "NO NOTIFICATIONS"

    onDismiss: root.notificationsVisible = false

    onKeyPressed: function(e) {
        if (e.key === Qt.Key_Escape)    { root.notificationsVisible = false; e.accepted = true; return; }
        if (e.key === Qt.Key_Backspace) { root.dismissAllNotifications(); e.accepted = true; }
    }

    Column {
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 38

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 8 }
                text: root.doNotDisturb ? "DO NOT DISTURB" : "NOTIFICATIONS ON"
                color: root.doNotDisturb ? root.seal : root.muted
                font.family: root.mono
                font.pixelSize: 10
                font.letterSpacing: 1
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                text: root.doNotDisturb
                      ? String.fromCodePoint(0xf1f6)
                      : String.fromCodePoint(0xf0f3)
                color: dndBtnMa.containsMouse
                       ? root.ink
                       : root.doNotDisturb ? root.seal : root.muted
                font.family: root.mono
                font.pixelSize: 16
                Behavior on color { ColorAnimation { duration: 100 } }

                MouseArea {
                    id: dndBtnMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doNotDisturb = !root.doNotDisturb
                }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                anchors.leftMargin: 8; anchors.rightMargin: 8
                height: 1; color: root.sep
            }
        }

        Item {
            width: parent.width
            height: Math.min(notifFlick.contentHeight, 320)

        Flickable {
            id: notifFlick
            anchors.fill: parent
            clip: true
            contentHeight: root.notificationCount > 0 ? notifList.implicitHeight : 52
            boundsBehavior: Flickable.StopAtBounds

            Text {
                visible: root.notificationCount === 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: "No notifications"
                color: root.muted
                font.family: root.mono
                font.pixelSize: 12
            }

            Column {
                id: notifList
                visible: root.notificationCount > 0
                width: parent.width

                Repeater {
                    model: root.cardItems
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: notifList.width
                        implicitHeight: rowCol.implicitHeight + 16

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: rowHover.containsMouse ? Qt.alpha(root.paper, 0.08) : "transparent"
                            radius: 4
                        }

                        Column {
                            id: rowCol
                            anchors {
                                left: parent.left
                                right: dismissBtn.left
                                top: parent.top
                                leftMargin: 8; rightMargin: 4; topMargin: 8
                            }
                            spacing: 3

                            Text {
                                text: modelData.appName.toUpperCase()
                                color: root.seal
                                font.family: root.mono
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }
                            Text {
                                width: parent.width
                                text: modelData.summary
                                color: root.ink
                                font.family: root.mono
                                font.pixelSize: 12
                                font.bold: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: modelData.body.length > 0
                                width: parent.width
                                text: modelData.body
                                color: root.muted
                                font.family: root.mono
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: dismissBtn
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                            text: "×"
                            color: rowHover.containsMouse ? root.seal : root.muted
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: root.removeFromCard(modelData)
                            }
                        }

                        Rectangle {
                            visible: index < root.notificationCount - 1
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            height: 1
                            color: root.sep
                        }
                    }
                }
            }
        }
        }

        Item {
            width: parent.width
            height: 34

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: root.sep; opacity: 0.5
            }

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                text: "ESC CLOSE"
                color: root.inkDeep; font.family: root.mono; font.pixelSize: 10
                font.letterSpacing: 2; opacity: 0.7
            }

            Text {
                id: clearAllBtn
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                text: "CLEAR ALL"
                color: clearAllMa.containsMouse ? root.seal : root.inkDeep
                font.family: root.mono; font.pixelSize: 10; font.letterSpacing: 2
                opacity: clearAllMa.containsMouse ? 1.0 : 0.7
                Behavior on color { ColorAnimation { duration: 100 } }
                MouseArea {
                    id: clearAllMa
                    anchors.fill: parent; anchors.margins: -6
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissAllNotifications()
                }
            }
        }
    }
}
