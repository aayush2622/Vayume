import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string variant: "outline"
    property bool busy: false

    signal clicked

    readonly property bool live: root.enabled && !root.busy
    readonly property bool iconOnly: root.text.length === 0
    readonly property color toneColor: {
        switch (root.variant) {
        case "primary": return Vayori.accent;
        case "danger": return Theme.error;
        case "warning": return Theme.warning;
        default: return Vayori.ink;
        }
    }
    readonly property bool tinted: root.variant !== "outline" && root.variant !== "ghost"

    function trigger() {
        if (root.live)
            root.clicked();
    }

    implicitWidth: root.iconOnly ? implicitHeight : Math.max(64, content.implicitWidth + 26)
    implicitHeight: Vayori.controlHeight
    radius: Vayori.radius
    opacity: root.enabled ? 1 : 0.4
    color: {
        if (!root.live)
            return "transparent";
        if (root.tinted)
            return Theme.withAlpha(root.toneColor, area.pressed ? 0.3 : (area.containsMouse ? 0.22 : 0.13));
        return area.pressed ? Vayori.pressed : (area.containsMouse ? Vayori.hover : "transparent");
    }
    border.width: root.variant === "ghost" ? 0 : 1
    border.color: {
        if (root.tinted)
            return Theme.withAlpha(root.toneColor, root.live ? 0.55 : 0.3);
        return area.containsMouse && root.live ? Vayori.lineStrong : Vayori.hairline;
    }

    activeFocusOnTab: root.enabled
    Keys.onSpacePressed: root.trigger()
    Keys.onReturnPressed: root.trigger()
    Keys.onEnterPressed: root.trigger()

    Behavior on color { ColorAnimation { duration: Vayori.fast } }

    FocusRing {}

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        DankIcon {
            visible: root.icon.length > 0
            name: root.icon
            size: 14
            color: root.live ? root.toneColor : Vayori.inkFaint
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            visible: !root.iconOnly
            text: root.text
            font.pixelSize: Vayori.caption
            font.weight: Font.Medium
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Vayori.track
            color: root.live ? root.toneColor : Vayori.inkFaint
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.live
        cursorShape: Qt.PointingHandCursor
        onClicked: root.trigger()
    }
}
