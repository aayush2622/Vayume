import QtQuick
import qs.Common
import qs.Widgets

SettingItem {
    id: root

    required property var vm
    required property var setting

    readonly property bool isBool: setting.kind === "bool"
    readonly property bool isList: setting.kind === "list"
    readonly property bool isText: setting.kind === "int" || setting.kind === "str" || setting.kind === "list"
    readonly property bool busy: root.vm.settingsSaving

    function show(v) {
        if (v === null || v === undefined)
            return I18n.tr("Default");
        if (Array.isArray(v))
            return v.length === 0 ? I18n.tr("empty") : v.join(", ");
        return String(v);
    }

    readonly property string valueText: {
        const v = setting.value;
        if (v === null || v === undefined)
            return "";
        return root.isList ? v.join(" ") : String(v);
    }

    function commitText(text) {
        const t = text.trim();
        if (t === root.valueText.trim())
            return;
        if (t.length === 0 && setting.nullable) {
            root.vm.resetSetting(setting.path);
            return;
        }
        root.vm.setSetting(setting.path, root.isList ? t.split(/\s+/).filter(x => x.length > 0) : [t]);
    }

    title: setting.label
    description: setting.description.split(/\n\s*\n/).map(p => p.replace(/\s*\n\s*/g, " ").trim()).join("\n\n")
    meta: setting.path
    marker: setting.pending ? "warning" : ""

    tags: [
        Badge {
            visible: root.setting.pending
            label: I18n.tr("Pending rebuild")
            tone: "warning"
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        },
        Badge {
            visible: root.setting.configured && !root.setting.pending
            label: I18n.tr("Customized")
            tone: "info"
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
    ]

    notes: [
        StyledText {
            visible: root.setting.pending
            text: I18n.tr("Running now: %1").arg(root.show(root.setting.applied))
            width: parent ? parent.width : 0
            isMonospace: true
            font.pixelSize: Vayori.micro
            color: Theme.warning
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        },
        StyledText {
            visible: root.setting.unparsed
            text: I18n.tr("Set by a multi-line expression in _config.nix - edit it there.")
            width: parent ? parent.width : 0
            font.pixelSize: Vayori.body
            color: Theme.error
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    ]

    TextButton {
        visible: root.setting.configured
        icon: "undo"
        implicitHeight: 26
        enabled: !root.busy
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.vm.resetSetting(root.setting.path)
    }

    Toggle {
        visible: root.isBool
        checked: root.setting.value === true
        enabled: !root.busy
        anchors.verticalCenter: parent.verticalCenter
        onToggled: value => root.vm.setSetting(root.setting.path, [value ? "true" : "false"])
    }

    Select {
        visible: root.setting.kind === "enum"
        width: root.below ? Math.min(parent.width, 260) : 200
        enabled: !root.busy
        readonly property string defaultLabel: I18n.tr("Default")
        currentValue: root.setting.value === null ? defaultLabel : String(root.setting.value)
        options: (root.setting.nullable ? [defaultLabel] : []).concat(root.setting.choices || [])
        anchors.verticalCenter: parent.verticalCenter
        onValueChanged: value => {
            if (value === defaultLabel) {
                if (root.setting.value !== null)
                    root.vm.resetSetting(root.setting.path);
            } else if (value !== String(root.setting.value)) {
                root.vm.setSetting(root.setting.path, [value]);
            }
        }
    }

    Field {
        visible: root.isText
        width: root.setting.kind === "int" ? 96 : (root.below ? Math.min(parent.width, 320) : 220)
        text: root.valueText
        placeholderText: root.isList
            ? (root.setting.choices ? root.setting.choices.join(" ") : I18n.tr("space-separated"))
            : (root.setting.nullable ? I18n.tr("Default") : "")
        enabled: !root.busy
        anchors.verticalCenter: parent.verticalCenter
        onEditingFinished: root.commitText(text)
    }
}
