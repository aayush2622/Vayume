import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    property string searchQuery: ""

    readonly property var groups: {
        const q = root.searchQuery.trim().toLowerCase();
        const byGroup = {};
        for (const s of root.vm.settings) {
            if (q.length > 0 && !(s.label + " " + s.description + " " + s.path).toLowerCase().includes(q))
                continue;
            (byGroup[s.group] = byGroup[s.group] || []).push(s);
        }
        return Object.keys(byGroup).sort().map(name => ({ name: name, items: byGroup[name] }));
    }

    StyledText {
        text: I18n.tr("All Settings")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: I18n.tr("Every option a Vayume module declares that has no page of its own. New options appear here automatically. Changes are written to _config.nix and applied on the next rebuild.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }

    DankTextField {
        id: searchField
        width: parent.width
        placeholderText: I18n.tr("Search settings...")
        onTextChanged: searchDebounce.restart()

        Timer {
            id: searchDebounce
            interval: 80
            onTriggered: root.searchQuery = searchField.text
        }
    }

    StyledText {
        visible: root.vm.settingsLoading && root.vm.settings.length === 0
        text: I18n.tr("Loading...")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Repeater {
        model: root.groups

        SettingsCard {
            required property var modelData
            title: modelData.name
            icon: "tune"

            Repeater {
                model: modelData.items

                SettingRow {
                    required property var modelData
                    vm: root.vm
                    setting: modelData
                }
            }
        }
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
