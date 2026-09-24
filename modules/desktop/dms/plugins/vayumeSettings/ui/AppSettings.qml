import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    required property string appName

    property bool collapsed: true

    readonly property var items: root.vm.settings.filter(s => s.app === root.appName)
    readonly property var actionItems: root.vm.actions.filter(a => a.panel.app === root.appName)
    readonly property int totalCount: root.items.length + root.actionItems.length
    readonly property int pendingCount: root.items.filter(s => s.pending).length

    visible: root.totalCount > 0
    width: parent ? parent.width : 400
    spacing: Theme.spacingXS

    Rectangle {
        id: header
        x: Theme.spacingM
        width: parent.width - Theme.spacingM
        height: 40
        radius: Theme.cornerRadius
        color: headerArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            Rectangle {
                width: 26
                height: 26
                radius: 7
                color: Theme.primaryHoverLight
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: "tune"
                    size: 16
                    color: Theme.primary
                }
            }

            StyledText {
                text: I18n.tr("%1 options").arg(root.appName)
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: countText.implicitWidth + Theme.spacingM
                height: 20
                radius: 10
                color: Theme.surfaceContainerLow
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: countText
                    anchors.centerIn: parent
                    text: String(root.totalCount)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Badge {
                visible: root.pendingCount > 0
                label: I18n.tr("%1 pending rebuild").arg(root.pendingCount)
                tone: "warning"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        DankIcon {
            name: root.collapsed ? "chevron_right" : "expand_more"
            size: 20
            color: Theme.surfaceVariantText
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.collapsed = !root.collapsed
        }
    }

    Rectangle {
        id: body
        visible: !root.collapsed
        x: Theme.spacingM
        width: parent.width - Theme.spacingM
        height: bodyColumn.implicitHeight + Theme.spacingS * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerLow

        Rectangle {
            width: 3
            height: parent.height - Theme.spacingM
            radius: 1.5
            color: Theme.primary
            opacity: 0.6
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            id: bodyColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingXS
            anchors.topMargin: Theme.spacingS
            spacing: 2

            Repeater {
                model: root.items

                SettingRow {
                    required property var modelData
                    vm: root.vm
                    setting: modelData
                }
            }

            Repeater {
                model: root.actionItems

                ActionRow {
                    required property var modelData
                    vm: root.vm
                    action: modelData
                }
            }
        }
    }

    Item {
        width: 1
        height: Theme.spacingXS
    }
}
