import QtQuick
import qs.Common
import qs.Widgets

SettingItem {
    id: root

    required property var vm
    required property var action

    property bool armed: false

    readonly property bool busy: root.vm.rebuildBusy
    readonly property bool needsConfirm: root.action.confirm

    function activate() {
        if (root.busy)
            return;
        if (root.needsConfirm && !root.armed) {
            root.armed = true;
            disarmTimer.restart();
            return;
        }
        root.armed = false;
        root.vm.runAction(root.action);
    }

    title: root.action.panel.label
    description: root.action.description
    meta: "vayume " + [root.action.name].concat(root.action.panel.args).join(" ")
    marker: root.armed ? "warning" : ""

    tags: Badge {
        visible: root.needsConfirm
        label: I18n.tr("Confirm")
        tone: "warning"
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    notes: StyledText {
        visible: root.armed
        text: I18n.tr("Click again within 5 seconds to confirm.")
        font.pixelSize: Vayori.body
        color: Theme.warning
        wrapMode: Text.NoWrap
    }

    Timer {
        id: disarmTimer
        interval: 5000
        onTriggered: root.armed = false
    }

    TextButton {
        width: 112
        icon: root.armed ? "priority_high" : "play_arrow"
        text: root.armed ? I18n.tr("Confirm") : I18n.tr("Run")
        variant: root.armed ? "warning" : "tonal"
        busy: root.busy
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.activate()
    }
}
