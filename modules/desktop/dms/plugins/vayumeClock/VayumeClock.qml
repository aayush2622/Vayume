import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    property date now: new Date()
    readonly property bool use24h: SettingsData.use24HourClock
    readonly property int hour: use24h ? now.getHours() : ((now.getHours() + 11) % 12 + 1)
    readonly property real s: Math.min(height / 520, width / 460)
    readonly property string fontFamily: SettingsData.lockScreenFontFamily !== "" ? SettingsData.lockScreenFontFamily : Theme.fontFamily

    implicitWidth: 460
    implicitHeight: 520

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Column {
        id: clock
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * root.s

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.withAlpha(Theme.surface, 0.6)
            shadowBlur: 0.8
            shadowVerticalOffset: 2
        }

        Column {
            spacing: -38 * root.s

            Text {
                text: root.use24h ? String(root.hour).padStart(2, "0") : String(root.hour)
                font.family: root.fontFamily
                font.pixelSize: 156 * root.s
                font.weight: Font.Normal
                color: Theme.surfaceText
                lineHeight: 0.85
            }

            Row {
                spacing: 14 * root.s

                Text {
                    id: minutes
                    text: String(root.now.getMinutes()).padStart(2, "0")
                    font.family: root.fontFamily
                    font.pixelSize: 156 * root.s
                    font.weight: Font.Bold
                    color: Theme.primary
                    lineHeight: 0.85
                }

                Rectangle {
                    visible: !root.use24h
                    anchors.baseline: minutes.baseline
                    anchors.baselineOffset: -30 * root.s
                    width: ampm.implicitWidth + 20 * root.s
                    height: 32 * root.s
                    radius: 8 * root.s
                    color: Theme.secondaryContainer

                    Text {
                        id: ampm
                        anchors.centerIn: parent
                        text: root.now.getHours() < 12 ? "AM" : "PM"
                        font.family: root.fontFamily
                        font.pixelSize: 16 * root.s
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }
                }
            }
        }

        Item {
            width: 1
            height: 20 * root.s
        }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            font.family: root.fontFamily
            font.pixelSize: 24 * root.s
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        Text {
            text: {
                const h = root.now.getHours();
                const g = h < 5 ? "Still up" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
                return UserInfoService.username.length > 0 ? g + ", " + UserInfoService.username : g;
            }
            font.family: root.fontFamily
            font.pixelSize: 17 * root.s
            color: Theme.surfaceVariantText
        }
    }
}
