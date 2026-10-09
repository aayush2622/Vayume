pragma Singleton

import QtQuick
import qs.Common

QtObject {
    readonly property real radius: 16
    readonly property real radiusSmall: 10
    readonly property real radiusLarge: 24

    readonly property real pad: 20
    readonly property real gap: 28
    readonly property real cardGap: 4
    readonly property real rowPad: 16
    readonly property real controlHeight: 36
    readonly property real sidebarWidth: 256
    readonly property real contentMaxWidth: 980

    readonly property color base: Theme.withAlpha(Theme.surfaceContainer, Theme.floatingWindowTransparency)
    readonly property color canvas: Theme.withAlpha(Theme.surface, Theme.isLightMode ? 0.55 : 0.5)
    readonly property color card: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.isLightMode ? 0.95 : 0.85)
    readonly property color cardHover: Theme.withAlpha(Theme.surfaceContainerHighest, Theme.isLightMode ? 0.95 : 0.9)
    readonly property color field: Theme.surfaceContainerHighest

    readonly property color ink: Theme.surfaceText
    readonly property color inkMuted: Theme.surfaceVariantText
    readonly property color inkFaint: Theme.withAlpha(Theme.surfaceVariantText, 0.72)
    readonly property color inkGhost: Theme.withAlpha(Theme.surfaceVariantText, 0.45)

    readonly property color divider: Theme.withAlpha(Theme.outline, Theme.isLightMode ? 0.2 : 0.16)

    readonly property color hover: Theme.withAlpha(Theme.surfaceText, 0.06)
    readonly property color selected: Theme.secondaryContainer
    readonly property color chosen: Theme.primaryContainer
    readonly property color tonal: Theme.withAlpha(Theme.secondaryContainer, 0.85)

    readonly property color accent: Theme.primary
    readonly property color focus: Theme.primary

    readonly property string jpSerif: "Noto Serif CJK JP"

    readonly property real display: Math.round(Theme.fontSizeXLarge * 1.3)
    readonly property real title: Theme.fontSizeMedium
    readonly property real section: Theme.fontSizeMedium
    readonly property real body: Theme.fontSizeSmall
    readonly property real micro: Math.max(9, Theme.fontSizeSmall - 1)

    readonly property int fast: 120
    readonly property int normal: 180

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
