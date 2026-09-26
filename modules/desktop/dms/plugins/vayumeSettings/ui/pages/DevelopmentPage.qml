import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property var sections: [
        { title: I18n.tr("Languages"), items: root.vm.development.languages, languages: true },
        { title: I18n.tr("Editors"), items: root.vm.development.editors, languages: false },
        { title: I18n.tr("Tools"), items: root.vm.development.tools, languages: false }
    ]

    function labelOf(name) {
        const all = root.vm.development.editors.concat(root.vm.development.tools);
        const hit = all.find(e => e.name === name);
        return hit && hit.label ? hit.label : name;
    }

    readonly property string meta: {
        if (root.vm.developmentLoading)
            return "";
        const all = root.sections.reduce((n, s) => n.concat(s.items), []);
        return I18n.tr("%1 of %2 enabled").arg(all.filter(a => a.enabled).length).arg(all.length);
    }

    Notice {
        visible: root.vm.developmentLoading
        text: I18n.tr("Loading development environment...")
        busy: true
    }

    Repeater {
        model: root.vm.developmentLoading ? [] : root.sections

        Section {
            id: section
            required property var modelData
            visible: modelData.items.length > 0
            title: modelData.title
            meta: I18n.tr("%1 / %2").arg(modelData.items.filter(a => a.enabled).length).arg(modelData.items.length)

            Repeater {
                model: section.modelData.items

                SettingItem {
                    id: entry
                    required property var modelData
                    title: modelData.label || modelData.name
                    description: modelData.description
                    image: root.vm.iconUrl(modelData.icon)
                    icon: modelData.symbol || "code"
                    meta: {
                        if (!section.modelData.languages)
                            return "";
                        return modelData.integrations.length > 0
                            ? I18n.tr("Works in %1").arg(modelData.integrations.map(n => root.labelOf(n)).join(", "))
                            : I18n.tr("No enabled editor supports it yet");
                    }

                    Toggle {
                        checked: entry.modelData.enabled
                        onToggled: value => root.vm.setAppEnabled(entry.modelData.name, value)
                    }
                }
            }
        }
    }
}
