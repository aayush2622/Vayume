import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    readonly property var systemActions: root.vm.actions.filter(a => !a.panel.app)
    width: parent.width
    spacing: Vayori.gap

    readonly property var stats: [
        {
            label: I18n.tr("Git status"),
            value: root.vm.repoKnown ? (root.vm.repo.dirty ? I18n.tr("Uncommitted changes") : I18n.tr("Clean")) : "···",
            tone: root.vm.repoKnown && root.vm.repo.dirty ? "warning" : "neutral"
        },
        {
            label: I18n.tr("Running system"),
            value: root.vm.repoKnown ? (root.vm.repo.rebuildPending ? I18n.tr("Rebuild pending") : I18n.tr("Up to date")) : "···",
            tone: root.vm.repoKnown ? (root.vm.repo.rebuildPending ? "warning" : "success") : "neutral"
        }
    ]

    Rectangle {
        width: parent.width
        height: 76
        radius: Vayori.radius
        color: Vayori.panel
        border.width: 1
        border.color: Vayori.hairline

        Row {
            anchors.fill: parent

            Repeater {
                model: root.stats

                Item {
                    id: stat
                    required property var modelData
                    required property int index
                    width: parent.width / root.stats.length
                    height: parent.height

                    Rectangle {
                        visible: stat.index > 0
                        width: 1
                        height: parent.height - 24
                        anchors.verticalCenter: parent.verticalCenter
                        color: Vayori.divider
                    }

                    Column {
                        x: Vayori.pad
                        width: parent.width - Vayori.pad * 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Eyebrow {
                            text: stat.modelData.label
                            font.pixelSize: Vayori.micro
                        }

                        Row {
                            spacing: 9

                            Rectangle {
                                width: 6
                                height: 6
                                color: Vayori.tone(stat.modelData.tone)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: stat.modelData.value
                                font.pixelSize: Vayori.title + 1
                                color: stat.modelData.tone === "warning" ? Theme.warning : Vayori.ink
                                wrapMode: Text.NoWrap
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Repository")

        Repeater {
            model: [
                { label: I18n.tr("Hostname"), value: root.vm.repoKnown ? root.vm.repo.hostName : "···" },
                { label: I18n.tr("Repository"), value: root.vm.repoKnown ? root.vm.repo.path : I18n.tr("Locating...") },
                { label: I18n.tr("Branch"), value: root.vm.repoKnown ? root.vm.repo.branch : "···" },
                { label: I18n.tr("Configuration file"), value: root.vm.repoKnown ? root.vm.repo.configFile : "···" }
            ]

            Item {
                id: fact
                required property var modelData
                width: parent.width
                height: 40

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Vayori.divider
                }

                StyledText {
                    id: factLabel
                    width: Math.min(170, parent.width * 0.35)
                    anchors.verticalCenter: parent.verticalCenter
                    text: fact.modelData.label
                    font.pixelSize: Vayori.body + 1
                    color: Vayori.inkMuted
                    wrapMode: Text.NoWrap
                }

                StyledText {
                    anchors.left: factLabel.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: fact.modelData.value
                    isMonospace: true
                    font.pixelSize: Vayori.body
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Maintenance")
        subtitle: I18n.tr("One-click versions of vayume commands. Output streams into the log at the bottom.")
        meta: String(root.systemActions.length).padStart(2, "0")
        visible: root.systemActions.length > 0

        Repeater {
            model: root.systemActions

            ActionRow {
                required property var modelData
                vm: root.vm
                action: modelData
            }
        }
    }
}
