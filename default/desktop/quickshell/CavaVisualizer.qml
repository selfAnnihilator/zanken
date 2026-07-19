import QtQuick

Item {
    id: vizRoot
    clip: true

    property color barColor: "white"
    property real  barOpacity: 0.35
    property color barBorderColor: "transparent"
    property real  barBorderWidth: 0

    ListModel {
        id: barModel
        Component.onCompleted: {
            for (var i = 0; i < 24; i++) barModel.append({ "val": 0.0 });
        }
    }

    function updateBars(semicolonLine) {
        const parts = semicolonLine.split(";");
        for (var j = 0; j < Math.min(parts.length, barModel.count); j++)
            barModel.setProperty(j, "val", parseFloat(parts[j]) || 0.0);
    }

    Repeater {
        model: barModel
        Rectangle {
            readonly property real barW: vizRoot.width / barModel.count
            x:      index * barW
            y:      parent.height - height
            width:  barW
            height: (model.val / 100.0) * vizRoot.height
            color:  vizRoot.barColor
            opacity: vizRoot.barOpacity
            border.color: vizRoot.barBorderColor
            border.width: vizRoot.barBorderWidth
            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
        }
    }
}
