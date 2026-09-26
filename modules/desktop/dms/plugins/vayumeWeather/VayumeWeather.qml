import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    readonly property var w: WeatherService.weather
    readonly property bool ready: root.w && root.w.available
    readonly property var days: root.ready && root.w.forecast ? root.w.forecast.slice(1, 5) : []

    implicitWidth: 300
    implicitHeight: 190

    Component.onCompleted: WeatherService.addRef()
    Component.onDestruction: WeatherService.removeRef()

    Rectangle {
        anchors.fill: parent
        radius: 32
        color: Theme.withAlpha(Theme.surfaceContainer, 0.82)
        opacity: root.ready ? 1 : 0.6

        Behavior on opacity { NumberAnimation { duration: 250 } }

        Item {
            id: now
            x: 22
            y: 18
            width: parent.width - 44
            height: 72

            Rectangle {
                id: badge
                width: 64
                height: 64
                radius: 22
                color: Theme.primaryContainer
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: root.ready ? WeatherService.getWeatherIcon(root.w.wCode, root.w.isDay) : "cloud_off"
                    size: 36
                    filled: true
                    color: Theme.primary
                }
            }

            Column {
                anchors.left: badge.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Row {
                    spacing: 8

                    StyledText {
                        id: tempText
                        text: root.ready ? WeatherService.formatTemp(Math.round(root.w.temp)) : "--°"
                        font.pixelSize: 40
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        anchors.baseline: tempText.baseline
                        visible: root.ready
                        text: I18n.tr("feels %1").arg(WeatherService.formatTemp(Math.round(root.w.feelsLike)))
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                StyledText {
                    width: parent.width
                    text: root.ready ? WeatherService.getWeatherCondition(root.w.wCode) : I18n.tr("Weather unavailable")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }
        }

        Row {
            x: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            width: parent.width - 28
            spacing: 6

            Repeater {
                model: root.days

                Rectangle {
                    id: day
                    required property var modelData
                    width: (parent.width - parent.spacing * 3) / 4
                    height: 78
                    radius: 20
                    color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.7)

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: day.modelData.rawSunrise ? Qt.formatDate(new Date(day.modelData.rawSunrise), "ddd") : String(day.modelData.day).slice(0, 3)
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                        }

                        DankIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: WeatherService.getWeatherIcon(day.modelData.wCode, true)
                            size: 22
                            filled: true
                            color: Theme.primary
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WeatherService.formatTemp(day.modelData.tempMax) + " " + WeatherService.formatTemp(day.modelData.tempMin)
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.surfaceText
                        }
                    }
                }
            }
        }
    }
}
