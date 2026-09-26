import QtQuick

Rectangle {
    id: root

    property real s: 1
    property color tone: "#e11d1f2c"
    default property alias content: inner.data
    property real padding: 20 * root.s

    implicitHeight: inner.implicitHeight + root.padding * 2
    radius: 28 * root.s
    color: root.tone

    Column {
        id: inner
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 12 * root.s
    }
}
