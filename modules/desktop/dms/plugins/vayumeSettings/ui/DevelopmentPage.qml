import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    StyledText {
        text: I18n.tr("Development")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        visible: root.vm.developmentLoading
        text: I18n.tr("Loading development environment...")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    SettingsCard {
        title: I18n.tr("Languages")
        icon: "code"
        visible: !root.vm.developmentLoading && root.vm.development.languages.length > 0
        width: parent.width

        Repeater {
            model: root.vm.development.languages

            Column {
                required property var modelData
                width: parent.width
                spacing: 2

                DankToggle {
                    width: parent.width
                    text: modelData.name
                    description: {
                        const integrations = modelData.integrations.length > 0
                            ? I18n.tr("Integrates with: %1").arg(modelData.integrations.join(", "))
                            : I18n.tr("No enabled editor integrates with this language yet.");
                        return modelData.description.length > 0
                            ? modelData.description + "\n" + integrations
                            : integrations;
                    }
                    checked: modelData.enabled
                    onToggled: isChecked => root.vm.setAppEnabled(modelData.name, isChecked)
                }
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Editors")
        icon: "edit"
        visible: !root.vm.developmentLoading && root.vm.development.editors.length > 0
        width: parent.width

        Repeater {
            model: root.vm.development.editors

            DankToggle {
                required property var modelData
                width: parent.width
                text: modelData.name
                description: modelData.description
                checked: modelData.enabled
                onToggled: isChecked => root.vm.setAppEnabled(modelData.name, isChecked)
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Development Tools")
        icon: "build"
        visible: !root.vm.developmentLoading && root.vm.development.tools.length > 0
        width: parent.width

        Repeater {
            model: root.vm.development.tools

            DankToggle {
                required property var modelData
                width: parent.width
                text: modelData.name
                description: modelData.description
                checked: modelData.enabled
                onToggled: isChecked => root.vm.setAppEnabled(modelData.name, isChecked)
            }
        }
    }
}
