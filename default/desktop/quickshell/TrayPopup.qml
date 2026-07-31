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
    property var menuHandle: null
    property var menuStack: []
    property string menuLabel: ""
    property int menuX: 0
    property int menuY: 0

    function openMenu(item, x, y) {
        if (!item || !item.hasMenu || !item.menu) return;
        menuHandle = item.menu;
        menuStack = [];
        menuLabel = item.tooltipTitle || item.title || item.id || "TRAY MENU";
        menuX = x;
        menuY = y;
    }

    function openSubmenu(menuEntry) {
        if (!menuEntry || !menuEntry.hasChildren) return;
        menuStack = menuStack.concat([{ handle: menuHandle, label: menuLabel }]);
        menuHandle = menuEntry;
        menuLabel = menuEntry.text || menuLabel;
    }

    function closeMenu() {
        menuHandle = null;
        menuStack = [];
        menuLabel = "";
    }

    function goBack() {
        if (menuStack.length === 0) {
            closeMenu();
            return;
        }
        const parent = menuStack[menuStack.length - 1];
        menuStack = menuStack.slice(0, -1);
        menuHandle = parent.handle;
        menuLabel = parent.label;
    }

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

    QsMenuOpener {
        id: menuOpener
        menu: trayPopup.menuHandle
    }

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: {
            trayPopup.closeMenu();
            root.trayVisible = false;
        }
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
            if (e.key === Qt.Key_Escape) {
                if (trayPopup.menuHandle) trayPopup.closeMenu();
                else root.trayVisible = false;
                e.accepted = true;
            }
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
                                const p = trayMa.mapToItem(null, e.x, e.y);
                                trayPopup.openMenu(item, Math.round(p.x), Math.round(p.y));
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

    Rectangle {
        id: menuPanel
        readonly property int contentHeight: Math.min(menuList.implicitHeight, 360)

        visible: trayPopup.menuHandle !== null
        width: 248
        height: menuHeader.height + contentHeight + 8
        x: Math.max(8, Math.min(parent.width - width - 8, trayPopup.menuX))
        y: Math.max(8, Math.min(parent.height - height - 8, trayPopup.menuY))
        z: 2
        color: trayPopup.root.bg
        border.color: trayPopup.root.sep
        border.width: 1
        radius: trayPopup.root.cornerRadius

        MouseArea { anchors.fill: parent }

        Item {
            id: menuHeader
            width: parent.width
            height: 32

            Image {
                id: menuAppIcon
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                source: {
                    const item = trayPopup.trayItems.find(candidate =>
                        candidate && (candidate.tooltipTitle || candidate.title || candidate.id || "") === trayPopup.menuLabel);
                    return item ? item.icon : "";
                }
                sourceSize.width: 24
                sourceSize.height: 24
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.left: menuAppIcon.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: trayPopup.menuStack.length > 0
                      ? "‹  " + trayPopup.menuLabel.toUpperCase()
                      : trayPopup.menuLabel.toUpperCase()
                color: trayPopup.root.ink
                elide: Text.ElideRight
                font.family: trayPopup.root.mono
                font.pixelSize: 10
                font.weight: Font.Medium
                font.letterSpacing: 1.5
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: trayPopup.root.sep
            }

            MouseArea {
                anchors.fill: parent
                enabled: trayPopup.menuStack.length > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: trayPopup.goBack()
            }
        }

        Flickable {
            id: menuScroller
            anchors.top: menuHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            contentWidth: width
            contentHeight: menuList.implicitHeight
            clip: true

            Column {
                id: menuList
                width: menuScroller.width

                Repeater {
                    model: menuOpener.children

                    delegate: Item {
                        required property var modelData
                        readonly property var menuEntry: modelData
                        readonly property bool separator: menuEntry ? menuEntry.isSeparator : false

                        width: menuList.width
                        height: separator ? 6 : 28

                        Rectangle {
                            visible: parent.separator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            height: 1
                            color: trayPopup.root.sep
                        }

                        Rectangle {
                            visible: !parent.separator && menuMouse.containsMouse && parent.menuEntry.enabled
                            anchors.fill: parent
                            radius: trayPopup.root.cornerRadius - 1
                            color: Qt.rgba(trayPopup.root.ink.r, trayPopup.root.ink.g, trayPopup.root.ink.b, 0.10)
                        }

                        Text {
                            id: menuMark
                            visible: !parent.separator && parent.menuEntry.buttonType !== QsMenuButtonType.None
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (parent.menuEntry.buttonType === QsMenuButtonType.RadioButton)
                                    return parent.menuEntry.checkState === Qt.Checked ? "●" : "○";
                                return parent.menuEntry.checkState === Qt.Checked ? "✓" : "";
                            }
                            color: trayPopup.root.seal
                            font.family: trayPopup.root.mono
                            font.pixelSize: 10
                        }

                        Image {
                            id: menuIcon
                            visible: !parent.separator && parent.menuEntry.icon !== ""
                            anchors.left: menuMark.visible ? menuMark.right : parent.left
                            anchors.leftMargin: menuMark.visible ? 7 : 9
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            source: parent.menuEntry.icon || ""
                            sourceSize.width: 20
                            sourceSize.height: 20
                            fillMode: Image.PreserveAspectFit
                        }

                        Text {
                            anchors.left: menuIcon.visible ? menuIcon.right : (menuMark.visible ? menuMark.right : parent.left)
                            anchors.leftMargin: menuIcon.visible ? 7 : (menuMark.visible ? 7 : 9)
                            anchors.right: menuArrow.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.separator ? "" : parent.menuEntry.text
                            color: parent.menuEntry.enabled ? trayPopup.root.fg : trayPopup.root.muted
                            elide: Text.ElideRight
                            font.family: trayPopup.root.mono
                            font.pixelSize: 10
                        }

                        Text {
                            id: menuArrow
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !parent.separator && parent.menuEntry.hasChildren
                            text: "›"
                            color: trayPopup.root.inkDeep
                            font.family: trayPopup.root.mono
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            enabled: !parent.separator && parent.menuEntry.enabled
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (parent.menuEntry.hasChildren) {
                                    trayPopup.openSubmenu(parent.menuEntry);
                                    return;
                                }
                                parent.menuEntry.triggered();
                                trayPopup.closeMenu();
                                root.trayVisible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
