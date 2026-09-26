import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: pet

    property var cfg: ({})
    property var masks: ({})
    property real areaWidth: 1920
    property real areaHeight: 1080
    property real screenX: 0
    property real screenY: 0

    readonly property int cell: 32
    readonly property int px: Math.max(1, cfg.size ?? 3)
    readonly property real speed: Math.max(1, cfg.speed ?? 10)
    readonly property string behaviour: cfg.behaviour ?? "wander"
    readonly property real restlessness: ({
            lazy: 0.004,
            normal: 0.01,
            playful: 0.025
        })[cfg.activity ?? "normal"] ?? 0.01
    readonly property int napLength: ({
            lazy: 600,
            normal: 300,
            playful: 150
        })[cfg.activity ?? "normal"] ?? 300
    readonly property bool bubbles: cfg.bubbles ?? true
    readonly property string petName: cfg.name ?? ""

    readonly property var sprites: ({
            idle: [[3, 3]],
            alert: [[7, 3]],
            scratchSelf: [[5, 0], [6, 0], [7, 0]],
            scratchWallN: [[0, 0], [0, 1]],
            scratchWallS: [[7, 1], [6, 2]],
            scratchWallE: [[2, 2], [2, 3]],
            scratchWallW: [[4, 0], [4, 1]],
            tired: [[3, 2]],
            sleeping: [[2, 0], [2, 1]],
            N: [[1, 2], [1, 3]],
            NE: [[0, 2], [0, 3]],
            E: [[3, 0], [3, 1]],
            SE: [[5, 1], [5, 2]],
            S: [[6, 3], [7, 2]],
            SW: [[5, 3], [6, 1]],
            W: [[4, 2], [4, 3]],
            NW: [[1, 0], [1, 1]]
        })

    property string mode: "idle"
    property int modeFrame: 0
    property int idleTicks: 0
    property int tick: 0
    property string sprite: "idle"
    property int spriteFrame: 0
    property real targetX: 0
    property real targetY: 0
    property string wall: ""
    property point dragVelocity: Qt.point(0, 0)
    property int stillTicks: 0

    readonly property var spriteCell: sprites[sprite][spriteFrame % sprites[sprite].length]
    readonly property string cellKey: spriteCell[0] + "," + spriteCell[1]
    readonly property real maxX: Math.max(0, areaWidth - width)
    readonly property real maxY: Math.max(0, areaHeight - height)

    width: cell * px
    height: cell * px

    function setMode(m) {
        mode = m;
        modeFrame = 0;
        idleTicks = 0;
    }

    function show(name, frame) {
        sprite = name;
        spriteFrame = frame;
    }

    function clampX(v) {
        return Math.max(0, Math.min(v, maxX));
    }

    function clampY(v) {
        return Math.max(0, Math.min(v, maxY));
    }

    function edgeWall() {
        if (x <= 0)
            return "W";
        if (x >= maxX)
            return "E";
        if (y <= 0)
            return "N";
        if (y >= maxY)
            return "S";
        return "";
    }

    function headingTo(dx, dy) {
        const d = Math.sqrt(dx * dx + dy * dy);
        let dir = dy / d < -0.5 ? "N" : dy / d > 0.5 ? "S" : "";
        dir += dx / d < -0.5 ? "W" : dx / d > 0.5 ? "E" : "";
        return dir === "" ? "idle" : dir;
    }

    function stepToward(tx, ty) {
        const dx = tx - x;
        const dy = ty - y;
        const d = Math.sqrt(dx * dx + dy * dy);
        if (d <= speed) {
            x = clampX(tx);
            y = clampY(ty);
            return true;
        }
        show(headingTo(dx, dy), tick);
        x = clampX(x + dx / d * speed);
        y = clampY(y + dy / d * speed);
        return false;
    }

    function pickWanderTarget() {
        const reach = Math.min(areaWidth, areaHeight) * 0.35;
        const angle = Math.random() * Math.PI * 2;
        const dist = reach * (0.3 + Math.random() * 0.7);
        targetX = clampX(x + Math.cos(angle) * dist);
        targetY = clampY(y + Math.sin(angle) * dist * 0.6);
    }

    function startSomething() {
        const options = ["sleep", "scratch"];
        if (behaviour === "wander")
            options.push("walk", "walk");
        const w = edgeWall();
        if (w !== "") {
            wall = w;
            options.push("wall");
        }
        const pick = options[Math.floor(Math.random() * options.length)];
        if (pick === "walk")
            pickWanderTarget();
        setMode(pick);
    }

    function step() {
        tick++;
        const chasing = behaviour === "follow" && cursor.valid && mode !== "held" && mode !== "happy";
        if (chasing) {
            const cx = cursor.x - screenX - width / 2;
            const cy = cursor.y - screenY - height / 2;
            const far = Math.hypot(cx - x, cy - y) > 48;
            if (far && mode !== "chase" && mode !== "alertChase") {
                setMode("alertChase");
            }
            if (mode === "alertChase") {
                show("alert", 0);
                if (++modeFrame > 3)
                    setMode("chase");
                return;
            }
            if (mode === "chase") {
                if (!far || stepToward(cx, cy)) {
                    saveState();
                    setMode("idle");
                }
                return;
            }
        }

        switch (mode) {
        case "held":
            {
                const fast = Math.abs(dragVelocity.x) + Math.abs(dragVelocity.y) > 6;
                stillTicks = fast ? 0 : stillTicks + 1;
                if (stillTicks > 2) {
                    show("alert", 0);
                } else if (Math.abs(dragVelocity.x) > Math.abs(dragVelocity.y)) {
                    show(dragVelocity.x > 0 ? "scratchWallW" : "scratchWallE", tick);
                } else {
                    show(dragVelocity.y > 0 ? "scratchWallN" : "scratchWallS", tick);
                }
                dragVelocity = Qt.point(dragVelocity.x * 0.5, dragVelocity.y * 0.5);
                return;
            }
        case "happy":
            show(modeFrame < 14 ? "scratchSelf" : "idle", modeFrame);
            if (++modeFrame > 26)
                setMode("idle");
            return;
        case "alert":
            show("alert", 0);
            if (++modeFrame > 7)
                setMode("idle");
            return;
        case "sleep":
            show(modeFrame < 10 ? "tired" : "sleeping", Math.floor(modeFrame / 5));
            if (++modeFrame > napLength)
                setMode("alert");
            return;
        case "scratch":
            show("scratchSelf", modeFrame);
            if (++modeFrame > 12)
                setMode("idle");
            return;
        case "wall":
            show("scratchWall" + wall, modeFrame);
            if (++modeFrame > 14)
                setMode("idle");
            return;
        case "walk":
            if (stepToward(targetX, targetY)) {
                saveState();
                wall = edgeWall();
                setMode(wall !== "" && Math.random() < 0.5 ? "wall" : "idle");
            }
            return;
        }

        show("idle", 0);
        if (++idleTicks > 30 && Math.random() < restlessness)
            startSomething();
    }

    function saveState() {
        stateFile.setText(JSON.stringify({
            x: areaWidth > 0 ? x / areaWidth : 0,
            y: areaHeight > 0 ? y / areaHeight : 0
        }));
    }

    function restoreState() {
        let saved = null;
        try {
            saved = JSON.parse(stateFile.text());
        } catch (e) {
            saved = null;
        }
        if (saved && typeof saved.x === "number") {
            x = clampX(saved.x * areaWidth);
            y = clampY(saved.y * areaHeight);
        } else {
            x = clampX((cfg.startX ?? 0.08) * areaWidth);
            y = clampY((cfg.startY ?? 0.8) * areaHeight);
        }
    }

    FileView {
        id: stateFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/vayume-pet/pet.json"
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: placeTimer
        interval: 50
        onTriggered: pet.restoreState()
    }

    onAreaWidthChanged: placeTimer.restart()
    onAreaHeightChanged: placeTimer.restart()

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: pet.step()
    }

    QtObject {
        id: cursor

        property real x: 0
        property real y: 0
        property bool valid: false
        readonly property string signature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""
        readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR") ?? ""
    }

    Socket {
        id: hyprSocket

        property real nextX: 0

        path: cursor.runtime + "/hypr/" + cursor.signature + "/.socket.sock"
        onConnectedChanged: {
            if (connected) {
                write("j/cursorpos");
                flush();
            }
        }
        parser: SplitParser {
            onRead: line => {
                const mx = line.match(/"x":\s*(-?\d+)/);
                if (mx)
                    hyprSocket.nextX = Number(mx[1]);
                const my = line.match(/"y":\s*(-?\d+)/);
                if (my) {
                    cursor.x = hyprSocket.nextX;
                    cursor.y = Number(my[1]);
                    cursor.valid = true;
                }
            }
        }
    }

    Timer {
        interval: 100
        running: pet.behaviour === "follow" && cursor.signature !== ""
        repeat: true
        onTriggered: {
            hyprSocket.connected = false;
            hyprSocket.connected = true;
        }
    }

    Item {
        id: frameBox
        anchors.fill: parent
        clip: true

        Image {
            source: Qt.resolvedUrl("skin.png")
            width: 256 * pet.px
            height: 128 * pet.px
            smooth: false
            x: -pet.spriteCell[0] * pet.cell * pet.px
            y: -pet.spriteCell[1] * pet.cell * pet.px
        }
    }

    Repeater {
        model: pet.bubbles && pet.mode === "happy" ? 4 : 0

        Text {
            required property int index
            text: "♥"
            color: "#ff6f9c"
            style: Text.Outline
            styleColor: "#40101c"
            font.pixelSize: (5 + index * 2) * pet.px
            x: pet.width * (0.1 + index * 0.25)
            y: pet.height * 0.05 - pet.modeFrame * (0.6 + index * 0.25) * pet.px
            opacity: Math.max(0, 1 - pet.modeFrame / 26)
        }
    }

    Repeater {
        model: pet.bubbles && pet.mode === "sleep" && pet.modeFrame > 10 ? 3 : 0

        Text {
            required property int index
            readonly property real phase: ((pet.tick + index * 12) % 36) / 36
            text: "z"
            color: "#f2f2ff"
            style: Text.Outline
            styleColor: "#20203a"
            font.bold: true
            font.pixelSize: (4 + phase * 5) * pet.px
            x: pet.width * (0.6 + phase * 0.35)
            y: pet.height * (0.2 - phase * 0.55)
            opacity: phase < 0.8 ? 1 : (1 - phase) * 5
        }
    }

    Text {
        visible: pet.bubbles && (pet.mode === "alert" || pet.mode === "alertChase")
        text: "!"
        color: "#ffd166"
        style: Text.Outline
        styleColor: "#3a2a00"
        font.bold: true
        font.pixelSize: 8 * pet.px
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: -2 * pet.px
    }

    Rectangle {
        visible: opacity > 0
        opacity: pet.petName !== "" && (grab.containsMouse || grab.pressed) ? 1 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        width: tag.implicitWidth + 16
        height: tag.implicitHeight + 8
        radius: height / 2
        color: "#cc1b1b24"

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Text {
            id: tag
            anchors.centerIn: parent
            text: pet.petName
            color: "#f4f4fb"
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: grab
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property point anchor
        property bool dragged: false

        onPressed: mouse => {
            anchor = Qt.point(mouse.x, mouse.y);
            dragged = false;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const dx = mouse.x - anchor.x;
            const dy = mouse.y - anchor.y;
            if (!dragged && Math.abs(dx) + Math.abs(dy) < 4)
                return;
            if (!dragged) {
                dragged = true;
                pet.stillTicks = 0;
                pet.setMode("held");
            }
            pet.dragVelocity = Qt.point(pet.dragVelocity.x + dx, pet.dragVelocity.y + dy);
            pet.x = pet.clampX(pet.x + dx);
            pet.y = pet.clampY(pet.y + dy);
        }
        onReleased: {
            if (dragged) {
                pet.saveState();
                pet.setMode("alert");
            }
        }
        onClicked: {
            if (!dragged)
                pet.setMode("happy");
        }
        onDoubleClicked: pet.setMode(pet.mode === "sleep" ? "alert" : "sleep")
    }
}
