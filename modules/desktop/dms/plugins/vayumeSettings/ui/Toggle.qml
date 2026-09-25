import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    function flip() {
        if (root.enabled)
            root.toggled(!root.checked);
    }

    implicitWidth: 36
    implicitHeight: 20
    opacity: root.enabled ? 1 : 0.4

    activeFocusOnTab: root.enabled
    Keys.onSpacePressed: root.flip()
    Keys.onReturnPressed: root.flip()
    Keys.onEnterPressed: root.flip()

    FocusRing {}

    Rectangle {
        anchors.fill: parent
        radius: Vayori.radius - 1
        color: root.checked ? Vayori.accentSoft : (area.containsMouse ? Vayori.hover : "transparent")
        border.width: 1
        border.color: (root.checked ? Vayori.accentLine : (area.containsMouse ? Vayori.lineStrong : Vayori.hairline))

        Behavior on color { ColorAnimation { duration: Vayori.fast } }
    }

    Rectangle {
        width: 10
        height: 10
        radius: 1.5
        x: root.checked ? root.width - width - 5 : 5
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Vayori.accent : Vayori.inkFaint

        Behavior on x { NumberAnimation { duration: Vayori.normal; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.flip()
    }
}
