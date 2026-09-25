import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string jp: ""
    property string group: ""
    property string index: ""
    property string title: ""
    property string subtitle: ""
    property string meta: ""
    default property alias actions: actionRow.data

    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 18

            Row {
                id: eyebrow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9

                Rectangle {
                    width: 16
                    height: 1
                    color: Vayori.inkFaint
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.jp
                    font.family: Vayori.jp
                    font.pixelSize: Vayori.caption
                    color: Vayori.inkMuted
                    wrapMode: Text.NoWrap
                    anchors.verticalCenter: parent.verticalCenter
                }

                Eyebrow {
                    text: root.index + " / " + root.group
                    font.pixelSize: Vayori.micro
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                anchors.left: eyebrow.right
                anchors.leftMargin: 14
                anchors.right: actionRow.left
                anchors.rightMargin: actionRow.width > 0 ? 16 : 0
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: Vayori.divider
            }

            Row {
                id: actionRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
            }
        }

        Item { width: 1; height: 12 }

        StyledText {
            width: parent.width
            text: root.title
            font.pixelSize: Vayori.display
            font.weight: Font.Light
            font.letterSpacing: -0.4
            color: Vayori.ink
            wrapMode: Text.NoWrap
        }

        Item { width: 1; height: 8 }

        StyledText {
            visible: root.subtitle.length > 0
            width: Math.min(parent.width, 720)
            text: root.subtitle
            font.pixelSize: Vayori.body + 1
            color: Vayori.inkMuted
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            lineHeight: 1.15
        }

        Item { width: 1; height: root.meta.length > 0 ? 10 : 0 }

        StyledText {
            visible: root.meta.length > 0
            text: root.meta
            isMonospace: true
            font.pixelSize: Vayori.micro
            font.letterSpacing: 0.6
            color: Vayori.inkFaint
            wrapMode: Text.NoWrap
        }
    }
}
