import QtQuick
import qs.Common
import qs.DankCommon.Widgets
import "../components"

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property var p: vm.power
    readonly property bool hasBackend: p.backend !== "none"
    readonly property bool busy: vm.powerBusy
    readonly property var limits: ["60", "80", "100"]
    readonly property string meta: I18n.tr("hardware changes apply at once")

    Notice {
        visible: root.vm.powerLoading
        text: I18n.tr("Loading...")
        busy: true
    }

    Notice {
        visible: !root.vm.powerLoading && !root.hasBackend
        text: I18n.tr("No power profile service found - start asusd or power-profiles-daemon to switch profiles here.")
        tone: "warning"
    }

    Section {
        visible: root.hasBackend
        title: I18n.tr("Power profile")
        subtitle: I18n.tr("How hard the machine runs. Switches immediately and sticks across rebuilds.")

        SettingItem {
            title: I18n.tr("Profile")
            description: I18n.tr("Quiet saves the most power, Performance lets the fans and clocks go all out.")
            icon: "speed"

            Segmented {
                visible: root.p.profiles.length <= 3
                enabled: !root.busy
                options: root.p.profiles
                current: root.p.profile
                anchors.verticalCenter: parent.verticalCenter
                onPicked: value => root.vm.setPower("profile", value)
            }

            Select {
                visible: root.p.profiles.length > 3
                width: 220
                enabled: !root.busy
                currentValue: root.p.profile
                options: root.p.profiles
                anchors.verticalCenter: parent.verticalCenter
                onValueChanged: value => root.vm.setPower("profile", value)
            }
        }

        SettingItem {
            visible: root.p.batteryLimit !== null
            title: I18n.tr("Battery charge limit")
            description: I18n.tr("Stop charging at this level to keep the battery healthy. 100 is no limit.")
            icon: "battery_charging_full"

            Segmented {
                enabled: !root.busy
                options: root.limits
                current: String(root.p.batteryLimit)
                anchors.verticalCenter: parent.verticalCenter
                onPicked: value => root.vm.setPower("battery-limit", value)
            }
        }

        SettingItem {
            visible: root.p.gpu !== null && root.p.gpuModes.length > 1
            title: I18n.tr("Graphics mode")
            description: I18n.tr("Integrated keeps the discrete GPU off for battery life. Switching asks you to log out.")
            icon: "memory"

            Segmented {
                visible: root.p.gpuModes.length <= 3
                enabled: !root.busy
                options: root.p.gpuModes
                current: root.p.gpu || ""
                anchors.verticalCenter: parent.verticalCenter
                onPicked: value => root.vm.setPower("gpu", value)
            }

            Select {
                visible: root.p.gpuModes.length > 3
                width: 220
                enabled: !root.busy
                currentValue: root.p.gpu || ""
                options: root.p.gpuModes
                anchors.verticalCenter: parent.verticalCenter
                onValueChanged: value => root.vm.setPower("gpu", value)
            }
        }

        SettingItem {
            visible: root.p.panelOverdrive !== null
            title: I18n.tr("Panel overdrive")
            description: I18n.tr("Faster pixel response on the built-in display, at the cost of a little power.")
            icon: "monitor"

            Toggle {
                checked: root.p.panelOverdrive === true
                enabled: !root.busy
                anchors.verticalCenter: parent.verticalCenter
                onToggled: value => root.vm.setPower("overdrive", value ? "on" : "off")
            }
        }

        SettingItem {
            visible: root.p.autoBrightness !== null
            title: I18n.tr("Auto brightness")
            description: I18n.tr("Let the panel adjust its brightness to the content on screen.")
            icon: "brightness_auto"

            Toggle {
                checked: root.p.autoBrightness === true
                enabled: !root.busy
                anchors.verticalCenter: parent.verticalCenter
                onToggled: value => root.vm.setPower("auto-brightness", value ? "on" : "off")
            }
        }
    }

    Notice {
        visible: root.vm.powerStatus.length > 0
        text: root.vm.powerStatus
        tone: root.vm.powerError ? "error" : "neutral"
    }

    PageOptions {
        id: options
        vm: root.vm
        page: "power"
    }
}
