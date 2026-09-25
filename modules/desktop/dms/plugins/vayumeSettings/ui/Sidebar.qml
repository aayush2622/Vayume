import QtQuick
import qs.Common
import qs.Widgets
import "components"

Item {
    id: root

    required property var vm
    required property var groups
    required property var categories
    required property string activeCategory
    property bool logOpen: false
    property string searchQuery: ""

    property bool keyNav: false

    signal select(string id)
    signal toggleLog
    signal searchEdited(string text)

    function focusSearch() {
        search.forceActiveFocus();
        search.selectAll();
    }

    function step(delta) {
        const ids = root.categories.map(c => c.id);
        const next = ids[(ids.indexOf(root.activeCategory) + delta + ids.length) % ids.length];
        root.keyNav = true;
        root.select(next);
    }

    function reveal(item) {
        const y = item.mapToItem(nav, 0, 0).y;
        if (y < navFlick.contentY)
            navFlick.contentY = Math.max(0, y - 8);
        else if (y + item.height > navFlick.contentY + navFlick.height)
            navFlick.contentY = Math.min(nav.height - navFlick.height, y + item.height - navFlick.height + 8);
    }

    function countFor(id) {
        if (id === "overview")
            return root.vm.settings.filter(s => s.pending).length;
        if (id === "applications" && !root.vm.appsLoading)
            return root.vm.apps.filter(a => a.enabled && a.category !== "development").length;
        if (id === "development" && !root.vm.developmentLoading) {
            const d = root.vm.development;
            return d.languages.concat(d.editors, d.tools).filter(a => a.enabled).length;
        }
        if (id === "users" && !root.vm.usersLoading)
            return Object.keys(root.vm.users).length;
        return 0;
    }

    Row {
        id: brand
        x: 28
        y: 26
        spacing: 14

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: Vayori.selected
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                anchors.centerIn: parent
                text: "夜"
                font.family: Vayori.jpSerif
                font.pixelSize: 19
                color: Vayori.ink
                wrapMode: Text.NoWrap
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            StyledText {
                text: "Vayume"
                font.pixelSize: Vayori.title + 1
                font.weight: Font.DemiBold
                color: Vayori.ink
                wrapMode: Text.NoWrap
            }

            StyledText {
                text: I18n.tr("Settings")
                font.pixelSize: Vayori.micro
                color: Vayori.inkFaint
                wrapMode: Text.NoWrap
            }
        }
    }

    Field {
        id: search
        x: 16
        anchors.top: brand.bottom
        anchors.topMargin: 20
        width: parent.width - 32
        leftIconName: "search"
        showClearButton: true
        placeholderText: I18n.tr("Search settings...")
        onTextEdited: searchDebounce.restart()
        Keys.onDownPressed: root.select(root.activeCategory.length > 0 ? root.activeCategory : root.categories[0].id)

        Timer {
            id: searchDebounce
            interval: 120
            onTriggered: root.searchEdited(search.text)
        }

        Connections {
            target: root
            function onSearchQueryChanged() {
                if (root.searchQuery !== search.text)
                    search.text = root.searchQuery;
            }
        }
    }

    Flickable {
        id: navFlick
        x: 12
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: statusCard.top
        anchors.bottomMargin: 12
        width: parent.width - 24
        contentHeight: nav.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: nav
            width: parent.width
            spacing: 2

            Repeater {
                model: root.groups

                Column {
                    id: group
                    required property var modelData
                    required property int index
                    width: nav.width
                    spacing: 2

                    Item {
                        width: parent.width
                        height: group.modelData.label.length === 0 ? 0 : 34

                        StyledText {
                            x: 18
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            text: group.modelData.label
                            font.pixelSize: Vayori.micro
                            font.weight: Font.DemiBold
                            color: Vayori.inkFaint
                            wrapMode: Text.NoWrap
                        }
                    }

                    Repeater {
                        model: group.modelData.items

                        SidebarItem {
                            id: item
                            required property var modelData
                            label: modelData.label
                            icon: modelData.icon
                            active: root.activeCategory === modelData.id
                            badgeCount: root.countFor(modelData.id)
                            badgeTone: modelData.id === "overview" ? "warning" : "neutral"
                            onActivated: root.select(modelData.id)
                            onActiveChanged: {
                                if (!active)
                                    return;
                                root.reveal(item);
                                if (root.keyNav) {
                                    item.forceActiveFocus();
                                    root.keyNav = false;
                                }
                            }
                            Component.onCompleted: if (active) Qt.callLater(() => root.reveal(item))
                            Keys.onUpPressed: root.step(-1)
                            Keys.onDownPressed: root.step(1)
                        }
                    }
                }
            }
        }
    }

    StatusCard {
        id: statusCard
        x: 12
        width: parent.width - 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        vm: root.vm
        logOpen: root.logOpen
        compact: root.height < 660
        onToggleLog: root.toggleLog()
    }
}
