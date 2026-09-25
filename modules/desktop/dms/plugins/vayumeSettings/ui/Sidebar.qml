import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property var vm
    required property var groups
    required property var categories
    required property string activeCategory

    property bool keyNav: false

    signal select(string id)

    function step(delta) {
        const ids = root.categories.map(c => c.id);
        const next = ids[(ids.indexOf(root.activeCategory) + delta + ids.length) % ids.length];
        root.keyNav = true;
        root.select(next);
    }

    function countFor(id) {
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

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Vayori.hairline
    }

    Rectangle {
        id: brand
        x: 16
        y: 16
        width: parent.width - 32
        height: 60
        radius: Vayori.radius
        color: "transparent"
        border.width: 1
        border.color: Vayori.hairline

        StyledText {
            id: mark
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "夜"
            font.family: Vayori.jpSerif
            font.pixelSize: 24
            color: Vayori.ink
            wrapMode: Text.NoWrap
        }

        Rectangle {
            x: mark.x + mark.width + 13
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 26
            color: Vayori.hairline
        }

        Column {
            x: mark.x + mark.width + 27
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            StyledText {
                text: "VAYUME"
                font.pixelSize: Vayori.section
                font.weight: Font.Medium
                font.letterSpacing: 3
                color: Vayori.ink
                wrapMode: Text.NoWrap
            }

            Row {
                spacing: 6

                StyledText {
                    text: I18n.tr("Settings")
                    font.pixelSize: Vayori.micro
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Vayori.trackWide
                    color: Vayori.inkFaint
                    wrapMode: Text.NoWrap
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "設定"
                    font.family: Vayori.jp
                    font.pixelSize: Vayori.micro
                    color: Vayori.inkGhost
                    wrapMode: Text.NoWrap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Column {
        id: nav
        x: 16
        anchors.top: brand.bottom
        anchors.topMargin: 18
        width: parent.width - 32
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
                    height: group.index === 0 ? 24 : 34

                    Row {
                        id: groupLabel
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        spacing: 8

                        StyledText {
                            text: group.modelData.index
                            isMonospace: true
                            font.pixelSize: Vayori.micro
                            color: Vayori.inkGhost
                            wrapMode: Text.NoWrap
                        }

                        StyledText {
                            text: group.modelData.label
                            font.pixelSize: Vayori.micro
                            font.weight: Font.Medium
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: Vayori.trackWide
                            color: Vayori.inkFaint
                            wrapMode: Text.NoWrap
                        }
                    }

                    Rectangle {
                        anchors.left: groupLabel.right
                        anchors.leftMargin: 10
                        anchors.right: tick.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: groupLabel.verticalCenter
                        height: 1
                        color: Vayori.divider
                    }

                    Rectangle {
                        id: tick
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: groupLabel.verticalCenter
                        width: 1
                        height: 5
                        color: Vayori.hairline
                    }
                }

                Repeater {
                    model: group.modelData.items

                    SidebarItem {
                        id: item
                        required property var modelData
                        label: modelData.label
                        jp: modelData.jp
                        active: root.activeCategory === modelData.id
                        badgeCount: root.countFor(modelData.id)
                        onActivated: root.select(modelData.id)
                        onActiveChanged: {
                            if (active && root.keyNav) {
                                item.forceActiveFocus();
                                root.keyNav = false;
                            }
                        }
                        Keys.onUpPressed: root.step(-1)
                        Keys.onDownPressed: root.step(1)
                    }
                }
            }
        }
    }

    Column {
        id: colophon
        x: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        width: parent.width - 32
        spacing: 6
        visible: nav.y + nav.height + height + 32 < root.height

        Repeater {
            model: [
                { key: I18n.tr("Host"), value: root.vm.repoKnown ? root.vm.repo.hostName : "···" },
                { key: I18n.tr("Branch"), value: root.vm.repoKnown ? root.vm.repo.branch + (root.vm.repo.dirty ? " *" : "") : "···" }
            ]

            Row {
                required property var modelData
                spacing: 0

                StyledText {
                    width: 64
                    text: modelData.key
                    font.pixelSize: Vayori.micro
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Vayori.track
                    color: Vayori.inkGhost
                    wrapMode: Text.NoWrap
                }

                StyledText {
                    width: colophon.width - 64
                    text: modelData.value
                    isMonospace: true
                    font.pixelSize: Vayori.micro
                    color: Vayori.inkFaint
                    wrapMode: Text.NoWrap
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Vayori.divider
        }

        StyledText {
            text: "VAYORI // " + I18n.tr("quiet configuration")
            isMonospace: true
            font.pixelSize: Vayori.micro
            font.letterSpacing: 0.4
            color: Vayori.inkGhost
            wrapMode: Text.NoWrap
        }
    }
}
