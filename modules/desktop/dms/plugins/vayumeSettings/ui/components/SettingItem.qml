import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string title: ""
    property string description: ""
    property string meta: ""
    property string marker: ""
    property bool card: true
    property bool divider: false
    property bool stacked: false
    property string icon: ""
    property string image: ""

    default property alias control: controlSlot.data
    property alias tags: tagRow.data
    property alias notes: noteColumn.data
    property alias footer: footerColumn.data

    readonly property real inset: root.card ? Vayori.pad : 0
    readonly property bool hasLeading: root.icon.length > 0 || root.image.length > 0
    readonly property real lead: root.hasLeading ? 56 : 0
    readonly property bool below: root.stacked || root.width < 560
    readonly property bool hasText: root.title.length > 0 || root.description.length > 0 || root.meta.length > 0
    readonly property real controlsWidth: controlSlot.implicitWidth

    width: parent ? parent.width : 400
    implicitHeight: body.height + Vayori.rowPad * 2 + (footerColumn.implicitHeight > 0 ? footerColumn.implicitHeight + 4 : 0)

    HoverHandler { id: hover }

    Rectangle {
        visible: root.card
        anchors.fill: parent
        radius: Vayori.radius
        color: hover.hovered && root.enabled ? Vayori.cardHover : Vayori.card

        Behavior on color { ColorAnimation { duration: Vayori.fast } }
    }

    Rectangle {
        visible: root.divider && !root.card
        width: parent.width
        height: 1
        color: Vayori.divider
    }

    Rectangle {
        visible: root.marker.length > 0
        x: root.card ? 6 : -12
        y: Vayori.rowPad
        width: 3
        height: body.height
        radius: 1.5
        color: Vayori.tone(root.marker)
    }

    Rectangle {
        id: leading
        visible: root.hasLeading
        x: root.inset
        y: root.below ? Vayori.rowPad : Vayori.rowPad + Math.max(0, (body.height - height) / 2)
        width: 40
        height: 40
        radius: 12
        color: picture.status === Image.Ready ? "transparent" : Vayori.tonal
        opacity: root.enabled ? 1 : 0.5

        Image {
            id: picture
            anchors.centerIn: parent
            width: 36
            height: 36
            source: root.image
            sourceSize: Qt.size(72, 72)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: status === Image.Ready
        }

        DankIcon {
            anchors.centerIn: parent
            visible: picture.status !== Image.Ready
            name: root.icon.length > 0 ? root.icon : "apps"
            size: 20
            color: Vayori.ink
        }
    }

    Item {
        id: body
        x: root.inset + root.lead
        y: Vayori.rowPad
        width: parent.width - root.inset * 2 - root.lead
        height: root.below
            ? (root.hasText ? textColumn.height + (controlSlot.implicitHeight > 0 ? 12 : 0) : 0) + controlSlot.implicitHeight
            : Math.max(textColumn.height, controlSlot.implicitHeight)
        opacity: root.enabled ? 1 : 0.5

        Column {
            id: textColumn
            visible: root.hasText
            width: root.below ? parent.width : parent.width - root.controlsWidth - (root.controlsWidth > 0 ? 24 : 0)
            height: root.hasText ? implicitHeight : 0
            anchors.verticalCenter: root.below ? undefined : parent.verticalCenter
            spacing: 4

            Flow {
                width: parent.width
                spacing: 8
                visible: root.title.length > 0 || tagRow.children.length > 0

                StyledText {
                    text: root.title
                    visible: root.title.length > 0
                    font.pixelSize: Vayori.title
                    font.weight: Font.Medium
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
                lineHeight: 1.15
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
                spacing: 4
            }
        }

        Row {
            id: controlSlot
            width: root.below ? parent.width : root.controlsWidth
            y: root.below ? (root.hasText ? textColumn.height + 12 : 0) : (parent.height - implicitHeight) / 2
            x: root.below ? 0 : parent.width - width
            spacing: 8
        }
    }

    Column {
        id: footerColumn
        x: root.inset + root.lead
        y: body.y + body.height + 12
        width: parent.width - root.inset * 2 - root.lead
    }
}
