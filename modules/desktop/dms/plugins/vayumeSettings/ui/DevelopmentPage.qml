import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property var sections: [
        { title: I18n.tr("Languages"), items: root.vm.development.languages, languages: true },
        { title: I18n.tr("Editors"), items: root.vm.development.editors, languages: false },
        { title: I18n.tr("Development Tools"), items: root.vm.development.tools, languages: false }
    ]

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

        SettingsCard {
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
                    title: modelData.name
                    description: modelData.description
                    meta: {
                        if (!section.modelData.languages)
                            return "";
                        return modelData.integrations.length > 0
                            ? I18n.tr("integrates with: %1").arg(modelData.integrations.join(", "))
                            : I18n.tr("no enabled editor integrates with this language yet");
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
