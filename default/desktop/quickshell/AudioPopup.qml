import QtQuick

CardWindow {
    id: audioPopup
    required property var root

    theme: root
    revealed: root.audioVisible
    cardWidth: 400
    layerNamespace: "zanken-audio"
    footer: "M MUTE · TAB SWITCH · ESC CLOSE"

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    onDismiss: root.audioVisible = false
    onRevealedChanged: if (revealed) {
        root.refreshAudioSinks();
        root.refreshAudioStreams();
        root.refreshAudioInputs();
    }

    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.audioVisible = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_M) {
            if (audioPopup.activeTab === 0) root.toggleMute();
            else if (audioPopup.defaultSrcName) root.toggleSourceMute(audioPopup.defaultSrcName);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            audioPopup.activeTab = audioPopup.activeTab === 0 ? 1 : 0;
            event.accepted = true;
        }
    }

    property int activeTab: 0  // 0 = output, 1 = input

    property bool inputMuted: {
        const d = (audioPopup.root.audioInputSources || []).find(s => s.isDefault);
        return d ? d.muted : false;
    }
    property int inputVol: {
        const d = (audioPopup.root.audioInputSources || []).find(s => s.isDefault);
        return d ? d.vol : 0;
    }
    property string defaultSrcName: {
        const d = (audioPopup.root.audioInputSources || []).find(s => s.isDefault);
        return d ? d.srcName : "";
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        // Header
        Item {
            width: parent.width
            height: 43

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "AUDIO"
                    color: audioPopup.root.ink
                    font.family: audioPopup.root.mono
                    font.pixelSize: 19
                    font.letterSpacing: 4
                    font.weight: Font.Medium
                }
                Text {
                    text: audioPopup.activeTab === 0
                          ? (audioPopup.root.audioMuted ? "OUTPUT · MUTED" : "OUTPUT · " + audioPopup.root.audioVol + "%")
                          : (audioPopup.inputMuted ? "INPUT · MUTED" : "INPUT · " + audioPopup.inputVol + "%")
                    color: audioPopup.root.inkDeep
                    font.family: audioPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: audioPopup.root.sep }

        // Tab bar
        Item {
            width: parent.width
            height: 28

            Row {
                spacing: 2

                Repeater {
                    model: ["OUTPUT", "INPUT"]
                    delegate: Item {
                        required property string modelData
                        required property int index

                        readonly property bool active: audioPopup.activeTab === index

                        width: 80; height: 28

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: parent.active
                                   ? Qt.rgba(audioPopup.root.seal.r, audioPopup.root.seal.g, audioPopup.root.seal.b, 0.12)
                                   : tabMouse.containsMouse
                                       ? Qt.rgba(audioPopup.root.ink.r, audioPopup.root.ink.g, audioPopup.root.ink.b, 0.06)
                                       : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: parent.active ? audioPopup.root.seal : audioPopup.root.inkDeep
                            font.family: audioPopup.root.mono
                            font.pixelSize: 10
                            font.letterSpacing: 2
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioPopup.activeTab = parent.index
                        }
                    }
                }
            }
        }

        // ===== OUTPUT TAB =====
        Column {
            width: parent.width
            spacing: 12
            visible: audioPopup.activeTab === 0

            // Master volume
            Item {
                width: parent.width
                height: 26

                Text {
                    id: volIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioPopup.root.audioIcon
                    color: audioPopup.root.audioMuted ? audioPopup.root.inkDeep : audioPopup.root.seal
                    font.family: audioPopup.root.mono
                    font.pixelSize: 14
                    width: 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                ToggleSwitch {
                    id: outMuteToggle
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    checked: !audioPopup.root.audioMuted
                    onColor: audioPopup.root.seal
                    offColor: Qt.rgba(0.3, 0.3, 0.3, 1)
                    onToggled: audioPopup.root.toggleMute()
                }

                QuickSlider {
                    anchors.left: volIcon.right
                    anchors.right: outMuteToggle.left
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    root: audioPopup.root
                    value: audioPopup.root.audioVol
                    min: 0; max: 150
                    label: audioPopup.root.audioMuted ? "MUTED" : audioPopup.root.audioVol + "%"
                    onCommitted: (v) => audioPopup.root.setVolume(Math.round(v))
                }
            }

            // Output sinks
            Column {
                width: parent.width
                spacing: 4
                visible: (audioPopup.root.audioSinks || []).length > 0

                Rectangle { width: parent.width; height: 1; color: audioPopup.root.sep; opacity: 0.5 }

                Text {
                    text: "OUTPUT DEVICE"
                    color: audioPopup.root.inkDeep
                    font.family: audioPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    opacity: 0.7
                    topPadding: 2
                }

                Repeater {
                    model: audioPopup.root.audioSinks || []
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 30
                        radius: audioPopup.root.cornerRadius
                        color: sinkMouse.containsMouse ? audioPopup.root.rowHi : "transparent"
                        border.color: audioPopup.root.sep
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.isDefault ? "✓" : ""
                            color: audioPopup.root.seal
                            font.family: audioPopup.root.mono; font.pixelSize: 11; font.weight: Font.Medium
                        }
                        Text {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 26; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name; elide: Text.ElideRight
                            color: audioPopup.root.inkDeep
                            font.family: audioPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 1
                        }
                        MouseArea {
                            id: sinkMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioPopup.root.setDefaultSink(modelData.id)
                        }
                    }
                }
            }

            // Playback streams
            Column {
                width: parent.width
                spacing: 0
                visible: (audioPopup.root.audioStreams || []).length > 0

                Rectangle { width: parent.width; height: 1; color: audioPopup.root.sep; opacity: 0.5 }

                Text {
                    text: "PLAYBACK"
                    color: audioPopup.root.inkDeep
                    font.family: audioPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    opacity: 0.7
                    topPadding: 4; bottomPadding: 2
                }

                Repeater {
                    model: audioPopup.root.audioStreams || []
                    delegate: Item {
                        required property var modelData
                        width: parent.width; height: 34

                        Text {
                            id: pIcon
                            anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.muted ? audioPopup.root.icoMute : audioPopup.root.audioIcon
                            color: modelData.muted ? audioPopup.root.inkDeep : audioPopup.root.seal
                            font.family: audioPopup.root.mono; font.pixelSize: 12; width: 18
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: audioPopup.root.toggleStreamMute(modelData.index)
                            }
                        }

                        Text {
                            id: pName
                            anchors.left: pIcon.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 80; elide: Text.ElideRight
                            text: modelData.name
                            color: audioPopup.root.ink
                            font.family: audioPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 1
                        }

                        QuickSlider {
                            anchors.left: pName.right; anchors.right: parent.right
                            anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                            root: audioPopup.root; value: modelData.vol; min: 0; max: 100
                            label: modelData.muted ? "MUTED" : modelData.vol + "%"
                            onCommitted: (v) => audioPopup.root.setStreamVolume(modelData.index, Math.round(v))
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 1
                            color: audioPopup.root.sep; opacity: 0.3
                        }
                    }
                }
            }
        }

        // ===== INPUT TAB =====
        Column {
            width: parent.width
            spacing: 12
            visible: audioPopup.activeTab === 1

            // Default source volume
            Item {
                width: parent.width
                height: 26
                visible: (audioPopup.root.audioInputSources || []).length > 0

                Text {
                    id: micIcon
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: audioPopup.inputMuted ? audioPopup.root.icoMicOff : audioPopup.root.icoMicOn
                    color: audioPopup.inputMuted ? audioPopup.root.inkDeep : audioPopup.root.seal
                    font.family: audioPopup.root.mono; font.pixelSize: 14; width: 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                ToggleSwitch {
                    id: micMuteToggle
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    checked: !audioPopup.inputMuted
                    onColor: audioPopup.root.seal
                    offColor: Qt.rgba(0.3, 0.3, 0.3, 1)
                    onToggled: if (audioPopup.defaultSrcName) audioPopup.root.toggleSourceMute(audioPopup.defaultSrcName)
                }

                QuickSlider {
                    anchors.left: micIcon.right; anchors.right: micMuteToggle.left
                    anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    root: audioPopup.root
                    value: audioPopup.inputVol
                    min: 0; max: 100
                    label: audioPopup.inputMuted ? "MUTED" : audioPopup.inputVol + "%"
                    onCommitted: (v) => { if (audioPopup.defaultSrcName) audioPopup.root.setSourceVolume(audioPopup.defaultSrcName, Math.round(v)); }
                }
            }

            // Input sources
            Column {
                width: parent.width
                spacing: 4

                Rectangle { width: parent.width; height: 1; color: audioPopup.root.sep; opacity: 0.5 }

                Text {
                    text: "INPUT DEVICE"
                    color: audioPopup.root.inkDeep
                    font.family: audioPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    opacity: 0.7
                    topPadding: 2
                }

                Text {
                    width: parent.width; height: 40
                    visible: (audioPopup.root.audioInputSources || []).length === 0
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: "NO INPUT DEVICES"
                    color: audioPopup.root.inkDeep
                    font.family: audioPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 3
                    opacity: 0.5
                }

                Repeater {
                    model: audioPopup.root.audioInputSources || []
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 30
                        radius: audioPopup.root.cornerRadius
                        color: srcMouse.containsMouse ? audioPopup.root.rowHi : "transparent"
                        border.color: audioPopup.root.sep
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.isDefault ? "✓" : ""
                            color: audioPopup.root.seal
                            font.family: audioPopup.root.mono; font.pixelSize: 11; font.weight: Font.Medium
                        }
                        Text {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 26; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name; elide: Text.ElideRight
                            color: audioPopup.root.inkDeep
                            font.family: audioPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 1
                        }
                        MouseArea {
                            id: srcMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioPopup.root.setDefaultSource(modelData.srcName)
                        }
                    }
                }
            }

            // Capture streams
            Column {
                width: parent.width
                spacing: 0
                visible: (audioPopup.root.audioInputStreams || []).length > 0

                Rectangle { width: parent.width; height: 1; color: audioPopup.root.sep; opacity: 0.5 }

                Text {
                    text: "CAPTURE"
                    color: audioPopup.root.inkDeep
                    font.family: audioPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    opacity: 0.7
                    topPadding: 4; bottomPadding: 2
                }

                Repeater {
                    model: audioPopup.root.audioInputStreams || []
                    delegate: Item {
                        required property var modelData
                        width: parent.width; height: 34

                        Text {
                            id: cIcon
                            anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.muted ? audioPopup.root.icoMicOff : audioPopup.root.icoMicOn
                            color: modelData.muted ? audioPopup.root.inkDeep : audioPopup.root.seal
                            font.family: audioPopup.root.mono; font.pixelSize: 12; width: 18
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: audioPopup.root.toggleInputStreamMute(modelData.index)
                            }
                        }

                        Text {
                            id: cName
                            anchors.left: cIcon.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 80; elide: Text.ElideRight
                            text: modelData.name
                            color: audioPopup.root.ink
                            font.family: audioPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 1
                        }

                        QuickSlider {
                            anchors.left: cName.right; anchors.right: parent.right
                            anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                            root: audioPopup.root; value: modelData.vol; min: 0; max: 100
                            label: modelData.muted ? "MUTED" : modelData.vol + "%"
                            onCommitted: (v) => audioPopup.root.setInputStreamVolume(modelData.index, Math.round(v))
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 1
                            color: audioPopup.root.sep; opacity: 0.3
                        }
                    }
                }
            }
        }
    }
}
