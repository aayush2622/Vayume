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
    property bool modifiedOnly: false

    readonly property var systemSettings: root.vm.settings.filter(s => !s.app)
    readonly property int pendingCount: root.systemSettings.filter(s => s.pending).length
    readonly property int customizedCount: root.systemSettings.filter(s => s.configured).length

    readonly property string meta: root.vm.settingsLoading && root.systemSettings.length === 0
        ? I18n.tr("loading...")
        : I18n.tr("%1 settings · %2 customized").arg(root.systemSettings.length).arg(root.customizedCount)

    readonly property var groups: {
        const q = root.searchQuery.trim().toLowerCase();
        const byGroup = {};
        for (const s of root.systemSettings) {
            if (root.modifiedOnly && !s.configured && !s.pending)
                continue;
            if (q.length > 0 && !(s.label + " " + s.description + " " + s.path + " " + s.group).toLowerCase().includes(q))
                continue;
            (byGroup[s.group] = byGroup[s.group] || []).push(s);
        }
        return Object.keys(byGroup).sort().map(name => ({
            name: name,
            description: byGroup[name][0].groupDescription || "",
            items: byGroup[name]
        }));
    }

    Notice {
        text: I18n.tr("An app's own options are under that app in Applications. Changes are written to _config.nix instantly and checked when you rebuild.")
    }

    Rectangle {
        visible: root.pendingCount > 0
        width: parent.width
        height: pendingRow.height + 32
        radius: Vayori.radius
        color: Theme.withAlpha(Theme.warning, 0.12)

        Item {
            id: pendingRow
            x: Vayori.pad
            width: parent.width - Vayori.pad * 2
            height: Math.max(pendingText.height, rebuildNow.height)
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                id: pendingIcon
                name: "pending_actions"
                size: 22
                color: Theme.warning
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                id: pendingText
                anchors.left: pendingIcon.right
                anchors.leftMargin: 14
                anchors.right: rebuildNow.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    text: I18n.tr("%1 change(s) pending").arg(root.pendingCount)
                    font.pixelSize: Vayori.title
                    font.weight: Font.DemiBold
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                }

                StyledText {
                    width: parent.width
                    text: I18n.tr("Saved but not applied yet. Rebuild to apply them - the configuration is checked then.")
                    font.pixelSize: Vayori.body
                    color: Vayori.inkMuted
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }
            }

            TextButton {
                id: rebuildNow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                variant: "primary"
                icon: "sync"
                text: root.vm.rebuildBusy ? I18n.tr("Rebuilding") : I18n.tr("Rebuild now")
                busy: root.vm.rebuildBusy
                onClicked: root.vm.rebuild()
            }
        }
    }

    Item {
        width: parent.width
        height: searchField.height

        Field {
            id: searchField
            width: parent.width - filter.width - 12
            leftIconName: "search"
            showClearButton: true
            placeholderText: I18n.tr("Search settings...")
            onTextChanged: searchDebounce.restart()

            Timer {
                id: searchDebounce
                interval: 80
                onTriggered: root.searchQuery = searchField.text
            }
        }

        Segmented {
            id: filter
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            readonly property string allLabel: I18n.tr("All")
            readonly property string modifiedLabel: I18n.tr("Modified")
            options: [allLabel, modifiedLabel]
            current: root.modifiedOnly ? modifiedLabel : allLabel
            onPicked: value => root.modifiedOnly = value === modifiedLabel
        }
    }

    Notice {
        visible: root.vm.settingsLoading && root.systemSettings.length === 0
        text: I18n.tr("Loading...")
        busy: true
    }

    Repeater {
        model: root.groups

        Section {
            id: groupCard
            required property var modelData
            title: modelData.name
            subtitle: modelData.description
            meta: String(modelData.items.length)

            Repeater {
                model: groupCard.modelData.items

                OptionRow {
                    required property var modelData
                    vm: root.vm
                    setting: modelData
                }
            }
        }
    }

    Notice {
        visible: !root.vm.settingsLoading && root.groups.length === 0
        text: root.modifiedOnly ? I18n.tr("Nothing has been customized yet.") : I18n.tr("No settings match your search.")
    }

    Notice {
        text: root.vm.settingsStatus
        tone: root.vm.settingsError ? "error" : "neutral"
    }
}
