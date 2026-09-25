import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string variant: "tonal"
    property bool busy: false

    signal clicked

    readonly property bool live: root.enabled && !root.busy
    readonly property bool iconOnly: root.text.length === 0
    readonly property color fill: {
        switch (root.variant) {
        case "primary": return Theme.primary;
        case "danger": return Theme.withAlpha(Theme.error, 0.16);
        case "warning": return Theme.withAlpha(Theme.warning, 0.18);
        case "ghost": return "transparent";
        default: return Vayori.tonal;
        }
    }
    readonly property color ink: {
        switch (root.variant) {
        case "primary": return Theme.onPrimary;
        case "danger": return Theme.error;
        case "warning": return Theme.warning;
        default: return Vayori.ink;
        }
    }

    function trigger() {
        if (root.live)
            root.clicked();
    }

    implicitWidth: root.iconOnly ? implicitHeight : Math.max(72, content.implicitWidth + 32)
    implicitHeight: Vayori.controlHeight
    radius: height / 2
    color: root.live ? root.fill : Theme.withAlpha(Vayori.ink, 0.08)
    opacity: root.enabled ? 1 : 0.6

    activeFocusOnTab: root.enabled
    Keys.onSpacePressed: root.trigger()
    Keys.onReturnPressed: root.trigger()
    Keys.onEnterPressed: root.trigger()

    FocusRing {}

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Vayori.ink
        opacity: area.pressed ? 0.12 : (area.containsMouse ? 0.07 : 0)

        Behavior on opacity { NumberAnimation { duration: Vayori.fast } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        DankIcon {
            visible: root.icon.length > 0
            name: root.icon
            size: 18
            color: root.live ? root.ink : Vayori.inkGhost
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            visible: !root.iconOnly
            text: root.text
            font.pixelSize: Vayori.body + 1
            font.weight: Font.Medium
            color: root.live ? root.ink : Vayori.inkGhost
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
