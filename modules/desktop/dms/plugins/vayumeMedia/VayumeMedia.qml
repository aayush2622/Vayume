import QtQuick
import QtQuick.Effects
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
    readonly property bool canSeek: root.hasPlayer && root.player.canSeek && root.length > 0
    readonly property real pad: Math.round(width * 0.065)
    readonly property string artUrl: root.hasPlayer ? (root.player.trackArtUrl || "") : ""

    property real position: 0
    property bool seeking: false
    property real seekValue: 0

    readonly property real fraction: root.seeking ? root.seekValue : (root.length > 0 ? Math.min(1, root.position / root.length) : 0)

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        const sec = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + sec : m + ":" + sec;
    }

    function syncPosition() {
        root.position = root.hasPlayer ? root.player.position : 0;
    }

    implicitWidth: 300
    implicitHeight: 500

    onPlayerChanged: syncPosition()

    Timer {
        interval: 500
        running: root.hasPlayer
        repeat: true
        triggeredOnStart: true
        onTriggered: root.syncPosition()
    }

    Item {
        id: card
        anchors.fill: parent
        opacity: root.hasPlayer ? 1 : 0
        visible: opacity > 0
        scale: root.hasPlayer ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        Rectangle {
            id: cardMask
            anchors.fill: parent
            radius: 32
            visible: false
            layer.enabled: true
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: cardMask
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.surfaceContainer
            }

            Image {
                id: backdrop
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(160, 160)
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: backdrop
                visible: backdrop.status === Image.Ready
                blurEnabled: true
                blur: 1
                blurMax: 64
                saturation: 0.2
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.withAlpha(Theme.surfaceContainer, 0.55) }
                    GradientStop { position: 0.55; color: Theme.withAlpha(Theme.surfaceContainer, 0.8) }
                    GradientStop { position: 1; color: Theme.withAlpha(Theme.surfaceContainer, 0.92) }
                }
            }
        }

        Row {
            id: header
            x: root.pad
            y: root.pad - 2
            spacing: 6

            DankIcon {
                name: "graphic_eq"
                size: 16
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.hasPlayer && root.player.identity ? root.player.identity : I18n.tr("Now playing")
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: art
            x: root.pad
            anchors.top: header.bottom
            anchors.topMargin: 10
            width: parent.width - root.pad * 2
            height: width
            radius: 24
            color: Theme.surfaceContainerHighest

            Image {
                id: artImage
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(width * 2, height * 2)
                visible: false
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: parent.radius
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: parent
                source: artImage
                visible: artImage.status === Image.Ready
                maskEnabled: true
                maskSource: artMask
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
            anchors.topMargin: 14
            width: parent.width - root.pad * 2
            spacing: 2

            StyledText {
                width: parent.width
                text: root.hasPlayer ? (root.player.trackTitle || I18n.tr("Unknown title")) : ""
                font.pixelSize: Theme.fontSizeLarge + 2
                font.weight: Font.Bold
                color: Theme.surfaceText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                text: root.hasPlayer ? (root.player.trackArtist || "") : ""
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }
        }

        WavyBar {
            id: progress
            x: root.pad
            anchors.top: meta.bottom
            anchors.topMargin: 10
            width: parent.width - root.pad * 2
            height: 26
            value: root.fraction
            moving: root.playing && !root.seeking
            activeColor: Theme.primary
            trackColor: Theme.withAlpha(Theme.surfaceText, 0.16)
            thickness: root.seeking ? 6 : 5

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                enabled: root.canSeek
                hoverEnabled: true
                cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                preventStealing: true

                function valueAt(x) {
                    return Math.max(0, Math.min(1, x / width));
                }

                onPressed: mouse => {
                    root.seekValue = valueAt(mouse.x);
                    root.seeking = true;
                }
                onPositionChanged: mouse => {
                    if (pressed)
                        root.seekValue = valueAt(mouse.x);
                }
                onReleased: {
                    if (!root.seeking)
                        return;
                    const target = root.seekValue * root.length;
                    root.player.position = target;
                    root.position = target;
                    root.seeking = false;
                }
                onCanceled: root.seeking = false
            }
        }

        Item {
            id: times
            x: root.pad
            anchors.top: progress.bottom
            width: parent.width - root.pad * 2
            height: 16

            StyledText {
                text: root.hasPlayer ? root.clock(root.fraction * root.length) : ""
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: root.seeking ? Font.Bold : Font.Normal
                color: root.seeking ? Theme.primary : Theme.surfaceVariantText
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
            spacing: 8

            Repeater {
                model: [
                    { icon: "skip_previous", main: false, act: () => MprisController.previousOrRewind() },
                    { icon: root.playing ? "pause" : "play_arrow", main: true, act: () => root.player && root.player.togglePlaying() },
                    { icon: "skip_next", main: false, act: () => MprisController.next() }
                ]

                Rectangle {
                    id: btn
                    required property var modelData
                    width: modelData.main ? 96 : 60
                    height: 56
                    radius: area.pressed ? 12 : (modelData.main ? (root.playing ? 18 : 28) : 16)
                    anchors.verticalCenter: parent.verticalCenter
                    color: modelData.main ? Theme.primary : Theme.withAlpha(Theme.secondaryContainer, 0.95)

                    Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: btn.modelData.main ? Theme.onPrimary : Theme.surfaceText
                        opacity: area.pressed ? 0.12 : (area.containsMouse ? 0.08 : 0)
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: btn.modelData.icon
                        size: btn.modelData.main ? 30 : 24
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
