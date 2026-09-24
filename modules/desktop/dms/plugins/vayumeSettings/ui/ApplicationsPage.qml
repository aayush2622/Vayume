import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    property string searchQuery: ""

    readonly property var categoryLabels: ({
        "gaming": I18n.tr("Gaming"),
        "utils": I18n.tr("Utilities")
    })

    readonly property var categoryOrder: ({ "gaming": 0, "utils": 1 })

    readonly property var filteredApps: {
        const q = root.searchQuery.trim().toLowerCase();
        const list = root.vm.apps.filter(a => a.category !== "development"
            && (q.length === 0 || a.name.toLowerCase().includes(q)));
        return list.slice().sort((a, b) => {
            const ca = root.categoryOrder[a.category] ?? 99;
            const cb = root.categoryOrder[b.category] ?? 99;
            if (ca !== cb) return ca - cb;
            return a.name.localeCompare(b.name);
        });
    }

    StyledText {
        text: I18n.tr("Applications")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    DankTextField {
        id: searchField
        width: parent.width
        placeholderText: I18n.tr("Search applications...")
        onTextChanged: searchDebounce.restart()

        Timer {
            id: searchDebounce
            interval: 80
            onTriggered: root.searchQuery = searchField.text
        }
    }

    SettingsCard {
        width: parent.width

        StyledText {
            visible: root.vm.appsLoading
            text: I18n.tr("Loading applications...")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        StyledText {
            visible: !root.vm.appsLoading && root.filteredApps.length === 0
            text: I18n.tr("No applications match \"%1\".").arg(root.searchQuery)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        ListView {
            id: appsListView
            width: parent.width
            height: Math.min(480, contentHeight)
            clip: true
            spacing: 2
            visible: !root.vm.appsLoading && root.filteredApps.length > 0
            model: root.filteredApps

            section.property: "category"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                width: appsListView.width
                height: 28

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.categoryLabels[section] ?? section
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }
            }

            delegate: DankToggle {
                required property var modelData
                width: appsListView.width
                text: modelData.name
                description: modelData.description
                checked: modelData.enabled
                onToggled: isChecked => root.vm.setAppEnabled(modelData.name, isChecked)
            }
        }
    }
}
