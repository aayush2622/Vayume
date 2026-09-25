import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string label: ""
    property string tone: "neutral"

    readonly property color toneColor: Vayori.tone(root.tone)

    implicitWidth: labelText.implicitWidth + 12
    implicitHeight: 17
    radius: Vayori.radiusSmall
    color: root.tone === "neutral" ? "transparent" : Theme.withAlpha(root.toneColor, 0.1)
    border.width: 1
    border.color: root.tone === "neutral" ? Vayori.hairline : Theme.withAlpha(root.toneColor, 0.42)

    StyledText {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        isMonospace: true
        font.pixelSize: Vayori.micro
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
        color: root.toneColor
        wrapMode: Text.NoWrap
    }
}
