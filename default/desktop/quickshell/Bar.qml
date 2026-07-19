import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var root

    color: "transparent"
    // Anchors track barEdge — three sides anchored, the side opposite
    // the bar's edge is left free for the bar's thickness to extend.
    anchors {
        top:    bar.root.barEdge !== "bottom"
        bottom: bar.root.barEdge !== "top"
        left:   bar.root.barEdge !== "right"
        right:  bar.root.barEdge !== "left"
    }
    // Cloud mode: horizontal+round only. Vertical bars keep the original
    // slab geometry to avoid breaking the proven layout.
    readonly property int cloudPad: 4
    readonly property int cloudHAir: 16
    readonly property int cloudVAir: 5
    readonly property int cloudInnerAir: 2
    readonly property int cloudHPad: 8
    readonly property bool cloudMode: bar.root.round && bar.root.isHorizontal
    readonly property int extraThickness: cloudMode ? 2 * cloudPad + cloudVAir + cloudInnerAir : 0
    // innerSign tells which side gets the extra outer air (away from screen).
    readonly property int innerSign: bar.root.barEdge === "top" ? 1 : (bar.root.barEdge === "bottom" ? -1 : 0)

    implicitHeight: bar.root.isHorizontal ? bar.root.barHeight + extraThickness : 0
    implicitWidth:  bar.root.isHorizontal ? 0 : bar.root.barHeight
    exclusiveZone:  bar.root.isHorizontal ? bar.root.barHeight + extraThickness : bar.root.barHeight

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "zanken-menu"

    // In cloud mode the slab bg is replaced by a single rounded backdrop
    // sized to match the inner bar (barHeight tall, with cloudAir margins
    // on each side along the bar axis, sliding toward the inner edge so
    // outer-side air sits between cloud and screen edge).
    Rectangle {
        visible: bar.cloudMode
        x: bar.cloudHAir
        y: bar.innerSign === 1 ? bar.cloudVAir : bar.cloudInnerAir
        width: parent.width - 2 * bar.cloudHAir
        height: bar.root.barHeight + 2 * bar.cloudPad
        radius: 0
        color: bar.root.bg
        border.width: 2
        border.color: bar.root.seal
        opacity: 1.0
        z: 0
    }

    // Container for clock + modules + hairlines. In cloud mode the bg
    // becomes transparent so the cloud rectangle above shows through;
    // in slab mode this acts as the bar background.
    Rectangle {
        anchors.fill: parent
        color: bar.cloudMode ? "transparent" : bar.root.bg
        opacity: 1.0

        // 静 (stillness) mark, parked in the bar's trailing corner.
        Text {
            visible: !bar.cloudMode
            anchors.right:  bar.root.isHorizontal ? parent.right  : undefined
            anchors.bottom: bar.root.isHorizontal ? undefined     : parent.bottom
            anchors.rightMargin:  bar.root.isHorizontal ? 8 : 0
            anchors.bottomMargin: bar.root.isHorizontal ? 0 : 8
            anchors.verticalCenter:   bar.root.isHorizontal ? parent.verticalCenter   : undefined
            anchors.horizontalCenter: bar.root.isHorizontal ? undefined : parent.horizontalCenter
            text: "静"
            color: Qt.rgba(bar.root.ink.r, bar.root.ink.g, bar.root.ink.b, 0.07)
            font.family: bar.root.serif
            font.pixelSize: bar.root.barHeight + 6
            font.weight: Font.Light
            z: 0
        }

        // Inner-edge hairline (facing the rest of the screen). Hidden in
        // cloud mode — the rounded backdrop replaces it visually.
        Rectangle {
            visible: !bar.cloudMode && bar.root.isHorizontal
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    bar.root.barEdge === "bottom" ? parent.top    : undefined
            anchors.bottom: bar.root.barEdge === "top"    ? parent.bottom : undefined
            height: 2
            color: bar.root.seal
        }
        Rectangle {
            visible: !bar.cloudMode && !bar.root.isHorizontal
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.right:  bar.root.barEdge === "left"  ? parent.right : undefined
            anchors.left:   bar.root.barEdge === "right" ? parent.left  : undefined
            width: 2
            color: bar.root.seal
        }

        // Centre cluster: clock only, clickable. Horizontal bars show
        // "HH:MM" on one line; vertical bars stack HH and MM.
        Item {
            id: clockItem
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            z: 10
            Component.onCompleted: bar.root.calendarAnchorItem = clockItem

            implicitWidth:  bar.root.isHorizontal
                            ? clockOneLine.implicitWidth + 14
                            : Math.max(clockHH.implicitWidth, clockMM.implicitWidth) + 8
            implicitHeight: bar.root.isHorizontal
                            ? clockOneLine.implicitHeight + 8
                            : (clockHH.implicitHeight + clockMM.implicitHeight + 6)

            Bloom { id: clockBloom; root: bar.root }

            Text {
                id: clockOneLine
                visible: bar.root.isHorizontal
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: bar.root.hh + ":" + bar.root.mm
                color: clockMouse.containsMouse ? bar.root.seal : bar.root.ink
                font.family: bar.root.mono
                font.pixelSize: 12
                font.letterSpacing: 2
                font.weight: Font.Light
                Behavior on color { ColorAnimation { duration: 180 } }
            }
            Text {
                id: clockHH
                visible: !bar.root.isHorizontal
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: 1
                text: bar.root.hh
                color: clockMouse.containsMouse ? bar.root.seal : bar.root.ink
                font.family: bar.root.mono
                font.pixelSize: 11
                font.weight: Font.Light
                Behavior on color { ColorAnimation { duration: 180 } }
            }
            Text {
                id: clockMM
                visible: !bar.root.isHorizontal
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 1
                text: bar.root.mm
                color: clockMouse.containsMouse ? bar.root.seal : bar.root.ink
                font.family: bar.root.mono
                font.pixelSize: 11
                font.weight: Font.Light
                Behavior on color { ColorAnimation { duration: 180 } }
            }

            Timer {
                id: clockTipDelay
                interval: 320
                onTriggered: {
                    const p = clockItem.mapToItem(null, clockItem.width / 2, clockItem.height / 2);
                    bar.root.showTooltip("Calendar", p.x, p.y);
                }
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: { clockBloom.fire(mouseX, mouseY); clockTipDelay.restart(); }
                onExited:  { clockTipDelay.stop(); bar.root.hideTooltip("Calendar"); }
                onClicked: {
                    clockTipDelay.stop();
                    bar.root.hideTooltip("Calendar");
                    if (bar.root.calendarVisible) bar.root.calendarVisible = false;
                    else bar.root.openCalendar();
                }
            }
        }

        // Now-playing pill, anchored to the bar's right edge so it sits
        // outside (to the right of) the system-icons cluster. The
        // GridLayout reserves room for it via an enlarged rightMargin when
        // visible so the icons stop short and don't overlap. Sits above
        // the GridLayout (same z trick the clockItem uses).
        Item {
            id: musicItem
            visible: bar.root.isHorizontal && bar.root.musicTitle.length > 0
            anchors.right: parent.right
            anchors.rightMargin: bar.cloudMode ? bar.cloudHAir + bar.cloudHPad : 10
            anchors.verticalCenter: parent.verticalCenter
            // Match the -1 optical lift applied to icons / clock so the
            // pill sits on the same baseline as the rest of the bar row.
            anchors.verticalCenterOffset: -1
            height: 16
            width: musicPill.width
            z: 10
            Component.onCompleted: bar.root.musicAnchorItem = musicItem

            readonly property string tipText: bar.root.musicArtist.length > 0
                                              ? bar.root.musicTitle + " - " + bar.root.musicArtist
                                              : bar.root.musicTitle

            Rectangle {
                id: musicPill
                anchors.verticalCenter: parent.verticalCenter
                width: musicRow.width + 22
                height: parent.height
                radius: height / 2
                color: bar.root.accent
                opacity: musicMouse.containsMouse ? 1.0 : 0.9
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    id: musicRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        id: musicIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: bar.root.icoMusic
                        color: bar.root.paper
                        font.family: bar.root.mono
                        font.pixelSize: 13
                    }

                    Text {
                        id: musicLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 140)
                        text: bar.root.musicTitle
                        color: bar.root.paper
                        font.family: bar.root.mono
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }
            }

            Timer {
                id: musicTipDelay
                interval: 320
                onTriggered: {
                    const p = musicItem.mapToItem(null, musicItem.width / 2, musicItem.height / 2);
                    bar.root.showTooltip(musicItem.tipText, p.x, p.y);
                }
            }

            MouseArea {
                id: musicMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onEntered: musicTipDelay.restart()
                onExited:  { musicTipDelay.stop(); bar.root.hideTooltip(musicItem.tipText); }
                onClicked: (e) => {
                    musicTipDelay.stop();
                    bar.root.hideTooltip(musicItem.tipText);
                    if (e.button === Qt.RightButton)       bar.root.musicNext();
                    else if (e.button === Qt.MiddleButton) bar.root.musicPrev();
                    else {
                        if (bar.root.musicVisible) bar.root.musicVisible = false;
                        else bar.root.openMusic();
                    }
                }
            }
        }

        GridLayout {
            anchors.fill: parent
            anchors.leftMargin:   bar.root.isHorizontal ? (bar.cloudMode ? bar.cloudHAir + bar.cloudHPad : 10) : 0
            anchors.rightMargin:  bar.root.isHorizontal
                                  ? ((bar.cloudMode ? bar.cloudHAir + bar.cloudHPad : 10)
                                     + (musicItem.visible ? musicItem.width + 8 : 0))
                                  : 0
            anchors.topMargin:    bar.root.isHorizontal
                                  ? (bar.cloudMode
                                     ? (bar.root.barEdge === "top" ? bar.cloudVAir + bar.cloudPad : bar.cloudInnerAir + bar.cloudPad)
                                     : 0)
                                  : 10
            anchors.bottomMargin: bar.root.isHorizontal
                                  ? (bar.cloudMode
                                     ? (bar.root.barEdge === "top" ? bar.cloudInnerAir + bar.cloudPad : bar.cloudVAir + bar.cloudPad)
                                     : 0)
                                  : 10
            flow: bar.root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
            rowSpacing: 4
            columnSpacing: 4
            columns: bar.root.isHorizontal ? -1 : 1
            rows:    bar.root.isHorizontal ? 1  : -1

            Module {
                id: zankenModule
                root: bar.root
                glyph: bar.root.icoZanken
                tooltip: "System"
                color: bar.root.seal
                fontFamily: bar.root.serif
                fontSize: 14
                onActivated: {
                    bar.root.anchorPopupTo(zankenModule);
                    bar.root.openSystem();
                }
                onRightActivated: bar.root.run("xdg-terminal-exec")
            }

            Separator { root: bar.root }

            Repeater {
                model: 10
                delegate: Workspace {
                    required property int index
                    root: bar.root
                    wsId: index + 1
                    label: bar.root.indexKanji(index + 1)
                    active: bar.root.activeWs === (index + 1)
                    present: bar.root.existingWs.indexOf(index + 1) !== -1
                    onActivated: bar.root.run("niri msg action focus-workspace " + (index + 1))
                }
            }

            Item {
                Layout.fillWidth:  bar.root.isHorizontal
                Layout.fillHeight: !bar.root.isHorizontal
            }

            Module {
                id: trayMod
                root: bar.root
                glyph: bar.root.trayVisible ? String.fromCodePoint(0xf0143) : String.fromCodePoint(0xf0140)
                tooltip: bar.root.trayItemCount > 0 ? "System tray · " + bar.root.trayItemCount + " items" : "System tray"
                color: bar.root.trayVisible ? bar.root.seal : bar.root.trayItemCount > 0 ? bar.root.ink : bar.root.muted
                fontSize: 14
                Component.onCompleted: bar.root.trayAnchorItem = trayMod
                onActivated: {
                    if (bar.root.trayItemCount === 0) return;
                    if (bar.root.trayVisible) bar.root.trayVisible = false;
                    else bar.root.openTray();
                }
            }

            Separator { root: bar.root }

            // Pop-up / overlay openers sit on the inside of the right
            // cluster — weather, display tweaks, screenshots browser.
            Module {
                id: weatherMod
                root: bar.root
                Component.onCompleted: bar.root.weatherAnchorItem = weatherMod
                // Muted middle dot stands in until the first wttr fetch
                // lands; a "?" marks an unreachable network.
                glyph: bar.root.weatherUnavailable ? "?"
                       : (bar.root.weatherLoaded ? bar.root.weatherIcon : "·")
                tooltip: bar.root.weatherUnavailable
                         ? "Weather offline"
                         : (bar.root.weatherLoaded
                            ? bar.root.weatherTempC + "°C"
                            : "Weather…")
                color: bar.root.weatherUnavailable ? bar.root.inkDeep : bar.root.ink
                fontSize: 17
                onActivated: {
                    if (bar.root.weatherVisible) bar.root.weatherVisible = false;
                    else bar.root.openWeather();
                }
                onRightActivated: bar.root.refreshWeather()
            }

            // Aether / Display / Screenshots / Videos moved into the
            // OmniMenu Quick panel (Alt+Space). The bar keeps only the
            // always-glanced status indicators on the right.

            Separator { root: bar.root }

            // System indicators read right-to-left as
            //   battery · sound · wifi · bluetooth · cpu · [edge]
            // so the most-glanced item (battery) sits adjacent to the
            // bar-position chevron.
            Module {
                id: coffeeMod
                root: bar.root
                glyph: bar.root.icoCoffee
                tooltip: bar.root.idleInhibit ? "Idle inhibitor: ON" : "Idle inhibitor: OFF"
                color: bar.root.idleInhibit ? bar.root.seal : bar.root.ink
                onActivated: bar.root.toggleIdleInhibit()

                SequentialAnimation {
                    running: bar.root.idleInhibit
                    loops: Animation.Infinite
                    NumberAnimation { target: coffeeMod; property: "opacity"; to: 0.25; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { target: coffeeMod; property: "opacity"; to: 1.0;  duration: 1800; easing.type: Easing.InOutSine }
                    onStopped: coffeeMod.opacity = 1.0
                }
            }

            Module {
                id: clipboardMod
                root: bar.root
                glyph: String.fromCodePoint(0xf0c5)
                tooltip: bar.root.clipHistory.length > 0
                         ? "Clipboard · " + bar.root.clipHistory.length + " items"
                         : "Clipboard"
                color: bar.root.clipboardVisible ? bar.root.seal : bar.root.ink
                Component.onCompleted: bar.root.clipboardAnchorItem = clipboardMod
                onActivated: {
                    if (bar.root.clipboardVisible) bar.root.clipboardVisible = false;
                    else bar.root.openClipboard();
                }
            }

            Module {
                id: bluetoothMod
                root: bar.root
                glyph: bar.root.btIcon
                tooltip: {
                    if (!bar.root.btPowered) return "Bluetooth off";
                    return bar.root.btCount > 0
                        ? "Bluetooth · " + bar.root.btCount + " connected"
                        : "Bluetooth on";
                }
                Component.onCompleted: bar.root.bluetoothAnchorItem = bluetoothMod
                onActivated: {
                    if (bar.root.bluetoothVisible) bar.root.bluetoothVisible = false;
                    else bar.root.openBluetooth();
                }
            }

            Module {
                id: netMod
                root: bar.root
                glyph: bar.root.netIcon
                tooltip: {
                    if (bar.root.netKind === "eth") return "Ethernet";
                    if (bar.root.netKind === "wifi") {
                        const name = bar.root.wifiSsid || "(hidden)";
                        return "Wi-Fi · " + name + " · " + bar.root.wifiSignal + "%";
                    }
                    return "Offline";
                }
                Component.onCompleted: bar.root.wifiAnchorItem = netMod
                onActivated: {
                    if (bar.root.wifiVisible) bar.root.wifiVisible = false;
                    else bar.root.openWifi();
                }

                // Network-burst dot: traverses the wifi glyph's outermost
                // arc once when a heavy rx+tx burst is detected.
                // Geometry is eyeballed for the Nerd Font wifi icon
                // rendered at fontSize 12 inside the 24x26 Module slot.
                Item {
                    id: arc
                    anchors.fill: parent
                    property real t: 0
                    property real op: 0
                    readonly property real cx: width / 2
                    readonly property real cy: 17
                    readonly property real r:  6

                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: Qt.lighter(bar.root.seal, 1.7)
                        antialiasing: true
                        opacity: arc.op
                        x: arc.cx - arc.r * Math.cos(Math.PI * arc.t) - width / 2
                        y: arc.cy - arc.r * Math.sin(Math.PI * arc.t) - height / 2
                    }

                    ParallelAnimation {
                        id: arcAnim
                        NumberAnimation {
                            target: arc; property: "t"
                            from: 0; to: 1
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                        SequentialAnimation {
                            NumberAnimation { target: arc; property: "op"; from: 0; to: 1; duration: 120; easing.type: Easing.OutQuad }
                            PauseAnimation { duration: 380 }
                            NumberAnimation { target: arc; property: "op"; to: 0; duration: 200; easing.type: Easing.InCubic }
                        }
                    }

                    Connections {
                        target: bar.root
                        function onNetBurst() { arc.t = 0; arcAnim.restart(); }
                    }
                }
            }

            Module {
                id: audioMod
                root: bar.root
                glyph: bar.root.audioIcon
                tooltip: bar.root.audioMuted
                         ? "Audio muted · " + bar.root.audioVol + "%"
                         : "Audio " + bar.root.audioVol + "%"
                Component.onCompleted: bar.root.audioAnchorItem = audioMod
                onActivated: {
                    if (bar.root.audioVisible) bar.root.audioVisible = false;
                    else bar.root.openAudio();
                }
                onRightActivated: bar.root.run("pamixer -t")
            }

            Module {
                id: battMod
                visible: bar.root.hasBattery
                root: bar.root
                Component.onCompleted: bar.root.batteryAnchorItem = battMod
                glyph: bar.root.batteryIcon()
                tooltip: {
                    let s = "Battery " + bar.root.batVal + "%";
                    if (bar.root.batPower >= 0.05) {
                        const sign = bar.root.batState === "Charging"    ? "+"
                                   : bar.root.batState === "Discharging" ? "-"
                                   : "";
                        s += "  " + sign + bar.root.batPower.toFixed(1) + " W";
                    }
                    return s;
                }
                color: bar.root.batVal <= 10 ? bar.root.seal : bar.root.batVal <= 20 ? bar.root.indigo : bar.root.ink
                onActivated: {
                    if (bar.root.batteryVisible) bar.root.batteryVisible = false;
                    else bar.root.openBattery();
                }
            }

            Item {
                id: notifItem
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 28
                Layout.preferredHeight: bar.root.barHeight

                Module {
                    id: notifMod
                    anchors.fill: parent
                    root: bar.root
                    glyph: bar.root.doNotDisturb
                           ? String.fromCodePoint(0xf1f6)
                           : String.fromCodePoint(0xf0f3)
                    color: bar.root.doNotDisturb
                           ? bar.root.muted
                           : bar.root.notificationCount > 0 ? bar.root.seal : bar.root.ink
                    tooltip: bar.root.doNotDisturb
                             ? "Do not disturb"
                             : bar.root.notificationCount > 0
                               ? bar.root.notificationCount + (bar.root.notificationCount === 1 ? " notification" : " notifications")
                               : "Notifications"
                    Component.onCompleted: bar.root.notificationAnchorItem = notifItem
                    onActivated: {
                        if (bar.root.notificationsVisible) bar.root.notificationsVisible = false;
                        else bar.root.openNotifications();
                    }
                }

                Rectangle {
                    visible: bar.root.notificationCount > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    anchors.rightMargin: 2
                    width: 6; height: 6; radius: 3
                    color: bar.root.seal
                }
            }

            Separator {
                root: bar.root
                visible: bar.root.isHorizontal && bar.root.musicTitle.length > 0
            }
        }
    }
}
