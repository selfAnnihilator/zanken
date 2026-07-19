import QtQuick

Item {
    id: ts
    property bool checked: false
    property color onColor: "#38bdf8"
    property color offColor: "#555"
    signal toggled()

    width: 42
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: ts.checked ? ts.onColor : ts.offColor
        Behavior on color { ColorAnimation { duration: 180 } }

        Rectangle {
            width: parent.height - 4
            height: width
            radius: width / 2
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: ts.checked ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ts.toggled()
    }
}
