import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    property string searchQuery: ""
    property bool modifiedOnly: false

    readonly property int pendingCount: root.vm.settings.filter(s => s.pending).length
    readonly property int customizedCount: root.vm.settings.filter(s => s.configured).length

    readonly property var groups: {
        const q = root.searchQuery.trim().toLowerCase();
        const byGroup = {};
        for (const s of root.vm.settings) {
            if (root.modifiedOnly && !s.configured && !s.pending)
                continue;
            if (q.length > 0 && !(s.label + " " + s.description + " " + s.path + " " + s.group).toLowerCase().includes(q))
                continue;
            (byGroup[s.group] = byGroup[s.group] || []).push(s);
        }
        return Object.keys(byGroup).sort().map(name => ({
            name: name,
            icon: byGroup[name][0].groupIcon || "tune",
            description: byGroup[name][0].groupDescription || "",
            items: byGroup[name]
        }));
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        Rectangle {
            width: 44
            height: 44
            radius: Theme.cornerRadius
            color: Theme.primaryHoverLight

            DankIcon {
                anchors.centerIn: parent
                name: "tune"
                size: 26
                color: Theme.primary
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                text: I18n.tr("All Settings")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: root.vm.settingsLoading && root.vm.settings.length === 0
                    ? I18n.tr("Loading...")
                    : I18n.tr("%1 settings · %2 customized").arg(root.vm.settings.length).arg(root.customizedCount)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }

    StyledText {
        text: I18n.tr("Every option a Vayume module declares that has no page of its own - new options show up here automatically. Changes are written to _config.nix instantly and checked when you rebuild.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }

    Rectangle {
        visible: root.pendingCount > 0
        width: parent.width
        height: bannerRow.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.warning, 0.14)

        Row {
            id: bannerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingM

            DankIcon {
                name: "pending_actions"
                size: 22
                color: Theme.warning
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                width: parent.width - 22 - rebuildNow.width - Theme.spacingM * 2
                text: I18n.tr("%1 change(s) saved but not applied yet. Rebuild to apply them - the configuration is checked then.").arg(root.pendingCount)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: rebuildNow
                width: 110
                height: 34
                radius: Theme.cornerRadius
                color: root.vm.rebuildBusy ? Theme.surfaceContainerLow : Theme.primary
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    anchors.centerIn: parent
                    text: root.vm.rebuildBusy ? I18n.tr("Rebuilding...") : I18n.tr("Rebuild now")
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.vm.rebuildBusy ? Theme.surfaceVariantText : Theme.onPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.vm.rebuildBusy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.vm.rebuild()
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        DankTextField {
            id: searchField
            width: parent.width - 84 * 2 - Theme.spacingS * 2
            placeholderText: I18n.tr("Search settings...")
            onTextChanged: searchDebounce.restart()

            Timer {
                id: searchDebounce
                interval: 80
                onTriggered: root.searchQuery = searchField.text
            }
        }

        Repeater {
            model: [
                { label: I18n.tr("All"), modified: false },
                { label: I18n.tr("Modified"), modified: true }
            ]

            Rectangle {
                required property var modelData
                id: chipButton
                width: 84
                height: searchField.height
                radius: Theme.cornerRadius
                color: root.modifiedOnly === modelData.modified ? Theme.primaryHoverLight : Theme.surfaceContainerLow

                StyledText {
                    anchors.centerIn: parent
                    text: chipButton.modelData.label
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: root.modifiedOnly === chipButton.modelData.modified ? Font.Medium : Font.Normal
                    color: root.modifiedOnly === chipButton.modelData.modified ? Theme.primary : Theme.surfaceVariantText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.modifiedOnly = chipButton.modelData.modified
                }
            }
        }
    }

    Repeater {
        model: root.groups

        SettingsCard {
            required property var modelData
            title: modelData.name
            icon: modelData.icon
            subtitle: modelData.description

            Repeater {
                model: modelData.items

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

                    SettingRow {
                        vm: root.vm
                        setting: modelData
                    }
                }
            }
        }
    }

    StyledText {
        visible: !root.vm.settingsLoading && root.groups.length === 0
        text: root.modifiedOnly ? I18n.tr("Nothing has been customized yet.") : I18n.tr("No settings match your search.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    StyledText {
        visible: root.vm.settingsStatus.length > 0
        text: root.vm.settingsStatus
        font.pixelSize: Theme.fontSizeSmall
        color: root.vm.settingsError ? Theme.error : Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }
}
