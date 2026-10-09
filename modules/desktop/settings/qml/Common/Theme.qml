pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.DankCommon.Common

Singleton {
    id: root

    property bool isLightMode: false

    property color primary: "#D0BCFF"
    property color primaryText: "#381E72"
    property color primaryContainer: "#4F378B"
    property color secondary: "#CCC2DC"
    property color surface: "#141218"
    property color surfaceText: "#E6E0E9"
    property color surfaceVariant: "#49454F"
    property color surfaceVariantText: "#CAC4D0"
    property color background: "#141218"
    property color outline: "#938F99"
    property color surfaceContainer: "#211F26"
    property color surfaceContainerHigh: "#2B2930"
    property color error: "#F2B8B5"
    property color surfaceContainerHighest: "#36343B"
    property color surfaceContainerLowest: "#0F0D13"
    property color secondaryContainer: "#4A4458"
    property color success: "#81C784"

    property color warning: "#FF9800"

    property color onPrimary: primaryText
    property color onSurface: surfaceText
    property color onSurface_12: withAlpha(onSurface, 0.12)
    property color onSurface_38: withAlpha(onSurface, 0.38)
    property color surfaceTint: primary
    property color surfaceLight: withAlpha(surfaceVariant, 0.1)

    property color primaryHover: withAlpha(primary, 0.12)
    property color primaryHoverLight: withAlpha(primary, 0.08)
    property color primaryPressed: withAlpha(primary, 0.16)
    property color primarySelected: withAlpha(primary, 0.3)
    property color errorHover: withAlpha(error, 0.12)
    property color errorSelected: withAlpha(error, 0.3)
    property color surfaceHover: withAlpha(surfaceVariant, 0.08)
    property color surfacePressed: withAlpha(surfaceVariant, 0.12)
    property color surfaceVariantAlpha: withAlpha(surfaceVariant, 0.2)
    property color surfaceTextHover: withAlpha(surfaceText, 0.08)
    property color surfaceTextMedium: withAlpha(surfaceText, 0.7)
    property color surfaceTextSecondary: withAlpha(surfaceText, 0.6)
    property color outlineButton: withAlpha(outline, 0.5)
    property color outlineMedium: withAlpha(outline, 0.12)
    property color outlineStrong: withAlpha(outline, 0.18)
    property color outlineHeavy: withAlpha(outline, 0.2)
    property color shadowStrong: Qt.rgba(0, 0, 0, 0.3)

    property color buttonBg: primary
    property color buttonText: primaryText
    property color buttonHover: primaryHover
    property color buttonPressed: withAlpha(primary, 0.16)

    property real popupTransparency: 1.0
    readonly property color floatingSurface: withAlpha(surfaceContainer, popupTransparency)
    readonly property color nestedSurface: withAlpha(surfaceContainerHigh, popupTransparency)

    property real floatingWindowTransparency: popupTransparency
    property color floatingWindowSurface: withAlpha(surfaceContainer, floatingWindowTransparency)
    property color floatingWindowNestedSurface: nestedSurface
    property color floatingWindowFieldColor: withAlpha(surfaceContainerHigh, floatingWindowTransparency)
    property color floatingWindowFieldBorderColor: withAlpha(outline, 0.16)
    property color floatingWindowFieldFocusedBorderColor: primary
    property color popupFieldColor: withAlpha(surfaceContainerHigh, popupTransparency)
    property color popupFieldBorderColor: withAlpha(outline, 0.16)
    property color popupFieldFocusedBorderColor: primary
    property bool blurLayersActive: true

    property color widgetBaseHoverColor: {
        const blended = blend(surfaceContainerHigh, primary, 0.1);
        return withAlpha(blended, Math.max(0.3, blended.a));
    }

    property real spacingXXS: 2
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    property real spacingL: 16
    property real spacingXL: 24

    property real fontSizeSmall: 12
    property real fontSizeMedium: 14
    property real fontSizeLarge: 16
    property real fontSizeXLarge: 20

    property real iconSizeSmall: 16
    property real iconSize: 24
    property real iconSizeLarge: 32

    property real cornerRadius: 12

    readonly property string defaultFontFamily: Fonts.sans
    readonly property string defaultMonoFontFamily: Fonts.mono
    property string fontFamily: defaultFontFamily
    property string monoFontFamily: defaultMonoFontFamily
    property int fontWeight: Font.Normal

    property int shorterDuration: 100
    property int shortDuration: 200
    property int mediumDuration: 350
    property int standardEasing: Easing.OutCubic
    property int emphasizedEasing: Easing.OutQuart

    readonly property int currentAnimationSpeed: SettingsData.animationSpeed
    readonly property int currentAnimationBaseDuration: 500
    readonly property bool elevationEnabled: true

    readonly property var elevationLevel2: ({
            blurPx: 8,
            offsetX: 4,
            offsetY: 4,
            spreadPx: 0,
            alpha: 0.25
        })

    readonly property var expressiveCurves: ({
            "emphasized": [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1],
            "emphasizedAccel": [0.3, 0, 0.8, 0.15, 1, 1],
            "emphasizedDecel": [0.05, 0.7, 0.1, 1, 1, 1],
            "standard": [0.2, 0, 0, 1, 1, 1],
            "standardAccel": [0.3, 0, 1, 1, 1, 1],
            "standardDecel": [0, 0, 0, 1, 1, 1],
            "expressiveFastSpatial": [0.42, 1.67, 0.21, 0.9, 1, 1],
            "expressiveDefaultSpatial": [0.38, 1.21, 0.22, 1, 1, 1],
            "expressiveEffects": [0.34, 0.8, 0.34, 1, 1, 1]
        })

    readonly property var expressiveDurations: ({
            "fast": 200,
            "normal": 400,
            "large": 600,
            "extraLarge": 1000,
            "expressiveFastSpatial": 350,
            "expressiveDefaultSpatial": 500,
            "expressiveEffects": 200
        })

    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/vayume/colors.json"

    function applyColors(raw) {
        let c;
        try {
            c = JSON.parse(raw);
        } catch (e) {
            return;
        }
        const map = {
            primary: "primary",
            primaryText: "onPrimary",
            primaryContainer: "primaryContainer",
            secondary: "secondary",
            secondaryContainer: "secondaryContainer",
            surface: "surface",
            surfaceText: "onSurface",
            surfaceVariant: "surfaceVariant",
            surfaceVariantText: "onSurfaceVariant",
            background: "background",
            outline: "outline",
            surfaceContainer: "surfaceContainer",
            surfaceContainerHigh: "surfaceContainerHigh",
            surfaceContainerHighest: "surfaceContainerHighest",
            surfaceContainerLowest: "surfaceContainerLowest",
            error: "error"
        };
        for (const key in map) {
            if (c[map[key]])
                root[key] = c[map[key]];
        }
        root.isLightMode = c.mode === "light";
    }

    FileView {
        path: root.colorsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyColors(text())
    }

    function withAlpha(c, a) {
        if (!c || c.r === undefined)
            return Qt.rgba(0, 0, 0, 0);
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function blendAlpha(c, a) {
        if (!c || c.r === undefined)
            return Qt.rgba(0, 0, 0, 0);
        return Qt.rgba(c.r, c.g, c.b, c.a * a);
    }

    function blend(c1, c2, r) {
        return Qt.rgba(c1.r * (1 - r) + c2.r * r, c1.g * (1 - r) + c2.g * r, c1.b * (1 - r) + c2.b * r, c1.a * (1 - r) + c2.a * r);
    }
}
