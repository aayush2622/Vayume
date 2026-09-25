import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property var systemActions: root.vm.actions.filter(a => !a.panel.app)
    readonly property var safeActions: root.systemActions.filter(a => !a.confirm)
    readonly property var riskyActions: root.systemActions.filter(a => a.confirm)
    readonly property bool pending: root.vm.repoKnown && root.vm.repo.rebuildPending

    readonly property string meta: I18n.tr("%1 commands").arg(root.systemActions.length)

    Section {
        title: I18n.tr("Rebuild")

        SettingItem {
            title: root.pending ? I18n.tr("Changes are waiting") : I18n.tr("System is up to date")
            description: root.pending
                ? I18n.tr("_config.nix has edits the running system doesn't have yet. Rebuilding checks the configuration and switches to it.")
                : I18n.tr("Nothing saved since the last rebuild. Rebuilding anyway re-applies the current configuration.")
            meta: "vayume rebuild"
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

    Notice {
        visible: root.systemActions.length === 0
        text: I18n.tr("Loading commands...")
        busy: true
    }

    Section {
        title: I18n.tr("Checks and reports")
        subtitle: I18n.tr("Read-only - safe to run any time. Output streams into the log panel.")
        meta: String(root.safeActions.length)
        visible: root.safeActions.length > 0

        Repeater {
            model: root.safeActions

            CommandRow {
                required property var modelData
                vm: root.vm
                action: modelData
            }
        }
    }

    Section {
        title: I18n.tr("Cleanup and repair")
        subtitle: I18n.tr("These change or delete something, so each asks for a second click.")
        meta: String(root.riskyActions.length)
        visible: root.riskyActions.length > 0

        Repeater {
            model: root.riskyActions

            CommandRow {
                required property var modelData
                vm: root.vm
                action: modelData
            }
        }
    }
}
