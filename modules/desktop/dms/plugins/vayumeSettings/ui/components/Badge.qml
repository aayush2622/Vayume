import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string label: ""
    property string tone: "neutral"

    readonly property color toneColor: root.tone === "neutral" ? Vayori.inkMuted : Vayori.tone(root.tone)

    implicitWidth: labelText.implicitWidth + 16
    implicitHeight: 20
    radius: height / 2
    color: root.tone === "neutral" ? Theme.withAlpha(Vayori.ink, 0.08) : Theme.withAlpha(root.toneColor, 0.16)

    StyledText {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: Vayori.micro
        font.weight: Font.Medium
        color: root.toneColor
        wrapMode: Text.NoWrap
    }
}
