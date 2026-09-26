import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    function valueOf(path, fallback) {
        const s = root.vm.settings.find(x => x.path === path);
        return s && s.value !== null && s.value !== undefined ? s.value : fallback;
    }

    readonly property bool petOn: root.valueOf("desktop.pet.enable", false)
    readonly property string skin: root.valueOf("desktop.pet.skin", "classic")
    readonly property bool kuroneko: root.valueOf("desktop.pet.kuroneko", false)
    readonly property string petName: root.valueOf("desktop.pet.name", "")
    readonly property int scale: Math.max(2, Math.min(4, root.valueOf("desktop.pet.size", 3)))

    readonly property var script: [
        { sprite: [[3, 3]], ticks: 16 },
        { sprite: [[5, 0], [6, 0], [7, 0]], ticks: 12 },
        { sprite: [[3, 3]], ticks: 8 },
        { sprite: [[3, 0], [3, 1]], ticks: 22, walk: 1 },
        { sprite: [[3, 3]], ticks: 10 },
        { sprite: [[3, 2]], ticks: 8 },
        { sprite: [[2, 0], [2, 1]], ticks: 30 },
        { sprite: [[7, 3]], ticks: 6 },
        { sprite: [[4, 2], [4, 3]], ticks: 22, walk: -1 }
    ]
    property int step: 0
    property int tick: 0
    property real walkX: 0

    readonly property var frame: {
        const s = root.script[root.step];
        return s.sprite[Math.floor(root.tick / 2) % s.sprite.length];
    }

    readonly property string meta: options.pendingCount > 0 ? I18n.tr("%1 waiting for a rebuild").arg(options.pendingCount) : (root.petOn ? I18n.tr("on the desktop") : I18n.tr("off"))

    Timer {
        interval: 110
        running: root.visible
        repeat: true
        onTriggered: {
            const s = root.script[root.step];
            if (s.walk)
                root.walkX += s.walk * 7;
            if (++root.tick >= s.ticks) {
                root.tick = 0;
                root.step = (root.step + 1) % root.script.length;
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 200
        radius: Vayori.radiusLarge
        color: Vayori.chosen
        clip: true

        Item {
            id: stage
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width * 0.45, 360)
            height: 32 * root.scale + 16

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                radius: 1
                color: Theme.withAlpha(Vayori.ink, 0.12)
            }

            Item {
                id: sprite
                width: 32 * root.scale
                height: 32 * root.scale
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                x: (stage.width - width) / 2 + root.walkX
                clip: true
                opacity: root.petOn ? 1 : 0.45

                Image {
                    source: "file:///etc/vayume/pet-skins/" + root.skin + (root.kuroneko ? "-kuroneko" : "") + ".png"
                    width: 256 * root.scale
                    height: 128 * root.scale
                    smooth: false
                    x: -root.frame[0] * 32 * root.scale
                    y: -root.frame[1] * 32 * root.scale
                }
            }
        }

        Column {
            x: 32
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - stage.width - 96
            spacing: 6

            StyledText {
                text: root.petName.length > 0 ? root.petName : I18n.tr("Your desktop pet")
                font.pixelSize: Vayori.display - 6
                color: Vayori.ink
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                width: parent.width
                text: root.petOn
                    ? I18n.tr("Lives on your screen. Drag it anywhere, click to pet it, double-click to let it nap.")
                    : I18n.tr("Turn it on below and rebuild to let it out.")
                font.pixelSize: Vayori.body + 1
                color: Vayori.inkMuted
                wrapMode: Text.WordWrap
            }
        }
    }

    PageOptions {
        id: options
        vm: root.vm
        page: "pet"
    }
}
