import QtQuick

CardWindow {
  id: audioInputPopup
  required property var root

  theme: root
  revealed: root.audioInputVisible
  cardWidth: 400
  layerNamespace: "zanken-audio-input"
  footer: "M MUTE · ESC CLOSE"

  anchorEdge: root.barEdge
  anchorBarX: root.popupAnchorX
  anchorBarY: root.popupAnchorY

  onDismiss: root.audioInputVisible = false
  onRevealedChanged: if (revealed) root.refreshAudioInputs()

  onKeyPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      root.audioInputVisible = false;
      event.accepted = true;
    } else if (event.key === Qt.Key_M) {
      if (audioInputPopup.defaultSrcName) root.toggleSourceMute(audioInputPopup.defaultSrcName);
      event.accepted = true;
    }
  }

  readonly property bool inputMuted: root.audioDefaultSource ? root.audioDefaultSource.muted : false
  readonly property int inputVol: root.audioDefaultSource ? root.audioDefaultSource.vol : 0
  readonly property string defaultSrcName: root.audioDefaultSource ? root.audioDefaultSource.srcName : ""

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
          text: "AUDIO INPUT"
          color: audioInputPopup.root.ink
          font.family: audioInputPopup.root.mono
          font.pixelSize: 19
          font.letterSpacing: 4
          font.weight: Font.Medium
        }
        Text {
          text: !audioInputPopup.defaultSrcName ? "NO INPUT DEVICE"
             : audioInputPopup.inputMuted ? "MUTED" : "VOLUME · " + audioInputPopup.inputVol + "%"
          color: audioInputPopup.root.inkDeep
          font.family: audioInputPopup.root.mono
          font.pixelSize: 11
          font.letterSpacing: 2
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: audioInputPopup.root.sep }

    Column {
      width: parent.width
      spacing: 12

      // Default source volume
      Item {
        width: parent.width
        height: 26
        visible: (audioInputPopup.root.audioInputSources || []).length > 0

        Text {
          id: micIcon
          anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
          text: audioInputPopup.inputMuted ? audioInputPopup.root.icoMicOff : audioInputPopup.root.icoMicOn
          color: audioInputPopup.inputMuted ? audioInputPopup.root.inkDeep : audioInputPopup.root.seal
          font.family: audioInputPopup.root.mono; font.pixelSize: 14; width: 20
          Behavior on color { ColorAnimation { duration: 150 } }
        }

        ToggleSwitch {
          id: micMuteToggle
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          checked: !audioInputPopup.inputMuted
          onColor: audioInputPopup.root.seal
          offColor: Qt.rgba(0.3, 0.3, 0.3, 1)
          onToggled: if (audioInputPopup.defaultSrcName) audioInputPopup.root.toggleSourceMute(audioInputPopup.defaultSrcName)
        }

        QuickSlider {
          anchors.left: micIcon.right; anchors.right: micMuteToggle.left
          anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
          root: audioInputPopup.root
          value: audioInputPopup.inputVol
          min: 0; max: 100
          label: audioInputPopup.inputMuted ? "MUTED" : audioInputPopup.inputVol + "%"
          onCommitted: (v) => { if (audioInputPopup.defaultSrcName) audioInputPopup.root.setSourceVolume(audioInputPopup.defaultSrcName, Math.round(v)); }
        }
      }

      // Input sources
      Column {
        width: parent.width
        spacing: 4

        Rectangle { width: parent.width; height: 1; color: audioInputPopup.root.sep; opacity: 0.5 }

        Text {
          text: "INPUT DEVICE"
          color: audioInputPopup.root.inkDeep
          font.family: audioInputPopup.root.mono
          font.pixelSize: 9
          font.letterSpacing: 2
          opacity: 0.7
          topPadding: 2
        }

        Text {
          width: parent.width; height: 40
          visible: (audioInputPopup.root.audioInputSources || []).length === 0
          horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
          text: "NO INPUT DEVICES"
          color: audioInputPopup.root.inkDeep
          font.family: audioInputPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 3
          opacity: 0.5
        }

        Repeater {
          model: audioInputPopup.root.audioInputSources || []
          delegate: Rectangle {
            required property var modelData
            width: parent.width; height: 30
            radius: audioInputPopup.root.cornerRadius
            color: srcMouse.containsMouse ? audioInputPopup.root.rowHi : "transparent"
            border.color: audioInputPopup.root.sep
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
              anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
              text: modelData.isDefault ? "✓" : ""
              color: audioInputPopup.root.seal
              font.family: audioInputPopup.root.mono; font.pixelSize: 11; font.weight: Font.Medium
            }
            Text {
              anchors.left: parent.left; anchors.right: parent.right
              anchors.leftMargin: 26; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
              text: modelData.name; elide: Text.ElideRight
              color: audioInputPopup.root.inkDeep
              font.family: audioInputPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 1
            }
            MouseArea {
              id: srcMouse; anchors.fill: parent; hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: audioInputPopup.root.setDefaultSource(modelData.srcName)
            }
          }
        }
      }

      // Capture streams
      Column {
        width: parent.width
        spacing: 0
        visible: (audioInputPopup.root.audioInputStreams || []).length > 0

        Rectangle { width: parent.width; height: 1; color: audioInputPopup.root.sep; opacity: 0.5 }

        Text {
          text: "CAPTURE"
          color: audioInputPopup.root.inkDeep
          font.family: audioInputPopup.root.mono
          font.pixelSize: 9
          font.letterSpacing: 2
          opacity: 0.7
          topPadding: 4; bottomPadding: 2
        }

        Repeater {
          model: audioInputPopup.root.audioInputStreams || []
          delegate: Item {
            required property var modelData
            width: parent.width; height: 34

            Text {
              id: cIcon
              anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
              text: modelData.muted ? audioInputPopup.root.icoMicOff : audioInputPopup.root.icoMicOn
              color: modelData.muted ? audioInputPopup.root.inkDeep : audioInputPopup.root.seal
              font.family: audioInputPopup.root.mono; font.pixelSize: 12; width: 18
              Behavior on color { ColorAnimation { duration: 150 } }
              MouseArea {
                anchors.fill: parent; anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: audioInputPopup.root.toggleInputStreamMute(modelData.index)
              }
            }

            Text {
              id: cName
              anchors.left: cIcon.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
              width: 80; elide: Text.ElideRight
              text: modelData.name
              color: audioInputPopup.root.ink
              font.family: audioInputPopup.root.mono; font.pixelSize: 11; font.letterSpacing: 1
            }

            QuickSlider {
              anchors.left: cName.right; anchors.right: parent.right
              anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
              root: audioInputPopup.root; value: modelData.vol; min: 0; max: 100
              label: modelData.muted ? "MUTED" : modelData.vol + "%"
              onCommitted: (v) => audioInputPopup.root.setInputStreamVolume(modelData.index, Math.round(v))
            }

            Rectangle {
              anchors.bottom: parent.bottom; width: parent.width; height: 1
              color: audioInputPopup.root.sep; opacity: 0.3
            }
          }
        }
      }
    }
  }
}
