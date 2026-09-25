import QtQuick
import qs.Common

Rectangle {
    property Item target: parent

    anchors.fill: parent
    anchors.margins: -3
    radius: Vayori.radius + 2
    color: "transparent"
    border.width: 1
    border.color: Vayori.focus
    visible: target && target.activeFocus
}
