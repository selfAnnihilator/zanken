import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

CardWindow {
    id: musicPopup
    required property var root

    theme: root
    revealed: root.musicVisible
    cardWidth: 340
    layerNamespace: "zanken-music"
    footer: "SPC PLAY · ← → SEEK · ESC CLOSE"

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    onDismiss: root.musicVisible = false

    onRevealedChanged: {
        posTimer.running = revealed && !!musicPopup.player;
        if (revealed && musicPopup.player)
            musicPopup.trackPos = musicPopup.player.position;
        if (revealed) {
            cavaProc.running = false;
            cavaProc.running = true;
        } else {
            cavaProc.running = false;
        }
    }

    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.musicVisible = false; event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            root.musicToggle(); event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (player && player.canSeek) {
                const p = Math.max(0, trackPos - 10);
                player.position = p; trackPos = p;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (player && player.canSeek && trackLen > 0) {
                const p = Math.min(trackLen, trackPos + 10);
                player.position = p; trackPos = p;
            }
            event.accepted = true;
        }
    }

    readonly property string cavaConfigPath: Quickshell.env("HOME") + "/.config/cava/quickshell.conf"

    readonly property var player: root.musicPlayer
    readonly property real trackLen: player ? player.length : 0
    property real trackPos: 0

    onPlayerChanged: {
        trackPos = player ? player.position : 0;
        posTimer.running = revealed && !!player;
    }

    Timer {
        id: posTimer
        interval: 500
        repeat: true
        running: false
        onTriggered: {
            if (musicPopup.player && musicPopup.player.isPlaying)
                musicPopup.trackPos = musicPopup.player.position;
        }
    }

    Process {
        id: cavaProc
        running: false
        command: ["cava", "-p", musicPopup.cavaConfigPath]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                const t = line.trim();
                if (t.length > 0) cavaViz.updateBars(t);
            }
        }
    }

    function fmtTime(secs) {
        const s = Math.max(0, Math.floor(secs));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    CavaVisualizer {
        id: cavaViz
        parent: musicPopup.cardSurface
        z: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.7
        barColor: musicPopup.root.seal
        barOpacity: 0.35
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        // Header
        Item {
            width: parent.width
            height: 43

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "NOW PLAYING"
                color: musicPopup.root.ink
                font.family: musicPopup.root.mono
                font.pixelSize: 19
                font.letterSpacing: 4
                font.weight: Font.Medium
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: musicPopup.player ? (musicPopup.player.identity || "") : ""
                color: musicPopup.root.inkDeep
                font.family: musicPopup.root.mono
                font.pixelSize: 10
                font.letterSpacing: 2
                opacity: 0.7
            }
        }

        Rectangle { width: parent.width; height: 1; color: musicPopup.root.sep }

        // Album art squircle
        Item {
            width: parent.width
            height: 170

            Rectangle {
                id: artFrame
                anchors.centerIn: parent
                width: 150; height: 150
                radius: 26
                clip: true
                color: Qt.rgba(
                    musicPopup.root.rowHi.r,
                    musicPopup.root.rowHi.g,
                    musicPopup.root.rowHi.b,
                    0.6
                )

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: musicPopup.player ? (musicPopup.player.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: artImage.status !== Image.Ready
                    text: musicPopup.root.icoMusic
                    color: musicPopup.root.inkDeep
                    font.family: musicPopup.root.mono
                    font.pixelSize: 44
                    opacity: 0.35
                }
            }
        }

        // No-player placeholder
        Text {
            width: parent.width
            height: 36
            visible: !musicPopup.player
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "NOTHING PLAYING"
            color: musicPopup.root.inkDeep
            font.family: musicPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.5
        }

        // Title + Artist
        Column {
            width: parent.width
            spacing: 4
            visible: !!musicPopup.player

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: musicPopup.player ? (musicPopup.player.trackTitle || "Unknown") : ""
                color: musicPopup.root.ink
                font.family: musicPopup.root.mono
                font.pixelSize: 14
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: musicPopup.player ? (musicPopup.player.trackArtist || "") : ""
                color: musicPopup.root.inkDeep
                font.family: musicPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 1
                elide: Text.ElideRight
                opacity: 0.8
            }
        }

        // Progress
        Column {
            width: parent.width
            spacing: 4
            visible: !!musicPopup.player && musicPopup.trackLen > 0

            Item {
                id: scrubBar
                width: parent.width
                height: 20

                property bool hovered: false
                property bool dragging: false
                property real dragRatio: 0
                property real displayRatio: dragging
                    ? dragRatio
                    : (musicPopup.trackLen > 0 ? musicPopup.trackPos / musicPopup.trackLen : 0)

                Rectangle {
                    id: trackBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: (scrubBar.hovered || scrubBar.dragging) ? 4 : 3
                    radius: height / 2
                    color: musicPopup.root.sep
                    Behavior on height { NumberAnimation { duration: 100 } }

                    Rectangle {
                        id: trackFill
                        width: Math.max(0, trackBg.width * scrubBar.displayRatio)
                        height: parent.height
                        radius: parent.radius
                        color: musicPopup.root.seal
                        Behavior on width {
                            enabled: !scrubBar.dragging
                            NumberAnimation { duration: 450; easing.type: Easing.Linear }
                        }
                    }
                }

                // Thumb circle — appears on hover/drag
                Rectangle {
                    visible: scrubBar.hovered || scrubBar.dragging
                    width: 12; height: 12; radius: 6
                    color: musicPopup.root.ink
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(scrubBar.width - width,
                                Math.max(0, scrubBar.width * scrubBar.displayRatio - width / 2))
                    Behavior on x {
                        enabled: !scrubBar.dragging
                        NumberAnimation { duration: 450; easing.type: Easing.Linear }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: scrubBar.hovered = true
                    onExited:  { if (!scrubBar.dragging) scrubBar.hovered = false }

                    onPressed: (e) => {
                        scrubBar.dragging = true;
                        scrubBar.dragRatio = Math.max(0, Math.min(1, e.x / width));
                    }
                    onPositionChanged: (e) => {
                        if (scrubBar.dragging)
                            scrubBar.dragRatio = Math.max(0, Math.min(1, e.x / width));
                    }
                    onReleased: (e) => {
                        if (musicPopup.player && musicPopup.player.canSeek && musicPopup.trackLen > 0) {
                            const pos = scrubBar.dragRatio * musicPopup.trackLen;
                            musicPopup.player.position = pos;
                            musicPopup.trackPos = pos;
                        }
                        scrubBar.dragging = false;
                        scrubBar.hovered = containsMouse;
                    }
                }
            }

            Item {
                width: parent.width
                height: 12
                Text {
                    anchors.left: parent.left
                    text: musicPopup.fmtTime(musicPopup.trackPos)
                    color: musicPopup.root.inkDeep
                    font.family: musicPopup.root.mono; font.pixelSize: 9; opacity: 0.6
                }
                Text {
                    anchors.right: parent.right
                    text: musicPopup.fmtTime(musicPopup.trackLen)
                    color: musicPopup.root.inkDeep
                    font.family: musicPopup.root.mono; font.pixelSize: 9; opacity: 0.6
                }
            }
        }

        // Controls
        Item {
            width: parent.width
            height: 48
            visible: !!musicPopup.player

            Row {
                anchors.centerIn: parent
                spacing: 24

                // Loop
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: musicPopup.root.icoRepeat
                    color: (musicPopup.player && musicPopup.player.loopState !== MprisLoopState.None)
                           ? musicPopup.root.seal : musicPopup.root.inkDeep
                    font.family: musicPopup.root.mono; font.pixelSize: 13
                    opacity: musicPopup.player ? 1.0 : 0.3
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!musicPopup.player) return;
                            const s = musicPopup.player.loopState;
                            musicPopup.player.loopState =
                                s === MprisLoopState.None ? MprisLoopState.Track
                                : s === MprisLoopState.Track ? MprisLoopState.Playlist
                                : MprisLoopState.None;
                        }
                    }
                }

                // Prev
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: musicPopup.root.icoPrev
                    color: musicPopup.root.ink
                    font.family: musicPopup.root.mono; font.pixelSize: 16
                    opacity: (musicPopup.player && musicPopup.player.canGoPrevious) ? 1.0 : 0.3
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: musicPopup.root.musicPrev()
                    }
                }

                // Play / Pause
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38; radius: 19
                    color: musicPopup.root.seal

                    Text {
                        anchors.centerIn: parent
                        text: musicPopup.root.musicPlaying
                              ? musicPopup.root.icoPause
                              : musicPopup.root.icoPlay
                        color: musicPopup.root.paper
                        font.family: musicPopup.root.mono; font.pixelSize: 15
                        // optical nudge: play glyph has visual left-lean
                        anchors.horizontalCenterOffset: musicPopup.root.musicPlaying ? 0 : 1
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: musicPopup.root.musicToggle()
                    }
                }

                // Next
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: musicPopup.root.icoNext
                    color: musicPopup.root.ink
                    font.family: musicPopup.root.mono; font.pixelSize: 16
                    opacity: (musicPopup.player && musicPopup.player.canGoNext) ? 1.0 : 0.3
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: musicPopup.root.musicNext()
                    }
                }

                // Shuffle
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: musicPopup.root.icoShuffle
                    color: (musicPopup.player && musicPopup.player.shuffle)
                           ? musicPopup.root.seal : musicPopup.root.inkDeep
                    font.family: musicPopup.root.mono; font.pixelSize: 13
                    opacity: musicPopup.player ? 1.0 : 0.3
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (musicPopup.player) musicPopup.player.shuffle = !musicPopup.player.shuffle;
                        }
                    }
                }

            }
        }
    }  // Column col
}
