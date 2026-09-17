import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./ui"

PluginComponent {
    id: root

    property var repo: ({ path: "", branch: "", dirty: false, configFile: "", hostName: "", rebuildPending: false })
    property bool repoKnown: false

    property var apps: []
    property bool appsLoading: true

    property var development: ({ languages: [], editors: [], tools: [] })
    property bool developmentLoading: true

    property var theme: ({ font: "", fontSize: 11, cursorTheme: "", iconTheme: "", cursorOptions: [], fontOptions: [] })
    property bool themeLoading: true
    readonly property bool themeSaving: themeSetProc.running
    readonly property bool themePending: themeWriteDebounce.running || themeSaving
    property string themeStatus: ""
    property bool themeError: false

    property var users: ({})
    property var groupOptions: []
    property bool usersLoading: true
    property string usersStatus: ""
    property bool usersError: false
    readonly property bool usersSaving: usersSetProc.running || usersPasswordProc.running || usersAddRemoveProc.running

    property bool rebuildBusy: false
    property string rebuildStatus: ""
    property var rebuildLog: []

    // Capped so a runaway or unusually chatty rebuild can't grow this
    // without bound - only the tail is useful for "what just happened"
    // anyway.
    function appendRebuildLog(line) {
        const next = root.rebuildLog.concat([line]);
        root.rebuildLog = next.length > 500 ? next.slice(next.length - 500) : next;
    }
    function clearRebuildLog() { root.rebuildLog = []; }

    readonly property bool saving: root.themePending || setAppProc.running || root.usersSaving
    readonly property bool lastError: root.themeError || root.usersError

    function refreshRepo() { repoProc.running = true; }
    function refreshApps() { appsLoading = true; appsListProc.running = true; }
    function refreshDevelopment() { developmentLoading = true; developmentListProc.running = true; }
    function refreshTheme() { themeLoading = true; themeGetProc.running = true; }
    function refreshUsers() { usersLoading = true; usersListProc.running = true; }

    function refreshAll() {
        refreshRepo();
        refreshApps();
        refreshDevelopment();
        refreshTheme();
        refreshUsers();
    }

    // Every backend write pays for a real `nix eval` (apply_edit's own
    // validation, never skipped) - too slow to run on every single click of
    // a +/- spinner. The value shown updates immediately (optimistic - only
    // rolled back if the write is later rejected); the actual write is
    // debounced so five quick clicks become one backend call with the final
    // value, not five sequential validate-evals.
    function queueThemeWrite(field, value) {
        themeWriteDebounce.field = field;
        themeWriteDebounce.value = String(value);
        themeWriteDebounce.restart();
    }

    function setFontSize(delta) {
        const next = root.theme.fontSize + delta;
        if (next < 8 || next > 24) return;
        root.theme = Object.assign({}, root.theme, { fontSize: next });
        queueThemeWrite("fontSize", next);
    }

    function setFont(value) {
        root.theme = Object.assign({}, root.theme, { font: value });
        queueThemeWrite("font", value);
    }

    function setCursorTheme(value) {
        root.theme = Object.assign({}, root.theme, { cursorTheme: value });
        queueThemeWrite("cursorTheme", value);
    }

    function setAppEnabled(name, enabled) {
        root.apps = root.apps.map(a => a.name === name ? Object.assign({}, a, { enabled }) : a);
        root.development = {
            languages: root.development.languages.map(a => a.name === name ? Object.assign({}, a, { enabled }) : a),
            editors: root.development.editors.map(a => a.name === name ? Object.assign({}, a, { enabled }) : a),
            tools: root.development.tools.map(a => a.name === name ? Object.assign({}, a, { enabled }) : a)
        };
        setAppProc.command = ["vayume-config", "apps", "set", name, enabled ? "true" : "false"];
        setAppProc.running = true;
    }

    function setUserFullName(user, value) {
        root.users = Object.assign({}, root.users, {
            [user]: Object.assign({}, root.users[user], { fullName: value })
        });
        usersSetProc.command = ["vayume-config", "users", "set-name", user, value];
        usersSetProc.running = true;
    }

    function setUserSecret(user, key, value) {
        const current = root.users[user];
        root.users = Object.assign({}, root.users, {
            [user]: Object.assign({}, current, { secrets: Object.assign({}, current.secrets, { [key]: value }) })
        });
        usersSetProc.command = ["vayume-config", "users", "set-secret", user, key, value];
        usersSetProc.running = true;
    }

    function setUserGroup(user, group, enabled) {
        const current = root.users[user];
        const nextGroups = enabled
            ? current.extraGroups.concat(current.extraGroups.includes(group) ? [] : [group])
            : current.extraGroups.filter(g => g !== group);
        root.users = Object.assign({}, root.users, {
            [user]: Object.assign({}, current, { extraGroups: nextGroups })
        });
        usersSetProc.command = ["vayume-config", "users", "set-group", user, group, enabled ? "true" : "false"];
        usersSetProc.running = true;
    }

    // Not optimistic (there's no visible field to update ahead of the
    // write) and deliberately never kept in a long-lived property - the
    // plaintext only exists in this call's local scope and inside the
    // Process's own stdin pipe, same reasoning as
    // vayume-config's own "argv is visible to every process via /proc,
    // stdin isn't" - see VayumeConfig.nix.
    function setUserPassword(user, password) {
        usersPasswordProc.pendingWrite = password;
        usersPasswordProc.command = ["vayume-config", "users", "set-password", user];
        usersPasswordProc.running = true;
    }

    // Not optimistic like the field setters above - a fresh user arrives
    // with extraGroups/hasPassword/secrets defaults this widget doesn't
    // know ahead of time (userSubmodule's own, not duplicated here), and
    // a removal just needs the list to reflect reality. usersAddRemoveProc
    // always refetches on exit rather than only on failure.
    function addUser(user, fullName) {
        const args = ["vayume-config", "users", "add", user];
        if (fullName.length > 0) args.push(fullName);
        usersAddRemoveProc.command = args;
        usersAddRemoveProc.running = true;
    }

    function removeUser(user) {
        usersAddRemoveProc.command = ["vayume-config", "users", "remove", user];
        usersAddRemoveProc.running = true;
    }

    function rebuild() {
        root.rebuildLog = [];
        rebuildProc.running = true;
    }

    ccWidgetIcon: "settings_suggest"
    ccWidgetPrimaryText: I18n.tr("Vayume Settings")
    ccWidgetSecondaryText: {
        if (!root.repoKnown)
            return I18n.tr("Loading...");
        if (root.repo.rebuildPending)
            return I18n.tr("Rebuild required");
        return root.repo.dirty ? I18n.tr("Uncommitted changes") : I18n.tr("Up to date");
    }
    ccWidgetIsActive: root.repoKnown && root.repo.rebuildPending
    ccDetailHeight: 56

    onCcWidgetExpanded: root.openSettingsWindow()

    Component.onCompleted: refreshAll()

    Process {
        id: repoProc
        command: ["vayume-config", "repo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.repo = JSON.parse(text);
                    root.repoKnown = true;
                } catch (e) {
                    root.repoKnown = false;
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: if (!repoProc.running) repoProc.running = true
    }

    Process {
        id: appsListProc
        command: ["vayume-config", "apps", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.appsLoading = false;
                try {
                    root.apps = JSON.parse(text);
                } catch (e) {
                    root.apps = [];
                }
            }
        }
    }

    Process {
        id: developmentListProc
        command: ["vayume-config", "development", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.developmentLoading = false;
                try {
                    root.development = JSON.parse(text);
                } catch (e) {
                    root.development = { languages: [], editors: [], tools: [] };
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
                root.themeLoading = false;
                try {
                    root.theme = JSON.parse(text);
                } catch (e) {
                    // keep the previous value on a parse failure
                }
            }
        }
    }

    Timer {
        id: themeWriteDebounce
        property string field: ""
        property string value: ""
        interval: 400
        onTriggered: {
            themeSetProc.command = ["vayume-config", "theme", "set", field, value];
            themeSetProc.running = true;
        }
    }

    Process {
        id: themeSetProc
        running: false
        onExited: exitCode => {
            root.themeError = exitCode !== 0;
            root.themeStatus = exitCode === 0
                ? I18n.tr("Applied - rebuild to take effect.")
                : I18n.tr("Couldn't update that setting - see a terminal for the real error.");
            // Success: the optimistic value shown is already correct, no
            // need to pay for another full theme fetch. Failure: the
            // optimistic guess was wrong - refetch to show the real,
            // unchanged value instead of the rejected one.
            if (exitCode !== 0) root.refreshTheme();
            root.refreshRepo();
        }
    }

    Process {
        id: setAppProc
        running: false
        onExited: exitCode => {
            root.rebuildStatus = exitCode === 0
                ? I18n.tr("Saved - rebuild to apply.")
                : I18n.tr("Change failed - reloading current state.");
            // Same reasoning as themeSetProc: the toggle already flipped
            // optimistically, so a success needs no refetch (that's what
            // was showing a spurious "Loading applications..." flash after
            // every toggle, with no rebuild involved). Only re-derive the
            // real state on failure, to undo a toggle the backend rejected.
            if (exitCode !== 0) {
                root.refreshApps();
                root.refreshDevelopment();
            }
            root.refreshRepo();
        }
    }

    Process {
        id: usersListProc
        command: ["vayume-config", "users", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.usersLoading = false;
                try {
                    const parsed = JSON.parse(text);
                    root.users = parsed.users;
                    root.groupOptions = parsed.groupOptions;
                } catch (e) {
                    root.users = {};
                    root.groupOptions = [];
                }
            }
        }
    }

    Process {
        id: usersSetProc
        running: false
        onExited: exitCode => {
            root.usersError = exitCode !== 0;
            root.usersStatus = exitCode === 0
                ? I18n.tr("Applied - rebuild to take effect.")
                : I18n.tr("Couldn't update that setting - see a terminal for the real error.");
            // Same optimistic-update reasoning as setAppProc/themeSetProc -
            // only refetch (and so overwrite the optimistic value) on
            // failure.
            if (exitCode !== 0) root.refreshUsers();
            root.refreshRepo();
        }
    }

    // stdinEnabled + write() rather than a command-line argument, so the
    // new password is never visible via /proc to any other process on
    // the machine the way an argv value would be - see
    // cmd_users_set_password in VayumeConfig.nix for the same reasoning
    // on the backend side. `pendingWrite` is cleared the instant it's
    // been handed to the process, so the plaintext doesn't linger in a
    // QML property.
    Process {
        id: usersPasswordProc
        running: false
        stdinEnabled: true
        property string pendingWrite: ""
        onStarted: {
            write(pendingWrite + "\n");
            pendingWrite = "";
        }
        onExited: exitCode => {
            root.usersError = exitCode !== 0;
            root.usersStatus = exitCode === 0
                ? I18n.tr("Password updated - rebuild to take effect.")
                : I18n.tr("Couldn't update the password - see a terminal for the real error.");
            root.refreshUsers();
            root.refreshRepo();
        }
    }

    Process {
        id: usersAddRemoveProc
        running: false
        onExited: exitCode => {
            root.usersError = exitCode !== 0;
            root.usersStatus = exitCode === 0
                ? I18n.tr("Applied - rebuild to take effect.")
                : I18n.tr("Couldn't update users - see a terminal for the real error.");
            root.refreshUsers();
            root.refreshRepo();
        }
    }

    Process {
        id: rebuildProc
        command: ["vayume-rebuild"]
        running: false
        stdout: SplitParser { onRead: line => root.appendRebuildLog(line) }
        stderr: SplitParser { onRead: line => root.appendRebuildLog(line) }
        onStarted: {
            root.rebuildBusy = true;
            root.rebuildStatus = I18n.tr("Rebuilding - this can take a minute...");
        }
        onExited: exitCode => {
            root.rebuildBusy = false;
            root.rebuildStatus = exitCode === 0
                ? I18n.tr("Rebuild succeeded.")
                : I18n.tr("Rebuild failed (exit %1) - check a terminal for details.").arg(exitCode);
            root.refreshApps();
            root.refreshRepo();
        }
    }

    ccDetailContent: Component {
        Rectangle {
            implicitHeight: 40
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                anchors.centerIn: parent
                text: I18n.tr("Opens in its own window - click again if it didn't come to front.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openSettingsWindow()
            }
        }
    }

    // A closed-then-reopened DankFloatingWindow/FloatingWindow never comes
    // back: once the compositor destroys its Wayland toplevel, setting
    // `visible = true` on the same QML object again is a silent no-op -
    // verified directly with a Quickshell IPC test harness against a live
    // Hyprland session (close via the same dispatcher this repo's own "Q"
    // keybind uses, then call the reopen path: `visible` reports `true`
    // but no window ever reappears). A Loader sidesteps that by fully
    // destroying and recreating the window instead of trying to resurrect
    // one - `active: false` on close, then `active: true` builds a
    // genuinely new FloatingWindow with its own fresh Wayland surface.
    Loader {
        id: settingsWindowLoader
        active: false
        sourceComponent: SettingsWindow {
            vm: root
            visible: true
            onVisibleChanged: if (!visible) settingsWindowLoader.active = false
            Component.onCompleted: { raise(); requestActivate(); }
        }
    }

    function openSettingsWindow() {
        root.refreshAll();
        if (settingsWindowLoader.active && settingsWindowLoader.item) {
            settingsWindowLoader.item.visible = true;
            settingsWindowLoader.item.raise();
            settingsWindowLoader.item.requestActivate();
        } else {
            settingsWindowLoader.active = true;
        }
    }
}
