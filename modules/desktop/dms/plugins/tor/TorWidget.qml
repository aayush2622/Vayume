import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool torActive: false
    property bool busy: false

    ccWidgetIcon: "vpn_lock"
    ccWidgetPrimaryText: I18n.tr("Tor")
    ccWidgetSecondaryText: {
        if (root.busy)
            return I18n.tr("Working...");
        return root.torActive ? I18n.tr("All traffic routed") : I18n.tr("Direct connection");
    }
    ccWidgetIsActive: root.torActive

    onCcWidgetToggled: {
        if (root.busy)
            return;
        root.busy = true;
        toggleProc.command = ["vayume-tor", root.torActive ? "stop" : "start"];
        toggleProc.running = true;
    }

    // `vayume-tor status` prints exactly "active" or "inactive" - see
    // modules/system/network/Network.nix.
    Process {
        id: statusProc
        command: ["vayume-tor", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.torActive = text.trim() === "active";
                root.busy = false;
            }
        }
    }

    Process {
        id: toggleProc
        running: false
        onExited: statusProc.running = true
    }

    // Tor takes a moment to bootstrap, and it can also be started or
    // stopped from outside this widget, so re-read rather than trusting
    // the last toggle.
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!statusProc.running)
                statusProc.running = true;
        }
    }
}
