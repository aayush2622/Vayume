import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string meta: ""
    property bool collapsible: false
    property bool collapsed: false
    default property alias content: contentColumn.data
    property alias actions: actionRow.data

    readonly property bool hasHeader: root.title.length > 0
    readonly property bool open: !root.collapsible || !root.collapsed

    function toggle() {
        if (root.collapsible)
            root.collapsed = !root.collapsed;
    }

    width: parent ? parent.width : 400
    implicitHeight: header.height + (root.open ? contentColumn.implicitHeight + (root.hasHeader ? 4 : 0) : 0)
    height: implicitHeight
    radius: Vayori.radius
    color: Vayori.panel
    border.width: 1
    border.color: Vayori.hairline

    Item {
        id: header
        width: parent.width
        height: root.hasHeader ? headerText.height + 32 : 0
        visible: root.hasHeader

        activeFocusOnTab: root.collapsible
        Keys.onSpacePressed: root.toggle()
        Keys.onReturnPressed: root.toggle()
        Keys.onEnterPressed: root.toggle()

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Vayori.radius
            color: headerArea.containsMouse ? Vayori.hover : "transparent"
            border.width: header.activeFocus ? 1 : 0
            border.color: Vayori.focus
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            enabled: root.collapsible
            hoverEnabled: root.collapsible
            cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.toggle()
        }

        Column {
            id: headerText
            x: Vayori.pad
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Vayori.pad * 2 - trailing.width - 16
            spacing: 4

            StyledText {
                text: root.title
                width: parent.width
                font.pixelSize: Vayori.section
                font.weight: Font.Medium
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Vayori.trackWide
                color: Vayori.ink
                wrapMode: Text.NoWrap
            }

            StyledText {
                visible: root.subtitle.length > 0
                text: root.subtitle
                width: parent.width
                font.pixelSize: Vayori.body
                color: Vayori.inkFaint
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }
        }

        Row {
            id: trailing
            anchors.right: parent.right
            anchors.rightMargin: Vayori.pad - 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Row {
                id: actionRow
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.meta.length > 0
                text: root.meta
                isMonospace: true
                font.pixelSize: Vayori.micro
                font.letterSpacing: 0.6
                color: Vayori.inkFaint
                wrapMode: Text.NoWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                visible: root.collapsible
                name: root.collapsed ? "add" : "remove"
                size: 14
                color: headerArea.containsMouse ? Vayori.ink : Vayori.inkFaint
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                visible: !root.collapsible
                width: 4
                height: 1
            }
        }
    }

    Column {
        id: contentColumn
        x: Vayori.pad
        y: root.hasHeader ? header.height : -1
        width: parent.width - Vayori.pad * 2
        visible: root.open
        spacing: 0
    }
}
