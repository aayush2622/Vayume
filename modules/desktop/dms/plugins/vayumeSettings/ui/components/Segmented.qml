import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property var options: []
    property string current: ""

    signal picked(string value)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Vayori.controlHeight + 4
    radius: height / 2
    color: Theme.withAlpha(Theme.surfaceContainerLowest, 0.7)
    opacity: root.enabled ? 1 : 0.5

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options

            Rectangle {
                id: segment
                required property var modelData
                readonly property bool active: String(modelData) === root.current
                width: Math.max(88, segmentRow.implicitWidth + 32)
                height: root.height - 8
                radius: height / 2
                color: segment.active ? Vayori.chosen : (segmentArea.containsMouse ? Vayori.hover : "transparent")

                activeFocusOnTab: root.enabled
                Keys.onSpacePressed: root.picked(String(segment.modelData))
                Keys.onReturnPressed: root.picked(String(segment.modelData))

                Behavior on color { ColorAnimation { duration: Vayori.fast } }

                FocusRing {}

                Row {
                    id: segmentRow
                    anchors.centerIn: parent
                    spacing: 6

                    DankIcon {
                        visible: segment.active
                        name: "check"
                        size: 16
                        color: Vayori.ink
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: String(segment.modelData)
                        font.pixelSize: Vayori.body + 1
                        font.weight: Font.Medium
                        color: segment.active ? Vayori.ink : Vayori.inkMuted
                        wrapMode: Text.NoWrap
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: segmentArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(String(segment.modelData))
                }
            }
        }
    }
}
