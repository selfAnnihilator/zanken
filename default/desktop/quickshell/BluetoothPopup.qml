import QtQuick

CardWindow {
    id: btPopup
    required property var root

    theme: root
    revealed: root.bluetoothVisible
    cardWidth: 400
    layerNamespace: "zanken-bluetooth"
    footer: "CLICK CONNECT · T TOGGLE · S SCAN · ESC"

    anchorEdge: btPopup.root.barEdge
    anchorBarX: btPopup.root.popupAnchorX
    anchorBarY: btPopup.root.popupAnchorY

    onDismiss: btPopup.root.bluetoothVisible = false

    // Known = paired or trusted; Available = discovered but not yet paired
    property var knownDevices: (btPopup.root.btDevices || []).filter(d => d.paired || d.trusted || d.connected)
    property var availableDevices: (btPopup.root.btDevices || []).filter(d => !d.paired && !d.trusted && !d.connected)

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

        // Header: title + power toggle switch
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
                    elide: Text.ElideRight
                    text: btPopup.root.btPowered
                        ? (btPopup.root.btCount > 0
                            ? btPopup.root.btCount + " CONNECTED"
                            : (btPopup.root.btScanning ? "SCANNING…" : "ON · NO DEVICES"))
                        : "OFF"
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

        // Power off state
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

        // === KNOWN DEVICES section ===
        Column {
            width: parent.width
            spacing: 0
            visible: btPopup.root.btPowered && btPopup.knownDevices.length > 0

            Text {
                text: "KNOWN DEVICES"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
                bottomPadding: 6
            }

            Repeater {
                model: btPopup.knownDevices.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    readonly property bool isConnected: modelData.connected === true

                    Rectangle {
                        anchors.fill: parent
                        color: isConnected ? btPopup.root.seal : "transparent"
                        opacity: isConnected ? 0.10 : 0
                    }

                    Text {
                        id: kBtIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: isConnected ? "󰂱" : (modelData.paired ? "󰂴" : "󰂯")
                        color: isConnected ? btPopup.root.seal : btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 14
                        width: 20
                    }

                    Text {
                        anchors.left: kBtIcon.right
                        anchors.leftMargin: 6
                        anchors.right: kDevTag.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.name || modelData.mac || "Unknown"
                        color: isConnected ? btPopup.root.seal : btPopup.root.ink
                        font.family: btPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        font.weight: isConnected ? Font.Medium : Font.Normal
                    }

                    Text {
                        id: kDevTag
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: isConnected ? "CONNECTED" : (modelData.paired ? "PAIRED" : "")
                        color: isConnected ? btPopup.root.seal : btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        font.weight: isConnected ? Font.Medium : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isConnected) btPopup.root.btDisconnect(modelData.mac);
                            else btPopup.root.btConnect(modelData.mac);
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

        // === AVAILABLE DEVICES section ===
        Column {
            width: parent.width
            spacing: 0
            visible: btPopup.root.btPowered && (btPopup.availableDevices.length > 0 || btPopup.root.btScanning)

            // Spacer between sections when both visible
            Item {
                width: parent.width
                height: btPopup.knownDevices.length > 0 ? 8 : 0
                visible: btPopup.knownDevices.length > 0
            }

            Text {
                text: "NEARBY DEVICES"
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
                visible: btPopup.root.btScanning && btPopup.availableDevices.length === 0
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
                visible: !btPopup.root.btScanning && btPopup.availableDevices.length === 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "PRESS S TO SCAN"
                color: btPopup.root.inkDeep
                font.family: btPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 3
                opacity: 0.6
            }

            Repeater {
                model: btPopup.availableDevices.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    Text {
                        id: aBtIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂯"
                        color: btPopup.root.inkDeep
                        font.family: btPopup.root.mono
                        font.pixelSize: 14
                        width: 20
                    }

                    Text {
                        anchors.left: aBtIcon.right
                        anchors.leftMargin: 6
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.name || modelData.mac || "Unknown"
                        color: btPopup.root.ink
                        font.family: btPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btPopup.root.btConnect(modelData.mac)
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

        // Scan button row
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

        // Empty state (powered, no devices at all, not scanning)
        Text {
            width: parent.width
            height: 36
            visible: btPopup.root.btPowered
                  && !btPopup.root.btScanning
                  && btPopup.root.btDevices.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "NO DEVICES FOUND"
            color: btPopup.root.inkDeep
            font.family: btPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.6
        }
    }
}
