import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width; height: Screen.height
    readonly property real s: height / 768
    color: "#f0eee9"

    readonly property color cInk:    "#4b4b4b"
    readonly property color cSub:    "#8b8b8b"
    readonly property color cPink:   "#d37785"
    readonly property color cGlass:  "#20000000"
    readonly property color cPaper:  "#b3fbfaf7"
    readonly property color cLine:   "#26000000"
    readonly property string iconFont: "Material Symbols Rounded"

    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0

    readonly property string fontName: (typeof config !== "undefined" && config.fontFamily) ? config.fontFamily : mainFont.name

    readonly property real cursorSizePx: (typeof config !== "undefined" && config.cursorSize) ? Number(config.cursorSize) : 24

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    TextConstants { id: textConstants }

    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }
    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic }

    Image {
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.ui
    }

    Rectangle {
        anchors.fill: parent; visible: root.ui < 1.0; opacity: 1.0 - root.ui; color: "#f0eee9"; z: 100
    }

    Item {
        anchors.top: parent.top; anchors.left: parent.left
        anchors.margins: 60 * s; height: clockCol.height; width: clockCol.width; opacity: root.ui

        Column {
            id: clockCol
            spacing: 2 * s
            Text {
                id: clockText; text: Qt.formatTime(new Date(), "HH:mm")
                color: root.cInk; font.family: root.fontName; font.pixelSize: 84 * s; font.weight: Font.Light
                Timer { interval: 1000; running: true; repeat: true; onTriggered: { clockText.text = Qt.formatTime(new Date(), "HH:mm"); dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM") } }
            }
            Text {
                id: dateText
                text: Qt.formatDate(new Date(), "dddd, d MMMM")
                color: root.cInk; font.family: root.fontName; font.pixelSize: 18 * s
            }
            Text {
                text: {
                    var h = new Date().getHours()
                    return h < 5 ? "still up" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : "good evening"
                }
                color: root.cSub; font.family: root.fontName; font.pixelSize: 14 * s
            }
        }
    }

    Row {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.margins: 40 * s; spacing: 10 * s; opacity: root.ui * 0.8
        Text { text: "夜"; color: root.cInk; font.family: "Noto Serif CJK JP"; font.pixelSize: 18 * s; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "vayume"; color: root.cSub; font.family: root.fontName; font.pixelSize: 12 * s; font.letterSpacing: 2 * s; anchors.verticalCenter: parent.verticalCenter }
    }

    Item {
        id: bellyArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.width * 0.20
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.height * 0.20
        width: 250 * s; height: loginCol.height
        opacity: root.ui

        Column {
            id: loginCol; width: parent.width; spacing: 14 * s

            Item {
                id: userChip
                anchors.horizontalCenter: parent.horizontalCenter
                width: chipRow.width; height: chipRow.height
                property string name: (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? userModel.lastUser : "user")

                Row {
                id: chipRow
                spacing: 10 * s

                Rectangle {
                    width: 34 * s; height: width; radius: width / 2
                    color: userMa.containsMouse ? root.cPink : root.cPaper
                    border.color: root.cLine; border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: userChip.name.length > 0 ? userChip.name.charAt(0).toUpperCase() : "?"
                        color: userMa.containsMouse ? "#ffffff" : root.cInk
                        font.family: root.fontName; font.pixelSize: 15 * s
                    }
                }

                Text {
                    text: userChip.name
                    color: userMa.containsMouse ? root.cPink : root.cInk
                    font.family: root.fontName; font.pixelSize: 18 * s
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                }

                MouseArea { id: userMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.BlankCursor; onClicked: { if (typeof userModel !== "undefined") root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
            }

            Rectangle {
                width: parent.width; height: 44 * s; radius: height / 2; color: root.cPaper
                border.color: pwd.activeFocus ? root.cInk : root.cLine; border.width: 1
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Text {
                    id: lockIcon
                    anchors.left: parent.left; anchors.leftMargin: 14 * s; anchors.verticalCenter: parent.verticalCenter
                    text: "lock"; color: root.cSub; font.family: root.iconFont; font.pixelSize: 18 * s
                }

                TextInput {
                    id: pwd
                    anchors.left: lockIcon.right; anchors.leftMargin: 8 * s
                    anchors.right: goButton.left; anchors.rightMargin: 8 * s
                    anchors.top: parent.top; anchors.bottom: parent.bottom
                    horizontalAlignment: TextInput.AlignLeft; verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password; passwordCharacter: "•"; color: root.cInk
                    font.family: root.fontName; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                    focus: true; clip: true; cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    onAccepted: doLogin()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter; text: "password"; color: root.cSub; opacity: pwd.text.length === 0 ? 0.8 : 0
                        font.family: root.fontName; font.pixelSize: 14 * s
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: cursor; width: 2 * s; height: 18 * s; color: root.cInk; anchors.verticalCenter: parent.verticalCenter
                        x: pwd.cursorRectangle.x; visible: pwd.focus && pwd.text.length > 0
                        SequentialAnimation { loops: Animation.Infinite; running: cursor.visible; NumberAnimation { target: cursor; property: "opacity"; from: 1.0; to: 0.1; duration: 450 } NumberAnimation { target: cursor; property: "opacity"; from: 0.1; to: 1.0; duration: 450 } }
                    }
                }

                Rectangle {
                    id: goButton
                    anchors.right: parent.right; anchors.rightMargin: 5 * s; anchors.verticalCenter: parent.verticalCenter
                    width: 34 * s; height: width; radius: width / 2
                    color: goMa.containsMouse || pwd.text.length > 0 ? root.cPink : "transparent"
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent; text: "arrow_forward"; font.family: root.iconFont; font.pixelSize: 18 * s
                        color: goMa.containsMouse || pwd.text.length > 0 ? "#ffffff" : root.cSub
                    }
                    MouseArea { id: goMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.BlankCursor; onClicked: doLogin() }
                }

                MouseArea { anchors.fill: pwd; cursorShape: Qt.BlankCursor; onClicked: pwd.forceActiveFocus() }
            }

            Text {
                id: errorMsg; anchors.horizontalCenter: parent.horizontalCenter
                text: ""; color: root.cPink; font.family: root.fontName; font.pixelSize: 13 * s
                visible: text !== ""
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 8 * s
                Repeater {
                    model: [
                        { icon: "desktop_windows", a: 0 },
                        { icon: "bedtime", a: 3 },
                        { icon: "restart_alt", a: 1 },
                        { icon: "power_settings_new", a: 2 }
                    ]
                    delegate: Rectangle {
                        height: 32 * s; radius: height / 2
                        width: modelData.a === 0 ? sessionLabel.width + 44 * s : height
                        color: actMa.containsMouse ? root.cPink : root.cPaper
                        border.color: root.cLine; border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Row {
                            anchors.centerIn: parent; spacing: 6 * s
                            Text {
                                text: modelData.icon; font.family: root.iconFont; font.pixelSize: 16 * s
                                color: actMa.containsMouse ? "#ffffff" : root.cInk
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: sessionLabel
                                visible: modelData.a === 0
                                width: visible ? implicitWidth : 0
                                text: sessionHelper.currentItem ? sessionHelper.currentItem.sName.toLowerCase() : "session"
                                font.family: root.fontName; font.pixelSize: 13 * s
                                color: actMa.containsMouse ? "#ffffff" : root.cInk
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.BlankCursor
                            onClicked: {
                                if (modelData.a === 0) { if (typeof sessionModel !== "undefined") root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                                else if (modelData.a === 1) { if (typeof sddm !== "undefined") sddm.reboot() }
                                else if (modelData.a === 2) { if (typeof sddm !== "undefined") sddm.powerOff() }
                                else if (modelData.a === 3) { if (typeof sddm !== "undefined") sddm.suspend() }
                            }
                        }
                    }
                }
            }
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
            ctx.strokeStyle = root.cInk
            ctx.stroke()
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { errorMsg.text = "try again"; pwd.text = ""; pwd.focus = true }
    }

    function doLogin() {
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex)
    }
}
