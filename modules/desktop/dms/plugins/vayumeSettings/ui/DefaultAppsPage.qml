import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    function labelOf(role, id) {
        const c = role.choices.find(c => c.id === id);
        return c ? c.label : id;
    }

    function autoLabel(role) {
        return role.automatic
            ? I18n.tr("Automatic (%1)").arg(labelOf(role, role.automatic))
            : I18n.tr("Automatic (nothing enabled)");
    }

    StyledText {
        text: I18n.tr("Default Apps")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: I18n.tr("Which app opens links, folders and code files, and which one the Super+Return / Super+E / Super+C / Super+B keybinds start. Automatic uses the first enabled app in the list. Only enabled apps can be picked - turn more on under Development or Applications.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }

    StyledText {
        visible: root.vm.defaultAppsLoading && root.vm.defaultApps.length === 0
        text: I18n.tr("Loading...")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Repeater {
        model: root.vm.defaultApps

        SettingsCard {
            required property var modelData
            readonly property var role: modelData
            readonly property var enabledChoices: role.choices.filter(c => c.enabled)
            readonly property var disabledChoices: role.choices.filter(c => !c.enabled)

            title: role.label
            icon: role.role === "terminal" ? "terminal"
                : role.role === "fileManager" ? "folder"
                : role.role === "editor" ? "code"
                : "public"

            Row {
                width: parent.width
                spacing: Theme.spacingS

                Column {
                    width: parent.width - 260
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        spacing: Theme.spacingS
                        StyledText {
                            text: role.effective ? root.labelOf(role, role.effective) : I18n.tr("None")
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                        Badge { label: I18n.tr("Rebuild required"); tone: "warning" }
                    }
                    StyledText {
                        text: disabledChoices.length > 0
                            ? I18n.tr("Also supported when enabled: %1").arg(disabledChoices.map(c => c.label).join(", "))
                            : I18n.tr("Every supported app is enabled.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }

                DankDropdown {
                    width: 250
                    popupWidth: 250
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !root.vm.defaultAppsLoading
                    currentValue: role.chosen ? root.labelOf(role, role.chosen) : root.autoLabel(role)
                    options: [root.autoLabel(role)].concat(enabledChoices.map(c => c.label))
                    emptyText: I18n.tr("Loading...")
                    onValueChanged: newValue => {
                        const picked = enabledChoices.find(c => c.label === newValue);
                        const id = picked ? picked.id : "auto";
                        if (id !== (role.chosen || "auto"))
                            root.vm.setDefaultApp(role.role, id);
                    }
                }
            }
        }
    }

    StyledText {
        visible: root.vm.defaultAppsStatus.length > 0
        text: root.vm.defaultAppsStatus
        font.pixelSize: Theme.fontSizeSmall
        color: root.vm.defaultAppsError ? Theme.error : Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }
}
