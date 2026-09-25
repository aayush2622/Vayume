import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm

    property bool logCollapsed: false
    readonly property bool hasLog: root.vm.rebuildLog.length > 0
    readonly property bool logVisible: root.hasLog && !root.logCollapsed
    readonly property bool pending: root.vm.repoKnown && root.vm.repo.rebuildPending

    readonly property var status: {
        if (root.vm.lastError)
            return { tone: "error", label: I18n.tr("Error"), detail: I18n.tr("Last change failed - see the page where it happened, or run `vayume config validate` in a terminal.") };
        if (root.vm.saving)
            return { tone: "info", label: I18n.tr("Saving"), detail: I18n.tr("Saving changes...") };
        if (root.vm.rebuildBusy)
            return { tone: "info", label: I18n.tr("Running"), detail: root.vm.rebuildStatus };
        if (!root.vm.repoKnown)
            return { tone: "neutral", label: I18n.tr("Loading"), detail: I18n.tr("Reading the repository...") };
        if (root.pending)
            return { tone: "warning", label: I18n.tr("Rebuild pending"), detail: I18n.tr("Changes saved - rebuild to apply them.") };
        return { tone: "success", label: I18n.tr("Saved"), detail: root.vm.rebuildStatus.length > 0 ? root.vm.rebuildStatus : I18n.tr("Everything up to date.") };
    }

    width: parent ? parent.width : 800
    spacing: 0

    Connections {
        target: root.vm
        function onRebuildBusyChanged() {
            if (root.vm.rebuildBusy) root.logCollapsed = false;
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Vayori.hairline
    }

    Rectangle {
        width: parent.width
        height: root.logVisible ? 190 : 0
        clip: true
        color: Vayori.well
        visible: height > 0

        Behavior on height { NumberAnimation { duration: Vayori.normal; easing.type: Easing.OutCubic } }

        Item {
            id: logHeader
            x: 20
            width: parent.width - 40
            height: 36

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Eyebrow {
                    text: root.vm.rebuildBusy ? I18n.tr("Live output") : I18n.tr("Last output")
                    font.pixelSize: Vayori.micro
                    color: root.vm.rebuildBusy ? Vayori.ink : Vayori.inkFaint
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: I18n.tr("%1 lines").arg(root.vm.rebuildLog.length)
                    isMonospace: true
                    font.pixelSize: Vayori.micro
                    color: Vayori.inkGhost
                    wrapMode: Text.NoWrap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            TextButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 22
                variant: "ghost"
                text: I18n.tr("Clear")
                onClicked: root.vm.clearRebuildLog()
            }
        }

        Rectangle {
            x: 20
            y: logHeader.height
            width: parent.width - 40
            height: 1
            color: Vayori.divider
        }

        ListView {
            id: rebuildLogView
            x: 20
            y: logHeader.height + 8
            width: parent.width - 40
            height: parent.height - y - 8
            clip: true
            model: root.vm.rebuildLog
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: positionViewAtEnd()

            delegate: StyledText {
                required property var modelData
                width: rebuildLogView.width
                text: modelData
                isMonospace: true
                font.pixelSize: Vayori.body
                color: Vayori.inkMuted
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }
        }
    }

    Item {
        width: parent.width
        height: 48

        StyledText {
            id: slashes
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "///"
            isMonospace: true
            font.pixelSize: Vayori.caption
            color: Vayori.inkGhost
            wrapMode: Text.NoWrap
        }

        Rectangle {
            id: dot
            anchors.left: slashes.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            color: Vayori.tone(root.status.tone)

            SequentialAnimation on opacity {
                running: root.vm.saving || root.vm.rebuildBusy
                loops: Animation.Infinite
                onRunningChanged: if (!running) dot.opacity = 1
                NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
            }
        }

        Eyebrow {
            id: stateLabel
            anchors.left: dot.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.status.label
            color: root.status.tone === "neutral" || root.status.tone === "success" ? Vayori.ink : Vayori.tone(root.status.tone)
        }

        StyledText {
            anchors.left: stateLabel.right
            anchors.leftMargin: 14
            anchors.right: actions.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: root.status.detail
            font.pixelSize: Vayori.body
            color: Vayori.inkFaint
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            TextButton {
                visible: root.hasLog
                variant: "ghost"
                icon: root.logCollapsed ? "expand_less" : "expand_more"
                text: I18n.tr("Log")
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.logCollapsed = !root.logCollapsed
            }

            Rectangle {
                visible: root.hasLog
                width: 1
                height: 18
                color: Vayori.hairline
                anchors.verticalCenter: parent.verticalCenter
            }

            TextButton {
                variant: root.pending && !root.vm.rebuildBusy ? "primary" : "outline"
                icon: "sync"
                text: root.vm.rebuildBusy ? I18n.tr("Rebuilding") : I18n.tr("Rebuild now")
                busy: root.vm.rebuildBusy
                implicitWidth: 132
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.vm.rebuild()
            }
        }
    }
}
