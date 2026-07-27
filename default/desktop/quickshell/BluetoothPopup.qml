import QtQuick

CardWindow {
    id: btPopup
    required property var root

    theme: root
    revealed: root.bluetoothVisible
    cardWidth: 400
    layerNamespace: "zanken-bluetooth"
    footer: ""

    anchorEdge: btPopup.root.barEdge
    anchorBarX: btPopup.root.popupAnchorX
    anchorBarY: btPopup.root.popupAnchorY

    onDismiss: btPopup.root.bluetoothVisible = false

    function sortByName(devices) {
        return devices.slice().sort((a, b) =>
            (a.name || a.mac || "").localeCompare(b.name || b.mac || ""));
    }

    // A device belongs to exactly one section, so a connected device is never
    // repeated under saved devices.
    property var connectedDevices: sortByName((btPopup.root.btDevices || []).filter(d => d.connected))
    property var savedDevices: sortByName((btPopup.root.btDevices || []).filter(d =>
        !d.connected && (d.paired || d.trusted)))
    property var nearbyDevices: sortByName((btPopup.root.btDevices || []).filter(d =>
        !d.connected && !d.paired && !d.trusted))

    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            btPopup.root.bluetoothVisible = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_T) {
            btPopup.root.btTogglePower();
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            if (btPopup.root.btPowered) btPopup.root.btToggleScan();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            btPopup.root.refreshBluetooth();
            event.accepted = true;
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        // The header identifies Bluetooth's radio state. Device names live
        // only in their dedicated section below.
        Item {
            width: parent.width
            height: 43

            Column {
                anchors.left: parent.left
                anchors.right: btToggle.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "BLUETOOTH"
                    color: btPopup.root.ink
                    font.family: btPopup.root.mono
                    font.pixelSize: 19
                    font.letterSpacing: 4
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: !btPopup.root.btPowered ? "OFF"
                        : btPopup.root.btScanning ? "SCANNING"
                        : btPopup.connectedDevices.length > 0 ? "CONNECTED"
                        : "READY"
                    color: btPopup.root.inkDeep
                    font.family: btPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }

            ToggleSwitch {
                id: btToggle
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: btPopup.root.btPowered
                onColor: btPopup.root.seal
                offColor: Qt.rgba(0.3, 0.3, 0.3, 1)
                onToggled: btPopup.root.btTogglePower()
            }
        }

        Rectangle { width: parent.width; height: 1; color: btPopup.root.sep }

        Text {
            width: parent.width
            height: 60
            visible: !btPopup.root.btPowered
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "BLUETOOTH OFF"
            color: btPopup.root.inkDeep
            font.family: btPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.6
        }

        // === CONNECTED ===
        Column {
            width: parent.width
            spacing: 4
            visible: btPopup.root.btPowered && btPopup.connectedDevices.length > 0

            Text {
                text: "CONNECTED"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
            }

            Repeater {
                model: btPopup.connectedDevices.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        color: btPopup.root.seal
                        opacity: 0.08
                    }

                    Text {
                        id: connectedIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        text: "󰂱"
                        color: btPopup.root.seal
                        font.family: btPopup.root.mono
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.left: connectedIcon.right
                        anchors.leftMargin: 6
                        anchors.right: disconnectLabel.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.name || modelData.mac || "Unknown"
                        color: btPopup.root.ink
                        font.family: btPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        font.weight: Font.Medium
                    }

                    Text {
                        id: disconnectLabel
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "DISCONNECT"
                        color: disconnectArea.containsMouse ? btPopup.root.seal : btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        MouseArea {
                            id: disconnectArea
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btPopup.root.btDisconnect(modelData.mac)
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: btPopup.root.sep
                        opacity: 0.4
                    }
                }
            }
        }

        // === SAVED DEVICES ===
        Column {
            width: parent.width
            spacing: 0
            visible: btPopup.root.btPowered && btPopup.savedDevices.length > 0

            Text {
                text: "SAVED DEVICES"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
                bottomPadding: 6
            }

            Repeater {
                model: btPopup.savedDevices.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    Text {
                        id: savedIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        text: "󰂴"
                        color: btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.left: savedIcon.right
                        anchors.leftMargin: 6
                        anchors.right: savedAction.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.name || modelData.mac || "Unknown"
                        color: btPopup.root.ink
                        font.family: btPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }

                    Text {
                        id: savedAction
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CONNECT"
                        color: savedActionArea.containsMouse ? btPopup.root.seal : btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        MouseArea {
                            id: savedActionArea
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btPopup.root.btConnect(modelData.mac)
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: btPopup.root.sep
                        opacity: 0.4
                    }
                }
            }
        }

        // === NEARBY ===
        Column {
            width: parent.width
            spacing: 0
            visible: btPopup.root.btPowered

            Text {
                text: "NEARBY"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
                bottomPadding: 6
            }

            Text {
                width: parent.width
                height: 36
                visible: btPopup.root.btScanning
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "DISCOVERING…"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 3
                opacity: 0.6
            }

            Text {
                width: parent.width
                height: 36
                visible: !btPopup.root.btScanning && btPopup.nearbyDevices.length === 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "NO DEVICES FOUND · PRESS S TO SCAN"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 10
                font.letterSpacing: 1
                opacity: 0.6
            }

            Repeater {
                model: btPopup.root.btScanning ? [] : btPopup.nearbyDevices.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    readonly property bool isPairing: modelData.mac === btPopup.root.btPairingMac
                    readonly property bool hasFailed: modelData.mac === btPopup.root.btPairError

                    Text {
                        id: nearbyIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        text: "󰂯"
                        color: btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.left: nearbyIcon.right
                        anchors.leftMargin: 6
                        anchors.right: nearbyAction.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.name || modelData.mac || "Unknown"
                        color: btPopup.root.ink
                        font.family: btPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }

                    Text {
                        id: nearbyAction
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: isPairing ? "PAIRING…" : hasFailed ? "FAILED" : "PAIR + CONNECT"
                        color: isPairing ? btPopup.root.ink
                            : hasFailed ? "#e06c75"
                            : nearbyActionArea.containsMouse ? btPopup.root.seal : btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        font.weight: isPairing || hasFailed ? Font.Medium : Font.Normal
                        SequentialAnimation on opacity {
                            running: isPairing
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        }
                        MouseArea {
                            id: nearbyActionArea
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: isPairing ? Qt.BusyCursor : Qt.PointingHandCursor
                            enabled: !isPairing
                            onClicked: btPopup.root.btPairAndConnect(modelData.mac)
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: btPopup.root.sep
                        opacity: 0.4
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            visible: btPopup.root.btPowered
            color: btPopup.root.sep
            opacity: 0.5
        }

        Item {
            width: parent.width
            height: 34
            visible: btPopup.root.btPowered

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: btPopup.root.btScanning ? "STOP SCANNING" : "SCAN FOR DEVICES"
                color: scanMouse.containsMouse ? btPopup.root.seal : btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 2
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: btPopup.root.btScanning ? "󰑦" : "󰑣"
                color: scanMouse.containsMouse ? btPopup.root.seal : btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 16
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: btPopup.root.btToggleScan()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: btPopup.root.sep
            opacity: 0.5
        }

        Text {
            width: parent.width
            text: "CLICK ACTION · T TOGGLE · S SCAN · ESC CLOSE"
            color: btPopup.root.inkDeep
            font.family: btPopup.root.mono
            font.pixelSize: 10
            font.letterSpacing: 1
            opacity: 0.7
        }
    }
}
