import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string title: ""
    property string icon: ""
    default property alias content: contentColumn.data

    width: parent ? parent.width : 400
    implicitHeight: outerColumn.implicitHeight + Theme.spacingM * 2
    height: implicitHeight
    radius: Theme.cornerRadius
    color: Theme.surfaceContainer

    Column {
        id: outerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        Row {
            visible: root.title.length > 0
            width: parent.width
            spacing: Theme.spacingS

            DankIcon {
                visible: root.icon.length > 0
                name: root.icon
                size: 18
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.spacingM
        }
    }
}
