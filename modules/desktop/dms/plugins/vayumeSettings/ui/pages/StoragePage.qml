import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property real fraction: root.vm.disk.known && root.vm.disk.size > 0 ? root.vm.disk.used / root.vm.disk.size : 0

    function human(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let v = bytes;
        let i = 0;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i];
    }

    readonly property string meta: root.vm.disk.known ? I18n.tr("%1 free").arg(root.human(root.vm.disk.avail)) : ""

    Rectangle {
        width: parent.width
        height: diskColumn.implicitHeight + 44
        radius: Vayori.radiusLarge
        color: root.fraction > 0.9 ? Theme.withAlpha(Theme.warning, 0.14) : Vayori.card

        Column {
            id: diskColumn
            x: 24
            y: 22
            width: parent.width - 48
            spacing: 14

            Row {
                spacing: 14

                DankIcon {
                    name: "hard_drive"
                    size: 28
                    color: Vayori.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: root.vm.disk.known ? I18n.tr("%1 of %2 used").arg(root.human(root.vm.disk.used)).arg(root.human(root.vm.disk.size)) : I18n.tr("Reading the disk...")
                        font.pixelSize: Vayori.title + 2
                        font.weight: Font.Medium
                        color: Vayori.ink
                        wrapMode: Text.NoWrap
                    }

                    StyledText {
                        text: I18n.tr("The system disk (/). Run the disk usage report below to see what takes the space.")
                        font.pixelSize: Vayori.body
                        color: Vayori.inkMuted
                        wrapMode: Text.NoWrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 10
                radius: 5
                color: Theme.withAlpha(Vayori.ink, 0.1)

                Rectangle {
                    width: Math.max(height, parent.width * root.fraction)
                    height: parent.height
                    radius: parent.radius
                    color: root.fraction > 0.9 ? Theme.warning : Vayori.accent
                    visible: root.vm.disk.known

                    Behavior on width { NumberAnimation { duration: Vayori.normal; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    PageOptions {
        vm: root.vm
        page: "storage"
        toolsFirst: true
        toolsTitle: I18n.tr("Reclaim space")
        toolsSubtitle: I18n.tr("The report only reads; the two cleanups ask before deleting anything.")
    }
}
