import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool active: false
    property int badgeCount: 0

    signal activated

    width: parent ? parent.width : 190
    height: 40
    radius: Theme.cornerRadius
    color: root.active ? Theme.primaryHoverLight : (mouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent")

    activeFocusOnTab: true
    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()

    border.width: root.activeFocus ? 1 : 0
    border.color: Theme.primary

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingS

        DankIcon {
            name: root.icon
            size: 18
            color: root.active ? Theme.primary : Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.label
            font.pixelSize: Theme.fontSizeMedium
            font.weight: root.active ? Font.Medium : Font.Normal
            color: root.active ? Theme.surfaceText : Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 18 - Theme.spacingS - (badgeText.visible ? badgeText.width + Theme.spacingS : 0)
            elide: Text.ElideRight
        }

        StyledText {
            id: badgeText
            visible: root.badgeCount > 0
            text: root.badgeCount
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
