import QtQuick

CardWindow {
    id: battPopup
    required property var root

    theme: root
    revealed: root.batteryVisible
    cardWidth: 300
    layerNamespace: "zanken-battery"
    footer: "← → PROFILE · ESC CLOSE"

    anchorEdge: root.barEdge
    anchorBarX: root.popupAnchorX
    anchorBarY: root.popupAnchorY

    title: root.batteryIcon() + "  " + root.batVal + "%"
    subtitle: {
        let s = root.batState.toUpperCase();
        if (root.batPower >= 0.05) {
            const sign = root.batState === "Charging"    ? "+"
                       : root.batState === "Discharging" ? "-"
                       : "";
            s += "  ·  " + sign + root.batPower.toFixed(1) + " W";
        }
        return s;
    }

    onDismiss: root.batteryVisible = false

    onRevealedChanged: {
        if (revealed) root.refreshPowerProfile();
    }

    onKeyPressed: function(e) {
        if (e.key === Qt.Key_Escape) { root.batteryVisible = false; e.accepted = true; return; }
        if (battBody.kbdHandle(e)) e.accepted = true;
    }

    QuickBatteryBody {
        id: battBody
        width: parent.width
        root: battPopup.root
        nav:  battPopup.root
    }
}
