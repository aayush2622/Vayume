import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    required property string appName
    property string appLabel: root.appName

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
    spacing: 10

    Rectangle {
        id: disclosure
        width: disclosureRow.implicitWidth + 28
        height: 32
        radius: height / 2
        color: root.collapsed ? Vayori.tonal : Vayori.chosen

        activeFocusOnTab: root.visible
        Keys.onSpacePressed: root.toggle()
        Keys.onReturnPressed: root.toggle()
        Keys.onEnterPressed: root.toggle()

        FocusRing {}

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Vayori.ink
            opacity: area.containsMouse ? 0.07 : 0
        }

        Row {
            id: disclosureRow
            anchors.centerIn: parent
            spacing: 8

            DankIcon {
                name: "tune"
                size: 16
                color: Vayori.ink
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: I18n.tr("%1 options").arg(root.appLabel)
                font.pixelSize: Vayori.body
                font.weight: Font.Medium
                color: Vayori.ink
                wrapMode: Text.NoWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: String(root.totalCount)
                font.pixelSize: Vayori.micro
                color: Vayori.inkMuted
                wrapMode: Text.NoWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            Badge {
                visible: root.pendingCount > 0
                label: I18n.tr("%1 pending rebuild").arg(root.pendingCount)
                tone: "warning"
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                name: root.collapsed ? "expand_more" : "expand_less"
                size: 18
                color: Vayori.inkMuted
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

    Rectangle {
        visible: !root.collapsed
        width: parent.width
        height: body.implicitHeight + 8
        radius: Vayori.radiusSmall + 2
        color: Theme.withAlpha(Theme.surfaceContainerLowest, 0.55)

        Column {
            id: body
            x: 18
            y: 4
            width: parent.width - 36

            Repeater {
                model: root.collapsed ? [] : root.items

                OptionRow {
                    required property var modelData
                    required property int index
                    vm: root.vm
                    setting: modelData
                    card: false
                    divider: index > 0
                }
            }

            Repeater {
                model: root.collapsed ? [] : root.actionItems

                CommandRow {
                    required property var modelData
                    vm: root.vm
                    action: modelData
                    card: false
                    divider: true
                }
            }
        }
    }

    Item {
        width: 1
        height: 2
    }
}
