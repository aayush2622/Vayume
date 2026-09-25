import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string title: ""
    property string description: ""
    property string meta: ""
    property string marker: ""
    property bool divider: true
    property bool stacked: false
    property real controlGap: 24

    default property alias control: controlSlot.data
    property alias tags: tagRow.data
    property alias notes: noteColumn.data

    readonly property bool below: root.stacked || root.width < 540
    readonly property bool hasText: root.title.length > 0 || root.description.length > 0 || root.meta.length > 0
    readonly property real controlsWidth: controlSlot.implicitWidth

    width: parent ? parent.width : 400
    implicitHeight: body.height + Vayori.rowPad * 2

    HoverHandler { id: hover }

    Rectangle {
        visible: root.divider
        width: parent.width
        height: 1
        color: Vayori.divider
    }

    Rectangle {
        x: -10
        y: 1
        width: parent.width + 20
        height: parent.height - 1
        radius: Vayori.radiusSmall
        color: hover.hovered && root.enabled ? Vayori.hover : "transparent"
    }

    Rectangle {
        visible: root.marker.length > 0
        x: -Vayori.pad + 1
        y: Vayori.rowPad
        width: 2
        height: textColumn.height
        color: Vayori.tone(root.marker)
    }

    Item {
        id: body
        y: Vayori.rowPad
        width: parent.width
        height: root.below
            ? (root.hasText ? textColumn.height + (controlSlot.implicitHeight > 0 ? 10 : 0) : 0) + controlSlot.implicitHeight
            : Math.max(textColumn.height, controlSlot.implicitHeight)
        opacity: root.enabled ? 1 : 0.5

        Column {
            id: textColumn
            visible: root.hasText
            width: root.below ? parent.width : parent.width - root.controlsWidth - (root.controlsWidth > 0 ? root.controlGap : 0)
            height: root.hasText ? implicitHeight : 0
            anchors.verticalCenter: root.below ? undefined : parent.verticalCenter
            spacing: 3

            Flow {
                width: parent.width
                spacing: 8
                visible: root.title.length > 0 || tagRow.children.length > 0

                StyledText {
                    text: root.title
                    visible: root.title.length > 0
                    font.pixelSize: Vayori.title
                    color: Vayori.ink
                    wrapMode: Text.NoWrap
                    height: 20
                }

                Row {
                    id: tagRow
                    spacing: 6
                    height: 20
                }
            }

            StyledText {
                visible: root.description.length > 0
                text: root.description
                width: parent.width
                font.pixelSize: Vayori.body
                color: Vayori.inkMuted
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                lineHeight: 1.12
            }

            StyledText {
                visible: root.meta.length > 0
                text: root.meta
                width: parent.width
                isMonospace: true
                font.pixelSize: Vayori.micro
                color: Vayori.inkGhost
                wrapMode: Text.NoWrap
                elide: Text.ElideMiddle
            }

            Column {
                id: noteColumn
                width: parent.width
                spacing: 3
            }
        }

        Row {
            id: controlSlot
            width: root.below ? parent.width : root.controlsWidth
            y: root.below ? (root.hasText ? textColumn.height + 10 : 0) : (parent.height - implicitHeight) / 2
            x: root.below ? 0 : parent.width - width
            spacing: 8
        }
    }
}
