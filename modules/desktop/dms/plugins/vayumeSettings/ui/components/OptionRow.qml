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
    readonly property string defaultLabel: I18n.tr("Default")
    readonly property var enumOptions: setting.kind === "enum" ? (setting.nullable ? [root.defaultLabel] : []).concat(setting.choices || []) : []
    readonly property bool segmented: root.enumOptions.length > 0 && root.enumOptions.length <= 3 && root.enumOptions.every(o => String(o).length <= 14)
    readonly property string enumValue: setting.value === null ? root.defaultLabel : String(setting.value)

    function pickEnum(value) {
        if (value === root.defaultLabel) {
            if (root.setting.value !== null)
                root.vm.resetSetting(root.setting.path);
        } else if (value !== String(root.setting.value)) {
            root.vm.setSetting(root.setting.path, [value]);
        }
    }

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
        variant: "ghost"
        icon: "undo"
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

    Segmented {
        visible: root.segmented
        enabled: !root.busy
        options: root.segmented ? root.enumOptions : []
        current: root.enumValue
        anchors.verticalCenter: parent.verticalCenter
        onPicked: value => root.pickEnum(value)
    }

    Select {
        visible: root.setting.kind === "enum" && !root.segmented
        width: root.below ? Math.min(parent.width, 280) : 220
        enabled: !root.busy
        currentValue: root.enumValue
        options: root.segmented ? [] : root.enumOptions
        anchors.verticalCenter: parent.verticalCenter
        onValueChanged: value => root.pickEnum(value)
    }

    Field {
        visible: root.isText
        width: root.setting.kind === "int" ? 100 : (root.below ? Math.min(parent.width, 340) : 240)
        text: root.valueText
        placeholderText: root.isList
            ? (root.setting.choices ? root.setting.choices.join(" ") : I18n.tr("space-separated"))
            : (root.setting.nullable ? I18n.tr("Default") : "")
        enabled: !root.busy
        anchors.verticalCenter: parent.verticalCenter
        onEditingFinished: root.commitText(text)
    }
}
