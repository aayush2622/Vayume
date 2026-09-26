import QtQuick
import QtQuick.Effects

FocusScope {
    id: root

    property url wallpaper: ""
    property real blur: 0.65
    property real scrim: 0.5

    property var scheme: ({
        surface: "#11131c",
        surfaceContainer: "#1d1f2c",
        surfaceContainerHigh: "#282a37",
        surfaceContainerHighest: "#333542",
        onSurface: "#e3e1ef",
        onSurfaceVariant: "#c6c5d6",
        outline: "#8f8fa0",
        outlineVariant: "#454654",
        primary: "#b8c4ff",
        onPrimary: "#1f2c61",
        primaryContainer: "#36437a",
        onPrimaryContainer: "#dde1ff",
        secondaryContainer: "#414659",
        onSecondaryContainer: "#dee1f9",
        tertiary: "#ffb3b0",
        error: "#ffb4ab",
        errorContainer: "#93000a",
        onErrorContainer: "#ffdad6"
    })

    property string fontFamily: ""
    property string iconFont: "Material Symbols Rounded"
    property bool use24h: true

    property string displayName: ""
    property url avatar: ""
    property string greetingName: root.displayName

    property bool busy: false
    property string message: ""
    property bool messageIsError: false
    property bool capsLock: false
    property bool inputEnabled: true
    property var powerActions: []

    property alias topLeft: topLeftSlot.data
    property alias chips: chipRow.data
    property alias cards: cardColumn.data

    readonly property real s: Math.max(0.6, Math.min(width / 1920, height / 1080))
    readonly property string passwordText: passwordInput.text
    property date now: new Date()
    property real entrance: 0

    signal submitted(string password)
    signal passwordEdited(string password)
    signal powerRequested(string id)
    signal nameClicked

    function clearPassword() {
        passwordInput.text = "";
    }

    function focusPassword() {
        passwordInput.forceActiveFocus();
    }

    function submit() {
        if (root.inputEnabled && !root.busy && passwordInput.text.length > 0)
            root.submitted(passwordInput.text);
    }

    function alpha(c, a) {
        return Qt.rgba(Qt.color(c).r, Qt.color(c).g, Qt.color(c).b, a);
    }

    Component.onCompleted: entranceAnim.start()

    NumberAnimation {
        id: entranceAnim
        target: root
        property: "entrance"
        from: 0
        to: 1
        duration: 700
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: root.scheme.surface
    }

    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
        sourceSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaperImage
        visible: wallpaperImage.status === Image.Ready
        blurEnabled: root.blur > 0
        blur: root.blur
        blurMax: 64
        autoPaddingEnabled: false
        saturation: 0.05
        scale: 1.02 + 0.03 * (1 - root.entrance)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.alpha(root.scheme.surface, root.scrim + 0.15) }
            GradientStop { position: 0.55; color: root.alpha(root.scheme.surface, root.scrim - 0.1) }
            GradientStop { position: 1; color: root.alpha(root.scheme.surface, root.scrim + 0.05) }
        }
    }

    Item {
        id: topLeftSlot
        x: 104 * root.s
        y: 64 * root.s
        width: 600 * root.s
        height: childrenRect.height
        opacity: root.entrance
    }

    Column {
        id: clock
        x: 104 * root.s
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (40 + 24 * (1 - root.entrance)) * root.s
        opacity: root.entrance
        spacing: 2 * root.s

        readonly property int hour: root.use24h ? root.now.getHours() : ((root.now.getHours() + 11) % 12 + 1)

        Column {
            spacing: -38 * root.s

            Text {
                text: root.use24h ? String(clock.hour).padStart(2, "0") : String(clock.hour)
                font.family: root.fontFamily
                font.pixelSize: 156 * root.s
                font.weight: Font.Normal
                color: root.scheme.onSurface
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
                    color: root.scheme.primary
                    lineHeight: 0.85
                }

                Rectangle {
                    visible: !root.use24h
                    anchors.baseline: minutes.baseline
                    anchors.baselineOffset: -30 * root.s
                    width: ampm.implicitWidth + 20 * root.s
                    height: 32 * root.s
                    radius: 8 * root.s
                    color: root.scheme.secondaryContainer

                    Text {
                        id: ampm
                        anchors.centerIn: parent
                        text: root.now.getHours() < 12 ? "AM" : "PM"
                        font.family: root.fontFamily
                        font.pixelSize: 16 * root.s
                        font.weight: Font.Medium
                        color: root.scheme.onSecondaryContainer
                    }
                }
            }
        }

        Item { width: 1; height: 20 * root.s }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            font.family: root.fontFamily
            font.pixelSize: 24 * root.s
            font.weight: Font.Medium
            color: root.scheme.onSurface
        }

        Text {
            text: {
                const h = root.now.getHours();
                const g = h < 5 ? "Still up" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
                return root.greetingName.length > 0 ? g + ", " + root.greetingName : g;
            }
            font.family: root.fontFamily
            font.pixelSize: 17 * root.s
            color: root.scheme.onSurfaceVariant
        }
    }

    Rectangle {
        id: toolbar
        visible: root.powerActions.length > 0
        x: 104 * root.s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (90 - 24 * (1 - root.entrance)) * root.s
        opacity: root.entrance
        width: powerRow.implicitWidth + 16 * root.s
        height: 64 * root.s
        radius: height / 2
        color: root.alpha(root.scheme.surfaceContainer, 0.88)

        Row {
            id: powerRow
            anchors.centerIn: parent
            spacing: 4 * root.s

            Repeater {
                model: root.powerActions

                LockIconButton {
                    required property var modelData
                    s: root.s
                    scheme: root.scheme
                    icon: modelData.icon
                    variant: modelData.id === "poweroff" ? "error" : "standard"
                    iconFont: root.iconFont
                    onClicked: root.powerRequested(modelData.id)
                }
            }
        }
    }

    Item {
        id: rightColumn
        width: 440 * root.s
        anchors.right: parent.right
        anchors.rightMargin: 90 * root.s
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        opacity: root.entrance

        Row {
            id: chipRow
            anchors.right: parent.right
            y: 64 * root.s
            spacing: 8 * root.s
            layoutDirection: Qt.RightToLeft
        }

        Column {
            id: stack
            width: parent.width
            y: Math.max(chipRow.y + chipRow.height + 40 * root.s, parent.height * 0.2) + 32 * root.s * (1 - root.entrance)
            spacing: 12 * root.s

            LockCard {
                id: profile
                width: parent.width
                s: root.s
                tone: root.alpha(root.scheme.surfaceContainer, 0.88)
                padding: 28 * root.s

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96 * root.s
                    height: width
                    radius: width / 2
                    color: root.scheme.primaryContainer

                    Text {
                        anchors.centerIn: parent
                        visible: avatarImage.status !== Image.Ready
                        text: root.displayName.length > 0 ? root.displayName.charAt(0).toUpperCase() : "?"
                        font.family: root.fontFamily
                        font.pixelSize: 40 * root.s
                        font.weight: Font.Medium
                        color: root.scheme.onPrimaryContainer
                    }

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: root.avatar
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                        sourceSize: Qt.size(width * 2, height * 2)
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: avatarImage
                        radius: width / 2
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: avatarImage
                        source: avatarImage
                        visible: avatarImage.status === Image.Ready
                        maskEnabled: true
                        maskSource: avatarMask
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.displayName
                    font.family: root.fontFamily
                    font.pixelSize: 24 * root.s
                    font.weight: Font.Medium
                    color: root.scheme.onSurface
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.nameClicked()
                    }
                }

                Item { width: 1; height: 6 * root.s }

                Item {
                    id: fieldRow
                    width: parent.width
                    height: 56 * root.s

                    readonly property bool raised: passwordInput.activeFocus || passwordInput.text.length > 0
                    readonly property bool showError: root.messageIsError && root.message.length > 0

                    Rectangle {
                        id: field
                        anchors.left: parent.left
                        anchors.right: go.left
                        anchors.rightMargin: 10 * root.s
                        height: parent.height
                        radius: 16 * root.s
                        color: root.scheme.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: passwordInput.activeFocus || fieldRow.showError ? 2 : 1
                            color: fieldRow.showError ? root.scheme.error : (passwordInput.activeFocus ? root.scheme.primary : root.scheme.outline)
                        }

                        Text {
                            id: lockGlyph
                            x: 16 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: fieldRow.showError ? "error" : "lock"
                            font.family: root.iconFont
                            font.pixelSize: 22 * root.s
                            color: fieldRow.showError ? root.scheme.error : root.scheme.onSurfaceVariant
                        }

                        Text {
                            id: label
                            x: lockGlyph.x + lockGlyph.width + 14 * root.s
                            y: fieldRow.raised ? 7 * root.s : (parent.height - height) / 2
                            text: "Password"
                            font.family: root.fontFamily
                            font.pixelSize: (fieldRow.raised ? 12 : 16) * root.s
                            color: fieldRow.showError ? root.scheme.error : (passwordInput.activeFocus ? root.scheme.primary : root.scheme.onSurfaceVariant)

                            Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        TextInput {
                            id: passwordInput
                            anchors.left: label.left
                            anchors.right: parent.right
                            anchors.rightMargin: 16 * root.s
                            y: 22 * root.s
                            height: 28 * root.s
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            font.family: root.fontFamily
                            font.pixelSize: 18 * root.s
                            font.letterSpacing: 3 * root.s
                            color: root.scheme.onSurface
                            selectionColor: root.scheme.primary
                            clip: true
                            focus: true
                            enabled: root.inputEnabled && !root.busy
                            onTextChanged: root.passwordEdited(text)
                            onAccepted: root.submit()
                            Keys.onEscapePressed: text = ""
                        }

                        Rectangle {
                            id: progressTrack
                            visible: root.busy
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 3 * root.s
                            color: root.scheme.secondaryContainer

                            Rectangle {
                                id: progressBar
                                width: parent.width * 0.35
                                height: parent.height
                                radius: height / 2
                                color: root.scheme.primary

                                NumberAnimation on x {
                                    running: root.busy
                                    from: -progressBar.width
                                    to: progressTrack.width
                                    duration: 1100
                                    loops: Animation.Infinite
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }
                    }

                    LockIconButton {
                        id: go
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        size: 56
                        scheme: root.scheme
                        iconFont: root.iconFont
                        icon: "arrow_forward"
                        variant: passwordInput.text.length > 0 && !root.busy ? "filled" : "tonal"
                        corner: 16
                        onClicked: root.submit()
                    }
                }

                Row {
                    visible: root.message.length > 0 || root.capsLock
                    width: parent.width
                    spacing: 6 * root.s
                    leftPadding: 16 * root.s

                    Text {
                        text: root.message.length > 0 ? root.message : "Caps Lock is on"
                        font.family: root.fontFamily
                        font.pixelSize: 13 * root.s
                        color: root.messageIsError && root.message.length > 0 ? root.scheme.error : root.scheme.onSurfaceVariant
                        width: parent.width - parent.leftPadding
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Column {
                id: cardColumn
                width: parent.width
                spacing: 12 * root.s
            }
        }
    }
}
