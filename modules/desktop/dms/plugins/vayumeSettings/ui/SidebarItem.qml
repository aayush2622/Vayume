import QtQuick
import qs.Common
import qs.Widgets
import "components"

Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool active: false
    property int badgeCount: 0
    property string badgeTone: "neutral"

    signal activated

    width: parent ? parent.width : 220
    height: 42

    activeFocusOnTab: true
    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: root.active ? Vayori.selected : (area.containsMouse ? Vayori.hover : "transparent")

        Behavior on color { ColorAnimation { duration: Vayori.fast } }

        FocusRing { target: root }
    }

    DankIcon {
        id: glyph
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 22
        filled: root.active
        color: root.active ? Vayori.ink : Vayori.inkMuted
    }

    StyledText {
        anchors.left: glyph.right
        anchors.leftMargin: 16
        anchors.right: countPill.visible ? countPill.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: Vayori.title
        font.weight: root.active ? Font.DemiBold : Font.Medium
        color: root.active ? Vayori.ink : Vayori.inkMuted
        wrapMode: Text.NoWrap
    }

    Badge {
        id: countPill
        visible: root.badgeCount > 0
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        label: String(root.badgeCount)
        tone: root.badgeTone
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
