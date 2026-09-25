import QtQuick
import qs.Common
import qs.Widgets

DankFloatingWindow {
    id: root

    required property var vm

    title: I18n.tr("Vayume Settings")
    implicitWidth: 1080
    implicitHeight: 720
    minimumSize: Qt.size(720, 480)
    surfaceColor: Vayori.base

    property string activeCategory: "appearance"
    onActiveCategoryChanged: {
        root.vm.ensurePage(root.activeCategory);
        contentFlick.contentY = 0;
    }
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
            index: "01", label: I18n.tr("Look"),
            items: [
                { id: "appearance", label: I18n.tr("Appearance"), jp: "外観",
                  subtitle: I18n.tr("Font, cursor, and icon theme - the parts of Vayume's look shared by GTK, kitty, SDDM, and DMS itself.") }
            ]
        },
        {
            index: "02", label: I18n.tr("Software"),
            items: [
                { id: "applications", label: I18n.tr("Applications"), jp: "アプリ",
                  subtitle: I18n.tr("Every app Vayume can install and configure. An app's own options open underneath it.") },
                { id: "development", label: I18n.tr("Development"), jp: "開発",
                  subtitle: I18n.tr("Languages, editors and developer tools. Each language lists the enabled editors it integrates with.") },
                { id: "defaults", label: I18n.tr("Default Apps"), jp: "既定",
                  subtitle: I18n.tr("Which app opens links, folders and code files, and which one the Super+Return / Super+E / Super+C / Super+B keybinds start.") }
            ]
        },
        {
            index: "03", label: I18n.tr("System"),
            items: [
                { id: "options", label: I18n.tr("All Settings"), jp: "設定",
                  subtitle: I18n.tr("System-level options a Vayume module declares - new ones show up here automatically.") },
                { id: "users", label: I18n.tr("Users"), jp: "ユーザー",
                  subtitle: I18n.tr("Every person configured on this machine (vayume.users).") },
                { id: "system", label: I18n.tr("System"), jp: "システム",
                  subtitle: I18n.tr("Read-only information about this host and its Vayume repository, plus one-click maintenance.") }
            ]
        }
    ]

    readonly property var categories: root.groups.reduce((all, g) => all.concat(g.items.map(i => Object.assign({ group: g.label, index: g.index }, i))), [])
    readonly property var current: root.categories.find(c => c.id === root.activeCategory) || root.categories[0]

    Item {
        anchors.fill: parent

        Sidebar {
            id: sidebar
            width: Vayori.sidebarWidth
            height: parent.height - statusBar.height
            vm: root.vm
            groups: root.groups
            categories: root.categories
            activeCategory: root.activeCategory
            onSelect: id => root.activeCategory = id
        }

        Item {
            id: main
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: statusBar.top

            readonly property real margin: width > 900 ? 44 : 28
            readonly property real columnWidth: Math.min(width - margin * 2, Vayori.contentMaxWidth)

            readonly property bool pinHeader: height >= 600
            readonly property Item focusItem: main.Window.activeFocusItem
            onFocusItemChanged: root.reveal(main.focusItem)

            Loader {
                id: pinnedHeader
                x: main.margin
                y: 26
                width: main.columnWidth
                active: main.pinHeader
                sourceComponent: headerComponent
            }

            DankFlickable {
                id: contentFlick
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: main.pinHeader ? pinnedHeader.bottom : parent.top
                anchors.topMargin: main.pinHeader ? 22 : 0
                anchors.bottom: parent.bottom
                contentWidth: width
                contentHeight: pageLoader.y + (pageLoader.item ? pageLoader.item.implicitHeight : 0) + 36
                clip: true

                Loader {
                    id: flowingHeader
                    x: main.margin
                    y: 22
                    width: main.columnWidth
                    active: !main.pinHeader
                    sourceComponent: headerComponent
                }

                Loader {
                    id: pageLoader
                    x: main.margin
                    y: flowingHeader.active ? flowingHeader.y + flowingHeader.height + 22 : 0
                    width: main.columnWidth

                    transform: Translate { id: pageShift }

                    onLoaded: pageIn.restart()

                    sourceComponent: {
                        switch (root.activeCategory) {
                        case "appearance": return appearancePageComponent;
                        case "development": return developmentPageComponent;
                        case "applications": return applicationsPageComponent;
                        case "defaults": return defaultAppsPageComponent;
                        case "options": return optionsPageComponent;
                        case "users": return usersPageComponent;
                        case "system": return systemPageComponent;
                        default: return null;
                        }
                    }
                }

                Rectangle {
                    parent: contentFlick
                    x: main.margin
                    width: main.columnWidth
                    height: 1
                    color: Vayori.hairline
                    opacity: main.pinHeader && contentFlick.contentY > 4 ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Vayori.fast } }
                }

                ParallelAnimation {
                    id: pageIn
                    NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: Vayori.normal; easing.type: Easing.OutCubic }
                    NumberAnimation { target: pageShift; property: "y"; from: 6; to: 0; duration: Vayori.normal; easing.type: Easing.OutCubic }
                }
            }
        }

        StatusBar {
            id: statusBar
            anchors.bottom: parent.bottom
            width: parent.width
            vm: root.vm
        }
    }

    Component {
        id: headerComponent

        PageHeader {
            jp: root.current.jp
            group: root.current.group
            index: root.current.index
            title: root.current.label
            subtitle: root.current.subtitle
            meta: pageLoader.item && pageLoader.item.meta !== undefined ? pageLoader.item.meta : ""

            TextButton {
                icon: "refresh"
                text: I18n.tr("Reload")
                implicitHeight: 24
                onClicked: root.vm.refreshAll()
            }
        }
    }

    Component { id: appearancePageComponent; AppearancePage { vm: root.vm } }
    Component { id: developmentPageComponent; DevelopmentPage { vm: root.vm } }
    Component { id: applicationsPageComponent; ApplicationsPage { vm: root.vm } }
    Component { id: defaultAppsPageComponent; DefaultAppsPage { vm: root.vm } }
    Component { id: optionsPageComponent; OptionsPage { vm: root.vm } }
    Component { id: usersPageComponent; UsersPage { vm: root.vm } }
    Component { id: systemPageComponent; SystemPage { vm: root.vm } }
}
