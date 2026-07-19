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

    // Connected = only the currently active network(s).
    // Falls back to bar's wifiSsid before the first scan completes.
    property var connectedNetworks: {
        const active = wifiPopup.activeSsid;
        const networks = wifiPopup.root.wifiNetworks || [];
        if (networks.length > 0) {
            return networks.filter(n => n.inUse || (active && n.ssid === active));
        }
        // No scan data yet — derive from bar state
        if (active) return [{ ssid: active, inUse: true, signal: wifiPopup.root.wifiSignal || 0, security: "" }];
        return [];
    }
    // SSID awaiting password entry (shows inline password panel in available list)
    property string pendingConnectSsid: ""

    // Known-available = in-range + saved to NM + not currently connected
    property var knownAvailableNetworks: {
        const active = wifiPopup.activeSsid;
        const known = new Set(wifiPopup.root.wifiKnownSsids || []);
        return (wifiPopup.root.wifiNetworks || []).filter(n =>
            !n.inUse && n.ssid !== active && known.has(n.ssid));
    }

    // Available = in-range + not connected + NOT saved to NM (new/unknown networks)
    property var availableNetworks: {
        const active = wifiPopup.activeSsid;
        const known = new Set(wifiPopup.root.wifiKnownSsids || []);
        return (wifiPopup.root.wifiNetworks || []).filter(n =>
            !n.inUse && n.ssid !== active && !known.has(n.ssid));
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

        // Header: title + toggle switch
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
                        ? (wifiPopup.root.wifiSsid.length > 0
                            ? wifiPopup.root.wifiSsid.toUpperCase()
                            : "NOT CONNECTED")
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

        // === CONNECTED NETWORKS ===
        Column {
            width: parent.width
            spacing: 0
            visible: wifiPopup.root.wifiRadioOn && wifiPopup.connectedNetworks.length > 0

            Text {
                text: "CONNECTED NETWORKS"
                color: wifiPopup.root.inkDeep
                font.family: wifiPopup.root.mono
                font.pixelSize: 9
                font.letterSpacing: 2
                opacity: 0.7
                bottomPadding: 6
            }

            Repeater {
                model: wifiPopup.connectedNetworks.slice(0, 6)
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 34

                    readonly property bool isActive: modelData.inUse === true
                        || modelData.ssid === wifiPopup.activeSsid

                    // Active row background
                    Rectangle {
                        anchors.fill: parent
                        color: isActive ? wifiPopup.root.seal : "transparent"
                        opacity: isActive ? 0.10 : 0
                    }

                    // WiFi signal icon
                    Text {
                        id: kSigIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        text: wifiPopup.root.wifiBarsGlyph(modelData.signal || 0)
                        color: isActive ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                        font.family: wifiPopup.root.mono
                        font.pixelSize: 14
                    }

                    // SSID
                    Text {
                        anchors.left: kSigIcon.right
                        anchors.leftMargin: 6
                        anchors.right: kRightRow.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.ssid || "(hidden)"
                        color: isActive ? wifiPopup.root.seal : wifiPopup.root.ink
                        font.family: wifiPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        font.weight: isActive ? Font.Medium : Font.Normal
                    }

                    // Right area: status + disconnect (if active) + delete
                    Row {
                        id: kRightRow
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // Status label — "CONNECTED" or signal%
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: isActive
                            text: "CONNECTED"
                            color: wifiPopup.root.seal
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            font.weight: Font.Medium
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !isActive
                            text: (modelData.security && modelData.security !== "" && modelData.security !== "none" ? "󰌆 " : "") + (modelData.signal || 0) + "%"
                            color: wifiPopup.root.inkDeep
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }

                        // Disconnect button — only when connected
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: isActive
                            text: "󰖭"
                            color: kDisconnectArea.containsMouse ? "#f87171" : wifiPopup.root.inkDeep
                            opacity: kDisconnectArea.containsMouse ? 1.0 : 0.5
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            MouseArea {
                                id: kDisconnectArea
                                anchors.fill: parent
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiPopup.root.disconnectWifi()
                            }
                        }

                        // Delete/forget icon — always visible for known networks
                        Text {
                            id: kDeleteIcon
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰩺"
                            color: kDeleteArea.containsMouse ? wifiPopup.root.seal : wifiPopup.root.inkDeep
                            opacity: kDeleteArea.containsMouse ? 1.0 : 0.35
                            font.family: wifiPopup.root.mono
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            MouseArea {
                                id: kDeleteArea
                                anchors.fill: parent
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiPopup.root.forgetWifi(modelData.ssid)
                            }
                        }
                    }

                    // Row double-click — connect to this network (disconnects current automatically)
                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: kRightRow.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {}
                        onDoubleClicked: wifiPopup.root.connectWifi(modelData.ssid)
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

        // === KNOWN NETWORKS (saved to NM, in range, not connected) ===
        Column {
            width: parent.width
            spacing: 0
            visible: wifiPopup.root.wifiRadioOn
                  && !wifiPopup.root.wifiScanning
                  && wifiPopup.knownAvailableNetworks.length > 0

            Item {
                width: parent.width
                height: wifiPopup.connectedNetworks.length > 0 ? 8 : 0
                visible: wifiPopup.connectedNetworks.length > 0
            }

            Text {
                text: "KNOWN NETWORKS"
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

        // === AVAILABLE NETWORKS header ===
        Text {
            width: parent.width
            visible: wifiPopup.root.wifiRadioOn
                  && (wifiPopup.availableNetworks.length > 0 || wifiPopup.root.wifiScanning)
            text: "AVAILABLE NETWORKS"
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

            // Scanning placeholder — replaces list while scan in progress
            Text {
                width: parent.width
                height: 40
                visible: wifiPopup.root.wifiScanning
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "SCANNING…"
                color: wifiPopup.root.inkDeep
                font.family: wifiPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 3
                opacity: 0.6
            }

            ListView {
                id: availList
                width: parent.width
                height: Math.min(contentHeight, 5 * 34)
                clip: true
                visible: !wifiPopup.root.wifiScanning
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
                                passInput.forceActiveFocus();
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
