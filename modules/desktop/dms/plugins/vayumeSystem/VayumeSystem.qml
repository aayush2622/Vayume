import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    readonly property var gauges: {
        const list = [
            { label: I18n.tr("CPU"), icon: "memory", value: DgopService.cpuUsage / 100, alarm: DgopService.cpuUsage > 90 },
            { label: I18n.tr("Memory"), icon: "memory_alt", value: DgopService.memoryUsage / 100, alarm: DgopService.memoryUsage > 90 }
        ];
        if (BatteryService.batteryAvailable)
            list.push({ label: BatteryService.isCharging ? I18n.tr("Charging") : I18n.tr("Battery"), icon: BatteryService.isCharging ? "bolt" : "battery_full", value: BatteryService.batteryLevel / 100, alarm: BatteryService.isLowBattery && !BatteryService.isCharging });
        return list;
    }

    implicitWidth: 300
    implicitHeight: 190

    Component.onCompleted: DgopService.addRef(["cpu", "memory", "system"])
    Component.onDestruction: DgopService.removeRef(["cpu", "memory", "system"])

    Rectangle {
        anchors.fill: parent
        radius: 32
        color: Theme.withAlpha(Theme.surfaceContainer, 0.82)

        Row {
            anchors.centerIn: parent
            spacing: Math.max(8, (parent.width - 40 - root.gauges.length * 76) / Math.max(1, root.gauges.length - 1))

            Repeater {
                model: root.gauges

                Column {
                    id: gauge
                    required property var modelData
                    spacing: 6

                    Item {
                        width: 76
                        height: 76

                        WavyRing {
                            anchors.fill: parent
                            value: gauge.modelData.value
                            thickness: 6
                            activeColor: gauge.modelData.alarm ? Theme.error : Theme.primary
                            trackColor: Theme.withAlpha(Theme.surfaceText, 0.14)
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: -2

                            DankIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: gauge.modelData.icon
                                size: 16
                                color: Theme.surfaceVariantText
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.round(gauge.modelData.value * 100) + "%"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: gauge.modelData.label
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                    }
                }
            }
        }
    }
}
