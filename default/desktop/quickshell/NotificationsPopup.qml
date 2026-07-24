import QtQuick

CardWindow {
    id: notifPopup
    required property var root

    theme: root
    revealed: root.notificationsVisible
    cardWidth: 400
    layerNamespace: "zanken-notifications"
    title: ""
    subtitle: ""
    cardSurface.color: Qt.rgba(root.paper.r, root.paper.g, root.paper.b, 0.985)

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    property var collapsedSources: ({})
    property var expandedSources: ({})
    property var selectedItem: null

    function sourceKey(item) {
        return item && item.appName ? item.appName : "SYSTEM";
    }

    function notificationGroups() {
        const byKey = {};
        const ordered = [];
        for (let i = root.cardItems.length - 1; i >= 0; i--) {
            const item = root.cardItems[i];
            const key = sourceKey(item);
            if (!byKey[key]) {
                byKey[key] = { key: key, name: item.appName || "SYSTEM", items: [] };
                ordered.push(byKey[key]);
            }
            byKey[key].items.push(item);
        }
        return ordered;
    }

    readonly property var groups: notificationGroups()

    function setSourceCollapsed(key, collapsed) {
        const next = {};
        for (const existing in collapsedSources) next[existing] = collapsedSources[existing];
        next[key] = collapsed;
        collapsedSources = next;
    }

    function setSourceExpanded(key, expanded) {
        const next = {};
        for (const existing in expandedSources) next[existing] = expandedSources[existing];
        next[key] = expanded;
        expandedSources = next;
    }

    function isSourceCollapsed(key) { return collapsedSources[key] === true; }
    function isSourceExpanded(key) { return expandedSources[key] === true; }

    function visibleItems(group) {
        if (!group || !group.items) return [];
        if (isSourceCollapsed(group.key)) return group.items.slice(0, 1);
        return isSourceExpanded(group.key) ? group.items : group.items.slice(0, 2);
    }

    function relativeTime(timestamp) {
        if (!timestamp) return "";
        const seconds = Math.max(0, Math.floor((Date.now() - timestamp) / 1000));
        if (seconds < 60) return "NOW";
        if (seconds < 3600) return Math.floor(seconds / 60) + "M";
        if (seconds < 86400) return Math.floor(seconds / 3600) + "H";
        return Math.floor(seconds / 86400) + "D";
    }

    function isFailure(item) {
        const message = ((item && item.summary) || "") + " " + ((item && item.body) || "");
        return /\b(failed|failure|error|unable)\b/i.test(message);
    }

    function orderedItems() {
        const items = [];
        for (let i = 0; i < groups.length; i++) {
            for (let j = 0; j < groups[i].items.length; j++) items.push(groups[i].items[j]);
        }
        return items;
    }

    function focusRelative(step) {
        const items = orderedItems();
        if (items.length === 0) return;
        let index = items.indexOf(selectedItem);
        if (index < 0) index = step > 0 ? -1 : 0;
        index = (index + step + items.length) % items.length;
        selectedItem = items[index];
        const key = sourceKey(selectedItem);
        setSourceCollapsed(key, false);
        setSourceExpanded(key, true);
    }

    onDismiss: root.notificationsVisible = false

    onKeyPressed: function(e) {
        if (e.key === Qt.Key_Escape) {
            root.notificationsVisible = false;
            e.accepted = true;
            return;
        }
        if (e.key === Qt.Key_Backspace) {
            root.dismissAllNotifications();
            e.accepted = true;
            return;
        }
        if (e.key === Qt.Key_Down) {
            focusRelative(1);
            e.accepted = true;
            return;
        }
        if (e.key === Qt.Key_Up) {
            focusRelative(-1);
            e.accepted = true;
            return;
        }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            const notification = selectedItem && selectedItem.notif;
            const defaultAction = root.notificationDefaultAction(notification);
            if (defaultAction) root.invokeNotificationAction(notification, defaultAction);
            e.accepted = true;
        }
    }

    Column {
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 32

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: String.fromCodePoint(0xf0f3)
                color: root.ink
                font.family: root.mono
                font.pixelSize: 16
            }

            Text {
                anchors { left: parent.left; leftMargin: 27; verticalCenter: parent.verticalCenter }
                text: "NOTIFICATIONS"
                color: root.ink
                font.family: root.mono
                font.pixelSize: 13
                font.letterSpacing: 2.6
                font.weight: Font.Medium
            }

            Text {
                anchors { right: dndControl.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                visible: root.notificationCount > 0
                text: root.notificationCount
                color: root.seal
                font.family: root.mono
                font.pixelSize: 11
                font.letterSpacing: 1
            }

            Rectangle {
                id: dndControl
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 58
                height: 22
                color: dndMouse.containsMouse ? Qt.alpha(root.seal, 0.14) : "transparent"
                border.color: root.doNotDisturb ? root.seal : root.sep
                border.width: 1
                radius: root.cornerRadius

                Text {
                    anchors.centerIn: parent
                    text: root.doNotDisturb ? "DND ON" : "DND"
                    color: root.doNotDisturb ? root.seal : root.muted
                    font.family: root.mono
                    font.pixelSize: 8
                    font.letterSpacing: 0.8
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doNotDisturb = !root.doNotDisturb
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.sep
        }

        Item {
            width: parent.width
            height: Math.min(notifFlick.contentHeight, 354)

            Flickable {
                id: notifFlick
                anchors.fill: parent
                clip: true
                contentHeight: root.notificationCount > 0 ? groupList.implicitHeight : 72
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    visible: root.notificationCount === 0
                    anchors.centerIn: parent
                    width: parent.width
                    height: 38

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(0xf012c)
                        color: root.seal
                        font.family: root.mono
                        font.pixelSize: 16
                    }
                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 24 }
                        text: "ALL CLEAR"
                        color: root.muted
                        font.family: root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                    }
                }

                Column {
                    id: groupList
                    visible: root.notificationCount > 0
                    width: parent.width

                    Repeater {
                        model: notifPopup.groups

                        delegate: Column {
                            required property var modelData
                            required property int index
                            readonly property var group: modelData
                            width: groupList.width
                            spacing: 0

                            Item {
                                width: parent.width
                                height: index > 0 ? 9 : 0
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                    height: 1
                                    color: root.sep
                                }
                            }

                            Item {
                                width: parent.width
                                height: 29

                                Text {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    text: group.name.toUpperCase()
                                    color: root.seal
                                    font.family: root.mono
                                    font.pixelSize: 8
                                    font.letterSpacing: 1.3
                                }

                                Text {
                                    anchors { right: groupChevron.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    text: group.items.length
                                    color: root.muted
                                    font.family: root.mono
                                    font.pixelSize: 9
                                }

                                Text {
                                    id: groupChevron
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    text: notifPopup.isSourceCollapsed(group.key) ? "›" : "⌄"
                                    color: groupMouse.containsMouse ? root.ink : root.muted
                                    font.family: root.mono
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    id: groupMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifPopup.setSourceCollapsed(group.key, !notifPopup.isSourceCollapsed(group.key))
                                }
                            }

                            Repeater {
                                model: notifPopup.visibleItems(group)

                                delegate: Item {
                                    required property var modelData
                                    readonly property var item: modelData
                                    readonly property var notification: item.notif
                                    readonly property var actions: root.notificationActions(notification)
                                    readonly property var defaultAction: root.notificationDefaultAction(notification)
                                    readonly property var primaryAction: defaultAction || (actions.length > 0 ? actions[0] : null)
                                    readonly property var secondaryActions: defaultAction ? actions : actions.slice(1)
                                    readonly property bool canOpen: defaultAction !== null
                                    readonly property bool canReply: notification && notification.hasInlineReply
                                    property bool replyOpen: false
                                    width: groupList.width
                                    implicitHeight: itemColumn.implicitHeight + 14

                                    MouseArea {
                                        id: itemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: canOpen && !replyOpen
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.invokeNotificationAction(notification, defaultAction)
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: itemMouse.containsMouse || notifPopup.selectedItem === item
                                               ? Qt.alpha(root.paper, 0.08)
                                               : "transparent"
                                        radius: root.cornerRadius
                                    }

                                    Item {
                                        id: dismissSlot
                                        anchors { right: parent.right; top: parent.top; rightMargin: 2; topMargin: 7 }
                                        width: 18
                                        height: 20

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: dismissMouse.containsMouse ? root.seal : root.muted
                                            font.family: root.mono
                                            font.pixelSize: 16
                                            opacity: itemMouse.containsMouse || notifPopup.selectedItem === item || dismissMouse.containsMouse ? 1 : 0.45
                                        }

                                        MouseArea {
                                            id: dismissMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.removeFromCard(item)
                                        }
                                    }

                                    Text {
                                        id: itemMeta
                                        anchors { right: dismissSlot.left; top: parent.top; rightMargin: 6; topMargin: 10 }
                                        text: notifPopup.isFailure(item) ? "FAILED" : notifPopup.relativeTime(item.time)
                                        color: notifPopup.isFailure(item) ? root.seal : root.muted
                                        font.family: root.mono
                                        font.pixelSize: 8
                                        font.letterSpacing: 0.8
                                    }

                                    Column {
                                        id: itemColumn
                                        anchors {
                                            left: parent.left
                                            right: itemMeta.left
                                            top: parent.top
                                            leftMargin: 4
                                            rightMargin: 10
                                            topMargin: 7
                                        }
                                        spacing: 3

                                        Text {
                                            width: parent.width
                                            text: item.summary
                                            textFormat: Text.PlainText
                                            color: root.ink
                                            font.family: root.mono
                                            font.pixelSize: 11
                                            font.bold: true
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: item.body.length > 0
                                            width: parent.width
                                            text: item.body
                                            textFormat: Text.PlainText
                                            color: root.muted
                                            font.family: root.mono
                                            font.pixelSize: 10
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: notifPopup.isFailure(item) ? 2 : 1
                                            elide: Text.ElideRight
                                        }

                                        Flow {
                                            visible: primaryAction !== null || secondaryActions.length > 0 || canReply
                                            width: parent.width
                                            spacing: 5

                                            Rectangle {
                                                visible: primaryAction !== null
                                                height: 22
                                                width: primaryLabel.implicitWidth + 14
                                                color: primaryMouse.containsMouse ? Qt.alpha(root.seal, 0.18) : Qt.alpha(root.paper, 0.08)
                                                border.color: primaryMouse.containsMouse ? root.seal : root.sep
                                                border.width: 1
                                                radius: root.cornerRadius

                                                Text {
                                                    id: primaryLabel
                                                    anchors.centerIn: parent
                                                    text: primaryAction && primaryAction.text ? primaryAction.text.toUpperCase() : "OPEN"
                                                    textFormat: Text.PlainText
                                                    color: primaryMouse.containsMouse ? root.ink : root.muted
                                                    font.family: root.mono
                                                    font.pixelSize: 8
                                                    font.letterSpacing: 0.7
                                                }

                                                MouseArea {
                                                    id: primaryMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.invokeNotificationAction(notification, primaryAction)
                                                }
                                            }

                                            Repeater {
                                                model: secondaryActions
                                                delegate: Text {
                                                    required property var modelData
                                                    height: 22
                                                    width: implicitWidth + 6
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: modelData.text.toUpperCase()
                                                    textFormat: Text.PlainText
                                                    color: secondaryMouse.containsMouse ? root.seal : root.muted
                                                    font.family: root.mono
                                                    font.pixelSize: 8
                                                    font.letterSpacing: 0.7

                                                    MouseArea {
                                                        id: secondaryMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.invokeNotificationAction(notification, modelData)
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: canReply && !replyOpen
                                                height: 22
                                                width: implicitWidth + 6
                                                verticalAlignment: Text.AlignVCenter
                                                text: "REPLY"
                                                color: replyOpenMouse.containsMouse ? root.seal : root.muted
                                                font.family: root.mono
                                                font.pixelSize: 8
                                                font.letterSpacing: 0.7

                                                MouseArea {
                                                    id: replyOpenMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: replyOpen = true
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: canReply && replyOpen
                                            width: parent.width
                                            height: 28
                                            color: Qt.alpha(root.paper, 0.06)
                                            border.color: replyInput.activeFocus ? root.seal : root.sep
                                            border.width: 1
                                            radius: root.cornerRadius

                                            TextInput {
                                                id: replyInput
                                                anchors {
                                                    left: parent.left
                                                    right: sendReply.left
                                                    verticalCenter: parent.verticalCenter
                                                    leftMargin: 8
                                                    rightMargin: 6
                                                }
                                                color: root.ink
                                                font.family: root.mono
                                                font.pixelSize: 10
                                                clip: true
                                                selectByMouse: true
                                                focus: replyOpen
                                                Keys.onReturnPressed: function(event) {
                                                    if (root.sendNotificationReply(notification, replyInput.text)) event.accepted = true;
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    visible: replyInput.text.length === 0
                                                    text: (notification && notification.inlineReplyPlaceholder) || "REPLY"
                                                    textFormat: Text.PlainText
                                                    color: root.muted
                                                    font: replyInput.font
                                                    opacity: 0.7
                                                }
                                            }

                                            Text {
                                                id: sendReply
                                                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 8 }
                                                text: "SEND"
                                                color: replyMouse.containsMouse && replyInput.text.trim().length > 0 ? root.seal : root.muted
                                                font.family: root.mono
                                                font.pixelSize: 8
                                                font.letterSpacing: 0.7
                                                opacity: replyInput.text.trim().length > 0 ? 1 : 0.5

                                                MouseArea {
                                                    id: replyMouse
                                                    anchors.fill: parent
                                                    anchors.margins: -4
                                                    hoverEnabled: true
                                                    cursorShape: replyInput.text.trim().length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                    onClicked: root.sendNotificationReply(notification, replyInput.text)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: !notifPopup.isSourceCollapsed(group.key)
                                         && !notifPopup.isSourceExpanded(group.key)
                                         && group.items.length > 2
                                width: parent.width
                                height: 27
                                leftPadding: 4
                                verticalAlignment: Text.AlignVCenter
                                text: "SHOW " + (group.items.length - 2) + " MORE"
                                color: moreMouse.containsMouse ? root.seal : root.muted
                                font.family: root.mono
                                font.pixelSize: 8
                                font.letterSpacing: 0.9

                                MouseArea {
                                    id: moreMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifPopup.setSourceExpanded(group.key, true)
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 31

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: root.sep
                opacity: 0.6
            }

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "ESC CLOSE"
                color: root.inkDeep
                font.family: root.mono
                font.pixelSize: 8
                font.letterSpacing: 1.1
                opacity: 0.75
            }

            Text {
                id: clearAll
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: root.notificationCount > 0
                text: "CLEAR ALL"
                color: clearAllMouse.containsMouse ? root.seal : root.inkDeep
                font.family: root.mono
                font.pixelSize: 8
                font.letterSpacing: 1.1
                opacity: clearAllMouse.containsMouse ? 1 : 0.75

                MouseArea {
                    id: clearAllMouse
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissAllNotifications()
                }
            }
        }
    }
}
