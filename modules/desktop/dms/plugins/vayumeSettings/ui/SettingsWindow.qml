import QtQuick
import QtQml
import qs.Common
import qs.Widgets
import "components"
import "pages"

DankFloatingWindow {
    id: root

    required property var vm

    title: I18n.tr("Vayume Settings")
    implicitWidth: 1120
    implicitHeight: 760
    minimumSize: Qt.size(720, 480)
    surfaceColor: Vayori.base

    property string activeCategory: root.categories.some(c => c.id === root.vm.activePage) ? root.vm.activePage : "overview"
    property bool logOpen: false
    property string searchQuery: ""
    readonly property bool searching: root.searchQuery.trim().length > 0
    readonly property string shownPage: root.searching ? "search" : root.activeCategory

    onShownPageChanged: contentFlick.contentY = 0
    onSearchingChanged: if (root.searching) root.vm.ensurePage("search")

    function go(id) {
        root.searchQuery = "";
        root.activeCategory = id;
    }

    Shortcut { sequence: "Ctrl+F"; onActivated: sidebar.focusSearch() }
    Shortcut { sequence: "Ctrl+R"; onActivated: root.vm.refreshAll() }
    Shortcut { sequence: "Ctrl+B"; onActivated: root.vm.rebuild() }
    Shortcut { sequence: "Ctrl+L"; onActivated: root.logOpen = !root.logOpen }
    Shortcut { sequence: "Escape"; enabled: root.searching; onActivated: root.searchQuery = "" }
    Instantiator {
        model: 9
        delegate: Shortcut {
            required property int index
            sequence: "Ctrl+" + (index + 1)
            enabled: index < root.categories.length
            onActivated: root.go(root.categories[index].id)
        }
    }

    Connections {
        target: pageLoader.item
        ignoreUnknownSignals: true
        function onNavigate(id) { root.go(id); }
    }

    Connections {
        target: root.vm
        function onRebuildBusyChanged() {
            if (root.vm.rebuildBusy) root.logOpen = true;
        }
    }
    onActiveCategoryChanged: root.vm.ensurePage(root.activeCategory)
    Component.onCompleted: root.vm.ensurePage(root.activeCategory)

    function reveal(item) {
        if (!item || !contentFlick.contentItem)
            return;
        let p = item;
        while (p && p !== contentFlick.contentItem)
            p = p.parent;
        if (!p)
            return;
        const top = item.mapToItem(contentFlick.contentItem, 0, 0).y;
        const bottom = top + item.height;
        if (top < contentFlick.contentY + 12)
            root.scrollTo(top - 24);
        else if (bottom > contentFlick.contentY + contentFlick.height - 12)
            root.scrollTo(bottom - contentFlick.height + 24);
    }

    function scrollTo(y) {
        contentFlick.contentY = Math.max(0, Math.min(y, contentFlick.contentHeight - contentFlick.height));
    }

    readonly property var groups: [
        {
            label: "",
            items: [
                { id: "overview", label: I18n.tr("Home"), icon: "home",
                  subtitle: I18n.tr("How this machine stands right now, and what is waiting to be applied.") }
            ]
        },
        {
            label: I18n.tr("Personal"),
            items: [
                { id: "appearance", label: I18n.tr("Appearance"), icon: "palette",
                  subtitle: I18n.tr("Font, cursor and the top bar - the look shared by GTK, kitty, the login screen and DMS.") },
                { id: "pet", label: I18n.tr("Desktop pet"), icon: "pets",
                  subtitle: I18n.tr("The little one living on your screen.") },
                { id: "users", label: I18n.tr("Users"), icon: "group",
                  subtitle: I18n.tr("Everyone who can sign in to this machine, their groups and their own packages.") }
            ]
        },
        {
            label: I18n.tr("Apps"),
            items: [
                { id: "applications", label: I18n.tr("Applications"), icon: "apps",
                  subtitle: I18n.tr("Install or remove apps. An app's own options and tools open underneath it.") },
                { id: "development", label: I18n.tr("Development"), icon: "code",
                  subtitle: I18n.tr("Languages, editors and developer tools. Each language shows which editors support it.") },
                { id: "defaults", label: I18n.tr("Default apps"), icon: "open_in_new",
                  subtitle: I18n.tr("Which app opens links, folders and code files, and which one the Super+Return / Super+E / Super+C / Super+B keybinds start.") }
            ]
        },
        {
            label: I18n.tr("System"),
            items: [
                { id: "network", label: I18n.tr("Network"), icon: "lan",
                  subtitle: I18n.tr("DNS, Tor and network privacy for the whole machine.") },
                { id: "performance", label: I18n.tr("Performance"), icon: "speed",
                  subtitle: I18n.tr("The kernel, system tuning and how fast the machine boots.") },
                { id: "storage", label: I18n.tr("Storage"), icon: "hard_drive",
                  subtitle: I18n.tr("How full the disk is, and what can safely be cleaned up.") },
                { id: "updates", label: I18n.tr("Updates"), icon: "system_update_alt",
                  subtitle: I18n.tr("Apply saved changes, check the configuration and pinned plugins.") },
                { id: "about", label: I18n.tr("About"), icon: "info",
                  subtitle: I18n.tr("This host, its Vayume repository, and the configuration file every change is written to.") }
            ]
        }
    ]

    readonly property var categories: root.groups.reduce((all, g) => all.concat(g.items), [])
    readonly property var current: root.categories.find(c => c.id === root.activeCategory) || root.categories[0]

    Item {
        anchors.fill: parent

        Sidebar {
            id: sidebar
            width: Vayori.sidebarWidth
            height: parent.height
            vm: root.vm
            groups: root.groups
            categories: root.categories
            activeCategory: root.searching ? "" : root.activeCategory
            logOpen: root.logOpen
            searchQuery: root.searchQuery
            onSearchEdited: text => root.searchQuery = text
            onSelect: id => root.go(id)
            onToggleLog: root.logOpen = !root.logOpen
        }

        Rectangle {
            id: canvas
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 12
            anchors.leftMargin: 0
            radius: Vayori.radiusLarge
            color: Vayori.canvas
            clip: true

            Item {
                id: main
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: logPanel.visible ? logPanel.top : parent.bottom
                anchors.bottomMargin: logPanel.visible ? 12 : 0

                readonly property real margin: width > 900 ? 48 : 28
                readonly property real columnWidth: Math.min(width - margin * 2, Vayori.contentMaxWidth)

                readonly property bool pinHeader: height >= 560
                readonly property Item focusItem: main.Window.activeFocusItem
                onFocusItemChanged: root.reveal(main.focusItem)

                Loader {
                    id: pinnedHeader
                    x: main.margin
                    y: 32
                    width: main.width - main.margin - 20
                    active: main.pinHeader
                    sourceComponent: headerComponent
                }

                DankFlickable {
                    id: contentFlick
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: main.pinHeader ? pinnedHeader.bottom : parent.top
                    anchors.topMargin: main.pinHeader ? 20 : 0
                    anchors.bottom: parent.bottom
                    contentWidth: width
                    contentHeight: pageLoader.y + (pageLoader.item ? pageLoader.item.implicitHeight : 0) + 32
                    clip: true

                    Loader {
                        id: flowingHeader
                        x: main.margin
                        y: 28
                        width: main.width - main.margin - 20
                        active: !main.pinHeader
                        sourceComponent: headerComponent
                    }

                    Loader {
                        id: pageLoader
                        x: main.margin
                        y: flowingHeader.active ? flowingHeader.y + flowingHeader.height + 20 : 8
                        width: main.columnWidth

                        transform: Translate { id: pageShift }

                        onLoaded: pageIn.restart()

                        sourceComponent: {
                            switch (root.shownPage) {
                            case "overview": return overviewPageComponent;
                            case "search": return searchPageComponent;
                            case "about": return aboutPageComponent;
                            case "appearance": return appearancePageComponent;
                            case "pet": return petPageComponent;
                            case "development": return developmentPageComponent;
                            case "applications": return applicationsPageComponent;
                            case "defaults": return defaultAppsPageComponent;
                            case "users": return usersPageComponent;
                            case "network": return networkPageComponent;
                            case "performance": return performancePageComponent;
                            case "storage": return storagePageComponent;
                            case "updates": return updatesPageComponent;
                            default: return null;
                            }
                        }
                    }

                    ParallelAnimation {
                        id: pageIn
                        NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: Vayori.normal; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pageShift; property: "y"; from: 8; to: 0; duration: Vayori.normal; easing.type: Easing.OutCubic }
                    }
                }
            }

            LogPanel {
                id: logPanel
                visible: root.logOpen && root.vm.rebuildLog.length > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                height: Math.min(220, parent.height * 0.4)
                vm: root.vm
                onClose: root.logOpen = false
            }
        }
    }

    Component {
        id: headerComponent

        PageHeader {
            title: root.searching ? I18n.tr("Search") : root.current.label
            subtitle: root.searching ? I18n.tr("Results for \"%1\" across every page.").arg(root.searchQuery.trim()) : root.current.subtitle
            meta: pageLoader.item && pageLoader.item.meta !== undefined ? pageLoader.item.meta : ""

            TextButton {
                variant: "ghost"
                icon: "refresh"
                onClicked: root.vm.refreshAll()
            }

            TextButton {
                variant: "ghost"
                icon: "close"
                onClicked: root.visible = false
            }
        }
    }

    Component { id: overviewPageComponent; OverviewPage { vm: root.vm } }
    Component { id: searchPageComponent; SearchPage { vm: root.vm; query: root.searchQuery; categories: root.categories } }
    Component { id: appearancePageComponent; AppearancePage { vm: root.vm } }
    Component { id: developmentPageComponent; DevelopmentPage { vm: root.vm } }
    Component { id: applicationsPageComponent; ApplicationsPage { vm: root.vm } }
    Component { id: defaultAppsPageComponent; DefaultAppsPage { vm: root.vm } }
    Component { id: usersPageComponent; UsersPage { vm: root.vm } }
    Component { id: petPageComponent; PetPage { vm: root.vm } }
    Component { id: networkPageComponent; SystemPage { vm: root.vm; page: "network" } }
    Component { id: performancePageComponent; SystemPage { vm: root.vm; page: "performance" } }
    Component { id: storagePageComponent; StoragePage { vm: root.vm } }
    Component { id: updatesPageComponent; UpdatesPage { vm: root.vm } }
    Component { id: aboutPageComponent; AboutPage { vm: root.vm } }
}
