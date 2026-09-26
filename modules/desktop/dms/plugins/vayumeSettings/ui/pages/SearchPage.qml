import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    property string query: ""
    property var categories: []
    width: parent.width
    spacing: Vayori.gap

    signal navigate(string id)

    readonly property int limit: 25
    readonly property string q: root.query.trim().toLowerCase()

    function hit(text) {
        return String(text).toLowerCase().includes(root.q);
    }

    readonly property var pages: root.q.length === 0 ? [] : root.categories.filter(c => root.hit(c.label + " " + c.subtitle))
    readonly property var options: root.q.length === 0 ? [] : root.vm.settings.filter(s => root.hit(s.label + " " + s.description + " " + s.path + " " + s.group + " " + (s.app || ""))).slice(0, root.limit)
    readonly property var apps: root.q.length === 0 ? [] : root.vm.apps.filter(a => root.hit((a.label || "") + " " + a.name + " " + a.description)).slice(0, root.limit)
    readonly property var commands: root.q.length === 0 ? [] : root.vm.actions.filter(a => root.hit(a.panel.label + " " + a.description + " " + a.name)).slice(0, root.limit)
    readonly property int total: root.pages.length + root.options.length + root.apps.length + root.commands.length

    readonly property string meta: root.q.length === 0 ? "" : I18n.tr("%1 result(s)").arg(root.total)

    Notice {
        visible: root.q.length > 0 && root.total === 0
        text: I18n.tr("Nothing matches \"%1\". Try a setting, an app or a tool name.").arg(root.query.trim())
    }

    Section {
        title: I18n.tr("Pages")
        visible: root.pages.length > 0

        Repeater {
            model: root.pages

            SettingItem {
                id: pageHit
                required property var modelData
                title: modelData.label
                description: modelData.subtitle
                icon: modelData.icon

                TextButton {
                    variant: "tonal"
                    icon: "arrow_forward"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.navigate(pageHit.modelData.id)
                }
            }
        }
    }

    Section {
        title: I18n.tr("Options")
        meta: String(root.options.length)
        visible: root.options.length > 0

        Repeater {
            model: root.options

            OptionRow {
                required property var modelData
                vm: root.vm
                setting: modelData
            }
        }
    }

    Section {
        title: I18n.tr("Applications")
        meta: String(root.apps.length)
        visible: root.apps.length > 0

        Repeater {
            model: root.apps

            SettingItem {
                id: appHit
                required property var modelData
                title: modelData.label || modelData.name
                description: modelData.description
                image: root.vm.iconUrl(modelData.icon)
                icon: modelData.symbol || "apps"

                Toggle {
                    checked: appHit.modelData.enabled
                    anchors.verticalCenter: parent.verticalCenter
                    onToggled: value => root.vm.setAppEnabled(appHit.modelData.name, value)
                }
            }
        }
    }

    Section {
        title: I18n.tr("Tools")
        meta: String(root.commands.length)
        visible: root.commands.length > 0

        Repeater {
            model: root.commands

            CommandRow {
                required property var modelData
                vm: root.vm
                action: modelData
            }
        }
    }
}
