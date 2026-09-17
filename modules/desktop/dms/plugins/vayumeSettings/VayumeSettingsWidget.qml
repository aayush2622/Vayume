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
    ccDetailHeight: 560

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

            property var theme: ({ font: "", fontSize: 11, cursorTheme: "", iconTheme: "" })
            property string themeStatus: ""
            readonly property var cursorOptions: [
                "Bibata-Modern-Ice", "Bibata-Modern-Classic", "Bibata-Modern-Amber",
                "Bibata-Original-Ice", "Bibata-Original-Classic", "Bibata-Original-Amber"
            ]

            function refreshTheme() {
                themeGetProc.running = true;
            }

            function setFontSize(delta) {
                const next = detailRoot.theme.fontSize + delta;
                if (next < 8 || next > 24) return;
                themeSetProc.command = ["vayume-config", "theme", "set", "fontSize", String(next)];
                themeSetProc.running = true;
            }

            function cycleCursor() {
                const options = detailRoot.cursorOptions;
                const idx = options.indexOf(detailRoot.theme.cursorTheme);
                const next = options[(idx + 1 + options.length) % options.length];
                themeSetProc.command = ["vayume-config", "theme", "set", "cursorTheme", next];
                themeSetProc.running = true;
            }

            readonly property var categoryOrder: ({ "development": 0, "gaming": 1, "utils": 2 })
            readonly property var categoryLabels: ({
                "development": I18n.tr("Development"),
                "gaming": I18n.tr("Gaming"),
                "utils": I18n.tr("Applications")
            })
            readonly property var sortedApps: {
                const copy = detailRoot.apps.slice();
                copy.sort((a, b) => {
                    const ca = detailRoot.categoryOrder[a.category] ?? 99;
                    const cb = detailRoot.categoryOrder[b.category] ?? 99;
                    if (ca !== cb) return ca - cb;
                    return a.name.localeCompare(b.name);
                });
                return copy;
            }

            function refreshApps() {
                appsLoading = true;
                appsListProc.running = true;
            }

            Component.onCompleted: {
                refreshApps();
                refreshTheme();
            }

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
                id: themeGetProc
                command: ["vayume-config", "theme", "get"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            detailRoot.theme = JSON.parse(text);
                        } catch (e) {
                            // keep the previous value on a parse failure
                        }
                    }
                }
            }

            Process {
                id: themeSetProc
                running: false
                onExited: exitCode => {
                    detailRoot.themeStatus = exitCode === 0
                        ? I18n.tr("Applied.")
                        : I18n.tr("Change rejected - see a terminal for why.");
                    detailRoot.refreshTheme();
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
                    text: I18n.tr("Appearance")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Font Size")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120
                    }

                    DankIcon {
                        name: "remove"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: detailRoot.setFontSize(-1)
                        }
                    }

                    StyledText {
                        text: detailRoot.theme.fontSize
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                    }

                    DankIcon {
                        name: "add"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: detailRoot.setFontSize(1)
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Cursor")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120
                    }

                    StyledRect {
                        width: 220
                        height: 28
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerLow

                        StyledText {
                            anchors.centerIn: parent
                            text: detailRoot.theme.cursorTheme
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: detailRoot.cycleCursor()
                        }
                    }

                    StyledText {
                        text: detailRoot.themeStatus
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
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
                    height: 280
                    clip: true
                    spacing: 2
                    model: detailRoot.sortedApps

                    section.property: "category"
                    section.criteria: ViewSection.FullString
                    section.delegate: Item {
                        width: appsListView.width
                        height: 28

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailRoot.categoryLabels[section] ?? section
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceVariantText
                        }
                    }

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
                        detailRoot.rebuildStatus = I18n.tr("Saved - rebuild to apply.");
                    }
                    detailRoot.refreshApps();
                    repoProc.running = true;
                }
            }
        }
    }
}
