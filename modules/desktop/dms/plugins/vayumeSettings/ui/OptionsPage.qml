import QtQuick
import qs.Common
import qs.Widgets

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
        height: pendingRow.height + 24
        radius: Vayori.radius
        color: Theme.withAlpha(Theme.warning, 0.07)
        border.width: 1
        border.color: Theme.withAlpha(Theme.warning, 0.35)

        Item {
            id: pendingRow
            x: Vayori.pad
            width: parent.width - Vayori.pad * 2
            height: Math.max(pendingText.height, rebuildNow.height)
            anchors.verticalCenter: parent.verticalCenter

            Column {
                id: pendingText
                width: parent.width - rebuildNow.width - 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Eyebrow {
                    text: I18n.tr("%1 pending").arg(String(root.pendingCount).padStart(2, "0"))
                    color: Theme.warning
                }

                StyledText {
                    width: parent.width
                    text: I18n.tr("%1 change(s) saved but not applied yet. Rebuild to apply them - the configuration is checked then.").arg(root.pendingCount)
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
                variant: "warning"
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
            width: parent.width - filter.width - 10
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

        Row {
            id: filter
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: [
                    { label: I18n.tr("All"), modified: false },
                    { label: I18n.tr("Modified"), modified: true }
                ]

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool active: root.modifiedOnly === modelData.modified
                    width: Math.max(64, chipText.implicitWidth + 22)
                    height: searchField.height - 4
                    radius: Vayori.radius
                    color: chip.active ? Vayori.selected : (chipArea.containsMouse ? Vayori.hover : "transparent")
                    border.width: 1
                    border.color: chip.activeFocus ? Vayori.focus : (chip.active ? Vayori.lineStrong : Vayori.hairline)

                    activeFocusOnTab: true
                    Keys.onSpacePressed: root.modifiedOnly = chip.modelData.modified
                    Keys.onReturnPressed: root.modifiedOnly = chip.modelData.modified

                    StyledText {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData.label
                        font.pixelSize: Vayori.caption
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: Vayori.track
                        font.weight: Font.Medium
                        color: chip.active ? Vayori.ink : Vayori.inkFaint
                        wrapMode: Text.NoWrap
                    }

                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modifiedOnly = chip.modelData.modified
                    }
                }
            }
        }
    }

    Notice {
        visible: root.vm.settingsLoading && root.systemSettings.length === 0
        text: I18n.tr("Loading...")
        busy: true
    }

    Repeater {
        model: root.groups

        SettingsCard {
            id: groupCard
            required property var modelData
            title: modelData.name
            subtitle: modelData.description
            meta: String(modelData.items.length).padStart(2, "0")

            Repeater {
                model: groupCard.modelData.items

                SettingRow {
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
