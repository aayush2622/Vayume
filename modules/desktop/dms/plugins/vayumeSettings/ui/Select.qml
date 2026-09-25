import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string currentValue: ""
    property var options: []
    property bool enableFuzzySearch: false
    property string emptyText: ""

    signal valueChanged(string value)

    function open() {
        if (root.enabled)
            picker.openDropdownMenu();
    }

    implicitWidth: 240
    implicitHeight: Vayori.controlHeight
    radius: Vayori.radius
    opacity: root.enabled ? 1 : 0.5
    color: area.containsMouse || picker.menuOpen ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.8) : Vayori.field
    border.width: 1
    border.color: picker.menuOpen ? Vayori.focus : (area.containsMouse ? Vayori.lineStrong : Vayori.hairline)

    activeFocusOnTab: root.enabled

    FocusRing {}
    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Down:
            if (root.enabled)
                picker.showDropdownMenu();
            event.accepted = true;
            break;
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: countText.visible ? countText.left : chevron.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentValue.length > 0 ? root.currentValue : root.emptyText
        font.pixelSize: Vayori.body + 1
        color: root.currentValue.length > 0 ? Vayori.ink : Vayori.inkGhost
        wrapMode: Text.NoWrap
    }

    StyledText {
        id: countText
        visible: root.options.length > 8 && root.width > 180
        anchors.right: chevron.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.options.length)
        isMonospace: true
        font.pixelSize: Vayori.micro
        color: Vayori.inkGhost
        wrapMode: Text.NoWrap
    }

    DankIcon {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        name: picker.menuOpen ? "expand_less" : "expand_more"
        size: 16
        color: Vayori.inkFaint
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open()
    }

    DankDropdown {
        id: picker
        showTrigger: false
        popupAnchorItem: root
        popupWidth: Math.max(root.width, 200)
        currentValue: root.currentValue
        options: root.options
        enableFuzzySearch: root.enableFuzzySearch
        emptyText: root.emptyText
        onValueChanged: value => {
            root.valueChanged(value);
            picker.currentValue = Qt.binding(() => root.currentValue);
        }
    }
}
