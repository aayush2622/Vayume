import QtQuick
import qs.Common
import qs.Widgets
import "components"

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string meta: ""
    default property alias actions: actionRow.data

    implicitHeight: Math.max(column.implicitHeight, actionRow.height)

    Column {
        id: column
        width: parent.width - actionRow.width - 16
        spacing: 6

        StyledText {
            width: parent.width
            text: root.title
            font.pixelSize: Vayori.display
            color: Vayori.ink
            wrapMode: Text.NoWrap
        }

        StyledText {
            visible: root.subtitle.length > 0
            width: Math.min(parent.width, 680)
            text: root.subtitle
            font.pixelSize: Vayori.body + 1
            color: Vayori.inkMuted
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            lineHeight: 1.15
        }

        StyledText {
            visible: root.meta.length > 0
            text: root.meta
            font.pixelSize: Vayori.micro
            color: Vayori.inkFaint
            wrapMode: Text.NoWrap
        }
    }

    Row {
        id: actionRow
        anchors.right: parent.right
        spacing: 4
    }
}
