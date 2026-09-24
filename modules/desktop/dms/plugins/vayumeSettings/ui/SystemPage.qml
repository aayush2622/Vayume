import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    StyledText {
        text: I18n.tr("System")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: I18n.tr("Read-only information about this host and its Vayume repository.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }

    SettingsCard {
        title: I18n.tr("Repository")
        icon: "folder_code"
        width: parent.width

        Repeater {
            model: [
                { label: I18n.tr("Hostname"), value: root.vm.repoKnown ? root.vm.repo.hostName : "..." },
                { label: I18n.tr("Repository"), value: root.vm.repoKnown ? root.vm.repo.path : I18n.tr("Locating...") },
                { label: I18n.tr("Branch"), value: root.vm.repoKnown ? root.vm.repo.branch : "..." },
                { label: I18n.tr("Configuration file"), value: root.vm.repoKnown ? root.vm.repo.configFile : "..." }
            ]

            Row {
                required property var modelData
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: modelData.label
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                    width: 150
                }
                StyledText {
                    text: modelData.value
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    elide: Text.ElideMiddle
                    width: parent.width - 150 - Theme.spacingS
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        SettingsCard {
            width: (parent.width - Theme.spacingM) / 2

            Column {
                width: parent.width
                spacing: 2
                StyledText {
                    text: root.vm.repoKnown ? (root.vm.repo.dirty ? I18n.tr("Uncommitted changes") : I18n.tr("Clean")) : "..."
                    font.pixelSize: Theme.fontSizeMedium
                    color: root.vm.repoKnown && root.vm.repo.dirty ? Theme.warning : Theme.surfaceText
                }
                StyledText {
                    text: I18n.tr("Git status")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }

        SettingsCard {
            width: (parent.width - Theme.spacingM) / 2

            Column {
                width: parent.width
                spacing: 2
                StyledText {
                    text: root.vm.repoKnown ? (root.vm.repo.rebuildPending ? I18n.tr("Rebuild pending") : I18n.tr("Up to date")) : "..."
                    font.pixelSize: Theme.fontSizeMedium
                    color: root.vm.repoKnown && root.vm.repo.rebuildPending ? Theme.warning : Theme.success
                }
                StyledText {
                    text: I18n.tr("Running system")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
    SettingsCard {
        title: I18n.tr("Maintenance")
        icon: "build_circle"
        subtitle: I18n.tr("One-click versions of vayume commands. Output streams into the log at the bottom.")
        width: parent.width
        visible: root.vm.actions.length > 0

        Repeater {
            model: root.vm.actions

            Column {
                required property var modelData
                required property int index
                width: parent.width
                spacing: 0

                Rectangle {
                    visible: index > 0
                    width: parent.width
                    height: 1
                    color: Theme.outline
                    opacity: 0.12
                }

                ActionRow {
                    vm: root.vm
                    action: modelData
                }
            }
        }
    }
}
