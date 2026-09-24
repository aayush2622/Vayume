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

    property var defaultApps: []
    property bool defaultAppsLoading: true
    property string defaultAppsStatus: ""
    property bool defaultAppsError: false

    property var settings: []
    property bool settingsLoading: true
    property string settingsStatus: ""
    property bool settingsError: false
    readonly property bool settingsSaving: settingsSetProc.running

    property var packageSearchResults: []
    readonly property bool packageSearching: packageSearchProc.running
    property string packageSearchError: ""

    property bool rebuildBusy: false
    property string rebuildStatus: ""
    property var rebuildLog: []

    function appendRebuildLog(line) {
        const next = root.rebuildLog.concat([line]);
        root.rebuildLog = next.length > 500 ? next.slice(next.length - 500) : next;
    }
    function clearRebuildLog() { root.rebuildLog = []; }

    function pickError(current, line) {
        const t = line.trim();
        if (t.startsWith("vayume-config:") && !t.includes("failed to evaluate"))
            return t.slice("vayume-config:".length).trim();
        if (/^error: \S/.test(t))
            return t.slice("error:".length).trim();
        return current;
    }

    readonly property bool saving: root.themePending || setAppProc.running || root.usersSaving || defaultsSetProc.running || root.settingsSaving
    readonly property bool lastError: root.themeError || root.usersError || root.defaultAppsError || root.settingsError

    function refreshRepo() { repoProc.running = true; }
    function refreshApps() { appsLoading = true; appsListProc.running = true; }
    function refreshDevelopment() { developmentLoading = true; developmentListProc.running = true; }
    function refreshTheme() { themeLoading = true; themeGetProc.running = true; }
    function refreshUsers() { usersLoading = true; usersListProc.running = true; }
    function refreshDefaultApps() { defaultAppsLoading = true; defaultsGetProc.running = true; }
    function refreshSettings() { settingsLoading = true; settingsGetProc.running = true; }

    function setSetting(path, values) {
        settingsSetProc.command = ["vayume", "config", "settings", "set", path].concat(values);
        settingsSetProc.running = true;
    }

    function resetSetting(path) {
        settingsSetProc.command = ["vayume", "config", "settings", "reset", path];
        settingsSetProc.running = true;
    }

    function setDefaultApp(role, id) {
        defaultsSetProc.command = ["vayume", "config", "defaults", "set", role, id];
        defaultsSetProc.running = true;
    }

    property string activePage: "appearance"
    property var loadedPages: ({})

    function ensurePage(id) {
        root.activePage = id;
        if (root.loadedPages[id])
            return;
        root.loadedPages = Object.assign({}, root.loadedPages, { [id]: true });
        switch (id) {
        case "appearance": refreshTheme(); break;
        case "development": refreshDevelopment(); refreshApps(); break;
        case "applications": refreshApps(); refreshSettings(); break;
        case "defaults": refreshDefaultApps(); break;
        case "users": refreshUsers(); break;
        case "options": refreshSettings(); break;
        }
    }

    function refreshAll() {
        refreshRepo();
        root.loadedPages = ({});
        ensurePage(root.activePage);
    }

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
        setAppProc.command = ["vayume", "config", "apps", "set", name, enabled ? "true" : "false"];
        setAppProc.running = true;
    }

    function setUserFullName(user, value) {
        root.users = Object.assign({}, root.users, {
            [user]: Object.assign({}, root.users[user], { fullName: value })
        });
        usersSetProc.command = ["vayume", "config", "users", "set-name", user, value];
        usersSetProc.running = true;
    }

    function setUserSecret(user, key, value) {
        const current = root.users[user];
        root.users = Object.assign({}, root.users, {
            [user]: Object.assign({}, current, { secrets: Object.assign({}, current.secrets, { [key]: value }) })
        });
        usersSetProc.command = ["vayume", "config", "users", "set-secret", user, key, value];
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
        usersSetProc.command = ["vayume", "config", "users", "set-group", user, group, enabled ? "true" : "false"];
        usersSetProc.running = true;
    }

    function setUserPassword(user, password) {
        usersPasswordProc.pendingWrite = password;
        usersPasswordProc.command = ["vayume", "config", "users", "set-password", user];
        usersPasswordProc.running = true;
    }

    function addUser(user, fullName) {
        const args = ["vayume", "config", "users", "add", user];
        if (fullName.length > 0) args.push(fullName);
        usersAddRemoveProc.command = args;
        usersAddRemoveProc.running = true;
    }

    function removeUser(user) {
        usersAddRemoveProc.command = ["vayume", "config", "users", "remove", user];
        usersAddRemoveProc.running = true;
    }

    function searchPackages(query) {
        root.packageSearchError = "";
        packageSearchProc.command = ["vayume", "config", "packages", "search", query];
        packageSearchProc.running = true;
    }

    function setUserPackage(user, path, enabled) {
        const current = root.users[user];
        root.users = Object.assign({}, root.users, {
            [user]: Object.assign({}, current, { packages: Object.assign({}, current.packages, { [path]: enabled }) })
        });
        usersSetProc.command = ["vayume", "config", "users", "set-package", user, path, enabled ? "true" : "false"];
        usersSetProc.running = true;
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

    Component.onCompleted: refreshRepo()

    Process {
        id: repoProc
        command: ["vayume", "config", "repo"]
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
        command: ["vayume", "config", "apps", "list"]
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
        command: ["vayume", "config", "development", "list"]
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
        command: ["vayume", "config", "theme", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.themeLoading = false;
                try {
                    root.theme = JSON.parse(text);
                } catch (e) {
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
            themeSetProc.command = ["vayume", "config", "theme", "set", field, value];
            themeSetProc.running = true;
        }
    }

    Process {
        id: themeSetProc
        running: false
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => themeSetProc.errorText = root.pickError(themeSetProc.errorText, line) }
        onExited: exitCode => {
            root.themeError = exitCode !== 0;
            root.themeStatus = exitCode === 0
                ? I18n.tr("Applied - rebuild to take effect.")
                : (themeSetProc.errorText || I18n.tr("Couldn't update that setting."));
            if (exitCode !== 0) root.refreshTheme();
            root.refreshRepo();
        }
    }

    Process {
        id: setAppProc
        running: false
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => setAppProc.errorText = root.pickError(setAppProc.errorText, line) }
        onExited: exitCode => {
            root.rebuildStatus = exitCode === 0
                ? I18n.tr("Saved - rebuild to apply.")
                : (setAppProc.errorText || I18n.tr("Change failed")) + " - " + I18n.tr("reloading current state.");
            if (exitCode !== 0) {
                root.refreshApps();
                root.refreshDevelopment();
            }
            root.refreshDefaultApps();
            root.refreshRepo();
        }
    }

    Process {
        id: defaultsGetProc
        command: ["vayume", "config", "defaults", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaultAppsLoading = false;
                try {
                    root.defaultApps = JSON.parse(text);
                } catch (e) {
                    root.defaultApps = [];
                }
            }
        }
    }

    Process {
        id: defaultsSetProc
        running: false
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => defaultsSetProc.errorText = root.pickError(defaultsSetProc.errorText, line) }
        onExited: exitCode => {
            root.defaultAppsError = exitCode !== 0;
            root.defaultAppsStatus = exitCode === 0
                ? I18n.tr("Saved - rebuild to apply.")
                : (defaultsSetProc.errorText || I18n.tr("Couldn't change that default."));
            root.refreshDefaultApps();
            root.refreshRepo();
        }
    }

    Process {
        id: settingsGetProc
        command: ["vayume", "config", "settings", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.settingsLoading = false;
                try {
                    root.settings = JSON.parse(text);
                } catch (e) {
                    root.settings = [];
                }
            }
        }
    }

    Process {
        id: settingsSetProc
        running: false
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => settingsSetProc.errorText = root.pickError(settingsSetProc.errorText, line) }
        onExited: exitCode => {
            root.settingsError = exitCode !== 0;
            root.settingsStatus = exitCode === 0
                ? I18n.tr("Saved - rebuild to apply.")
                : (settingsSetProc.errorText || I18n.tr("Couldn't change that setting."));
            root.refreshSettings();
            root.refreshRepo();
        }
    }

    Process {
        id: usersListProc
        command: ["vayume", "config", "users", "list"]
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
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => usersSetProc.errorText = root.pickError(usersSetProc.errorText, line) }
        onExited: exitCode => {
            root.usersError = exitCode !== 0;
            root.usersStatus = exitCode === 0
                ? I18n.tr("Applied - rebuild to take effect.")
                : (usersSetProc.errorText || I18n.tr("Couldn't update that setting."));
            if (exitCode !== 0) root.refreshUsers();
            root.refreshRepo();
        }
    }

    Process {
        id: usersPasswordProc
        running: false
        stdinEnabled: true
        property string pendingWrite: ""
        property string errorText: ""
        stderr: SplitParser { onRead: line => usersPasswordProc.errorText = root.pickError(usersPasswordProc.errorText, line) }
        onStarted: {
            errorText = "";
            write(pendingWrite + "\n");
            pendingWrite = "";
        }
        onExited: exitCode => {
            root.usersError = exitCode !== 0;
            root.usersStatus = exitCode === 0
                ? I18n.tr("Password updated - rebuild to take effect.")
                : (usersPasswordProc.errorText || I18n.tr("Couldn't update the password."));
            root.refreshUsers();
            root.refreshRepo();
        }
    }

    Process {
        id: usersAddRemoveProc
        running: false
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => usersAddRemoveProc.errorText = root.pickError(usersAddRemoveProc.errorText, line) }
        onExited: exitCode => {
            root.usersError = exitCode !== 0;
            root.usersStatus = exitCode === 0
                ? I18n.tr("Applied - rebuild to take effect.")
                : (usersAddRemoveProc.errorText || I18n.tr("Couldn't update users."));
            root.refreshUsers();
            root.refreshRepo();
        }
    }

    Process {
        id: packageSearchProc
        running: false
        property string errorText: ""
        onStarted: errorText = ""
        stderr: SplitParser { onRead: line => packageSearchProc.errorText = root.pickError(packageSearchProc.errorText, line) }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.packageSearchResults = JSON.parse(text);
                } catch (e) {
                    root.packageSearchResults = [];
                    root.packageSearchError = packageSearchProc.errorText || I18n.tr("Search failed.");
                }
            }
        }
    }

    Process {
        id: rebuildProc
        command: ["vayume", "rebuild"]
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
                : I18n.tr("Rebuild failed (exit %1) - the log below has the details.").arg(exitCode);
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
