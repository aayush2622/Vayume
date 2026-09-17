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

    Rectangle {
        visible: root.active
        width: 3
        height: 18
        radius: 1.5
        color: Theme.primary
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

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
            width: parent.width - 18 - Theme.spacingS - (badgePill.visible ? badgePill.width + Theme.spacingS : 0)
            elide: Text.ElideRight
        }

        Rectangle {
            id: badgePill
            visible: root.badgeCount > 0
            width: badgeText.width + 10
            height: 18
            radius: 9
            color: root.active ? Theme.primary : Theme.surfaceContainerHigh
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                id: badgeText
                anchors.centerIn: parent
                text: root.badgeCount
                font.pixelSize: Theme.fontSizeSmall
                color: root.active ? Theme.onPrimary : Theme.surfaceVariantText
            }
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
