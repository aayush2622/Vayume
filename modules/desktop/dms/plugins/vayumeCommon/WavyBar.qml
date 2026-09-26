import QtQuick

Item {
    id: root

    property real value: 0
    property bool moving: false
    property real waveHeight: 3
    property real wavelength: 30
    property real thickness: 5
    property real gap: 5
    property bool showHandle: true
    property color activeColor: "white"
    property color trackColor: "gray"
    property real phase: 0

    readonly property real amplitude: root.moving ? root.waveHeight : 0
    property real shownAmplitude: root.amplitude

    implicitHeight: 24

    Behavior on shownAmplitude {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation on phase {
        running: root.moving && root.visible
        from: 0
        to: Math.PI * 2
        duration: 1400
        loops: Animation.Infinite
    }

    onValueChanged: canvas.requestPaint()
    onPhaseChanged: canvas.requestPaint()
    onShownAmplitudeChanged: canvas.requestPaint()
    onActiveColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width;
            const cy = height / 2;
            const t = root.thickness;
            const handle = root.showHandle ? 4 : 0;
            const split = Math.max(t / 2, Math.min(w - t / 2, w * Math.max(0, Math.min(1, root.value))));
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.lineWidth = t;

            const waveEnd = split - (root.showHandle ? root.gap + handle / 2 : 0);
            if (waveEnd > t / 2) {
                ctx.strokeStyle = root.activeColor;
                ctx.beginPath();
                const k = Math.PI * 2 / root.wavelength;
                for (let x = t / 2; x <= waveEnd; x += 1) {
                    const y = cy + root.shownAmplitude * Math.sin(x * k - root.phase);
                    if (x === t / 2)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }

            const trackStart = split + root.gap + handle / 2;
            if (trackStart < w - t / 2) {
                ctx.strokeStyle = root.trackColor;
                ctx.beginPath();
                ctx.moveTo(trackStart, cy);
                ctx.lineTo(w - t / 2, cy);
                ctx.stroke();
                ctx.fillStyle = root.activeColor;
                ctx.beginPath();
                ctx.arc(w - t / 2, cy, t / 2 - 1, 0, Math.PI * 2);
                ctx.fill();
            }

            if (root.showHandle) {
                ctx.fillStyle = root.activeColor;
                ctx.beginPath();
                ctx.roundedRect(split - handle / 2, cy - height * 0.42, handle, height * 0.84, handle / 2, handle / 2);
                ctx.fill();
            }
        }
    }
}
