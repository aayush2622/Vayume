import QtQuick

Rectangle {
    id: root

    property real s: 1
    property var scheme: ({})
    property string icon: ""
    property string variant: "standard"
    property string iconFont: "Material Symbols Rounded"
    property real size: 48
    property real corner: -1

    signal clicked

    readonly property color ink: {
        switch (root.variant) {
        case "filled": return root.scheme.onPrimary;
        case "tonal": return root.scheme.onSecondaryContainer;
        case "error": return root.scheme.onErrorContainer;
        default: return root.scheme.onSurfaceVariant;
        }
    }

    implicitWidth: root.size * root.s
    implicitHeight: root.size * root.s
    radius: root.corner >= 0 ? root.corner * root.s : width / 2
    color: {
        switch (root.variant) {
        case "filled": return root.scheme.primary;
        case "tonal": return root.scheme.secondaryContainer;
        case "error": return root.scheme.errorContainer;
        default: return "transparent";
        }
    }

    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.ink
        opacity: area.pressed ? 0.12 : (area.containsMouse ? 0.08 : 0)

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: root.iconFont
        font.pixelSize: 24 * root.s
        color: root.ink
        scale: area.pressed ? 0.9 : 1

        Behavior on scale { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
