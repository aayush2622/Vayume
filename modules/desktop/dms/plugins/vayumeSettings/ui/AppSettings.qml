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

    function toggle() {
        root.collapsed = !root.collapsed;
    }

    visible: root.totalCount > 0
    width: parent ? parent.width : 400
    spacing: 0

    Item {
        id: disclosure
        width: disclosureRow.width + 16
        height: 26
        x: -8

        activeFocusOnTab: root.visible
        Keys.onSpacePressed: root.toggle()
        Keys.onReturnPressed: root.toggle()
        Keys.onEnterPressed: root.toggle()

        Rectangle {
            anchors.fill: parent
            radius: Vayori.radiusSmall
            color: area.containsMouse ? Vayori.hover : "transparent"
            border.width: disclosure.activeFocus ? 1 : 0
            border.color: Vayori.focus
        }

        Row {
            id: disclosureRow
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            DankIcon {
                name: root.collapsed ? "add" : "remove"
                size: 12
                color: area.containsMouse ? Vayori.ink : Vayori.inkFaint
                anchors.verticalCenter: parent.verticalCenter
            }

            Eyebrow {
                text: I18n.tr("%1 options").arg(root.appName)
                font.pixelSize: Vayori.micro
                color: area.containsMouse || !root.collapsed ? Vayori.ink : Vayori.inkFaint
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: String(root.totalCount).padStart(2, "0")
                isMonospace: true
                font.pixelSize: Vayori.micro
                color: Vayori.inkGhost
                wrapMode: Text.NoWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            Badge {
                visible: root.pendingCount > 0
                label: I18n.tr("%1 pending rebuild").arg(root.pendingCount)
                tone: "warning"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle()
        }
    }

    Item {
        visible: !root.collapsed
        width: parent.width
        height: body.implicitHeight + 6

        Rectangle {
            x: 5
            y: 6
            width: 1
            height: parent.height - 12
            color: Vayori.hairline
        }

        Column {
            id: body
            x: 22
            width: parent.width - x

            Repeater {
                model: root.collapsed ? [] : root.items

                SettingRow {
                    required property var modelData
                    required property int index
                    vm: root.vm
                    setting: modelData
                    divider: index > 0
                }
            }

            Repeater {
                model: root.collapsed ? [] : root.actionItems

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
        height: 10
    }
}
