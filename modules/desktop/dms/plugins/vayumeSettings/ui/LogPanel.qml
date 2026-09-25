import QtQuick
import qs.Common
import qs.Widgets
import "components"

Rectangle {
    id: root

    required property var vm

    signal close

    radius: Vayori.radius
    color: Vayori.card

    Item {
        id: logHeader
        x: 20
        width: parent.width - 32
        height: 48

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            StyledText {
                text: root.vm.rebuildBusy ? I18n.tr("Live output") : I18n.tr("Last output")
                font.pixelSize: Vayori.title
                font.weight: Font.DemiBold
                color: Vayori.accent
                wrapMode: Text.NoWrap
            }

            Badge {
                label: I18n.tr("%1 lines").arg(root.vm.rebuildLog.length)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            TextButton {
                variant: "ghost"
                icon: "content_copy"
                implicitHeight: 32
                onClicked: root.vm.copyText(root.vm.rebuildLog.join("\n"))
            }

            TextButton {
                variant: "ghost"
                text: I18n.tr("Clear")
                implicitHeight: 32
                onClicked: root.vm.clearRebuildLog()
            }

            TextButton {
                variant: "ghost"
                icon: "close"
                implicitHeight: 32
                onClicked: root.close()
            }
        }
    }

    ListView {
        id: rebuildLogView
        x: 20
        y: logHeader.height
        width: parent.width - 40
        height: parent.height - y - 14
        clip: true
        model: root.vm.rebuildLog
        boundsBehavior: Flickable.StopAtBounds
        onCountChanged: positionViewAtEnd()

        delegate: StyledText {
            required property var modelData
            width: rebuildLogView.width
            text: modelData
            isMonospace: true
            font.pixelSize: Vayori.body
            color: Vayori.inkMuted
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
    }
}
