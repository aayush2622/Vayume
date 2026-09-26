import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import SddmComponents 2.0
import "vayori"

Rectangle {
    id: root
    width: Screen.width; height: Screen.height
    color: "#0d1224"

    readonly property real s: height / 768

    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property bool busy: false
    property bool failed: false

    readonly property string fontName: (typeof config !== "undefined" && config.fontFamily) ? config.fontFamily : mainFont.name
    readonly property url background: (typeof config !== "undefined" && config.background) ? Qt.resolvedUrl(config.background) : ""
    readonly property real cursorSizePx: (typeof config !== "undefined" && config.cursorSize) ? Number(config.cursorSize) : 24

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    TextConstants { id: textConstants }

    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || ""; property string uIcon: model.icon || "" } }

    Timer { interval: 300; running: true; onTriggered: scene.focusPassword() }
    Component.onCompleted: { if (typeof keyboard !== "undefined") keyboard.numLock = true }

    LockScene {
        id: scene
        anchors.fill: parent
        focus: true
        wallpaper: root.background
        capsLock: typeof keyboard !== "undefined" && keyboard.capsLock
        fontFamily: root.fontName
        displayName: userHelper.currentItem ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        avatar: userHelper.currentItem && userHelper.currentItem.uIcon ? "file://" + userHelper.currentItem.uIcon : ""
        busy: root.busy
        message: root.failed ? "Wrong password - try again" : ""
        messageIsError: root.failed
        powerActions: {
            var a = []
            if (typeof sddm !== "undefined" && sddm.canSuspend) a.push({ id: "suspend", icon: "bedtime" })
            if (typeof sddm !== "undefined" && sddm.canHibernate) a.push({ id: "hibernate", icon: "ac_unit" })
            a.push({ id: "reboot", icon: "restart_alt" })
            a.push({ id: "poweroff", icon: "power_settings_new" })
            return a
        }
        onSubmitted: password => root.doLogin(password)
        onPasswordEdited: root.failed = false
        onNameClicked: { if (typeof userModel !== "undefined" && userModel.rowCount() > 1) root.userIndex = (root.userIndex + 1) % userModel.rowCount() }
        onPowerRequested: id => {
            if (typeof sddm === "undefined") return
            if (id === "suspend") sddm.suspend()
            else if (id === "hibernate") sddm.hibernate()
            else if (id === "reboot") sddm.reboot()
            else if (id === "poweroff") sddm.powerOff()
        }

        chips: [
            LockChip {
                s: scene.s
                scheme: scene.scheme
                fontFamily: scene.fontFamily
                icon: "desktop_windows"
                text: sessionHelper.currentItem ? sessionHelper.currentItem.sName : "session"
                MouseArea {
                    anchors.fill: parent
                    onClicked: { if (typeof sessionModel !== "undefined") root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                }
            },
            LockChip {
                s: scene.s
                scheme: scene.scheme
                fontFamily: scene.fontFamily
                icon: "computer"
                text: typeof sddm !== "undefined" && sddm.hostName ? sddm.hostName : ""
                visible: text.length > 0
            }
        ]

        topLeft: Row {
            spacing: 12 * scene.s
            Text { text: "夜"; font.family: "Noto Serif CJK JP"; font.pixelSize: 26 * scene.s; color: scene.scheme.onSurface; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Vayume"; font.family: scene.fontFamily; font.pixelSize: 16 * scene.s; font.weight: Font.Medium; color: scene.scheme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
        }

    }

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
            ctx.strokeStyle = "#0d1224"
            ctx.stroke()
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { root.busy = false; root.failed = true; scene.clearPassword(); scene.focusPassword() }
        function onLoginSucceeded() { root.busy = false }
    }

    function doLogin(password) {
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        if (typeof sddm === "undefined" || password.length === 0) return
        root.failed = false
        root.busy = true
        sddm.login(u, password, root.sessionIndex)
    }
}
