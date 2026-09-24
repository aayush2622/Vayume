import QtQuick
import qs.Common
import qs.Widgets

Row {
    id: root

    property string label: ""
    property string tone: "neutral"
    spacing: Theme.spacingXS

    readonly property color dotColor: {
        switch (root.tone) {
        case "warning": return Theme.warning;
        case "error": return Theme.error;
        case "success": return Theme.success;
        case "info": return Theme.primary;
        default: return Theme.surfaceVariantText;
        }
    }

    Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: root.dotColor
    }

    StyledText {
        text: root.label
        font.pixelSize: Theme.fontSizeSmall
        color: root.tone === "neutral" ? Theme.surfaceVariantText : root.dotColor
        anchors.verticalCenter: parent.verticalCenter
    }
}
