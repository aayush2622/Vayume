import QtQuick
import qs.Common
import qs.Widgets
import "components"

Rectangle {
    id: root

    required property var vm
    property bool logOpen: false
    property bool compact: false

    signal toggleLog

    readonly property bool pending: root.vm.repoKnown && root.vm.repo.rebuildPending
    readonly property var status: {
        if (root.vm.lastError)
            return { tone: "error", label: I18n.tr("Last change failed"), detail: I18n.tr("See the page where it happened, or run `vayume config validate` in a terminal.") };
        if (root.vm.saving)
            return { tone: "info", label: I18n.tr("Saving"), detail: I18n.tr("Writing to _config.nix...") };
        if (root.vm.rebuildBusy)
            return { tone: "info", label: I18n.tr("Running"), detail: root.vm.rebuildStatus };
        if (!root.vm.repoKnown)
            return { tone: "neutral", label: I18n.tr("Loading"), detail: I18n.tr("Reading the repository...") };
        if (root.pending)
            return { tone: "warning", label: I18n.tr("Rebuild pending"), detail: I18n.tr("Changes saved - rebuild to apply them.") };
        return { tone: "success", label: I18n.tr("Up to date"), detail: root.vm.rebuildStatus.length > 0 ? root.vm.rebuildStatus : I18n.tr("Everything is applied.") };
    }

    implicitHeight: column.implicitHeight + 32
    height: implicitHeight
    radius: Vayori.radius
    color: Vayori.card

    Column {
        id: column
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 10

        Row {
            spacing: 10

            Item {
                width: 10
                height: 18

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: Vayori.tone(root.status.tone)
                    visible: !(root.vm.saving || root.vm.rebuildBusy)
                }

                DankSpinner {
                    anchors.centerIn: parent
                    visible: root.vm.saving || root.vm.rebuildBusy
                    size: 14
                    strokeWidth: 2
                }
            }

            StyledText {
                text: root.status.label
                font.pixelSize: Vayori.body + 1
                font.weight: Font.DemiBold
                color: root.status.tone === "error" ? Theme.error : Vayori.ink
                wrapMode: Text.NoWrap
                height: 18
            }
        }

        StyledText {
            visible: !root.compact
            width: parent.width
            text: root.status.detail
            font.pixelSize: Vayori.micro
            color: Vayori.inkMuted
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            spacing: 8

            TextButton {
                width: parent.width - (logButton.visible ? logButton.width + 8 : 0)
                variant: root.pending && !root.vm.rebuildBusy ? "primary" : "tonal"
                icon: "sync"
                text: root.vm.rebuildBusy ? I18n.tr("Rebuilding") : I18n.tr("Rebuild")
                busy: root.vm.rebuildBusy
                onClicked: root.vm.rebuild()
            }

            TextButton {
                id: logButton
                visible: root.vm.rebuildLog.length > 0
                variant: root.logOpen ? "primary" : "tonal"
                icon: "terminal"
                onClicked: root.toggleLog()
            }
        }
    }
}
