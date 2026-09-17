import QtQuick
import qs.Common
import qs.Widgets

DankFloatingWindow {
    id: root

    required property var vm

    title: I18n.tr("Vayume Settings")
    implicitWidth: 820
    implicitHeight: 620
    minimumSize: Qt.size(600, 440)
    visible: false

    property string activeCategory: "appearance"
    property bool logCollapsed: false
    readonly property bool logVisible: root.vm.rebuildLog.length > 0 && !root.logCollapsed
    readonly property var categories: [
        { id: "appearance", label: I18n.tr("Appearance"), icon: "palette" },
        { id: "development", label: I18n.tr("Development"), icon: "code" },
        { id: "applications", label: I18n.tr("Applications"), icon: "apps" },
        { id: "users", label: I18n.tr("Users"), icon: "person" },
        { id: "system", label: I18n.tr("System"), icon: "info" }
    ]

    // A rebuild's real output belongs where it's visible no matter which
    // sidebar category happens to be open when it runs, not buried on
    // one settings page - it always shows fresh (never collapsed by
    // default) the moment a rebuild starts, since that's exactly when
    // someone wants to see it.
    Connections {
        target: root.vm
        function onRebuildBusyChanged() {
            if (root.vm.rebuildBusy) root.logCollapsed = false;
        }
    }

    function openWindow() {
        root.vm.refreshAll();
        // Closing a floating window via the compositor can leave the QML
        // `visible` property true while the actual Wayland window is gone,
        // so a plain `visible = true` re-open is a silent no-op. Reset
        // first, then re-show - the same resurrection pattern DMS's own
        // SettingsModal.show() uses.
        if (visible && !backingWindowVisible) visible = false;
        visible = true;
        raise();
        requestActivate();
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Row {
            width: parent.width
            height: parent.height - footer.height
            spacing: 0

            Item {
                id: sidebar
                width: 200
                height: parent.height

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.outline
                    opacity: 0.2
                }

                Column {
                    width: parent.width - Theme.spacingS * 2
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingM
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                    spacing: 2

                    Column {
                        width: parent.width
                        spacing: 2

                        StyledText {
                            x: Theme.spacingM
                            text: I18n.tr("Vayume")
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            x: Theme.spacingM
                            text: I18n.tr("NixOS control")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    Item { width: 1; height: Theme.spacingS }

                    Repeater {
                        model: root.categories

                        SidebarItem {
                            required property var modelData
                            label: modelData.label
                            icon: modelData.icon
                            active: root.activeCategory === modelData.id
                            badgeCount: {
                                if (modelData.id === "applications" && !root.vm.appsLoading)
                                    return root.vm.apps.filter(a => a.enabled && a.category !== "development").length;
                                if (modelData.id === "users" && !root.vm.usersLoading)
                                    return Object.keys(root.vm.users).length;
                                return 0;
                            }
                            onActivated: root.activeCategory = modelData.id
                        }
                    }
                }

                Column {
                    width: parent.width - Theme.spacingS * 2
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.spacingS
                    spacing: Theme.spacingXS

                    Badge {
                        label: {
                            if (root.vm.saving) return I18n.tr("Saving...");
                            if (root.vm.lastError) return I18n.tr("Error");
                            if (!root.vm.repoKnown) return I18n.tr("Loading...");
                            return root.vm.repo.rebuildPending ? I18n.tr("Rebuild required") : I18n.tr("Saved");
                        }
                        tone: {
                            if (root.vm.saving) return "info";
                            if (root.vm.lastError) return "error";
                            if (!root.vm.repoKnown) return "neutral";
                            return root.vm.repo.rebuildPending ? "warning" : "success";
                        }
                    }
                }
            }

            Flickable {
                id: contentFlick
                width: parent.width - sidebar.width
                height: parent.height
                contentWidth: width
                contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + Theme.spacingL * 2 : 0
                clip: true

                Loader {
                    id: pageLoader
                    x: Theme.spacingL
                    y: Theme.spacingL
                    width: contentFlick.width - Theme.spacingL * 2

                    sourceComponent: {
                        switch (root.activeCategory) {
                        case "appearance": return appearancePageComponent;
                        case "development": return developmentPageComponent;
                        case "applications": return applicationsPageComponent;
                        case "users": return usersPageComponent;
                        case "system": return systemPageComponent;
                        default: return null;
                        }
                    }
                }
            }
        }

        Column {
            id: footer
            width: parent.width
            spacing: 0

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outline
                opacity: 0.2
            }

            // The real nixos-rebuild switch output, streamed live - sits
            // at the bottom of the window regardless of which sidebar
            // category is open, so starting a rebuild from Appearance
            // doesn't mean switching to System just to watch it happen.
            Rectangle {
                width: parent.width
                height: root.logVisible ? 180 : 0
                clip: true
                color: Theme.surfaceContainerHighest
                visible: height > 0

                Behavior on height { NumberAnimation { duration: 120 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS

                    Row {
                        width: parent.width
                        StyledText {
                            width: parent.width - clearLogText.width - Theme.spacingS
                            text: root.vm.rebuildBusy ? I18n.tr("Live rebuild output") : I18n.tr("Last rebuild output")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        StyledText {
                            id: clearLogText
                            text: I18n.tr("Clear")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.vm.clearRebuildLog()
                            }
                        }
                    }

                    ListView {
                        id: rebuildLogView
                        width: parent.width
                        height: parent.height - Theme.fontSizeSmall * 1.6 - Theme.spacingXS
                        clip: true
                        model: root.vm.rebuildLog
                        onCountChanged: positionViewAtEnd()

                        delegate: StyledText {
                            required property var modelData
                            width: rebuildLogView.width
                            text: modelData
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 56

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.right: logToggle.left
                    anchors.rightMargin: Theme.spacingM
                    text: {
                        if (root.vm.lastError) return I18n.tr("Last change failed - see the page where it happened, or run vayume-config validate in a terminal.");
                        if (root.vm.saving) return I18n.tr("Saving changes...");
                        if (root.vm.rebuildBusy) return I18n.tr("Rebuilding system configuration...");
                        if (root.vm.repoKnown && root.vm.repo.rebuildPending) return I18n.tr("Changes saved - rebuild to apply them.");
                        if (root.vm.rebuildStatus.length > 0) return root.vm.rebuildStatus;
                        return I18n.tr("Everything up to date.");
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                }

                StyledText {
                    id: logToggle
                    visible: root.vm.rebuildLog.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: rebuildButton.left
                    anchors.rightMargin: Theme.spacingM
                    text: root.logCollapsed ? I18n.tr("Show Log") : I18n.tr("Hide Log")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.logCollapsed = !root.logCollapsed
                    }
                }

                StyledRect {
                    id: rebuildButton
                    width: 140
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    radius: Theme.cornerRadius
                    color: root.vm.rebuildBusy ? Theme.surfaceContainerLow : Theme.primary

                    StyledText {
                        anchors.centerIn: parent
                        text: root.vm.rebuildBusy ? I18n.tr("Rebuilding...") : I18n.tr("Rebuild Now")
                        color: root.vm.rebuildBusy ? Theme.surfaceVariantText : Theme.onPrimary
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.vm.rebuildBusy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.vm.rebuild()
                    }
                }
            }
        }
    }

    Component { id: appearancePageComponent; AppearancePage { vm: root.vm } }
    Component { id: developmentPageComponent; DevelopmentPage { vm: root.vm } }
    Component { id: applicationsPageComponent; ApplicationsPage { vm: root.vm } }
    Component { id: usersPageComponent; UsersPage { vm: root.vm } }
    Component { id: systemPageComponent; SystemPage { vm: root.vm } }
}
