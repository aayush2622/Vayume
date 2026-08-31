import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Theme
Rectangle {
    id: root
    width: Screen.width; height: Screen.height
    readonly property real s: height / 768
    color: "#f0eee9"

    // Palette
    readonly property color cInk:    "#4b4b4b"
    readonly property color cSub:    "#8b8b8b"
    readonly property color cPink:   "#d37785"
    readonly property color cGlass:  "#20000000"

    // State
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0

    // Cursor size, from vayori.theme.cursorSize via theme.conf (see SddmTheme.nix) -
    // falls back to a sane default if the config key isn't there for any reason.
    readonly property real cursorSizePx: (typeof config !== "undefined" && config.cursorSize) ? Number(config.cursorSize) : 24

    // Assets
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    TextConstants { id: textConstants }

    // Helpers
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Logic
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }
    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic }

    // Background
    Image {
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.ui
    }

    // Shadow
    Rectangle {
        anchors.fill: parent; visible: root.ui < 1.0; opacity: 1.0 - root.ui; color: "#f0eee9"; z: 100
    }

    // Header
    Item {
        anchors.top: parent.top; anchors.left: parent.left
        anchors.margins: 60 * s; height: 120 * s; opacity: root.ui
        
        Column {
            anchors.left: parent.left; spacing: -10 * s
            Text {
                id: clockText; text: Qt.formatTime(new Date(), "HH:mm")
                color: root.cInk; font.family: mainFont.name; font.pixelSize: 84 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") }
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toLowerCase()
                color: root.cSub; font.family: mainFont.name; font.pixelSize: 18 * s; font.letterSpacing: 1 * s
            }
        }
    }

    // Login
    Item {
        id: bellyArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.width * 0.20
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.height * 0.20
        width: 250 * s; height: loginCol.height
        opacity: root.ui

        Column {
            id: loginCol; width: parent.width; spacing: 18 * s

            // User
            Text {
                id: userDisp; anchors.horizontalCenter: parent.horizontalCenter
                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? userModel.lastUser : "user")).toUpperCase()
                color: userMa.containsMouse ? root.cPink : root.cInk; font.family: mainFont.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                Behavior on color { ColorAnimation { duration: 200 } }
                MouseArea { id: userMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.BlankCursor; onClicked: { if (typeof userModel !== "undefined") root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
            }

            // Input
            Rectangle {
                width: parent.width; height: 42 * s; radius: 10 * s; color: root.cGlass
                border.color: pwd.activeFocus ? root.cInk : "transparent"; border.width: 1 * s
                Behavior on border.color { ColorAnimation { duration: 300 } }

                TextInput {
                    id: pwd; anchors.fill: parent; anchors.leftMargin: 15*s; anchors.rightMargin: 15*s
                    horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password; passwordCharacter: "•"; color: root.cInk
                    font.family: mainFont.name; font.pixelSize: 18 * s; font.letterSpacing: 8 * s
                    focus: true; clip: true; cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    onAccepted: doLogin()
                    
                    Text {
                        anchors.centerIn: parent; text: "password"; color: root.cSub; opacity: pwd.text.length === 0 ? 0.6 : 0
                        font.family: mainFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // Cursor
                    Rectangle {
                        id: cursor; width: 2 * s; height: 18 * s; color: root.cInk; anchors.verticalCenter: parent.verticalCenter
                        x: pwd.cursorRectangle.x; visible: pwd.focus && pwd.text.length > 0
                        SequentialAnimation { loops: Animation.Infinite; running: cursor.visible; NumberAnimation { target: cursor; property: "opacity"; from: 1.0; to: 0.1; duration: 450 } NumberAnimation { target: cursor; property: "opacity"; from: 0.1; to: 1.0; duration: 450 } }
                    }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: Qt.BlankCursor; onClicked: pwd.forceActiveFocus() }
            }

            // Error
            Text {
                id: errorMsg; anchors.horizontalCenter: parent.horizontalCenter
                text: ""; color: root.cPink; font.family: mainFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1 * s
                visible: text !== ""
            }

            // Actions
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 25 * s
                Repeater {
                    model: [
                        { l: "SESSION", a: 0 },
                        { l: "REBOOT", a: 1 },
                        { l: "POWER", a: 2 }
                    ]
                    delegate: Text {
                        text: (modelData.a === 0 && sessionHelper.currentItem) ? sessionHelper.currentItem.sName.toUpperCase() : modelData.l
                        color: actMa.containsMouse ? root.cPink : root.cSub; font.family: mainFont.name; font.pixelSize: 11 * s; font.letterSpacing: 2 * s
                        Behavior on color { ColorAnimation { duration: 200 } }
                        MouseArea {
                            id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.BlankCursor
                            onClicked: {
                                if (modelData.a === 0) { if (typeof sessionModel !== "undefined") root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                                else if (modelData.a === 1) { if (typeof sddm !== "undefined") sddm.reboot() }
                                else if (modelData.a === 2) { if (typeof sddm !== "undefined") sddm.powerOff() }
                            }
                        }
                    }
                }
            }
        }
    }

    // Cursor - drawn here in QML instead of relying on the greeter picking up
    // XCURSOR_THEME over Wayland, which has been unreliable (see docs/core.md).
    // HoverHandler only observes position, it never grabs clicks - safe to sit
    // on root without breaking the password field or the buttons below it.
    HoverHandler {
        id: pointerTracker
        target: root
        cursorShape: Qt.BlankCursor
        onPointChanged: {
            cursorCanvas.x = point.position.x
            cursorCanvas.y = point.position.y
        }
    }

    Canvas {
        id: cursorCanvas
        readonly property real size: Math.max(12, root.cursorSizePx) * root.s * 0.85
        width: size; height: size
        z: 1000
        visible: pointerTracker.hovered
        onSizeChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(0, size * 0.75)
            ctx.lineTo(size * 0.28, size * 0.58)
            ctx.lineTo(size * 0.45, size)
            ctx.lineTo(size * 0.62, size * 0.92)
            ctx.lineTo(size * 0.43, size * 0.48)
            ctx.lineTo(size * 0.72, size * 0.48)
            ctx.closePath()
            ctx.fillStyle = "#f5f5f5"
            ctx.fill()
            ctx.lineWidth = Math.max(1, size * 0.05)
            ctx.strokeStyle = root.cInk
            ctx.stroke()
        }
    }

    // Wiring
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { errorMsg.text = "try again"; pwd.text = ""; pwd.focus = true }
    }

    function doLogin() {
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex)
    }
}
