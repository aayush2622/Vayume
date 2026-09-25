import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string text: ""
    property string tone: "neutral"
    property bool busy: false

    readonly property color toneColor: root.tone === "neutral" ? Vayori.lineStrong : Vayori.tone(root.tone)

    width: parent ? parent.width : 400
    implicitHeight: Math.max(body.implicitHeight, 16)
    visible: root.text.length > 0

    Rectangle {
        id: rule
        width: 1
        height: parent.height
        color: root.toneColor

        SequentialAnimation on opacity {
            running: root.busy && root.visible
            loops: Animation.Infinite
            onRunningChanged: if (!running) rule.opacity = 1
            NumberAnimation { to: 0.25; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
        }
    }

    StyledText {
        id: body
        x: 12
        width: parent.width - x
        text: root.text
        font.pixelSize: Vayori.body
        color: root.tone === "error" ? Theme.error : Vayori.inkMuted
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        lineHeight: 1.15
    }
}
