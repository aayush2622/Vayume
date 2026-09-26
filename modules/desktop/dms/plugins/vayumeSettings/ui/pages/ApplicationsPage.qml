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

    readonly property var sectionOrder: ["Internet", "Music", "Files", "Gaming", "System", "Security", "Containers"]
    readonly property var sectionNotes: ({
        "Internet": I18n.tr("Browsing and chat."),
        "Music": I18n.tr("Spotify clients."),
        "Files": I18n.tr("File managers. The default one is picked in Default apps."),
        "Gaming": I18n.tr("Launchers, Proton and GPU tuning."),
        "System": I18n.tr("The terminal and everything it starts with."),
        "Security": I18n.tr("Passwords and backups of app logins."),
        "Containers": I18n.tr("Other Linux distributions running beside this one.")
    })

    readonly property var appsHere: root.vm.apps.filter(a => a.category !== "development")

    readonly property var sections: {
        const q = root.searchQuery.trim().toLowerCase();
        const bySection = {};
        for (const a of root.appsHere) {
            if (q.length > 0 && !((a.label || a.name) + " " + a.name + " " + a.description).toLowerCase().includes(q))
                continue;
            if ((root.show === "on" && !a.enabled) || (root.show === "off" && a.enabled))
                continue;
            const key = a.section || "Other";
            (bySection[key] = bySection[key] || []).push(a);
        }
        const rank = key => {
            const i = root.sectionOrder.indexOf(key);
            return i < 0 ? 99 : i;
        };
        return Object.keys(bySection)
            .sort((a, b) => rank(a) - rank(b) || a.localeCompare(b))
            .map(key => ({
                key: key,
                note: root.sectionNotes[key] ?? "",
                items: bySection[key].slice().sort((a, b) => (a.label || a.name).localeCompare(b.label || b.name))
            }));
    }

    readonly property string meta: root.vm.appsLoading
        ? ""
        : I18n.tr("%1 of %2 installed").arg(root.appsHere.filter(a => a.enabled).length).arg(root.appsHere.length)

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
            readonly property var labels: ({ all: I18n.tr("All"), on: I18n.tr("Installed"), off: I18n.tr("Available") })
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
            title: modelData.key
            subtitle: modelData.note
            meta: I18n.tr("%1 / %2").arg(modelData.items.filter(a => a.enabled).length).arg(modelData.items.length)

            Repeater {
                model: section.modelData.items

                SettingItem {
                    id: appEntry
                    required property var modelData
                    title: modelData.label || modelData.name
                    description: modelData.description
                    image: root.vm.iconUrl(modelData.icon)
                    icon: modelData.symbol || "apps"

                    footer: AppOptions {
                        vm: root.vm
                        appName: appEntry.modelData.name
                        appLabel: appEntry.modelData.label || appEntry.modelData.name
                    }

                    Toggle {
                        checked: appEntry.modelData.enabled
                        onToggled: value => root.vm.setAppEnabled(appEntry.modelData.name, value)
                    }
                }
            }
        }
    }

    PageOptions {
        visible: root.searchQuery.length === 0 && root.show === "all"
        vm: root.vm
        page: "applications"
    }
}
