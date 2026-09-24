import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string title: ""
    property string icon: ""
    property bool collapsible: false
    property bool collapsed: false
    default property alias content: contentColumn.data

    width: parent ? parent.width : 400
    implicitHeight: outerColumn.implicitHeight + Theme.spacingM * 2
    height: implicitHeight
    radius: Theme.cornerRadius
    color: Theme.surfaceContainer

    Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Column {
        id: outerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        Item {
            id: titleBar
            visible: root.title.length > 0
            width: parent.width
            height: Math.max(iconChip.height, titleText.height, chevronIcon.height)

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                Rectangle {
                    id: iconChip
                    visible: root.icon.length > 0
                    width: 30
                    height: 30
                    radius: Theme.cornerRadius
                    color: Theme.primaryHoverLight

                    DankIcon {
                        anchors.centerIn: parent
                        name: root.icon
                        size: 18
                        color: Theme.primary
                    }
                }

                StyledText {
                    id: titleText
                    text: root.title
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }
            }

            DankIcon {
                id: chevronIcon
                visible: root.collapsible
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                name: root.collapsed ? "chevron_right" : "expand_more"
                size: 20
                color: Theme.surfaceVariantText
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.collapsible
                cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.collapsed = !root.collapsed
            }
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.spacingM
            visible: !root.collapsed
        }
    }
}
