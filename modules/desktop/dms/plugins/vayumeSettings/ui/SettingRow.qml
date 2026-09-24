import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var vm
    required property var setting

    readonly property bool isBool: setting.kind === "bool"
    readonly property bool isList: setting.kind === "list"
    readonly property bool isText: setting.kind === "int" || setting.kind === "str" || setting.kind === "list"
    readonly property string iconName: {
        if (setting.icon)
            return setting.icon;
        switch (setting.kind) {
        case "bool": return "toggle_on";
        case "enum": return "list";
        case "int": return "pin";
        case "list": return "format_list_bulleted";
        default: return "text_fields";
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

    width: parent ? parent.width : 400
    implicitHeight: content.implicitHeight + Theme.spacingS * 2
    height: implicitHeight
    radius: Theme.cornerRadius
    color: hover.hovered ? Theme.surfaceContainerHigh : "transparent"

    HoverHandler { id: hover }

    Rectangle {
        visible: root.setting.pending
        width: 3
        height: parent.height - Theme.spacingS * 2
        radius: 1.5
        color: Theme.warning
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingM

        Rectangle {
            id: chip
            width: 36
            height: 36
            radius: Theme.cornerRadius
            color: root.setting.pending ? Theme.withAlpha(Theme.warning, 0.15) : Theme.primaryHoverLight
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: 20
                color: root.setting.pending ? Theme.warning : Theme.primary
            }
        }

        Column {
            id: textColumn
            width: parent.width - chip.width - controls.width - Theme.spacingM * 2
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: Theme.spacingS

                StyledText {
                    text: root.setting.label
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Badge {
                    visible: root.setting.pending
                    label: I18n.tr("Pending rebuild")
                    tone: "warning"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Badge {
                    visible: root.setting.configured && !root.setting.pending
                    label: I18n.tr("Customized")
                    tone: "info"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                visible: root.setting.description.length > 0
                text: root.setting.description
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            StyledText {
                visible: root.setting.pending
                text: I18n.tr("Running now: %1").arg(root.show(root.setting.applied))
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.warning
                wrapMode: Text.WordWrap
                width: parent.width
            }

            StyledText {
                visible: root.setting.unparsed
                text: I18n.tr("Set by a multi-line expression in _config.nix - edit it there.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Row {
            id: controls
            spacing: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter

            DankToggle {
                visible: root.isBool
                hideText: true
                checked: root.setting.value === true
                enabled: !root.vm.settingsSaving
                anchors.verticalCenter: parent.verticalCenter
                onToggled: isChecked => root.vm.setSetting(root.setting.path, [isChecked ? "true" : "false"])
            }

            DankDropdown {
                visible: root.setting.kind === "enum"
                width: 190
                popupWidth: 190
                enabled: !root.vm.settingsSaving
                readonly property string defaultLabel: I18n.tr("Default")
                currentValue: root.setting.value === null ? defaultLabel : String(root.setting.value)
                options: (root.setting.nullable ? [defaultLabel] : []).concat(root.setting.choices || [])
                anchors.verticalCenter: parent.verticalCenter
                onValueChanged: newValue => {
                    if (newValue === defaultLabel) {
                        if (root.setting.value !== null)
                            root.vm.resetSetting(root.setting.path);
                    } else if (newValue !== String(root.setting.value)) {
                        root.vm.setSetting(root.setting.path, [newValue]);
                    }
                }
            }

            DankTextField {
                visible: root.isText
                width: root.setting.kind === "int" ? 100 : 230
                text: root.valueText
                placeholderText: root.isList
                    ? (root.setting.choices ? root.setting.choices.join(" ") : I18n.tr("space-separated"))
                    : (root.setting.nullable ? I18n.tr("Default") : "")
                enabled: !root.vm.settingsSaving
                anchors.verticalCenter: parent.verticalCenter
                onEditingFinished: root.commitText(text)
            }

            Rectangle {
                id: resetButton
                visible: root.setting.configured
                width: 32
                height: 32
                radius: Theme.cornerRadius
                color: resetArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: "undo"
                    size: 18
                    color: Theme.surfaceVariantText
                }

                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.vm.settingsSaving
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.vm.resetSetting(root.setting.path)
                }
            }
        }
    }
}
