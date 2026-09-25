import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property var stats: [
        {
            label: I18n.tr("Git status"),
            icon: "commit",
            value: root.vm.repoKnown ? (root.vm.repo.dirty ? I18n.tr("Uncommitted changes") : I18n.tr("Clean")) : "...",
            tone: root.vm.repoKnown && root.vm.repo.dirty ? "warning" : "neutral"
        },
        {
            label: I18n.tr("Running system"),
            icon: "deployed_code",
            value: root.vm.repoKnown ? (root.vm.repo.rebuildPending ? I18n.tr("Rebuild pending") : I18n.tr("Up to date")) : "...",
            tone: root.vm.repoKnown ? (root.vm.repo.rebuildPending ? "warning" : "success") : "neutral"
        }
    ]

    Row {
        width: parent.width
        spacing: 12

        Repeater {
            model: root.stats

            Rectangle {
                id: stat
                required property var modelData
                width: (parent.width - 12) / 2
                height: 76
                radius: Vayori.radius
                color: Vayori.card

                Rectangle {
                    id: statIcon
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.withAlpha(Vayori.tone(stat.modelData.tone), stat.modelData.tone === "neutral" ? 0.12 : 0.18)

                    DankIcon {
                        anchors.centerIn: parent
                        name: stat.modelData.icon
                        size: 20
                        color: stat.modelData.tone === "neutral" ? Vayori.inkMuted : Vayori.tone(stat.modelData.tone)
                    }
                }

                Column {
                    anchors.left: statIcon.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: stat.modelData.label
                        font.pixelSize: Vayori.micro
                        color: Vayori.inkFaint
                        wrapMode: Text.NoWrap
                    }

                    StyledText {
                        width: parent.width
                        text: stat.modelData.value
                        font.pixelSize: Vayori.title + 1
                        font.weight: Font.Medium
                        color: Vayori.ink
                        wrapMode: Text.NoWrap
                    }
                }
            }
        }
    }

    Section {
        title: I18n.tr("Repository")

        Repeater {
            model: [
                { label: I18n.tr("Hostname"), value: root.vm.repoKnown ? root.vm.repo.hostName : "...", path: "" },
                { label: I18n.tr("Repository"), value: root.vm.repoKnown ? root.vm.repo.path : I18n.tr("Locating..."), path: root.vm.repoKnown ? root.vm.repo.path : "" },
                { label: I18n.tr("Branch"), value: root.vm.repoKnown ? root.vm.repo.branch : "...", path: "" },
                { label: I18n.tr("Configuration file"), value: root.vm.repoKnown ? root.vm.repo.configFile : "...", path: root.vm.repoKnown ? root.vm.repo.configFile : "" }
            ]

            Rectangle {
                id: fact
                required property var modelData
                width: parent.width
                height: 54
                radius: Vayori.radius
                color: Vayori.card

                StyledText {
                    id: factLabel
                    x: Vayori.pad
                    width: Math.min(180, parent.width * 0.35)
                    anchors.verticalCenter: parent.verticalCenter
                    text: fact.modelData.label
                    font.pixelSize: Vayori.title
                    font.weight: Font.Medium
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                }

                Row {
                    id: factActions
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    visible: fact.modelData.path.length > 0

                    TextButton {
                        variant: "ghost"
                        icon: "content_copy"
                        implicitHeight: 32
                        onClicked: root.vm.copyText(fact.modelData.path)
                    }

                    TextButton {
                        variant: "ghost"
                        icon: "open_in_new"
                        implicitHeight: 32
                        onClicked: root.vm.openPath(fact.modelData.path)
                    }
                }

                StyledText {
                    anchors.left: factLabel.right
                    anchors.leftMargin: 12
                    anchors.right: factActions.visible ? factActions.left : parent.right
                    anchors.rightMargin: factActions.visible ? 8 : Vayori.pad
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: fact.modelData.value
                    isMonospace: true
                    font.pixelSize: Vayori.body
                    color: Vayori.inkMuted
                    wrapMode: Text.NoWrap
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: identity.implicitHeight + 40
        radius: Vayori.radius
        color: Vayori.card

        Row {
            id: identity
            x: Vayori.pad
            y: 20
            width: parent.width - Vayori.pad * 2
            spacing: 18

            Rectangle {
                width: 56
                height: 56
                radius: 28
                color: Vayori.selected

                StyledText {
                    anchors.centerIn: parent
                    text: "夜"
                    font.family: Vayori.jpSerif
                    font.pixelSize: 28
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                }
            }

            Column {
                width: parent.width - 74
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                StyledText {
                    text: "Vayume Settings"
                    font.pixelSize: Vayori.title + 2
                    font.weight: Font.DemiBold
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                }

                StyledText {
                    width: parent.width
                    text: I18n.tr("Drawn in Vayori - quiet, personal and dependable. Every change here is a line in _config.nix, applied by the next rebuild and undone by rolling back.")
                    font.pixelSize: Vayori.body
                    color: Vayori.inkMuted
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }
            }
        }
    }
}
