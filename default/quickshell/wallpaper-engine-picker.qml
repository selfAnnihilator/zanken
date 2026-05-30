import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

ShellRoot {
  id: root

  property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || ("/run/user/" + Quickshell.env("UID"))) + "/zanken-we-picker.sock"
  property string colorsFile: (Quickshell.env("HOME") || "") + "/.config/zanken/current/theme/quickshell.json"

  property color accent: "#798186"
  property color background: "#101315"
  property color foreground: "#cacccc"

  property bool opened: false
  property var wallpapers: []
  property int selectedIndex: 0
  property string selectionFile: ""
  property string doneFile: ""
  property bool requestActive: false

  function withAlpha(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha)
  }

  function decodeField(value) {
    return String(value || "").replace(/\v/g, "\n").replace(/\f/g, "\t")
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function parseRows(raw) {
    var result = []
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      if (!line) continue
      var cols = line.split("\t")
      if (cols.length < 2) continue
      result.push({
        wePath:    cols[0],
        thumbPath: cols[1],
        title:     cols[2] || cols[0].split("/").pop(),
        type:      (cols[3] || "scene").toLowerCase()
      })
    }
    return result
  }

  function openPicker(rowsRaw, nextSelectionFile, nextDoneFile) {
    if (requestActive && doneFile)
      finishDoneFile(doneFile)

    wallpapers = parseRows(rowsRaw)
    selectedIndex = 0
    selectionFile = nextSelectionFile
    doneFile = nextDoneFile
    requestActive = !!doneFile
    opened = wallpapers.length > 0
    if (opened) grid.forceActiveFocus()
  }

  function applySelected() {
    if (wallpapers.length === 0 || !selectionFile) { cancel(); return }
    var wp = wallpapers[selectedIndex]
    var sf = selectionFile
    var df = doneFile
    requestActive = false
    selectionFile = ""
    doneFile = ""
    applyProc.command = ["bash", "-lc",
      "printf '%s\\n' " + shellQuote(wp.wePath) + " > " + shellQuote(sf) + "; : > " + shellQuote(df)]
    applyProc.running = true
  }

  function cancel() {
    if (requestActive) finishDoneFile(doneFile)
    requestActive = false
    selectionFile = ""
    doneFile = ""
    opened = false
  }

  function finishDoneFile(path) {
    if (!path) return
    releaseProc.command = ["bash", "-lc", ": > " + shellQuote(path)]
    releaseProc.running = true
  }

  function cols() {
    return Math.max(1, Math.floor((panel.width - 80 - 40) / 220))
  }

  function navigate(dx, dy) {
    var c = cols()
    var n = wallpapers.length
    if (n === 0) return
    var row = Math.floor(selectedIndex / c)
    var col = selectedIndex % c
    col = (col + dx + c) % c
    row = (row + dy)
    var rows = Math.ceil(n / c)
    if (row < 0) row = rows - 1
    if (row >= rows) row = 0
    var idx = row * c + col
    if (idx >= n) idx = n - 1
    selectedIndex = idx
  }

  FileView {
    path: root.colorsFile
    watchChanges: true
    onLoaded: root.loadColors(text())
    onFileChanged: { reload(); root.loadColors(text()) }
  }

  function loadColors(raw) {
    try {
      var c = JSON.parse(raw || "{}")
      root.accent     = c.primary        || root.accent
      root.background = c.background     || root.background
      root.foreground = c.backgroundText || root.foreground
    } catch (e) {}
  }

  Process { id: applyProc;   onExited: { root.opened = false } }
  Process { id: releaseProc }

  SocketServer {
    active: true
    path: root.socketPath

    handler: Socket {
      id: clientSocket
      parser: SplitParser {
        onRead: function(message) {
          var fields = message.split("\t")
          if (root.opened) {
            if (root.requestActive) root.finishDoneFile(fields[2] || "")
            root.opened = false
            clientSocket.connected = false
            return
          }
          root.openPicker(root.decodeField(fields[0]), fields[1] || "", fields[2] || "")
          clientSocket.connected = false
        }
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "zanken-we-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.withAlpha(root.background, 0.72)
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    Item {
      id: card
      width:  Math.min(parent.width - 80, 1120)
      height: Math.min(parent.height - 80, 680)
      anchors.centerIn: parent

      MouseArea { anchors.fill: parent; onClicked: {} }

      Rectangle {
        anchors.fill: parent
        color: root.background
        radius: 12
        border.color: root.withAlpha(root.foreground, 0.08)
        border.width: 1
      }

      // Header
      Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 52

        Text {
          anchors.centerIn: parent
          text: "Wallpaper Engine"
          font.pixelSize: 15
          font.weight: Font.DemiBold
          color: root.accent
        }
      }

      // Grid area
      GridView {
        id: grid
        anchors {
          top: header.bottom
          left: parent.left; right: parent.right
          bottom: footer.top
          margins: 20
          topMargin: 0
          bottomMargin: 8
        }
        clip: true
        cellWidth:  210
        cellHeight: 160

        model: root.wallpapers.length

        currentIndex: root.selectedIndex

        focus: true
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Left)        { root.navigate(-1, 0); event.accepted = true }
          else if (event.key === Qt.Key_Right)  { root.navigate(1, 0);  event.accepted = true }
          else if (event.key === Qt.Key_Up)     { root.navigate(0, -1); event.accepted = true }
          else if (event.key === Qt.Key_Down)   { root.navigate(0, 1);  event.accepted = true }
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelected(); event.accepted = true
          }
          else if (event.key === Qt.Key_Escape) { root.cancel(); event.accepted = true }
        }

        onCurrentIndexChanged: {
          root.selectedIndex = currentIndex
        }

        delegate: Item {
          required property int index
          width: grid.cellWidth
          height: grid.cellHeight

          property var wp: root.wallpapers[index] || {}
          property bool isSelected: root.selectedIndex === index

          Rectangle {
            anchors { fill: parent; margins: 5 }
            color: "transparent"
            radius: 8
            border.color: isSelected ? root.accent : root.withAlpha(root.foreground, 0.1)
            border.width: isSelected ? 2 : 1

            // Thumbnail
            Image {
              id: thumb
              anchors { fill: parent; margins: 2 }
              source: wp.thumbPath ? "file://" + wp.thumbPath : ""
              fillMode: Image.PreserveAspectCrop
              smooth: true
              clip: true
              layer.enabled: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: ShaderEffectSource {
                  sourceItem: Rectangle {
                    width: thumb.width; height: thumb.height
                    radius: 6
                  }
                }
              }
            }

            // Type badge
            Rectangle {
              anchors { top: parent.top; right: parent.right; margins: 6 }
              width: typeLabel.width + 10
              height: 18
              radius: 3
              color: wp.type === "video"
                ? root.withAlpha("#4caf50", 0.85)
                : root.withAlpha("#26a69a", 0.85)

              Text {
                id: typeLabel
                anchors.centerIn: parent
                text: wp.type === "video" ? "VIDEO" : "SCENE"
                font.pixelSize: 9
                font.weight: Font.Bold
                color: "#ffffff"
              }
            }

            // Title overlay at bottom
            Rectangle {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
              height: titleText.height + 10
              radius: 6
              color: root.withAlpha(root.background, 0.82)

              Text {
                id: titleText
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 5 }
                text: wp.title || ""
                font.pixelSize: 11
                color: isSelected ? root.foreground : root.withAlpha(root.foreground, 0.7)
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked:      { root.selectedIndex = index; grid.forceActiveFocus() }
              onDoubleClicked: { root.selectedIndex = index; root.applySelected() }
            }
          }
        }
      }

      // Footer hint
      Item {
        id: footer
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 36

        Text {
          anchors.centerIn: parent
          text: "↵ Apply   Esc Cancel   ←→↑↓ Navigate   Double-click Apply"
          font.pixelSize: 11
          color: root.withAlpha(root.foreground, 0.35)
        }
      }
    }
  }
}
