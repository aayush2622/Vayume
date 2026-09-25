import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    property string searchQuery: ""
    property string show: "all"

    readonly property var categoryLabels: ({
        "gaming": I18n.tr("Gaming"),
        "utils": I18n.tr("Utilities")
    })

    readonly property var categoryOrder: ({ "gaming": 0, "utils": 1 })

    readonly property var appsHere: root.vm.apps.filter(a => a.category !== "development")

    readonly property var sections: {
        const q = root.searchQuery.trim().toLowerCase();
        const byCategory = {};
        for (const a of root.appsHere) {
            if (q.length > 0 && !(a.name + " " + a.description).toLowerCase().includes(q))
                continue;
            if ((root.show === "on" && !a.enabled) || (root.show === "off" && a.enabled))
                continue;
            (byCategory[a.category] = byCategory[a.category] || []).push(a);
        }
        return Object.keys(byCategory)
            .sort((a, b) => (root.categoryOrder[a] ?? 99) - (root.categoryOrder[b] ?? 99) || a.localeCompare(b))
            .map(key => ({
                key: key,
                label: root.categoryLabels[key] ?? key,
                items: byCategory[key].slice().sort((a, b) => a.name.localeCompare(b.name))
            }));
    }

    readonly property string meta: root.vm.appsLoading
        ? ""
        : I18n.tr("%1 of %2 enabled").arg(root.appsHere.filter(a => a.enabled).length).arg(root.appsHere.length)

    Item {
        width: parent.width
        height: searchField.height

        Field {
            id: searchField
            width: parent.width - showFilter.width - 12
            leftIconName: "search"
            showClearButton: true
            placeholderText: I18n.tr("Search applications...")
            onTextChanged: searchDebounce.restart()

            Timer {
                id: searchDebounce
                interval: 80
                onTriggered: root.searchQuery = searchField.text
            }
        }

        Segmented {
            id: showFilter
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            readonly property var labels: ({ all: I18n.tr("All"), on: I18n.tr("On"), off: I18n.tr("Off") })
            options: [labels.all, labels.on, labels.off]
            current: labels[root.show]
            onPicked: value => root.show = Object.keys(labels).find(k => labels[k] === value)
        }
    }

    Notice {
        visible: root.vm.appsLoading
        text: I18n.tr("Loading applications...")
        busy: true
    }

    Notice {
        visible: !root.vm.appsLoading && root.sections.length === 0
        text: root.searchQuery.length > 0 ? I18n.tr("No applications match \"%1\".").arg(root.searchQuery) : I18n.tr("Nothing to show with this filter.")
    }

    Repeater {
        model: root.vm.appsLoading ? [] : root.sections

        Section {
            id: section
            required property var modelData
            title: modelData.label
            meta: I18n.tr("%1 / %2").arg(modelData.items.filter(a => a.enabled).length).arg(modelData.items.length)

            Repeater {
                model: section.modelData.items

                SettingItem {
                    id: appEntry
                    required property var modelData
                    title: modelData.name
                    description: modelData.description

                    footer: AppOptions {
                        vm: root.vm
                        appName: appEntry.modelData.name
                    }

                    Toggle {
                        checked: appEntry.modelData.enabled
                        onToggled: value => root.vm.setAppEnabled(appEntry.modelData.name, value)
                    }
                }
            }
        }
    }
}
