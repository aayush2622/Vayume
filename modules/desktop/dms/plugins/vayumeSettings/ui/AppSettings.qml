import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    required property string appName

    property bool collapsed: true

    readonly property var items: root.vm.settings.filter(s => s.app === root.appName)
    readonly property int pendingCount: root.items.filter(s => s.pending).length

    visible: root.items.length > 0
    width: parent ? parent.width : 400
    spacing: 0

    Rectangle {
        width: parent.width
        height: 34
        radius: Theme.cornerRadius
        color: headerArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            DankIcon {
                name: root.collapsed ? "chevron_right" : "expand_more"
                size: 18
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                name: "tune"
                size: 16
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: I18n.tr("%1 settings").arg(root.appName)
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Badge {
                visible: root.pendingCount > 0
                label: I18n.tr("%1 pending rebuild").arg(root.pendingCount)
                tone: "warning"
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: I18n.tr("%1 options").arg(root.items.length)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.collapsed = !root.collapsed
        }
    }

    Column {
        visible: !root.collapsed
        width: parent.width - Theme.spacingL
        x: Theme.spacingL
        spacing: 0

        Repeater {
            model: root.items

            SettingRow {
                required property var modelData
                vm: root.vm
                setting: modelData
            }
        }
    }
}
