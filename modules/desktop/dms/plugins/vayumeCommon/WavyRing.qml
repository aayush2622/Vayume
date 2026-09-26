import QtQuick

Item {
    id: root

    property real value: 0
    property real waveHeight: 2.2
    property int waves: 9
    property real thickness: 6
    property color activeColor: "white"
    property color trackColor: "gray"

    property real shownValue: Math.max(0, Math.min(1, root.value))

    Behavior on shownValue {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    onShownValueChanged: canvas.requestPaint()
    onActiveColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2;
            const cy = height / 2;
            const r = Math.min(width, height) / 2 - root.thickness / 2 - root.waveHeight - 1;
            if (r <= 0)
                return;
            const start = -Math.PI / 2;
            const sweep = root.shownValue * Math.PI * 2;
            const gap = (root.thickness + 5) / r;
            ctx.lineCap = "round";
            ctx.lineWidth = root.thickness;

            if (sweep > 0.02) {
                ctx.strokeStyle = root.activeColor;
                ctx.beginPath();
                const end = start + Math.max(0.02, sweep - (sweep < Math.PI * 2 - 0.01 ? gap / 2 : 0));
                for (let a = start; a <= end; a += 0.015) {
                    const rr = r + root.waveHeight * Math.sin(root.waves * (a - start));
                    const x = cx + rr * Math.cos(a);
                    const y = cy + rr * Math.sin(a);
                    if (a === start)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }

            const trackFrom = start + sweep + (sweep > 0.02 ? gap : 0);
            const trackTo = start + Math.PI * 2 - (sweep > 0.02 ? gap / 2 : 0);
            if (trackTo - trackFrom > 0.02) {
                ctx.strokeStyle = root.trackColor;
                ctx.beginPath();
                ctx.arc(cx, cy, r, trackFrom, trackTo, false);
                ctx.stroke();
            }
        }
    }
}
