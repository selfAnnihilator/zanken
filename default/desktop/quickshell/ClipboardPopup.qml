import QtQuick
import Quickshell
import Quickshell.Io

CardWindow {
    id: clipPopup
    required property var root

    theme: root
    revealed: root.clipboardVisible
    cardWidth: 420
    layerNamespace: "zanken-clipboard"

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    title: String.fromCodePoint(0xf0c5) + "  CLIPBOARD"
    subtitle: activeTab === 0
              ? (clipSearch.length > 0
                 ? filteredClipHistory.length + " / " + root.clipHistory.length + " ITEMS"
                 : root.clipHistory.length > 0 ? root.clipHistory.length + " ITEMS" : "EMPTY")
              : activeTab === 1
                ? root.screenshotFiles.length + " SCREENSHOTS"
                : (clipFiles.length > 0 ? clipFiles.length + " FILES" : "NO FILES IN CLIPBOARD")

    onDismiss: root.clipboardVisible = false
    onKeyPressed: function(e) {
        if (e.key === Qt.Key_Escape) {
            if (clipSearch.length > 0) {
                clipSearch = "";
                searchInput.text = "";
                e.accepted = true;
                return;
            }
            root.clipboardVisible = false;
            e.accepted = true;
            return;
        }
        // Only clear history when search input is not active
        if (e.key === Qt.Key_Backspace && !searchInput.activeFocus) {
            root.clearClipHistory();
            e.accepted = true;
        }
    }

    property int activeTab: 0
    property var clipFiles: []
    property string clipSearch: ""

    readonly property var filteredClipHistory: {
        if (clipSearch.length === 0) return root.clipHistory;
        const q = clipSearch.toLowerCase();
        return root.clipHistory.filter(function(item) {
            return item.content.toLowerCase().indexOf(q) !== -1;
        });
    }

    // Probe clipboard for file URIs each time popup opens
    Process {
        id: fileTypeProbe
        running: false
        command: ["sh", "-c", "wl-paste --list-types 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.indexOf("text/uri-list") !== -1) {
                    fileUriProbe.running = false;
                    fileUriProbe.running = true;
                } else {
                    clipPopup.clipFiles = [];
                }
            }
        }
    }

    Process {
        id: fileUriProbe
        running: false
        command: ["sh", "-c", "wl-paste --type text/uri-list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                    .map(function(u) { return decodeURIComponent(u.replace(/^file:\/\//, "")); })
                    .filter(function(p) { return p.length > 0; });
                clipPopup.clipFiles = lines;
            }
        }
    }

    // Copy-ack feedback
    property string copiedContent: ""
    Timer {
        id: copyAckReset
        interval: 1200
        onTriggered: clipPopup.copiedContent = ""
    }

    function copyText(t) {
        Quickshell.clipboardText = t;
        clipPopup.copiedContent = t;
        copyAckReset.restart();
    }

    onRevealedChanged: {
        if (revealed) {
            clipSearch = "";
            searchInput.text = "";
            fileTypeProbe.running = false;
            fileTypeProbe.running = true;
            Qt.callLater(function() { searchInput.forceActiveFocus(); });
        }
    }

    Column {
        width: parent.width
        spacing: 0

        // Search bar
        Item {
            width: parent.width
            height: 44

            Rectangle {
                anchors {
                    left: parent.left; right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10; rightMargin: 10
                }
                height: 30
                radius: clipPopup.root.cornerRadius
                color: Qt.rgba(clipPopup.root.paper.r, clipPopup.root.paper.g, clipPopup.root.paper.b, 0.07)
                border.color: searchInput.activeFocus ? clipPopup.root.seal : clipPopup.root.sep
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.pixelSize: 12
                        color: searchInput.activeFocus ? clipPopup.root.seal : clipPopup.root.muted
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    TextInput {
                        id: searchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 17 - (clearBtn.visible ? 22 : 0)
                        text: ""
                        onTextChanged: clipPopup.clipSearch = text
                        color: clipPopup.root.ink
                        font.family: clipPopup.root.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        selectionColor: Qt.rgba(clipPopup.root.seal.r, clipPopup.root.seal.g, clipPopup.root.seal.b, 0.35)
                        selectedTextColor: clipPopup.root.ink
                        cursorDelegate: Rectangle {
                            width: 1
                            color: clipPopup.root.seal
                            opacity: searchInput.cursorVisible ? 1 : 0
                        }
                        clip: true

                        Text {
                            anchors.fill: parent
                            visible: searchInput.text.length === 0
                            text: "SEARCH CLIPBOARD..."
                            color: clipPopup.root.muted
                            font.family: clipPopup.root.mono
                            font.pixelSize: 11
                            font.letterSpacing: 1
                            verticalAlignment: Text.AlignVCenter
                            opacity: 0.6
                        }
                    }

                    Text {
                        id: clearBtn
                        visible: clipPopup.clipSearch.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "×"
                        color: clearMa.containsMouse ? clipPopup.root.seal : clipPopup.root.muted
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 80 } }

                        MouseArea {
                            id: clearMa
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { clipPopup.clipSearch = ""; searchInput.text = ""; searchInput.forceActiveFocus(); }
                        }
                    }
                }
            }
        }

        // Tab bar
        Item {
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 0

                Repeater {
                    model: ["TEXT", "SCREENSHOTS", "FILES"]
                    delegate: Item {
                        required property string modelData
                        required property int index
                        width: 140
                        height: 36
                        readonly property bool active: clipPopup.activeTab === index

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: parent.active ? clipPopup.root.seal : tabMa.containsMouse ? clipPopup.root.ink : clipPopup.root.muted
                            font.family: clipPopup.root.mono
                            font.pixelSize: 10
                            font.letterSpacing: 2
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: parent.active ? 2 : 1
                            color: parent.active ? clipPopup.root.seal : clipPopup.root.sep
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipPopup.activeTab = index
                        }
                    }
                }
            }
        }

        // Text tab
        Item {
            width: parent.width
            height: clipPopup.activeTab === 0 ? Math.min(textFlick.contentHeight, 320) : 0
            visible: clipPopup.activeTab === 0
            clip: true

            Flickable {
                id: textFlick
                anchors.fill: parent
                clip: true
                contentHeight: clipPopup.filteredClipHistory.length > 0 ? textList.implicitHeight : 52
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    visible: clipPopup.filteredClipHistory.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: clipPopup.clipSearch.length > 0 ? "No matches" : "No clipboard history"
                    color: clipPopup.root.muted
                    font.family: clipPopup.root.mono
                    font.pixelSize: 12
                }

                Column {
                    id: textList
                    visible: clipPopup.filteredClipHistory.length > 0
                    width: parent.width

                    Repeater {
                        model: clipPopup.filteredClipHistory
                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: textList.width
                            implicitHeight: clipRow.implicitHeight + 20

                            MouseArea {
                                id: textRowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clipPopup.copyText(modelData.content)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: clipPopup.copiedContent === modelData.content
                                       ? Qt.rgba(clipPopup.root.seal.r, clipPopup.root.seal.g, clipPopup.root.seal.b, 0.15)
                                       : textRowHover.containsMouse
                                         ? Qt.alpha(clipPopup.root.paper, 0.08)
                                         : "transparent"
                                radius: 4
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Column {
                                id: clipRow
                                anchors {
                                    left: parent.left
                                    right: clipDismissBtn.left
                                    top: parent.top
                                    leftMargin: 10; rightMargin: 4; topMargin: 10
                                }
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: modelData.content.replace(/\n/g, " ↵ ")
                                    color: clipPopup.copiedContent === modelData.content ? clipPopup.root.seal : clipPopup.root.ink
                                    font.family: clipPopup.root.mono
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WrapAnywhere
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Text {
                                    text: {
                                        const d = new Date(modelData.time);
                                        return d.toLocaleTimeString(Qt.locale(), "HH:mm");
                                    }
                                    color: clipPopup.root.muted
                                    font.family: clipPopup.root.mono
                                    font.pixelSize: 9
                                }
                            }

                            Text {
                                id: clipDismissBtn
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                                text: clipPopup.copiedContent === modelData.content ? String.fromCodePoint(0xf00c) : "×"
                                color: textRowHover.containsMouse ? clipPopup.root.seal : clipPopup.root.muted
                                font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    onClicked: {
                                        const realIdx = clipPopup.root.clipHistory.indexOf(clipPopup.filteredClipHistory[index]);
                                        if (realIdx !== -1) clipPopup.root.removeClipItem(realIdx);
                                    }
                                }
                            }

                            Rectangle {
                                visible: index < clipPopup.filteredClipHistory.length - 1
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                height: 1; color: clipPopup.root.sep
                            }
                        }
                    }
                }
            }
        }

        // Screenshots tab
        Item {
            width: parent.width
            visible: clipPopup.activeTab === 1
            height: clipPopup.activeTab === 1
                    ? (clipPopup.root.screenshotFiles.length > 0 ? shotGrid.implicitHeight + 16 : 52)
                    : 0
            clip: true

            Text {
                visible: clipPopup.root.screenshotFiles.length === 0
                anchors.centerIn: parent
                text: "No screenshots found"
                color: clipPopup.root.muted
                font.family: clipPopup.root.mono
                font.pixelSize: 12
            }

            Grid {
                id: shotGrid
                visible: clipPopup.root.screenshotFiles.length > 0
                columns: 3
                rowSpacing: 6
                columnSpacing: 6
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top
                    leftMargin: 10; rightMargin: 10; topMargin: 8
                }

                Repeater {
                    model: Math.min(clipPopup.root.screenshotFiles.length, 12)
                    delegate: Item {
                        required property int index
                        readonly property var entry: clipPopup.root.screenshotFiles[index] || null
                        width: (shotGrid.width - 12) / 3
                        height: width * 9 / 16

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(clipPopup.root.ink.r, clipPopup.root.ink.g, clipPopup.root.ink.b, 0.04)
                            border.color: shotCellMa.containsMouse ? clipPopup.root.seal : clipPopup.root.sep
                            border.width: 1
                            antialiasing: true
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: (entry !== null && clipPopup.root.clipboardVisible) ? "file://" + entry.path : ""
                            sourceSize.width: 256
                            sourceSize.height: 144
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            clip: true
                            opacity: shotCellMa.containsMouse ? 1.0 : 0.85
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: shotCellMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (entry) clipPopup.root.copyScreenshotToClipboard(entry.path);
                            }
                        }
                    }
                }
            }
        }

        // Files tab
        Item {
            width: parent.width
            height: clipPopup.activeTab === 2 ? Math.min(filesFlick.contentHeight, 320) : 0
            visible: clipPopup.activeTab === 2
            clip: true

            Flickable {
                id: filesFlick
                anchors.fill: parent
                clip: true
                contentHeight: clipPopup.clipFiles.length > 0 ? filesList.implicitHeight : 52
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    visible: clipPopup.clipFiles.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: "No files in clipboard"
                    color: clipPopup.root.muted
                    font.family: clipPopup.root.mono
                    font.pixelSize: 12
                }

                Column {
                    id: filesList
                    visible: clipPopup.clipFiles.length > 0
                    width: parent.width

                    Repeater {
                        model: clipPopup.clipFiles
                        delegate: Item {
                            required property string modelData
                            required property int index
                            width: filesList.width
                            implicitHeight: fileRow.implicitHeight + 20

                            MouseArea {
                                id: fileRowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clipPopup.copyText(modelData)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: fileRowHover.containsMouse ? Qt.alpha(clipPopup.root.paper, 0.08) : "transparent"
                                radius: 4
                            }

                            Column {
                                id: fileRow
                                anchors {
                                    left: parent.left; right: parent.right
                                    top: parent.top
                                    leftMargin: 10; rightMargin: 10; topMargin: 10
                                }
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: modelData.split("/").pop()
                                    color: clipPopup.root.ink
                                    font.family: clipPopup.root.mono
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: modelData
                                    color: clipPopup.root.muted
                                    font.family: clipPopup.root.mono
                                    font.pixelSize: 10
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                visible: index < clipPopup.clipFiles.length - 1
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                height: 1; color: clipPopup.root.sep
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
                height: 1; color: clipPopup.root.sep; opacity: 0.5
            }

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                text: "ESC CLOSE"
                color: clipPopup.root.inkDeep; font.family: clipPopup.root.mono; font.pixelSize: 10
                font.letterSpacing: 2; opacity: 0.7
            }

            Text {
                id: clearHistBtn
                visible: clipPopup.activeTab === 0
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                text: "CLEAR HISTORY"
                color: clearHistMa.containsMouse ? clipPopup.root.seal : clipPopup.root.inkDeep
                font.family: clipPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 2
                opacity: clearHistMa.containsMouse ? 1.0 : 0.7
                Behavior on color { ColorAnimation { duration: 100 } }
                MouseArea {
                    id: clearHistMa
                    anchors.fill: parent; anchors.margins: -6
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: clipPopup.root.clearClipHistory()
                }
            }
        }
    }
}
