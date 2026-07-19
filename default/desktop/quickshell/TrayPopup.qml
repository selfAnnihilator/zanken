import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: trayPopup
    required property var root

    readonly property var trayItems: SystemTray.items ? SystemTray.items.values : []
    readonly property int cols: Math.min(trayItems.length, 4)
    readonly property int pad: 6

    // Surface dimensions: icons fill edge-to-edge with pad margin
    readonly property int surfW: cols > 0 ? cols * 36 + (cols - 1) * 4 + pad * 2 : 0
    readonly property int rows: cols > 0 ? Math.ceil(trayItems.length / 4) : 0
    readonly property int surfH: rows > 0 ? rows * 36 + (rows - 1) * 4 + pad * 2 : 0

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zanken-tray"
    WlrLayershell.keyboardFocus: root.trayVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.margins.top:    root.barEdge === "top"    ? root.barHeight : 0
    WlrLayershell.margins.bottom: root.barEdge === "bottom" ? root.barHeight : 0
    WlrLayershell.margins.left:   root.barEdge === "left"   ? root.barHeight : 0
    WlrLayershell.margins.right:  root.barEdge === "right"  ? root.barHeight : 0

    visible: root.trayVisible || _reveal > 0.001

    property real _reveal: root.trayVisible ? 1 : 0
    Behavior on _reveal {
        NumberAnimation {
            duration: root.trayVisible ? 220 : 140
            easing.type: root.trayVisible ? Easing.OutCubic : Easing.InCubic
        }
    }

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: root.trayVisible = false
    }

    Rectangle {
        id: surface
        width: trayPopup.surfW
        height: trayPopup.surfH
        color: trayPopup.root.bg
        border.color: trayPopup.root.sep
        border.width: 1
        radius: trayPopup.root.cornerRadius

        x: Math.max(8, Math.min(parent.width - width - 8, root.popupAnchorX - width / 2))
        y: root.barEdge === "top" ? 14 : parent.height - height - 14

        transform: Scale {
            origin.x: Math.max(0, Math.min(surface.width, root.popupAnchorX - surface.x))
            origin.y: root.barEdge === "top" ? 0 : surface.height
            xScale: trayPopup._reveal
            yScale: trayPopup._reveal
        }

        // Swallow clicks so dismiss area doesn't fire on icon clicks
        MouseArea { anchors.fill: parent }

        focus: root.trayVisible
        Keys.onPressed: function(e) {
            if (e.key === Qt.Key_Escape) { root.trayVisible = false; e.accepted = true; }
        }

        Flow {
            anchors.fill: parent
            anchors.margins: trayPopup.pad
            spacing: 4

            Repeater {
                model: trayPopup.trayItems

                delegate: Item {
                    required property var modelData
                    required property int index

                    width: 36
                    height: 36

                    readonly property string iconSource: {
                        const icon = modelData ? (modelData.icon || "") : "";
                        if (!icon) return "";
                        if (icon.indexOf("?path=") !== -1) {
                            const chunks = icon.split("?path=");
                            const name = chunks[0];
                            const path = chunks[1];
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return "file://" + path + "/" + fileName;
                        }
                        return icon;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: trayPopup.root.cornerRadius
                        color: trayMa.containsMouse
                               ? Qt.rgba(trayPopup.root.ink.r, trayPopup.root.ink.g, trayPopup.root.ink.b, 0.10)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: parent.iconSource
                        sourceSize.width: 24
                        sourceSize.height: 24
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true

                        Text {
                            visible: trayIcon.status !== Image.Ready
                            anchors.centerIn: parent
                            text: {
                                const t = trayPopup.trayItems[index] ? (trayPopup.trayItems[index].title || "") : "";
                                return t.length > 0 ? t.charAt(0).toUpperCase() : "?";
                            }
                            color: trayPopup.root.muted
                            font.family: trayPopup.root.mono
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: trayMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                        onEntered: {
                            const item = trayPopup.trayItems[index];
                            if (!item) return;
                            const tip = item.tooltipTitle || item.title || item.id || "";
                            if (tip) {
                                const p = trayMa.mapToItem(null, width / 2, height / 2);
                                trayPopup.root.showTooltip(tip, p.x, p.y);
                            }
                        }
                        onExited: {
                            const item = trayPopup.trayItems[index];
                            const tip = item ? (item.tooltipTitle || item.title || item.id || "") : "";
                            trayPopup.root.hideTooltip(tip);
                        }
                        onClicked: (e) => {
                            const item = trayPopup.trayItems[index];
                            if (!item) return;
                            if (e.button === Qt.RightButton || item.onlyMenu) {
                                // display() opens the DBus context menu at the click position
                                // relative to the trayPopup window (full-screen = screen coords)
                                const p = trayMa.mapToItem(null, e.x, e.y);
                                item.display(trayPopup, Math.round(p.x), Math.round(p.y));
                            } else if (e.button === Qt.MiddleButton) {
                                item.secondaryActivate();
                            } else {
                                item.activate();
                            }
                        }
                    }
                }
            }
        }
    }
}
