import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    signal navigate(string id)

    readonly property bool pending: root.vm.repoKnown && root.vm.repo.rebuildPending
    readonly property var pendingSettings: root.vm.settings.filter(s => s.pending)
    readonly property var appsHere: root.vm.apps.filter(a => a.category !== "development")
    readonly property var devItems: root.vm.development.languages.concat(root.vm.development.editors, root.vm.development.tools)

    readonly property string greeting: {
        const h = new Date().getHours();
        if (h < 5) return I18n.tr("Still up");
        if (h < 12) return I18n.tr("Good morning");
        if (h < 18) return I18n.tr("Good afternoon");
        return I18n.tr("Good evening");
    }

    readonly property var tiles: [
        { id: "applications", icon: "apps", label: I18n.tr("Applications"),
          value: root.vm.appsLoading ? "..." : I18n.tr("%1 of %2").arg(root.appsHere.filter(a => a.enabled).length).arg(root.appsHere.length) },
        { id: "development", icon: "code", label: I18n.tr("Development"),
          value: root.vm.developmentLoading ? "..." : I18n.tr("%1 of %2").arg(root.devItems.filter(a => a.enabled).length).arg(root.devItems.length) },
        { id: "users", icon: "group", label: I18n.tr("Users"),
          value: root.vm.usersLoading ? "..." : String(Object.keys(root.vm.users).length) },
        { id: "systemOptions", icon: "tune", label: I18n.tr("Customized"),
          value: root.vm.settingsLoading && root.vm.settings.length === 0 ? "..." : String(root.vm.settings.filter(s => s.configured).length) }
    ]

    Rectangle {
        width: parent.width
        height: hero.implicitHeight + 48
        radius: Vayori.radiusLarge
        color: root.pending ? Theme.withAlpha(Theme.warning, 0.14) : Vayori.chosen

        Item {
            id: hero
            x: 28
            y: 24
            width: parent.width - 56
            implicitHeight: Math.max(heroText.implicitHeight, heroAction.height)

            Column {
                id: heroText
                width: parent.width - heroAction.width - 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                StyledText {
                    text: root.greeting + (root.vm.repoKnown ? " - " + root.vm.repo.hostName : "")
                    font.pixelSize: Vayori.display - 4
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                }

                StyledText {
                    width: parent.width
                    text: {
                        if (!root.vm.repoKnown)
                            return I18n.tr("Reading the repository...");
                        if (root.pending)
                            return I18n.tr("%1 change(s) are saved in _config.nix but not running yet.").arg(Math.max(root.pendingSettings.length, 1));
                        return root.vm.repo.dirty
                            ? I18n.tr("Everything is applied. The repository has uncommitted changes on %1.").arg(root.vm.repo.branch)
                            : I18n.tr("Everything is applied and the repository is clean on %1.").arg(root.vm.repo.branch);
                    }
                    font.pixelSize: Vayori.body + 1
                    color: Vayori.inkMuted
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }
            }

            TextButton {
                id: heroAction
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                variant: root.pending ? "primary" : "tonal"
                icon: root.pending ? "sync" : "build"
                text: root.pending ? (root.vm.rebuildBusy ? I18n.tr("Rebuilding") : I18n.tr("Rebuild now")) : I18n.tr("Maintenance")
                busy: root.pending && root.vm.rebuildBusy
                onClicked: root.pending ? root.vm.rebuild() : root.navigate("maintenance")
            }
        }
    }

    Grid {
        id: tileGrid
        width: parent.width
        columns: width > 700 ? 4 : 2
        spacing: 12

        Repeater {
            model: root.tiles

            Rectangle {
                id: tile
                required property var modelData
                width: (tileGrid.width - tileGrid.spacing * (tileGrid.columns - 1)) / tileGrid.columns
                height: 96
                radius: Vayori.radius
                color: tileArea.containsMouse ? Vayori.cardHover : Vayori.card

                activeFocusOnTab: true
                Keys.onSpacePressed: root.navigate(tile.modelData.id)
                Keys.onReturnPressed: root.navigate(tile.modelData.id)

                Behavior on color { ColorAnimation { duration: Vayori.fast } }

                FocusRing {}

                DankIcon {
                    x: 18
                    y: 18
                    name: tile.modelData.icon
                    size: 22
                    color: Vayori.accent
                }

                DankIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    y: 18
                    name: "arrow_forward"
                    size: 16
                    color: Vayori.inkGhost
                    opacity: tileArea.containsMouse ? 1 : 0
                }

                Column {
                    x: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    spacing: 0

                    StyledText {
                        text: tile.modelData.value
                        font.pixelSize: Vayori.title + 4
                        font.weight: Font.Medium
                        color: Vayori.ink
                        wrapMode: Text.NoWrap
                    }

                    StyledText {
                        text: tile.modelData.label
                        font.pixelSize: Vayori.micro
                        color: Vayori.inkFaint
                        wrapMode: Text.NoWrap
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigate(tile.modelData.id)
                }
            }
        }
    }

    Section {
        title: I18n.tr("Waiting for a rebuild")
        subtitle: I18n.tr("Saved options the running system doesn't have yet. Undo one here, or rebuild to apply them all.")
        meta: String(root.pendingSettings.length)
        visible: root.pendingSettings.length > 0

        Repeater {
            model: root.pendingSettings

            OptionRow {
                required property var modelData
                vm: root.vm
                setting: modelData
            }
        }
    }

    Section {
        title: I18n.tr("Shortcuts")

        Repeater {
            model: [
                { keys: "Ctrl+F", what: I18n.tr("Search every option, app and command") },
                { keys: "Ctrl+1 - Ctrl+9", what: I18n.tr("Jump to a page in the sidebar") },
                { keys: "Ctrl+R", what: I18n.tr("Reload the current page from _config.nix") },
                { keys: "Ctrl+B", what: I18n.tr("Rebuild") },
                { keys: "Ctrl+L", what: I18n.tr("Show or hide the rebuild log") },
                { keys: "Esc", what: I18n.tr("Clear the search") }
            ]

            SettingItem {
                required property var modelData
                title: modelData.what

                Badge {
                    label: modelData.keys
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
