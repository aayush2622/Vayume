import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string label: ""
    property string jp: ""
    property bool active: false
    property int badgeCount: 0

    signal activated

    width: parent ? parent.width : 200
    height: 32

    activeFocusOnTab: true
    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    FocusRing {}

    Rectangle {
        anchors.fill: parent
        radius: Vayori.radius
        color: root.active ? Vayori.selected : (area.containsMouse ? Vayori.hover : "transparent")
        border.width: root.active ? 1 : 0
        border.color: Vayori.hairline

        Behavior on color { ColorAnimation { duration: Vayori.fast } }
    }

    StyledText {
        id: slashes
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "//"
        isMonospace: true
        font.pixelSize: Vayori.caption
        color: Vayori.accent
        opacity: root.active ? 1 : 0
        wrapMode: Text.NoWrap

        Behavior on opacity { NumberAnimation { duration: Vayori.fast } }
    }

    Row {
        x: root.active ? 30 : 14
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - jpText.width - 20
        spacing: 7

        Behavior on x { NumberAnimation { duration: Vayori.normal; easing.type: Easing.OutCubic } }

        StyledText {
            id: labelText
            text: root.label
            width: Math.min(implicitWidth, parent.width - (countText.visible ? countText.width + parent.spacing : 0))
            font.pixelSize: Vayori.title - 1
            color: root.active ? Vayori.ink : (area.containsMouse ? Vayori.ink : Vayori.inkMuted)
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: countText
            visible: root.badgeCount > 0
            text: String(root.badgeCount).padStart(2, "0")
            isMonospace: true
            font.pixelSize: Vayori.micro
            color: root.active ? Vayori.inkFaint : Vayori.inkGhost
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    StyledText {
        id: jpText
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.jp
        font.family: Vayori.jp
        font.pixelSize: Vayori.caption
        color: root.active ? Vayori.inkMuted : Vayori.inkGhost
        wrapMode: Text.NoWrap
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
