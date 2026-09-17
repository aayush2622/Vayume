import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    StyledText {
        text: I18n.tr("Appearance")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: I18n.tr("Font, cursor, and icon theme - the parts of Vayume's look shared by GTK, kitty, SDDM, and DMS itself. Dark/light mode, wallpaper, and Material You colors are DMS's own settings, not Vayume's - find those in DMS Settings directly.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }

    SettingsCard {
        title: I18n.tr("Font")
        icon: "text_fields"

        Row {
            width: parent.width
            spacing: Theme.spacingS

            Column {
                width: parent.width - fontSizeControl.width - Theme.spacingM
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    spacing: Theme.spacingS
                    StyledText {
                        text: I18n.tr("Size")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    Badge { label: I18n.tr("Rebuild required"); tone: "warning" }
                }
                StyledText {
                    text: I18n.tr("UI/monospace size, in points.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Row {
                id: fontSizeControl
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                DankIcon {
                    name: "remove"
                    size: 20
                    color: Theme.surfaceVariantText
                    opacity: root.vm.themeLoading ? 0.4 : 1
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.vm.themeLoading
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.vm.setFontSize(-1)
                    }
                }

                StyledText {
                    text: root.vm.themeLoading ? "..." : String(root.vm.theme.fontSize)
                    font.pixelSize: Theme.fontSizeMedium
                    color: root.vm.themeLoading ? Theme.surfaceVariantText : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    horizontalAlignment: Text.AlignHCenter
                }

                DankIcon {
                    name: "add"
                    size: 20
                    color: Theme.surfaceVariantText
                    opacity: root.vm.themeLoading ? 0.4 : 1
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.vm.themeLoading
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.vm.setFontSize(1)
                    }
                }

                StyledText {
                    visible: root.vm.themePending
                    text: I18n.tr("Saving...")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.2 }

        Row {
            width: parent.width
            spacing: Theme.spacingS

            Column {
                width: parent.width - 260
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    spacing: Theme.spacingS
                    StyledText {
                        text: I18n.tr("Family")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    Badge { label: I18n.tr("Rebuild required"); tone: "warning" }
                }
                StyledText {
                    text: root.vm.themeLoading
                        ? I18n.tr("Loading available families...")
                        : I18n.tr("Every family the current fontPackage actually ships.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            DankDropdown {
                width: 250
                popupWidth: 250
                anchors.verticalCenter: parent.verticalCenter
                enabled: !root.vm.themeLoading
                currentValue: root.vm.theme.font
                options: root.vm.theme.fontOptions
                enableFuzzySearch: root.vm.theme.fontOptions.length > 8
                emptyText: I18n.tr("Loading...")
                onValueChanged: newValue => root.vm.setFont(newValue)
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Cursor")
        icon: "arrow_selector_tool"

        Row {
            width: parent.width
            spacing: Theme.spacingS

            Column {
                width: parent.width - 260
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    spacing: Theme.spacingS
                    StyledText {
                        text: I18n.tr("Cursor Theme")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    Badge { label: I18n.tr("Rebuild required"); tone: "warning" }
                }
                StyledText {
                    text: root.vm.themeLoading
                        ? I18n.tr("Loading available cursor themes...")
                        : I18n.tr("Every theme the current cursorPackage actually ships.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            DankDropdown {
                width: 250
                popupWidth: 250
                anchors.verticalCenter: parent.verticalCenter
                enabled: !root.vm.themeLoading
                currentValue: root.vm.theme.cursorTheme
                options: root.vm.theme.cursorOptions
                enableFuzzySearch: root.vm.theme.cursorOptions.length > 8
                emptyText: I18n.tr("Loading...")
                onValueChanged: newValue => root.vm.setCursorTheme(newValue)
            }
        }
    }

    Row {
        width: parent.width
        visible: root.vm.themeStatus.length > 0
        StyledText {
            text: root.vm.themeStatus
            font.pixelSize: Theme.fontSizeSmall
            color: root.vm.themeError ? Theme.error : Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    SettingsCard {
        title: I18n.tr("Not editable here")
        icon: "info"

        StyledText {
            text: I18n.tr("Icon theme, and the font/cursor/icon packages themselves, stay Nix-only: a package can't be safely produced from a text field, and a mismatched name/package pair would silently fail to resolve at runtime instead of erroring at build time. See docs/core-vayume-config.md.")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }
}
