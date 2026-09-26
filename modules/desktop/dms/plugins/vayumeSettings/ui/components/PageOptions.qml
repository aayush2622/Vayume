import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    required property string page
    property string toolsTitle: I18n.tr("Tools")
    property string toolsSubtitle: I18n.tr("Output streams into the log panel.")
    property bool toolsFirst: false

    readonly property var settingsHere: root.vm.settings.filter(s => !s.app && root.vm.pageOfSetting(s) === root.page)
    readonly property var actionsHere: root.vm.actions.filter(a => !a.panel.app && root.vm.pageOfAction(a) === root.page)

    readonly property var settingGroups: {
        const byGroup = {};
        for (const s of root.settingsHere)
            (byGroup[s.group] = byGroup[s.group] || []).push(s);
        return Object.keys(byGroup).map(name => {
            const items = byGroup[name].slice().sort((a, b) => (a.order ?? 100) - (b.order ?? 100) || a.path.localeCompare(b.path));
            return {
                name: name,
                description: items[0].groupDescription || "",
                order: items[0].groupOrder ?? 100,
                items: items
            };
        }).sort((a, b) => a.order - b.order || a.name.localeCompare(b.name));
    }

    readonly property var toolGroups: {
        const byGroup = {};
        for (const a of root.actionsHere) {
            const name = a.panel.group || root.toolsTitle;
            (byGroup[name] = byGroup[name] || []).push(a);
        }
        return Object.keys(byGroup).sort((a, b) => (a === root.toolsTitle) - (b === root.toolsTitle) || a.localeCompare(b)).map(name => ({
            name: name,
            items: byGroup[name].slice().sort((a, b) => a.confirm - b.confirm || a.panel.label.localeCompare(b.panel.label))
        }));
    }

    readonly property int pendingCount: root.settingsHere.filter(s => s.pending).length
    readonly property bool empty: root.settingGroups.length === 0 && root.toolGroups.length === 0

    width: parent ? parent.width : 400
    spacing: Vayori.gap

    Notice {
        visible: root.vm.settingsLoading && root.empty
        text: I18n.tr("Loading...")
        busy: true
    }

    Repeater {
        model: root.toolsFirst ? root.toolGroups : []

        Section {
            id: toolCard
            required property var modelData
            title: modelData.name
            subtitle: modelData.name === root.toolsTitle ? root.toolsSubtitle : ""

            Repeater {
                model: toolCard.modelData.items

                CommandRow {
                    required property var modelData
                    vm: root.vm
                    action: modelData
                }
            }
        }
    }

    Repeater {
        model: root.settingGroups

        Section {
            id: groupCard
            required property var modelData
            title: modelData.name
            subtitle: modelData.description

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

    Repeater {
        model: root.toolsFirst ? [] : root.toolGroups

        Section {
            id: toolCard
            required property var modelData
            title: modelData.name
            subtitle: modelData.name === root.toolsTitle ? root.toolsSubtitle : ""

            Repeater {
                model: toolCard.modelData.items

                CommandRow {
                    required property var modelData
                    vm: root.vm
                    action: modelData
                }
            }
        }
    }

    Notice {
        visible: root.vm.settingsStatus.length > 0
        text: root.vm.settingsStatus
        tone: root.vm.settingsError ? "error" : "neutral"
    }
}
