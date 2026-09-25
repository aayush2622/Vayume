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

    implicitWidth: 52
    implicitHeight: 32
    opacity: root.enabled ? 1 : 0.4

    activeFocusOnTab: root.enabled
    Keys.onSpacePressed: root.flip()
    Keys.onReturnPressed: root.flip()
    Keys.onEnterPressed: root.flip()

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline

        Behavior on color { ColorAnimation { duration: Vayori.fast } }

        FocusRing { target: root }
    }

    Rectangle {
        readonly property real size: root.checked || area.pressed ? 24 : 16
        width: size
        height: size
        radius: size / 2
        x: root.checked ? root.width - width - 4 : 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.onPrimary : Theme.outline

        Behavior on x { NumberAnimation { duration: Vayori.normal; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Vayori.fast } }
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
