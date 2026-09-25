import QtQuick
import qs.Common

Rectangle {
    property Item target: parent

    anchors.fill: parent
    anchors.margins: -3
    radius: (parent && parent.radius !== undefined ? parent.radius : Vayori.radiusSmall) + 3
    color: "transparent"
    border.width: 2
    border.color: Vayori.focus
    visible: target && target.activeFocus
}
