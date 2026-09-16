import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string repoPath: ""
    property string repoBranch: ""
    property bool repoDirty: false
    property bool repoKnown: false

    ccWidgetIcon: "settings_suggest"
    ccWidgetPrimaryText: I18n.tr("Vayume Settings")
    ccWidgetSecondaryText: {
        if (!root.repoKnown)
            return I18n.tr("Loading...");
        return root.repoDirty ? I18n.tr("Uncommitted changes") : I18n.tr("Up to date");
    }
    ccWidgetIsActive: root.repoDirty
    ccDetailHeight: 480

    Process {
        id: repoProc
        command: ["vayume-config", "repo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text);
                    root.repoPath = info.path;
                    root.repoBranch = info.branch;
                    root.repoDirty = info.dirty;
                    root.repoKnown = true;
                } catch (e) {
                    root.repoKnown = false;
                }
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: if (!repoProc.running) repoProc.running = true
    }

    ccDetailContent: Component {
        Rectangle {
            id: detailRoot
            implicitHeight: detailCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            property var apps: []
            property bool appsLoading: true
            property bool rebuildBusy: false
            property string rebuildStatus: ""

            function refreshApps() {
                appsLoading = true;
                appsListProc.running = true;
            }

            Component.onCompleted: refreshApps()

            Process {
                id: appsListProc
                command: ["vayume-config", "apps", "list"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        detailRoot.appsLoading = false;
                        try {
                            detailRoot.apps = JSON.parse(text);
                        } catch (e) {
                            detailRoot.apps = [];
                        }
                    }
                }
            }

            Process {
                id: rebuildProc
                command: ["vayume-rebuild"]
                running: false
                onStarted: {
                    detailRoot.rebuildBusy = true;
                    detailRoot.rebuildStatus = I18n.tr("Rebuilding - this can take a minute...");
                }
                onExited: exitCode => {
                    detailRoot.rebuildBusy = false;
                    detailRoot.rebuildStatus = exitCode === 0
                        ? I18n.tr("Rebuild succeeded.")
                        : I18n.tr("Rebuild failed (exit %1) - check a terminal for details.").arg(exitCode);
                    detailRoot.refreshApps();
                    repoProc.running = true;
                }
            }

            Column {
                id: detailCol
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacingM
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "folder_code"
                        size: 18
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: root.repoKnown ? root.repoPath : I18n.tr("Locating repo...")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideMiddle
                        width: parent.width - 140
                    }
                    StyledText {
                        text: root.repoKnown ? root.repoBranch : ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.repoDirty ? Theme.error : Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledText {
                    text: I18n.tr("Applications")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }

                ListView {
                    id: appsListView
                    width: parent.width
                    height: 260
                    clip: true
                    spacing: 2
                    model: detailRoot.apps

                    delegate: Item {
                        width: appsListView.width
                        height: 34

                        Row {
                            anchors.fill: parent
                            spacing: Theme.spacingS

                            StyledText {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 40
                            }

                            DankIcon {
                                name: modelData.enabled ? "toggle_on" : "toggle_off"
                                size: 24
                                color: modelData.enabled ? Theme.primary : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const newValue = !modelData.enabled;
                                        detailRoot.apps = detailRoot.apps.map(a =>
                                            a.name === modelData.name ? Object.assign({}, a, { enabled: newValue }) : a
                                        );
                                        setAppProc.command = ["vayume-config", "apps", "set", modelData.name, newValue ? "true" : "false"];
                                        setAppProc.running = true;
                                    }
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: detailRoot.appsLoading
                    text: I18n.tr("Loading applications...")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledRect {
                        width: 140
                        height: 36
                        radius: Theme.cornerRadius
                        color: detailRoot.rebuildBusy ? Theme.surfaceContainerLow : Theme.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: detailRoot.rebuildBusy ? I18n.tr("Rebuilding...") : I18n.tr("Rebuild Now")
                            color: detailRoot.rebuildBusy ? Theme.surfaceVariantText : Theme.onPrimary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !detailRoot.rebuildBusy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rebuildProc.running = true
                        }
                    }

                    StyledText {
                        text: detailRoot.rebuildStatus
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        width: parent.width - 160
                    }
                }
            }

            Process {
                id: setAppProc
                running: false
                onExited: exitCode => {
                    if (exitCode !== 0) {
                        detailRoot.rebuildStatus = I18n.tr("Change failed - reloading current state.");
                    } else {
                        detailRoot.rebuildStatus = I18n.tr("Saved to Host.nix - rebuild to apply.");
                    }
                    detailRoot.refreshApps();
                    repoProc.running = true;
                }
            }
        }
    }
}
