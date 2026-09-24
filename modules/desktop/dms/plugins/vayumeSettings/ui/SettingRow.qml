import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property var vm
    required property var setting

    width: parent ? parent.width : 400
    readonly property bool isBool: setting.kind === "bool"
    implicitHeight: (root.isBool ? boolRow.implicitHeight : rowLayout.implicitHeight) + Theme.spacingS
    height: implicitHeight

    readonly property bool isList: setting.kind === "list"
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

    Row {
        id: boolRow
        visible: root.isBool
        width: parent.width
        spacing: Theme.spacingS

        DankToggle {
            width: parent.width - (root.setting.configured ? resetBool.width + Theme.spacingS : 0)
            text: root.setting.label
            description: root.setting.description
            checked: root.setting.value === true
            enabled: !root.vm.settingsSaving
            onToggled: isChecked => root.vm.setSetting(root.setting.path, [isChecked ? "true" : "false"])
        }

        StyledRect {
            id: resetBool
            visible: root.setting.configured
            width: 64
            height: 32
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerLow
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                anchors.centerIn: parent
                text: I18n.tr("Reset")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.vm.settingsSaving
                cursorShape: Qt.PointingHandCursor
                onClicked: root.vm.resetSetting(root.setting.path)
            }
        }
    }

    Row {
        id: rowLayout
        visible: !root.isBool
        width: parent.width
        spacing: Theme.spacingS

        Column {
            width: parent.width - controlBox.width - Theme.spacingS
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: Theme.spacingS
                StyledText {
                    text: root.setting.label
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }
                Badge {
                    visible: root.setting.configured
                    label: I18n.tr("Set in _config.nix")
                    tone: "info"
                }
                Badge { label: I18n.tr("Rebuild required"); tone: "warning" }
            }

            StyledText {
                visible: root.setting.description.length > 0
                text: root.setting.description
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Row {
            id: controlBox
            spacing: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter

            DankDropdown {
                visible: root.setting.kind === "enum"
                width: 200
                popupWidth: 200
                enabled: !root.vm.settingsSaving
                readonly property string defaultLabel: I18n.tr("Default")
                currentValue: root.setting.value === null ? defaultLabel : String(root.setting.value)
                options: (root.setting.nullable ? [defaultLabel] : []).concat(root.setting.choices || [])
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
                visible: root.setting.kind === "int" || root.setting.kind === "str" || root.isList
                width: root.setting.kind === "int" ? 100 : 240
                text: root.valueText
                placeholderText: root.isList
                    ? (root.setting.choices ? root.setting.choices.join(" ") : I18n.tr("space-separated"))
                    : (root.setting.nullable ? I18n.tr("Default") : "")
                enabled: !root.vm.settingsSaving
                onEditingFinished: root.commitText(text)
            }

            StyledRect {
                id: resetButton
                visible: root.setting.configured
                width: 64
                height: 32
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerLow
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    anchors.centerIn: parent
                    text: I18n.tr("Reset")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.vm.settingsSaving
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.vm.resetSetting(root.setting.path)
                }
            }
        }
    }
}
