import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var vm
    required property var action

    property bool armed: false

    readonly property bool busy: root.vm.rebuildBusy
    readonly property bool needsConfirm: root.action.confirm

    function activate() {
        if (root.busy)
            return;
        if (root.needsConfirm && !root.armed) {
            root.armed = true;
            disarmTimer.restart();
            return;
        }
        root.armed = false;
        root.vm.runAction(root.action);
    }

    width: parent ? parent.width : 400
    implicitHeight: content.implicitHeight + Theme.spacingS * 2
    height: implicitHeight
    radius: Theme.cornerRadius
    color: hover.hovered ? Theme.surfaceContainerHigh : "transparent"

    HoverHandler { id: hover }

    Timer {
        id: disarmTimer
        interval: 5000
        onTriggered: root.armed = false
    }

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingM

        Rectangle {
            id: chip
            width: 36
            height: 36
            radius: Theme.cornerRadius
            color: root.needsConfirm ? Theme.withAlpha(Theme.warning, 0.15) : Theme.primaryHoverLight
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: root.action.panel.icon
                size: 20
                color: root.needsConfirm ? Theme.warning : Theme.primary
            }
        }

        Column {
            width: parent.width - chip.width - runButton.width - Theme.spacingM * 2
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.action.panel.label
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: root.action.description
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            StyledText {
                visible: root.armed
                text: I18n.tr("Click again within 5 seconds to confirm.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.warning
            }
        }

        Rectangle {
            id: runButton
            width: 96
            height: 34
            radius: Theme.cornerRadius
            anchors.verticalCenter: parent.verticalCenter
            color: root.busy ? Theme.surfaceContainerLow : (root.armed ? Theme.warning : (root.needsConfirm ? Theme.surfaceContainerHighest : Theme.primary))

            StyledText {
                anchors.centerIn: parent
                text: root.armed ? I18n.tr("Confirm") : I18n.tr("Run")
                font.pixelSize: Theme.fontSizeSmall
                color: root.busy ? Theme.surfaceVariantText : (root.armed || !root.needsConfirm ? Theme.onPrimary : Theme.surfaceText)
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.busy
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate()
            }
        }
    }
}
