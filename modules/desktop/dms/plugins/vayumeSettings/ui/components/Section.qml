import QtQuick
import qs.Common
import qs.Widgets

Item {
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
    implicitHeight: header.height + (root.open ? contentColumn.implicitHeight : 0)
    height: implicitHeight

    Item {
        id: header
        width: parent.width
        height: root.hasHeader ? headerText.height + 18 : 0
        visible: root.hasHeader

        activeFocusOnTab: root.collapsible
        Keys.onSpacePressed: root.toggle()
        Keys.onReturnPressed: root.toggle()
        Keys.onEnterPressed: root.toggle()

        Rectangle {
            x: -8
            y: -4
            width: parent.width + 16
            height: parent.height - 6
            radius: Vayori.radiusSmall
            color: headerArea.containsMouse ? Vayori.hover : "transparent"
            border.width: header.activeFocus ? 2 : 0
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
            x: 20
            width: parent.width - 20 - trailing.width - 16
            spacing: 2

            StyledText {
                text: root.title
                width: parent.width
                font.pixelSize: Vayori.section
                font.weight: Font.DemiBold
                color: Vayori.accent
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
            anchors.rightMargin: 8
            y: 0
            spacing: 10

            Row {
                id: actionRow
                spacing: 8
            }

            StyledText {
                visible: root.meta.length > 0
                text: root.meta
                font.pixelSize: Vayori.micro
                color: Vayori.inkFaint
                wrapMode: Text.NoWrap
                height: 20
            }

            DankIcon {
                visible: root.collapsible
                name: root.collapsed ? "expand_more" : "expand_less"
                size: 20
                color: headerArea.containsMouse ? Vayori.ink : Vayori.inkMuted
            }
        }
    }

    Column {
        id: contentColumn
        y: header.height
        width: parent.width
        visible: root.open
        spacing: Vayori.cardGap
    }
}
