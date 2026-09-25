import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property string meta: root.vm.themeLoading ? I18n.tr("reading theme...") : I18n.tr("changes apply on rebuild")

    Section {
        title: I18n.tr("Font")
        meta: root.vm.themePending ? I18n.tr("saving...") : ""

        SettingItem {
            title: I18n.tr("Size")
            description: I18n.tr("UI/monospace size, in points.")

            Row {
                spacing: 6

                TextButton {
                    icon: "remove"
                    implicitHeight: 32
                    enabled: !root.vm.themeLoading && root.vm.theme.fontSize > 8
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.vm.setFontSize(-1)
                }

                Row {
                    width: 58
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        width: 28
                        text: root.vm.themeLoading ? "··" : String(root.vm.theme.fontSize)
                        font.pixelSize: Vayori.title + 2
                        font.weight: Font.Medium
                        color: root.vm.themeLoading ? Vayori.inkFaint : Vayori.ink
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.NoWrap
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "pt"
                        font.pixelSize: Vayori.micro
                        color: Vayori.inkFaint
                        wrapMode: Text.NoWrap
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                TextButton {
                    icon: "add"
                    implicitHeight: 32
                    enabled: !root.vm.themeLoading && root.vm.theme.fontSize < 24
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.vm.setFontSize(1)
                }
            }
        }

        SettingItem {
            title: I18n.tr("Family")
            description: root.vm.themeLoading
                ? I18n.tr("Loading available families...")
                : I18n.tr("Every family the current fontPackage actually ships.")

            Select {
                width: 260
                enabled: !root.vm.themeLoading
                currentValue: root.vm.theme.font
                options: root.vm.theme.fontOptions
                enableFuzzySearch: root.vm.theme.fontOptions.length > 8
                emptyText: I18n.tr("Loading...")
                onValueChanged: value => root.vm.setFont(value)
            }
        }
    }

    Section {
        title: I18n.tr("Cursor")

        SettingItem {
            title: I18n.tr("Cursor Theme")
            description: root.vm.themeLoading
                ? I18n.tr("Loading available cursor themes...")
                : I18n.tr("Every theme the current cursorPackage actually ships.")

            Select {
                width: 260
                enabled: !root.vm.themeLoading
                currentValue: root.vm.theme.cursorTheme
                options: root.vm.theme.cursorOptions
                enableFuzzySearch: root.vm.theme.cursorOptions.length > 8
                emptyText: I18n.tr("Loading...")
                onValueChanged: value => root.vm.setCursorTheme(value)
            }
        }
    }

    Notice {
        text: root.vm.themeStatus
        tone: root.vm.themeError ? "error" : "neutral"
    }

    Section {
        title: I18n.tr("Elsewhere")

        Notice {
            text: I18n.tr("Dark/light mode, wallpaper, and Material You colors are DMS's own settings, not Vayume's - find those in DMS Settings directly.")
        }

        Notice {
            text: I18n.tr("Icon theme, and the font/cursor/icon packages themselves, stay Nix-only: a package can't be safely produced from a text field, and a mismatched name/package pair would silently fail to resolve at runtime instead of erroring at build time. See docs/core-vayume-config.md.")
        }
    }
}
