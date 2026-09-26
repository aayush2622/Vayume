pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import "vayori"

Item {
    id: root

    property var sessionLock: null
    property string passwordBuffer: ""
    property bool demoMode: false
    property var pam: null
    property string screenName: ""
    property bool unlocking: false
    property bool lockerReadySent: false
    property bool lockerReadyArmed: false

    signal unlockRequested
    signal passwordEdited(string text)

    function encodeFileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split("/").map(p => encodeURIComponent(p)).join("/");
    }

    function resetLockState() {
        lockerReadySent = false;
        lockerReadyArmed = true;
        unlocking = false;
        scene.clearPassword();
        if (pam)
            pam.lockMessage = "";
    }

    function focusPasswordField() {
        if (!demoMode)
            scene.focusPassword();
    }

    function sendLockerReadyOnce() {
        if (root.demoMode || lockerReadySent || root.unlocking)
            return;
        lockerReadySent = true;
        if (SessionService.loginctlAvailable && DMSService.apiVersion >= 2)
            DMSService.sendRequest("loginctl.lockerReady", null, resp => {});
    }

    function maybeSend() {
        if (!lockerReadyArmed || root.unlocking)
            return;
        if (!root.visible || root.opacity <= 0)
            return;
        if (root.sessionLock && !root.sessionLock.secure)
            return;
        Qt.callLater(() => {
            if (root.visible && root.opacity > 0 && !root.unlocking)
                sendLockerReadyOnce();
        });
    }

    readonly property string feedback: {
        if (!pam)
            return "";
        if (pam.lockMessage && pam.lockMessage.length > 0)
            return pam.lockMessage;
        switch (pam.state) {
        case "fail": return I18n.tr("Wrong password - try again");
        case "error": return I18n.tr("Authentication error");
        case "max": return I18n.tr("Too many attempts - wait a moment");
        default: return "";
        }
    }

    readonly property string wallpaperSource: {
        if (SettingsData.lockScreenWallpaperPath !== "")
            return encodeFileUrl(SettingsData.lockScreenWallpaperPath);
        const w = SessionData.getMonitorWallpaper(screenName);
        return (w && !w.startsWith("#")) ? encodeFileUrl(w) : "";
    }

    readonly property var player: MprisController.activePlayer
    readonly property var btDevice: BluetoothService.devices ? BluetoothService.devices.values.find(d => d.connected) : null

    Component.onCompleted: {
        WeatherService.addRef();
        UserInfoService.getUserInfo();
        lockerReadyArmed = true;
    }

    Component.onDestruction: WeatherService.removeRef()

    onVisibleChanged: maybeSend()
    onOpacityChanged: maybeSend()

    Connections {
        target: root.sessionLock
        enabled: target !== null
        function onSecureChanged() {
            root.maybeSend();
        }
    }

    Connections {
        target: root.Window.window
        enabled: target !== null
        function onAfterAnimating() {
            root.maybeSend();
        }
        function onAfterRendering() {
            root.maybeSend();
        }
    }

    Connections {
        target: root.pam
        enabled: target !== null

        function onUnlockRequested() {
            root.unlocking = true;
            root.lockerReadyArmed = false;
            scene.clearPassword();
            root.unlockRequested();
        }

        function onStateChanged() {
            if (!root.pam || root.pam.state === "")
                return;
            root.unlocking = false;
            scene.clearPassword();
        }

        function onUnlockInProgressChanged() {
            if (!root.pam.unlockInProgress && root.unlocking)
                root.unlocking = false;
        }
    }

    LockScene {
        id: scene
        anchors.fill: parent
        focus: true

        wallpaper: root.wallpaperSource
        scheme: ({
            surface: Theme.surface,
            surfaceContainer: Theme.surfaceContainer,
            surfaceContainerHigh: Theme.surfaceContainerHigh,
            surfaceContainerHighest: Theme.surfaceContainerHighest,
            onSurface: Theme.surfaceText,
            onSurfaceVariant: Theme.surfaceVariantText,
            outline: Theme.outline,
            outlineVariant: Theme.outlineVariant,
            primary: Theme.primary,
            onPrimary: Theme.onPrimary,
            primaryContainer: Theme.primaryContainer,
            onPrimaryContainer: Theme.surfaceText,
            secondaryContainer: Theme.secondaryContainer,
            onSecondaryContainer: Theme.surfaceText,
            tertiary: Theme.tertiary,
            error: Theme.error,
            errorContainer: Theme.withAlpha(Theme.error, 0.28),
            onErrorContainer: Theme.surfaceText
        })
        fontFamily: SettingsData.lockScreenFontFamily !== "" ? SettingsData.lockScreenFontFamily : Theme.fontFamily
        use24h: SettingsData.use24HourClock

        displayName: UserInfoService.fullName || UserInfoService.username
        greetingName: UserInfoService.username
        avatar: PortalService.profileImage === "" ? "" : (PortalService.profileImage.startsWith("/") ? root.encodeFileUrl(PortalService.profileImage) : PortalService.profileImage)

        inputEnabled: !root.demoMode && !root.unlocking
        busy: root.unlocking || (root.pam && root.pam.passwd.active)
        message: root.feedback
        messageIsError: root.pam && (root.pam.state === "fail" || root.pam.state === "error" || root.pam.state === "max")

        powerActions: SettingsData.lockScreenShowPowerActions ? [
            { id: "suspend", icon: "bedtime" },
            { id: "hibernate", icon: "ac_unit" },
            { id: "logout", icon: "logout" },
            { id: "reboot", icon: "restart_alt" },
            { id: "poweroff", icon: "power_settings_new" }
        ] : []

        onPasswordEdited: text => root.passwordEdited(text)
        onSubmitted: password => {
            if (root.demoMode || root.unlocking || !root.pam)
                return;
            if (root.pam.passwd.active || root.pam.u2fPending)
                return;
            root.pam.passwd.start();
        }
        onPowerRequested: id => {
            if (root.demoMode)
                return;
            switch (id) {
            case "suspend": SessionService.suspend(); break;
            case "hibernate": SessionService.hibernate(); break;
            case "logout": SessionService.logout(); break;
            case "reboot": SessionService.reboot(); break;
            case "poweroff": SessionService.poweroff(); break;
            }
        }

        topLeft: Row {
            visible: SettingsData.lockScreenShowWeather && WeatherService.weather.available
            spacing: 14 * scene.s

            Text {
                text: WeatherService.getWeatherIcon(WeatherService.weather.wCode, WeatherService.weather.isDay)
                font.family: scene.iconFont
                font.pixelSize: 40 * scene.s
                color: scene.scheme.onSurface
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: (SettingsData.useFahrenheit ? WeatherService.weather.tempF : WeatherService.weather.temp) + "°"
                font.family: scene.fontFamily
                font.pixelSize: 26 * scene.s
                color: scene.scheme.onSurface
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1
                height: 30 * scene.s
                color: scene.scheme.outlineVariant
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: WeatherService.getWeatherCondition(WeatherService.weather.wCode)
                    font.family: scene.fontFamily
                    font.pixelSize: 14 * scene.s
                    color: scene.scheme.onSurface
                }

                Text {
                    text: WeatherService.weather.city
                    font.family: scene.fontFamily
                    font.pixelSize: 12 * scene.s
                    color: scene.scheme.onSurfaceVariant
                }
            }
        }

        chips: [
            LockChip {
                visible: BatteryService.batteryAvailable
                s: scene.s
                scheme: scene.scheme
                fontFamily: scene.fontFamily
                icon: BatteryService.isCharging ? "battery_charging_full" : "battery_full"
                warn: BatteryService.batteryLevel <= 15 && !BatteryService.isCharging
                text: Math.round(BatteryService.batteryLevel) + "%"
            },
            LockChip {
                visible: NetworkService.networkStatus !== "disconnected"
                s: scene.s
                scheme: scene.scheme
                fontFamily: scene.fontFamily
                icon: NetworkService.ethernetConnected ? "lan" : "wifi"
                text: NetworkService.ethernetConnected ? I18n.tr("Ethernet") : NetworkService.currentWifiSSID
            },
            LockChip {
                visible: root.btDevice !== null && root.btDevice !== undefined
                s: scene.s
                scheme: scene.scheme
                fontFamily: scene.fontFamily
                icon: "bluetooth"
                text: root.btDevice ? (root.btDevice.name || root.btDevice.deviceName || "") : ""
            }
        ]

        cards: [
            LockCard {
                visible: SettingsData.lockScreenShowMediaPlayer && root.player !== null && root.player !== undefined
                width: parent ? parent.width : 0
                s: scene.s
                tone: Theme.withAlpha(Theme.surfaceContainer, 0.88)

                Item {
                    width: parent.width
                    height: 72 * scene.s

                    Rectangle {
                        id: art
                        width: 72 * scene.s
                        height: width
                        radius: 14 * scene.s
                        color: scene.scheme.surfaceContainerHighest
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.player ? (root.player.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        anchors.left: art.right
                        anchors.leftMargin: 16 * scene.s
                        anchors.right: controls.left
                        anchors.rightMargin: 10 * scene.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4 * scene.s

                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackTitle || "") : ""
                            font.family: scene.fontFamily
                            font.pixelSize: 16 * scene.s
                            font.weight: Font.Medium
                            color: scene.scheme.onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackArtist || "") : ""
                            font.family: scene.fontFamily
                            font.pixelSize: 13 * scene.s
                            color: scene.scheme.onSurfaceVariant
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: parent.width
                            height: 4 * scene.s
                            radius: height / 2
                            color: scene.scheme.surfaceContainerHighest

                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                color: scene.scheme.primary
                                width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                            }
                        }
                    }

                    Row {
                        id: controls
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * scene.s

                        LockIconButton {
                            s: scene.s
                            scheme: scene.scheme
                            size: 40
                            icon: "skip_previous"
                            onClicked: MprisController.previousOrRewind()
                        }

                        LockIconButton {
                            s: scene.s
                            scheme: scene.scheme
                            size: 48
                            variant: "filled"
                            corner: 16
                            icon: root.player && root.player.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                            onClicked: if (root.player) root.player.togglePlaying()
                        }

                        LockIconButton {
                            s: scene.s
                            scheme: scene.scheme
                            size: 40
                            icon: "skip_next"
                            onClicked: MprisController.next()
                        }
                    }
                }
            },
            LockCard {
                id: notificationCard
                readonly property int total: NotificationService.groupedNotifications.reduce((n, g) => n + (g.count || 0), 0)
                visible: SettingsData.lockScreenNotificationMode > 0 && total > 0
                width: parent ? parent.width : 0
                s: scene.s
                tone: Theme.withAlpha(Theme.surfaceContainer, 0.88)

                Row {
                    spacing: 10 * scene.s

                    Text {
                        text: I18n.tr("Notifications")
                        font.family: scene.fontFamily
                        font.pixelSize: 16 * scene.s
                        font.weight: Font.Medium
                        color: scene.scheme.onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: Math.max(height, countText.implicitWidth + 12 * scene.s)
                        height: 22 * scene.s
                        radius: height / 2
                        color: scene.scheme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: String(notificationCard.total)
                            font.family: scene.fontFamily
                            font.pixelSize: 12 * scene.s
                            font.weight: Font.DemiBold
                            color: scene.scheme.onPrimary
                        }
                    }
                }

                Repeater {
                    model: SettingsData.lockScreenNotificationMode > 1 ? NotificationService.groupedNotifications.slice(0, 3) : []

                    Rectangle {
                        required property var modelData
                        width: parent.width
                        height: noteText.implicitHeight + 24 * scene.s
                        radius: 18 * scene.s
                        color: scene.scheme.surfaceContainerHighest

                        Column {
                            id: noteText
                            x: 16 * scene.s
                            y: 12 * scene.s
                            width: parent.width - 32 * scene.s
                            spacing: 2 * scene.s

                            Text {
                                width: parent.width
                                text: (modelData.appName || "") + (modelData.count > 1 ? "  ·  " + modelData.count : "")
                                font.family: scene.fontFamily
                                font.pixelSize: 11 * scene.s
                                color: scene.scheme.onSurfaceVariant
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: SettingsData.lockScreenNotificationMode > 2
                                text: modelData.latestNotification ? (modelData.latestNotification.summary || "") : ""
                                font.family: scene.fontFamily
                                font.pixelSize: 14 * scene.s
                                font.weight: Font.Medium
                                color: scene.scheme.onSurface
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        ]
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.demoMode
        visible: root.demoMode
        onClicked: root.unlockRequested()
    }
}
