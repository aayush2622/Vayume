import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property string meta: I18n.tr("changes apply on rebuild")

    function labelOf(role, id) {
        const c = role.choices.find(c => c.id === id);
        return c ? c.label : id;
    }

    function autoLabel(role) {
        return role.automatic
            ? I18n.tr("Automatic (%1)").arg(labelOf(role, role.automatic))
            : I18n.tr("Automatic (nothing enabled)");
    }

    Notice {
        visible: root.vm.defaultAppsLoading && root.vm.defaultApps.length === 0
        text: I18n.tr("Loading...")
        busy: true
    }

    Section {
        visible: root.vm.defaultApps.length > 0
        title: I18n.tr("Handlers")
        meta: I18n.tr("%1 roles").arg(root.vm.defaultApps.length)

        Repeater {
            model: root.vm.defaultApps

            SettingItem {
                id: roleRow
                required property var modelData
                readonly property var role: modelData
                readonly property var enabledChoices: role.choices.filter(c => c.enabled)
                readonly property var disabledChoices: role.choices.filter(c => !c.enabled)

                title: role.label
                description: disabledChoices.length > 0
                    ? I18n.tr("Also supported when enabled: %1").arg(disabledChoices.map(c => c.label).join(", "))
                    : I18n.tr("Every supported app is enabled.")
                meta: I18n.tr("using %1").arg(role.effective ? root.labelOf(role, role.effective) : I18n.tr("None"))

                Select {
                    width: roleRow.below ? Math.min(parent.width, 280) : 240
                    enabled: !root.vm.defaultAppsLoading
                    currentValue: roleRow.role.chosen ? root.labelOf(roleRow.role, roleRow.role.chosen) : root.autoLabel(roleRow.role)
                    options: [root.autoLabel(roleRow.role)].concat(roleRow.enabledChoices.map(c => c.label))
                    emptyText: I18n.tr("Loading...")
                    onValueChanged: value => {
                        const picked = roleRow.enabledChoices.find(c => c.label === value);
                        const id = picked ? picked.id : "auto";
                        if (id !== (roleRow.role.chosen || "auto"))
                            root.vm.setDefaultApp(roleRow.role.role, id);
                    }
                }
            }
        }
    }

    Notice {
        text: I18n.tr("Automatic uses the first enabled app in the list. Only enabled apps can be picked - turn more on under Development or Applications.")
    }

    Notice {
        text: root.vm.defaultAppsStatus
        tone: root.vm.defaultAppsError ? "error" : "neutral"
    }
}
