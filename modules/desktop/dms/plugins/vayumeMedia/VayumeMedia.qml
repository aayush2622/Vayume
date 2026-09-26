import QtQuick
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property bool hasPlayer: root.player !== null && root.player !== undefined
    readonly property bool playing: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing
    readonly property real length: root.hasPlayer ? (MprisController.activePlayerStableLength > 0 ? MprisController.activePlayerStableLength : root.player.length) : 0
    readonly property real pad: Math.round(width * 0.06)

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    implicitWidth: 270
    implicitHeight: 420

    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: if (root.player) root.player.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Theme.withAlpha(Theme.surfaceContainer, 0.78)
        opacity: root.hasPlayer ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Rectangle {
            id: art
            x: root.pad
            y: root.pad
            width: parent.width - root.pad * 2
            height: width
            radius: 20
            color: Theme.surfaceContainerHighest
            clip: true

            Image {
                id: artImage
                anchors.fill: parent
                source: root.hasPlayer ? (root.player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(width * 2, height * 2)
            }

            DankIcon {
                anchors.centerIn: parent
                visible: artImage.status !== Image.Ready
                name: "music_note"
                size: parent.width * 0.3
                color: Theme.surfaceVariantText
            }
        }

        Column {
            id: meta
            x: root.pad
            anchors.top: art.bottom
            anchors.topMargin: Math.round(root.pad * 0.8)
            width: parent.width - root.pad * 2
            spacing: 2

            StyledText {
                width: parent.width
                text: root.hasPlayer ? (root.player.trackTitle || I18n.tr("Unknown title")) : ""
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                text: root.hasPlayer ? (root.player.trackArtist || "") : ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }
        }

        Item {
            id: progress
            x: root.pad
            anchors.top: meta.bottom
            anchors.topMargin: Math.round(root.pad * 0.7)
            width: parent.width - root.pad * 2
            height: 22

            readonly property real fraction: root.length > 0 && root.hasPlayer ? Math.min(1, root.player.position / root.length) : 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.surfaceContainerHighest
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * progress.fraction
                height: 4
                radius: 2
                color: Theme.primary
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, parent.width * progress.fraction - width / 2)
                width: 4
                height: 16
                radius: 2
                color: Theme.primary
            }
        }

        Item {
            id: times
            x: root.pad
            anchors.top: progress.bottom
            width: parent.width - root.pad * 2
            height: 16

            StyledText {
                text: root.hasPlayer ? root.clock(root.player.position) : ""
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
            }

            StyledText {
                anchors.right: parent.right
                text: root.clock(root.length)
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.pad
            spacing: 14

            Repeater {
                model: [
                    { icon: "skip_previous", main: false, act: () => MprisController.previousOrRewind() },
                    { icon: root.playing ? "pause" : "play_arrow", main: true, act: () => root.player && root.player.togglePlaying() },
                    { icon: "skip_next", main: false, act: () => MprisController.next() }
                ]

                Rectangle {
                    id: btn
                    required property var modelData
                    width: modelData.main ? 64 : 44
                    height: modelData.main ? 52 : 44
                    radius: modelData.main ? 18 : height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: modelData.main ? Theme.primary : Theme.withAlpha(Theme.secondaryContainer, 0.9)

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: btn.modelData.main ? Theme.onPrimary : Theme.surfaceText
                        opacity: area.pressed ? 0.12 : (area.containsMouse ? 0.08 : 0)
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: btn.modelData.icon
                        size: btn.modelData.main ? 28 : 22
                        filled: true
                        color: btn.modelData.main ? Theme.onPrimary : Theme.surfaceText
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btn.modelData.act()
                    }
                }
            }
        }
    }
}
