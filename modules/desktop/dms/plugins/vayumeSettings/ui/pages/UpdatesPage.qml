import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property bool pending: root.vm.repoKnown && root.vm.repo.rebuildPending
    readonly property var pendingSettings: root.vm.settings.filter(s => s.pending)

    readonly property string meta: root.pending ? I18n.tr("changes waiting") : I18n.tr("up to date")

    Section {
        title: I18n.tr("Rebuild")

        SettingItem {
            title: root.pending ? I18n.tr("Changes are waiting") : I18n.tr("System is up to date")
            description: root.pending
                ? I18n.tr("_config.nix has edits the running system doesn't have yet. Rebuilding checks the configuration and switches to it.")
                : I18n.tr("Nothing saved since the last rebuild. Rebuilding anyway re-applies the current configuration.")
            icon: root.pending ? "pending_actions" : "task_alt"
            marker: root.pending ? "warning" : ""

            TextButton {
                variant: root.pending ? "primary" : "tonal"
                icon: "sync"
                text: root.vm.rebuildBusy ? I18n.tr("Rebuilding") : I18n.tr("Rebuild now")
                busy: root.vm.rebuildBusy
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.vm.rebuild()
            }
        }
    }

    Section {
        title: I18n.tr("Waiting for a rebuild")
        subtitle: I18n.tr("Saved options the running system doesn't have yet. Undo one here, or rebuild to apply them all.")
        meta: String(root.pendingSettings.length)
        visible: root.pendingSettings.length > 0

        Repeater {
            model: root.pendingSettings

            OptionRow {
                required property var modelData
                vm: root.vm
                setting: modelData
            }
        }
    }

    PageOptions {
        vm: root.vm
        page: "updates"
        toolsTitle: I18n.tr("Checks")
        toolsSubtitle: I18n.tr("Read-only reports on the configuration and pinned plugins.")
    }
}
