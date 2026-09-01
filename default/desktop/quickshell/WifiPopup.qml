import QtQuick

CardWindow {
    id: wifiPopup
    required property var root

    theme: root
    revealed: root.wifiVisible
    cardWidth: 400
    layerNamespace: "zanken-wifi"
    footer: ""

    anchorEdge: wifiPopup.root.barEdge
    anchorBarX: wifiPopup.root.popupAnchorX
    anchorBarY: wifiPopup.root.popupAnchorY

    onDismiss: wifiPopup.root.wifiVisible = false

    // Active SSID: prefer inUse flag, fall back to bar's current SSID
    readonly property string activeSsid: {
        const inUse = (wifiPopup.root.wifiNetworks || []).find(n => n.inUse);
        return inUse ? inUse.ssid : (wifiPopup.root.wifiSsid || "");
    }

    // The active network is shown exactly once in its own detail block.
    // Fall back to bar telemetry before the first scan completes.
    readonly property var activeNetwork: {
        const active = wifiPopup.activeSsid;
        const networks = wifiPopup.root.wifiNetworks || [];
        const inUse = networks.find(n => n.inUse || (active && n.ssid === active));
        if (inUse) return inUse;
        if (active) return { ssid: active, inUse: true, signal: wifiPopup.root.wifiSignal || 0, security: "" };
        return null;
    }
    readonly property var activeNetworkData: wifiPopup.activeNetwork || ({
        ssid: "",
        signal: 0,
        security: ""
    })

    property bool detailsExpanded: false
    // SSID awaiting password entry (shows inline password panel in available list)
    property string pendingConnectSsid: ""

    // Known-available = in-range + saved to NM + not currently connected
    property var knownAvailableNetworks: {
        const active = wifiPopup.activeSsid;
        const known = new Set(wifiPopup.root.wifiKnownSsids || []);
        return (wifiPopup.root.wifiNetworks || []).filter(n =>
            !n.inUse && n.ssid !== active && known.has(n.ssid))
            .sort((a, b) => (b.signal || 0) - (a.signal || 0));
    }

    // Available = in-range + not connected + NOT saved to NM (new/unknown networks)
    property var availableNetworks: {
        const active = wifiPopup.activeSsid;
        const known = new Set(wifiPopup.root.wifiKnownSsids || []);
        return (wifiPopup.root.wifiNetworks || []).filter(n =>
            !n.inUse && n.ssid !== active && !known.has(n.ssid))
            .sort((a, b) => (b.signal || 0) - (a.signal || 0));
    }

    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (wifiPopup.pendingConnectSsid !== "") {
                wifiPopup.pendingConnectSsid = "";
            } else {
                wifiPopup.root.wifiVisible = false;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_T) {
            wifiPopup.root.toggleWifiRadio();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            wifiPopup.root.refreshWifi();
            event.accepted = true;
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        // Header identifies the surface and radio state only. The SSID lives
        // in the connected-network block below, so it is never duplicated.
        Item {
            width: parent.width
            height: 43

            Column {
                anchors.left: parent.left
                anchors.right: wifiToggle.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "WI-FI"
                    color: wifiPopup.root.ink
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 19
                    font.letterSpacing: 4
                    font.weight: Font.Medium
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: wifiPopup.root.wifiRadioOn
                        ? (wifiPopup.activeNetwork ? "CONNECTED" : "NOT CONNECTED")
                        : "RADIO OFF"
                    color: wifiPopup.root.inkDeep
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }

            ToggleSwitch {
                id: wifiToggle
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: wifiPopup.root.wifiRadioOn
                onColor: wifiPopup.root.seal
                offColor: Qt.rgba(0.3, 0.3, 0.3, 1)
                onToggled: wifiPopup.root.toggleWifiRadio()
            }
        }

        Rectangle { width: parent.width; height: 1; color: wifiPopup.root.sep }

        // Radio off state
        Text {
            width: parent.width
            height: 60
            visible: !wifiPopup.root.wifiRadioOn
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "RADIO OFF"
            color: wifiPopup.root.inkDeep
            font.family: wifiPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.6
        }

        // === ACTIVE CONNECTION ===
        Column {
            width: parent.width
            spacing: 4
            visible: wifiPopup.root.wifiRadioOn && wifiPopup.activeNetwork !== null

            Text {
                text: "CONNECTED"
                color: wifiPopup.root.inkDeep
                font.family: wifiPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
            }

            Item {
                width: parent.width
                height: wifiPopup.detailsExpanded ? 100 : 62
                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                Rectangle {
                    anchors.fill: parent
                    color: wifiPopup.root.seal
                    opacity: 0.08
                }

                Text {
                    id: activeSignal
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    width: 20
                    text: wifiPopup.root.wifiBarsGlyph(wifiPopup.activeNetworkData.signal || 0)
                    color: wifiPopup.root.seal
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 14
                }

                Text {
                    anchors.left: activeSignal.right
                    anchors.leftMargin: 6
                    anchors.right: activeMeta.left
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 7
                    elide: Text.ElideRight
                    text: wifiPopup.activeNetworkData.ssid || "(hidden)"
                    color: wifiPopup.root.ink
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 12
                    font.letterSpacing: 1
                    font.weight: Font.Medium
                }

                Text {
                    id: activeMeta
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    text: (wifiPopup.activeNetworkData.signal || 0) + "%"
                    color: wifiPopup.root.seal
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                Text {
                    anchors.left: activeSignal.right
                    anchors.leftMargin: 6
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: activeSignal.bottom
                    anchors.topMargin: 3
                    elide: Text.ElideRight
                    text: (wifiPopup.activeNetworkData.security || "OPEN").toUpperCase()
                        + " · " + (wifiPopup.root.wifiConnectionDetails.band || "LINK ACTIVE")
                    color: wifiPopup.root.inkDeep
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }

                Row {
                    anchors.left: activeSignal.right
                    anchors.leftMargin: 6
                    anchors.top: parent.top
                    anchors.topMargin: 42
                    spacing: 16

                    Text {
                        text: "DETAILS"
                        color: activeDetailsMouse.containsMouse ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                        font.family: wifiPopup.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        MouseArea {
                            id: activeDetailsMouse
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiPopup.detailsExpanded = !wifiPopup.detailsExpanded;
                                if (wifiPopup.detailsExpanded) wifiPopup.root.refreshWifiDetails();
                            }
                        }
                    }

                    Text {
                        text: "DISCONNECT"
                        color: activeDisconnectMouse.containsMouse ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                        font.family: wifiPopup.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        MouseArea {
                            id: activeDisconnectMouse
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifiPopup.root.disconnectWifi()
                        }
                    }
                }

                Text {
                    anchors.left: activeSignal.right
                    anchors.leftMargin: 6
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    visible: wifiPopup.detailsExpanded
                    elide: Text.ElideRight
                    text: wifiPopup.root.wifiDetailsLoading
                        ? "READING LINK…"
                        : ((wifiPopup.root.wifiConnectionDetails.address || "NO IPV4")
                            + " · " + (wifiPopup.root.wifiConnectionDetails.gateway || "NO GATEWAY"))
                    color: wifiPopup.root.inkDeep
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
            }
        }

        // === SAVED NEARBY (in range, saved to NetworkManager) ===
        Column {
            width: parent.width
            spacing: 0
            visible: wifiPopup.root.wifiRadioOn && wifiPopup.knownAvailableNetworks.length > 0

            Text {
                text: "SAVED NEARBY"
                color: wifiPopup.root.inkDeep
                font.family: wifiPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
                bottomPadding: 6
            }

            Repeater {
                model: wifiPopup.knownAvailableNetworks.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    readonly property bool isConnecting: modelData.ssid === (wifiPopup.root.wifiConnectingSSID || "")
                    readonly property bool hasFailed: modelData.ssid === (wifiPopup.root.wifiConnectError || "")

                    Text {
                        id: knSigIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        text: wifiPopup.root.wifiBarsGlyph(modelData.signal || 0)
                        color: wifiPopup.root.inkDeep
                        font.family: wifiPopup.root.mono
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.left: knSigIcon.right
                        anchors.leftMargin: 6
                        anchors.right: knRightRow.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.ssid || "(hidden)"
                        color: wifiPopup.root.ink
                        font.family: wifiPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }

                    Row {
                        id: knRightRow
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: isConnecting ? "CONNECTING…"
                                : hasFailed ? "FAILED"
                                : (modelData.signal || 0) + "%"
                            color: isConnecting ? wifiPopup.root.ink
                                : hasFailed ? "#e06c75"
                                : wifiPopup.root.inkDeep
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            font.weight: (isConnecting || hasFailed) ? Font.Medium : Font.Normal
                            SequentialAnimation on opacity {
                                running: isConnecting
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰩺"
                            color: knDeleteArea.containsMouse ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                            opacity: knDeleteArea.containsMouse ? 1.0 : 0.35
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            MouseArea {
                                id: knDeleteArea
                                anchors.fill: parent
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiPopup.root.forgetWifi(modelData.ssid)
                            }
                        }
                    }

                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: knRightRow.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        cursorShape: isConnecting ? Qt.BusyCursor : Qt.PointingHandCursor
                        onClicked: {}
                        onDoubleClicked: {
                            if (isConnecting) return;
                            wifiPopup.root.connectWifi(modelData.ssid, "");
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: wifiPopup.root.sep
                        opacity: 0.4
                    }
                }
            }
        }

        // === NEARBY (new networks, sorted strongest first) ===
        Text {
            width: parent.width
            visible: wifiPopup.root.wifiRadioOn
                  && (wifiPopup.availableNetworks.length > 0 || wifiPopup.root.wifiScanning)
            text: wifiPopup.root.wifiScanning ? "NEARBY · SCANNING…" : "NEARBY"
            color: wifiPopup.root.inkDeep
            font.family: wifiPopup.root.mono
            font.pixelSize: 9
            font.letterSpacing: 2
            opacity: 0.7
        }

        // === AVAILABLE NETWORKS list ===
        Column {
            width: parent.width
            spacing: 0
            visible: wifiPopup.root.wifiRadioOn
                  && (wifiPopup.availableNetworks.length > 0 || wifiPopup.root.wifiScanning)

            ListView {
                id: availList
                width: parent.width
                height: Math.min(contentHeight, 5 * 34)
                clip: true
                model: wifiPopup.availableNetworks
                boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    required property var modelData
                    width: availList.width
                    readonly property bool isPending: wifiPopup.pendingConnectSsid === modelData.ssid
                    height: isPending ? 86 : 34
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                    readonly property bool isActive: modelData.inUse === true
                        || modelData.ssid === wifiPopup.activeSsid
                    readonly property bool isConnecting: modelData.ssid === (wifiPopup.root.wifiConnectingSSID || "")
                    readonly property bool hasFailed: modelData.ssid === (wifiPopup.root.wifiConnectError || "")

                    // Top row
                    Item {
                        id: aTopRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            color: isActive ? wifiPopup.root.seal : "transparent"
                            opacity: isActive ? 0.10 : 0
                        }

                        Text {
                            id: aSigIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            text: wifiPopup.root.wifiBarsGlyph(modelData.signal || 0)
                            color: isActive ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.left: aSigIcon.right
                            anchors.leftMargin: 6
                            anchors.right: aSigText.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: modelData.ssid || "(hidden)"
                            color: isActive ? wifiPopup.root.seal : wifiPopup.root.ink
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            font.weight: isActive ? Font.Medium : Font.Normal
                        }

                        Text {
                            id: aSigText
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: isConnecting ? "CONNECTING…"
                                : hasFailed ? "FAILED"
                                : isActive ? "CONNECTED"
                                : ((modelData.security && modelData.security !== "" && modelData.security !== "none" ? "󰌆 " : "") + (modelData.signal || 0) + "%")
                            color: isConnecting ? wifiPopup.root.ink
                                : hasFailed ? "#e06c75"
                                : isActive ? wifiPopup.root.seal
                                : wifiPopup.root.inkDeep
                            font.family: wifiPopup.root.mono
                            font.pixelSize: (isConnecting || hasFailed || isActive) ? 9 : 10
                            font.letterSpacing: 1
                            font.weight: (isConnecting || hasFailed || isActive) ? Font.Medium : Font.Normal
                            SequentialAnimation on opacity {
                                running: isConnecting
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: isConnecting ? Qt.BusyCursor : Qt.PointingHandCursor
                            onClicked: {}
                            onDoubleClicked: {
                                if (isConnecting) return;
                                const hasSec = modelData.security
                                    && modelData.security !== ""
                                    && modelData.security !== "none";
                                const isKnown = (wifiPopup.root.wifiKnownSsids || []).includes(modelData.ssid);
                                if (hasSec && !isActive && !isKnown) {
                                    wifiPopup.pendingConnectSsid = modelData.ssid;
                                } else {
                                    wifiPopup.root.connectWifi(modelData.ssid, "");
                                }
                            }
                        }
                    }

                    // Inline password panel — expands below the row for secured networks
                    Item {
                        id: aPassPanel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: aTopRow.bottom
                        height: 52
                        visible: isPending
                        clip: true

                        onVisibleChanged: {
                            if (visible) {
                                passInput.text = "";
                                wifiPopup.requestKeyboardFocus(passInput);
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: wifiPopup.root.seal
                            opacity: 0.06
                        }

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: wifiPopup.root.sep
                            opacity: 0.5
                        }

                        // Lock icon
                        Text {
                            id: aLockIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰌆"
                            color: wifiPopup.root.seal
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 13
                        }

                        // Cancel button (rightmost)
                        Text {
                            id: aCancelBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰅖"
                            color: aCancelMouse.containsMouse ? "#f87171" : wifiPopup.root.inkDeep
                            opacity: aCancelMouse.containsMouse ? 1.0 : 0.5
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            MouseArea {
                                id: aCancelMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    passInput.text = "";
                                    wifiPopup.pendingConnectSsid = "";
                                }
                            }
                        }

                        // Connect button (left of cancel)
                        Text {
                            id: aConnectBtn
                            anchors.right: aCancelBtn.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰌑"
                            color: aConnectMouse.containsMouse ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 16
                            Behavior on color { ColorAnimation { duration: 120 } }
                            MouseArea {
                                id: aConnectMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (passInput.text.length > 0) {
                                        wifiPopup.root.connectWifi(wifiPopup.pendingConnectSsid, passInput.text);
                                        passInput.text = "";
                                        wifiPopup.pendingConnectSsid = "";
                                    }
                                }
                            }
                        }

                        // Password text field (fills middle)
                        Item {
                            anchors.left: aLockIcon.right
                            anchors.leftMargin: 8
                            anchors.right: aConnectBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: 24
                            clip: true

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: passInput.text === ""
                                text: "PASSWORD"
                                color: wifiPopup.root.inkDeep
                                opacity: 0.4
                                font.family: wifiPopup.root.mono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                            }

                            TextInput {
                                id: passInput
                                anchors.fill: parent
                                onActiveFocusChanged: if (activeFocus) wifiPopup.requestKeyboardFocus(passInput)
                                TapHandler {
                                    onTapped: wifiPopup.requestKeyboardFocus(passInput)
                                }
                                echoMode: TextInput.Password
                                color: wifiPopup.root.ink
                                font.family: wifiPopup.root.mono
                                font.pixelSize: 12
                                verticalAlignment: TextInput.AlignVCenter
                                selectionColor: wifiPopup.root.seal
                                selectedTextColor: "#ffffff"
                                Keys.onReturnPressed: {
                                    if (text.length > 0) {
                                        wifiPopup.root.connectWifi(wifiPopup.pendingConnectSsid, text);
                                        text = "";
                                        wifiPopup.pendingConnectSsid = "";
                                    }
                                }
                                Keys.onEscapePressed: {
                                    text = "";
                                    wifiPopup.pendingConnectSsid = "";
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: wifiPopup.root.sep
                        opacity: 0.4
                    }
                }
            }
        }

        // Empty state
        Text {
            width: parent.width
            height: 36
            visible: wifiPopup.root.wifiRadioOn
                  && !wifiPopup.root.wifiScanning
                  && wifiPopup.root.wifiNetworks.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "NO NETWORKS FOUND"
            color: wifiPopup.root.inkDeep
            font.family: wifiPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.6
        }

        // Custom footer: instruction text left, reload button right
        Rectangle {
            width: parent.width
            height: 1
            color: wifiPopup.root.sep
            opacity: 0.5
        }

        Item {
            width: parent.width
            height: 38

            Column {
                anchors.left: parent.left
                anchors.right: footerReloadBtn.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: "DBL-CLICK CONNECT · ENTER PASSWORD"
                    color: wifiPopup.root.inkDeep
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    opacity: 0.7
                }

                Text {
                    width: parent.width
                    text: "T TOGGLE RADIO · ESC CLOSE"
                    color: wifiPopup.root.inkDeep
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    opacity: 0.7
                }
            }

            Item {
                id: footerReloadBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                opacity: wifiPopup.root.wifiScanning ? 0.35 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 22; height: 22
                    radius: 11
                    color: wifiPopup.root.seal
                    opacity: footerReloadMouse.containsMouse ? 0.18 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰑓"
                    color: footerReloadMouse.containsMouse ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                    font.family: wifiPopup.root.mono
                    font.pixelSize: 13
                    Behavior on color { ColorAnimation { duration: 150 } }
                    SequentialAnimation on rotation {
                        running: wifiPopup.root.wifiScanning
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: 360; duration: 900; easing.type: Easing.Linear }
                    }
                }

                MouseArea {
                    id: footerReloadMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !wifiPopup.root.wifiScanning
                    onClicked: wifiPopup.root.refreshWifi()
                }
            }
        }
    }
}
