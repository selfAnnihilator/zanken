import QtQuick
import QtQuick.Layouts
import Quickshell

CardWindow {
    id: sysPopup
    required property var root

    theme: root
    revealed: root.systemVisible
    cardWidth: 320
    layerNamespace: "zanken-system"
    footer: "ESC CLOSE"
    title: "󰋊  SYSTEM"

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    onDismiss: root.systemVisible = false

    Column {
        width: parent.width
        spacing: 0

        // ── User header ───────────────────────────────────────
        Item {
            width: parent.width
            height: 76

            Row {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰀄"
                    color: sysPopup.root.seal
                    font.family: sysPopup.root.mono
                    font.pixelSize: 44
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: Quickshell.env("USER") || "user"
                        color: sysPopup.root.ink
                        font.family: sysPopup.root.mono
                        font.pixelSize: 17
                        font.weight: Font.Light
                    }
                    Text {
                        text: sysPopup.root.sysHostname || "…"
                        color: sysPopup.root.muted
                        font.family: sysPopup.root.mono
                        font.pixelSize: 11
                    }
                }
            }
        }

        // ── Separator ─────────────────────────────────────────
        Rectangle { width: parent.width; height: 1; color: sysPopup.root.sep }

        // ── System details — explicit rows, direct bindings ───
        Column {
            width: parent.width
            topPadding: 12
            bottomPadding: 12
            spacing: 8

            // OS
            Item {
                width: parent.width
                height: 14
                Text { x: 16; width: 64; text: "OS"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                Text { x: 80; width: parent.width - 96; text: sysPopup.root.sysOs || "…"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; elide: Text.ElideRight }
            }
            // KERNEL
            Item {
                width: parent.width
                height: 14
                Text { x: 16; width: 64; text: "KERNEL"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                Text { x: 80; width: parent.width - 96; text: sysPopup.root.sysKernel || "…"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; elide: Text.ElideRight }
            }
            // UPTIME
            Item {
                width: parent.width
                height: 14
                Text { x: 16; width: 64; text: "UPTIME"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                Text { x: 80; width: parent.width - 96; text: sysPopup.root.sysUptime || "…"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; elide: Text.ElideRight }
            }
            // SHELL
            Item {
                width: parent.width
                height: 14
                Text { x: 16; width: 64; text: "SHELL"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                Text { x: 80; width: parent.width - 96; text: (Quickshell.env("SHELL") || "").replace(/.*\//, "") || "…"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; elide: Text.ElideRight }
            }
        }

        // ── Separator ─────────────────────────────────────────
        Rectangle { width: parent.width; height: 1; color: sysPopup.root.sep }

        // ── Stats bars — explicit rows, direct bindings ───────
        Column {
            width: parent.width
            topPadding: 14
            bottomPadding: 14
            spacing: 12

            // CPU
            Column {
                width: parent.width
                spacing: 5
                Item {
                    x: 16; width: parent.parent.width - 32; height: 12
                    Text { x: 0; width: 42; text: "CPU"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                    Text { x: 42; width: parent.width - 42; text: sysPopup.root.cpuVal + "%"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                }
                Item {
                    x: 16; width: parent.parent.width - 32; height: 4
                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(sysPopup.root.ink.r, sysPopup.root.ink.g, sysPopup.root.ink.b, 0.10) }
                    Rectangle { width: Math.max(4, parent.width * Math.min(sysPopup.root.cpuVal, 100) / 100); height: parent.height; radius: 2; color: sysPopup.root.seal; Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
                }
            }

            // RAM
            Column {
                width: parent.width
                spacing: 5
                Item {
                    x: 16; width: parent.parent.width - 32; height: 12
                    Text { x: 0; width: 42; text: "RAM"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                    Text { x: 42; width: parent.width - 42; text: sysPopup.root.memVal + "%"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                }
                Item {
                    x: 16; width: parent.parent.width - 32; height: 4
                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(sysPopup.root.ink.r, sysPopup.root.ink.g, sysPopup.root.ink.b, 0.10) }
                    Rectangle { width: Math.max(4, parent.width * Math.min(sysPopup.root.memVal, 100) / 100); height: parent.height; radius: 2; color: sysPopup.root.seal; Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
                }
            }

            // DISK
            Column {
                width: parent.width
                spacing: 5
                Item {
                    x: 16; width: parent.parent.width - 32; height: 12
                    Text { x: 0; width: 42; text: "DISK"; color: sysPopup.root.muted; font.family: sysPopup.root.mono; font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Medium }
                    Text { x: 42; width: parent.width - 42; text: sysPopup.root.diskVal + "%"; color: sysPopup.root.ink; font.family: sysPopup.root.mono; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                }
                Item {
                    x: 16; width: parent.parent.width - 32; height: 4
                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(sysPopup.root.ink.r, sysPopup.root.ink.g, sysPopup.root.ink.b, 0.10) }
                    Rectangle { width: Math.max(4, parent.width * Math.min(sysPopup.root.diskVal, 100) / 100); height: parent.height; radius: 2; color: sysPopup.root.seal; Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
                }
            }
        }
    }
}
