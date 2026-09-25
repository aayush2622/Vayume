import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral"
    property bool busy: false

    readonly property bool tinted: root.tone !== "neutral"
    readonly property color toneColor: Vayori.tone(root.tone)

    width: parent ? parent.width : 400
    implicitHeight: Math.max(body.implicitHeight, 20) + (root.tinted ? 24 : 0)
    visible: root.text.length > 0
    radius: Vayori.radius
    color: root.tinted ? Theme.withAlpha(root.toneColor, 0.12) : "transparent"

    Item {
        id: lead
        x: root.tinted ? 16 : 20
        width: 20
        height: 20
        y: root.tinted ? 12 : 0

        DankSpinner {
            visible: root.busy
            anchors.centerIn: parent
            size: 16
            strokeWidth: 2
        }

        DankIcon {
            visible: !root.busy
            anchors.centerIn: parent
            name: root.tone === "error" ? "error" : (root.tone === "warning" ? "warning" : "info")
            size: 18
            color: root.tinted ? root.toneColor : Vayori.inkFaint
        }
    }

    StyledText {
        id: body
        anchors.left: lead.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: root.tinted ? 16 : 20
        y: root.tinted ? 12 : 0
        text: root.text
        font.pixelSize: Vayori.body
        color: root.tone === "error" ? Theme.error : Vayori.inkMuted
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        lineHeight: 1.15
    }
}
