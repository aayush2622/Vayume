pragma Singleton

import QtQuick
import qs.Common

QtObject {
    readonly property real radius: 4
    readonly property real radiusSmall: 2

    readonly property real pad: 20
    readonly property real gap: 20
    readonly property real rowPad: 12
    readonly property real controlHeight: 30
    readonly property real sidebarWidth: 236
    readonly property real contentMaxWidth: 940

    readonly property color base: Theme.withAlpha(Theme.surface, Theme.floatingWindowTransparency)
    readonly property color panel: Theme.withAlpha(Theme.surfaceContainerLow, Theme.isLightMode ? 0.7 : 0.55)
    readonly property color well: Theme.withAlpha(Theme.surfaceContainerLowest, Theme.isLightMode ? 0.9 : 0.7)
    readonly property color field: Theme.withAlpha(Theme.surfaceContainer, Theme.isLightMode ? 0.9 : 0.6)

    readonly property color ink: Theme.surfaceText
    readonly property color inkMuted: Theme.surfaceVariantText
    readonly property color inkFaint: Theme.withAlpha(Theme.surfaceVariantText, 0.66)
    readonly property color inkGhost: Theme.withAlpha(Theme.surfaceVariantText, 0.4)

    readonly property color hairline: Theme.withAlpha(Theme.outline, Theme.isLightMode ? 0.3 : 0.24)
    readonly property color divider: Theme.withAlpha(Theme.outline, Theme.isLightMode ? 0.18 : 0.13)
    readonly property color lineStrong: Theme.withAlpha(Theme.outline, 0.55)

    readonly property color hover: Theme.withAlpha(Theme.surfaceText, 0.035)
    readonly property color pressed: Theme.withAlpha(Theme.surfaceText, 0.07)
    readonly property color selected: Theme.withAlpha(Theme.surfaceText, 0.065)

    readonly property color accent: Theme.primary
    readonly property color accentSoft: Theme.withAlpha(Theme.primary, 0.14)
    readonly property color accentLine: Theme.withAlpha(Theme.primary, 0.6)
    readonly property color focus: Theme.withAlpha(Theme.primary, 0.85)

    readonly property string jp: "Noto Sans CJK JP"
    readonly property string jpSerif: "Noto Serif CJK JP"

    readonly property real display: Math.round(Theme.fontSizeXLarge * 1.7)
    readonly property real title: Theme.fontSizeMedium
    readonly property real section: Theme.fontSizeSmall + 1
    readonly property real body: Theme.fontSizeSmall
    readonly property real caption: Math.max(9, Theme.fontSizeSmall - 1)
    readonly property real micro: Math.max(8, Theme.fontSizeSmall - 2)

    readonly property real trackWide: 1.8
    readonly property real track: 1.1

    readonly property int fast: 110
    readonly property int normal: 170

    function tone(name) {
        switch (name) {
        case "warning": return Theme.warning;
        case "error": return Theme.error;
        case "success": return Theme.success;
        case "info": return Theme.primary;
        default: return inkFaint;
        }
    }
}
