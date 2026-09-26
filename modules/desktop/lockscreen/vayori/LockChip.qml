import QtQuick

Rectangle {
    id: root

    property real s: 1
    property var scheme: ({})
    property string icon: ""
    property string text: ""
    property bool warn: false
    property string fontFamily: ""
    property string iconFont: "Material Symbols Rounded"

    implicitWidth: row.implicitWidth + 24 * root.s
    implicitHeight: 34 * root.s
    radius: 8 * root.s
    color: Qt.rgba(Qt.color(root.scheme.surfaceContainer).r, Qt.color(root.scheme.surfaceContainer).g, Qt.color(root.scheme.surfaceContainer).b, 0.85)
    border.width: 1
    border.color: root.scheme.outlineVariant

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8 * root.s

        Text {
            visible: root.icon.length > 0
            text: root.icon
            font.family: root.iconFont
            font.pixelSize: 18 * root.s
            color: root.warn ? root.scheme.error : root.scheme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font.family: root.fontFamily
            font.pixelSize: 14 * root.s
            font.weight: Font.Medium
            color: root.scheme.onSurface
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
