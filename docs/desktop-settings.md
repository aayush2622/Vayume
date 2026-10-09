# Vayume Settings

[← Index](CONFIGURATION.md)

Vayume Settings is a standalone Quickshell app, `modules/desktop/settings/`. It runs under every shell (DMS, Noctalia, Caelestia) because it needs none of them: `vayume settings` starts it, there is a "Vayume Settings" desktop entry, and `vayume shell settings` opens the shell's own settings instead. See [core-vayume-config.md](core-vayume-config.md) for the backend it drives and why it talks to the real `_config.nix` through a CLI instead of its own state.

## How it is built

`Settings.nix` copies the `dank-qml-common` flake input (the same pin DMS uses, so one copy) into a store directory, drops its demo `shell.qml`, and overlays `qml/` on top. `dank-qml-common` supplies the widgets (`StyledText`, `DankIcon`, `DankTextField`, `DankDropdown`, ...) and stub `qs.Common` singletons; the overlay replaces `Common/Theme.qml` with one that reads colors from `~/.config/vayume/colors.json`, and adds `Widgets/DankFloatingWindow.qml` (the window type DMS has but the library lacks). `qml/shell.qml` sets `Style.theme = Theme`, which is how the library's widgets pick up the same palette.

The colors come from the `matugen/colors.json.template` template registered as `vayume.matugenTemplates.vayumeSettings`, so they follow the wallpaper under every shell, and the file is watched, so the window retints live. Until matugen has run once, `Theme.qml`'s built-in dark palette is used.

The app quits when its window closes, so there is nothing to resurrect: opening it again starts a fresh process (`--no-duplicate` stops a second copy).

## Layout

`qml/VayumeModel.qml` owns every `Process` that talks to `vayume config` (the one place that reads and writes backend state). `qml/ui/` holds the presentational pieces: `SettingsWindow.qml` (the shell: category table, page header, scrolling content), `Sidebar.qml`/`SidebarItem.qml`, `PageHeader.qml`, `StatusCard.qml` (status and rebuild button), `LogPanel.qml` (the live rebuild log), one file per category page, and the shared pieces described under [Vayori](#vayori-the-settings-design-language). Pages receive the model as `vm` and only call its functions (`setAppEnabled`, `setCursorTheme`, `rebuild`, ...) - they hold no `Process` of their own.

The sidebar opens on Home, then groups Personal (Appearance, Desktop pet, Users), Apps (Applications, Development, Default apps) and System (Network, Performance, Storage, Updates, About), with a search field at the top and the save and rebuild status in a card at the bottom. The grouping is presentation only: each entry is one page id that `ensurePage` knows. The pricier `vayume config apps list`/`theme get`/`development list`/`users list`/`defaults get` calls (real Nix evaluations, cached between runs) only run for the page you open, and `settings list` reads a snapshot instead of evaluating.

### Vayori, the settings design language

Vayume Settings is drawn in a small design language called Vayori: soft and rounded, one tinted card per setting,
a sidebar of icon rows with a pill highlight, accent-coloured section titles and
pill-shaped controls. Every colour is derived from the app's `Theme` (surface
containers, `primary`, `primaryContainer`, `secondaryContainer`), so matugen
wallpaper colours and the dark/light toggle keep working, and the user's own
font (`Theme.fontFamily`) is used throughout.

- **`ui/components/Vayori.qml` is a singleton holding every token** - radii, spacing, the
  derived surfaces (`base` for the window, `canvas` for the rounded content
  area, `card`, `field`), ink levels (`ink`, `inkMuted`, `inkFaint`,
  `inkGhost`), the selection fills, the type scale and the animation
  durations. Components read these instead of repeating `Theme.withAlpha(...)`
  expressions, so a change to, say, card radius is one line.
- **Files are split by role**: `ui/` holds the window shell (`SettingsWindow`,
  `Sidebar`, `SidebarItem`, `PageHeader`, `StatusCard`, `LogPanel`),
  `ui/pages/` one file per page, and `ui/components/` the shared building
  blocks and `Vayori.qml`. Pages `import "../components"`; the shell imports
  both folders.
- **`ui/components/qmldir` exists because of that singleton**, and a directory
  with a `qmldir` only exports the types it lists. A new `.qml` file under
  `ui/components/` must be added there or it fails to load with "is not a type"; `tests/eval.sh`
  checks this.
- **Layout.** The window is the sidebar (`Sidebar.qml`: brand, grouped
  `SidebarItem`s, and `StatusCard.qml` with the save/rebuild state, the Rebuild
  button and a button for the log) next to a rounded canvas holding
  `PageHeader.qml` (title, subtitle, reload and close) and the page. The live
  rebuild output is `LogPanel.qml`, docked at the bottom of the canvas.
- **Building blocks.** `Section` is a titled group: an accent title, optional
  subtitle, a right-aligned `meta` count, optional collapsing, and its rows
  stacked 4px apart. `SettingItem` is the row every page uses and draws its
  own card: a leading 40px icon tile (`image`, a themed icon file, or `icon`,
  a Material symbol on a tonal square when there is no image), title,
  description, an optional mono `meta` line, `tags`,
  `notes`, a `footer` inside the same card (the Applications page puts an
  app's options there), and a control slot on the right that drops under the
  text when the row is narrower than 560px or `stacked` is set; `card: false`
  gives a plain divided row for nesting. `OptionRow` and `CommandRow` are
  `SettingItem`s bound to a settings-schema entry and a `vayume.commands` panel
  entry. Controls are `Toggle` (a Material-style switch), `Segmented` (a pill
  row with a check on the selected entry, used for enums of up to three short
  choices and the All/Modified filter), `Select` (its own trigger, reusing
  `DankDropdown`'s searchable popup through `showTrigger: false`), `Field` (a
  restyled `DankTextField`) and `TextButton` (`tonal`, `primary`, `warning`,
  `danger`, `ghost`; no text makes it a round icon button). `Badge` is a small
  pill, `Notice` an inline hint or a tinted warning/error card (with a spinner
  while loading), and `FocusRing` the keyboard focus outline those controls
  share.
- **Identity** is deliberately small: the 夜 mark next to the wordmark,
  drawn in Noto Serif CJK JP, which `Fonts.nix` installs.
- **Behaviour.** Every page still only calls functions on `vm`; the sidebar
  keeps Tab/Enter and adds Up/Down between entries; Tab focus scrolls the
  focused control into view; the page header stays pinned when the content
  area is at least 560px tall and scrolls with the page below that; the status
  card drops its detail line in short windows; an app's own options are only
  instantiated when expanded; the log opens by itself when a rebuild starts.

**`DankTextField`'s eye button never actually reveals a password field
on its own - checked its source directly.** `showPasswordToggle`'s eye
icon only flips the field's own `passwordVisible` property; nothing in
the component wires that back to `echoMode` (confirmed by reading the
whole 314-line file: no binding, no `onPasswordVisibleChanged`, nothing
- clicking the eye changes the glyph and nothing else). A hardcoded
`echoMode: TextInput.Password`, the pattern DMS's native
`UsersTab.qml` uses too, means the eye button is decorative everywhere
it appears with that exact pattern. Every password-style field in
`UsersPage.qml` (both API-key secrets and the new-password pair)
instead binds `echoMode` to the field's own `passwordVisible` -
`echoMode: secretField.passwordVisible ? TextInput.Normal : TextInput.Password`
- the wiring the component's own design clearly expects the caller to
provide.

**Users can be added and removed from this page, not just edited.**
"Add User" writes just a username (and optional display name) via
`vayume config users add` - everything else falls back to
[vayume/Users.nix](core-users.md)'s own defaults, same as
`_config.nix.example`'s `random` entry. "Remove" is a two-step
click-to-arm button (`vayume config users remove`) rather than a single
click, with a line making clear the account is only actually deleted on
the *next rebuild*, not immediately - removing a user is materially
more destructive than any other edit on this page (a NixOS account
deletion, not a config toggle), so it gets the one confirmation step
nothing else here has. Both go through a separate `usersAddRemoveProc`
that always refetches the user list on exit, unlike the optimistic
per-field setters (`setUserFullName`, `setUserGroup`, ...) that only
refetch on failure - a fresh user arrives with server-computed defaults
this widget has no client-side copy of, so there's no value to
optimistically show ahead of the real one.

**Extra packages, per user, found by searching rather than typed in.**
"Add a Package" (its own top-level card, not nested per-user - one
search box, a `Select` to pick which user gets the result) runs
`vayume config packages search` against this flake's own pinned
nixpkgs. Searching is explicit (Enter or the Search button), never
per-keystroke - `nix search` takes several seconds even warm, up to a
minute stone-cold, so searching on every keystroke would queue up
several-second subprocess calls behind each other rather than firing
one. Clicking "Add" on a result calls `users set-package`; each user's
own card then shows every package they've ever added as a toggle
(`checked` = currently enabled) - turning one off disables it
without forgetting it, so getting it back is a click, not a re-search.
This is the one part of the page that reads from a *different* backend
option than it looks like at first: `packages` (`attrsOf bool`, keyed
by attribute-path string), not `extraPackages` (a plain package list,
still Nix-only) - see [core-vayume-config.md](core-vayume-config.md)
for why the split exists and what makes a search-driven field safe to
expose here at all when a free-text one wouldn't be.

**Each user's card can be collapsed** - `Section.qml` has an
opt-in `collapsible`/`collapsed` pair (both default `false`).
`UsersPage.qml` is the only caller that turns it on, one bool per user
card via the Repeater delegate's own instance - clicking anywhere in
the title bar (a chevron shows which way), or Space/Enter when it
has keyboard focus, toggles that one card only.
Needed once removal/packages/groups/secrets/password all landed on the
same card - with two or more users each showing every section at once,
the page got long enough that collapsing the ones you're not currently
editing genuinely helps.

The cursor picker is a `Select`, whose popup is the library's own searchable
`DankDropdown` menu, fed by `theme get`'s live `cursorOptions` - not a hardcoded list, and not a
click-to-cycle button. Every setting shown is `_config.nix`, which only
ever *persists* through the next rebuild - the status card always
reads "Rebuild pending" once something has changed, never
something that implies the write alone was the whole story.

**`cursorTheme` is the one exception with an actual live-apply step,
added directly in `vayume config theme set` (not the app) so a
terminal `vayume config theme set cursorTheme ...` gets it too.**
Reported as "changing it doesn't update live" - correct as filed, this
plugin genuinely had no live-apply tier for anything before. Verified
directly against a running Hyprland session: `hyprctl setcursor <theme>
<size>` is a plain top-level hyprctl verb, not `hyprctl dispatch` (the
Lua-based dispatch rebind [Hyprland.nix](desktop-hyprland.md) uses for
its own keybinds has no bearing on it - confirmed by running it
directly, no Lua-dispatch error), and switching themes with it and back
worked cleanly. `gsettings set org.gnome.desktop.interface cursor-
theme/-size` covers GTK apps that read their cursor from dconf instead
of the compositor's own renderer. Neither reaches XWayland or a process
that already cached `XCURSOR_THEME` at its own startup, and niri has no
equivalent runtime call at all (checked `niri msg --help`'s full
subcommand list directly) - Hyprland-only in practice, a silent no-op
everywhere else (`command -v` guards each call, `|| true` on the calls
themselves - a session with no compositor IPC up yet, or one that isn't
Hyprland, just skips this step exactly as if it were never called).

Every app/language/editor/tool toggle also shows the one-line
`description` `vayume config` reads from `flake.appMeta` (see
[core-vayume-config.md](core-vayume-config.md)) as the row's
description - nothing invented in the UI layer that isn't already declared in the app's own
`.nix` file.

`LogPanel.qml` shows `vayume rebuild`'s stdout and
stderr live, line by line (`Quickshell.Io`'s `SplitParser`, not a
post-hoc `StdioCollector` read at exit) into a capped 500-line buffer
on the root widget, so a long `nixos-rebuild switch` is visible as it
happens rather than only as a final pass/fail line. It is docked in the
window rather than on one settings page specifically so it's visible
no matter which sidebar category happens to be open when a rebuild is
started - it auto-expands the moment a rebuild begins (a
`Connections { target: root.vm }` on `rebuildBusy`), and can be
collapsed by hand once it's no longer needed.

### Overview, search and shortcuts

The window opens on **Home** (page id `overview`, or whichever page was open
last in this session - `activePage` lives on the widget, which outlives the
window). It shows the host with a time-of-day greeting, whether anything
is waiting for a rebuild and whether the repository is clean, with Rebuild
and Review buttons while something is, and four tiles that jump to their
pages: apps, development, users and free disk space. The list of settings
waiting for a rebuild is on Updates, which also carries the count in the
sidebar. Home loads apps, development, settings, users and the disk figures
the first time it opens; later visits reuse them like every other page.

**Search** is the field at the top of the sidebar. Typing shows the
search page in place of the current one (clearing it goes back): pages
whose name or description match, options (matched on label, description,
path, group and app), apps and tools, and commands, 25 at most per group.
The results are the same rows the pages use, so an option can be changed
or an app switched off without leaving the search. The first search loads
the settings, apps, development and command lists (`ensurePage("search")`).

**Shortcuts** (`Shortcut` items on the window): `Ctrl+F` focuses search,
`Ctrl+1`-`Ctrl+9` open the sidebar entries in order, `Ctrl+R` reloads
the current page from `_config.nix`, `Ctrl+B` rebuilds, `Ctrl+L` shows or
hides the log, and `Esc` clears the search. Home lists them.

**About** has copy and open buttons next to the repository and config
file paths. They run `wl-copy` and `xdg-open` through
`Quickshell.execDetached` (`copyText`/`openPath` on the widget), so the
copy button does nothing on a host without `wl-clipboard`.

### Setting rows

Each `OptionRow.qml` has the setting's icon, label and description, and the control: a toggle for booleans, a segmented control or a dropdown for enums (with a "Default" entry when the option is nullable), a text field for numbers, strings and string lists. The option path is no longer printed under each row; search still matches it. A row whose value differs from what is running gets an amber marker inside its card, a "Pending rebuild" tag and a "Running now: ..." line; a row with a line in `_config.nix` shows "Customized" and an undo button that resets it. There is no per-option QML - a new `lib.mkOption` under `vayume.*` appears after the next rebuild, on Updates until its group names a page; how that works and how to customise the label, icon, group and order is in [Settings.nix](core-settings.md). Errors come back the same way as on the other pages (`pickError`).

**App settings live under the app.** `AppOptions.qml` sits beneath each toggle on the Applications page and lists the settings whose `settingsMeta` names that app (Distrobox has eleven). It is a small pill button inside the app's card, collapsed by default: "<App> options", the count, a pending-rebuild tag when needed and a chevron. Expanded, the rows sit in a recessed panel inside the same card, and the app's buttons (see [Where things go](#where-things-go)) follow the settings; the rows are only created while it is open, and it reuses `OptionRow.qml`, so the controls behave exactly as on the other pages. Apps with no settings show nothing extra. The Development page does not render them yet, since none of its apps declares options.

**Loading is lazy.** The bar widget only runs `vayume config repo` (about 60 ms) at login. Opening the window loads just the visible page's data (`ensurePage`), and each other page the first time it is opened; reopening the window reloads the active page. Combined with the read cache in [Config.nix](core-vayume-config.md), switching pages is instant unless something in the repo changed.

### Users page: the one category that can change real access

`vayume.users` is genuinely security-sensitive - group membership can
grant sudo, and a password controls login - so this page (unlike every
other category here) exists behind the explicit choice to expose it,
not by default caution. What it can touch, and why each piece is safe
to expose:

- **Display name** (`fullName`) - cosmetic only, a plain string field.
- **App secrets** (WakaTime API key, rbw/Bitwarden email) - already
  plain values in a gitignored file (see
  [core-vayume-config.md](core-vayume-config.md)); shown as
  password-masked fields (`Field.qml`, a restyled `DankTextField`)
  with a reveal toggle.
- **Groups** (`extraGroups`, including `wheel`/sudo) - shown as
  toggles over `vayume config users list`'s live `groupOptions`
  (curated shortlist ∩ this system's real `config.users.groups`, see
  core-vayume-config.md), never free text - a typo'd group name can't
  reach `_config.nix` at all. "wheel" carries an "admin" marker, and
  the page opens with a warning that groups and password control real
  access. Removing an account is the last row of that user's panel and
  needs a second click within four seconds.
- **Password** (`hashedPassword`) - a "new password"/"confirm
  password" pair, only enabled once they match; the plaintext is
  written over the `vayume config users set-password` `Process`'s own
  stdin (`stdinEnabled: true` + `write()`), never as a command-line
  argument - argv is readable by any process on the machine via
  `/proc`, stdin isn't. The backend hashes it (`mkpasswd -m sha-512`)
  before it ever touches `_config.nix`; the plaintext never becomes a
  long-lived QML property, and the response never echoes it back.

`avatar`, `shell`, and `extraPackages` stay Nix-only, same boundary as
`iconTheme`/`fontPackage` on the Appearance page: `avatar` is a path
literal and `shell`/`extraPackages` are packages, none of which can be
safely produced from a text field. `validate_config_file` (the `nix
eval` `apply_edit` runs before committing any write) was extended to
force-evaluate every field this page actually writes -
`fullName`/`hashedPassword`/`extraGroups`/each secret value - so a
broken users edit is caught the same way a broken apps/theme edit
already was, not silently deferred to the next real rebuild.

`vayume.network` is still absent, on purpose: it lives in `Host.nix`
(machine-level), not `_config.nix` - editing it here would quietly
reopen the two-file config split this whole plugin exists to avoid.


## Notes from the code

### `modules/desktop/settings/qml/VayumeModel.qml`

- Above `function appendRebuildLog(line) {`: Capped so a runaway or unusually chatty rebuild can't grow this without bound - only the tail is useful for "what just happened" anyway.
- Above `function queueThemeWrite(field, value) {`: Every backend write pays for a real `nix eval` (apply_edit's own validation, never skipped) - too slow to run on every single click of a +/- spinner. The value shown updates immediately (optimistic - only rolled back if the write is later rejected); the actual write is debounced so five quick clicks become one backend call with the final value, not five sequential validate-evals.
- Above `function setUserPassword(user, password) {`: Not optimistic (there's no visible field to update ahead of the write) and deliberately never kept in a long-lived property - the plaintext only exists in this call's local scope and inside the Process's own stdin pipe, same reasoning as `vayume config`'s own "argv is visible to every process via /proc, stdin isn't" - see modules/vayume/Config.nix.
- Above `function addUser(user, fullName) {`: Not optimistic like the field setters above - a fresh user arrives with extraGroups/hasPassword/secrets defaults this widget doesn't know ahead of time (userSubmodule's own, not duplicated here), and a removal just needs the list to reflect reality. usersAddRemoveProc always refetches on exit rather than only on failure.
- Above `function searchPackages(query) {`: Explicit trigger, not per-keystroke - a search against the whole of nixpkgs takes several seconds even with `nix search`'s own cache warm (and up to a minute stone-cold, the first time it builds that cache), so searching on every keystroke would mean piling up several-second subprocess calls behind each other instead of one on Enter/click.
- Above `function setUserPackage(user, path, enabled) {`: Same optimistic-update convention as setUserGroup - flips the one key immediately, only refetches (undoing the optimistic guess) if the backend rejects it, e.g. a package that stopped existing in nixpkgs since the last `nix flake update`.
- Above `}`: keep the previous value on a parse failure
- Above `if (exitCode !== 0) root.refreshTheme();`: Success: the optimistic value shown is already correct, no need to pay for another full theme fetch. Failure: the optimistic guess was wrong - refetch to show the real, unchanged value instead of the rejected one.
- Above `if (exitCode !== 0) {`: Same reasoning as themeSetProc: the toggle already flipped optimistically, so a success needs no refetch (that's what was showing a spurious "Loading applications..." flash after every toggle, with no rebuild involved). Only re-derive the real state on failure, to undo a toggle the backend rejected.
- Above `if (exitCode !== 0) root.refreshUsers();`: Same optimistic-update reasoning as setAppProc/themeSetProc - only refetch (and so overwrite the optimistic value) on failure.
- Above `Process {`: stdinEnabled + write() rather than a command-line argument, so the new password is never visible via /proc to any other process on the machine the way an argv value would be - see cmd_users_set_password in modules/vayume/Config.nix for the same reasoning on the backend side. `pendingWrite` is cleared the instant it's been handed to the process, so the plaintext doesn't linger in a QML property.

### `modules/desktop/settings/qml/ui/pages/ApplicationsPage.qml`

- `appsHere` leaves out the development apps: they have their own page (with editor integrations), and showing them here too would be the same toggle in two places. Sections come from each app's `appMeta.section`, in the fixed order of `sectionOrder`; an unknown section sorts after those.

### `modules/desktop/settings/qml/ui/components/Badge.qml`

- `tone` is one of `neutral`, `info`, `warning`, `error`, `success`.

### `modules/desktop/settings/qml/ui/components/Section.qml`

- Above `property bool collapsible: false`: Opt-in - only a section that sets collapsible: true gets a clickable (and keyboard-focusable) title and a chevron; collapsed itself is left to the caller to own (per-instance, e.g. one bool per Repeater delegate) rather than reset here, so a page with several of these cards controls each one's default/remembered state itself.

### `modules/desktop/settings/qml/ui/SettingsWindow.qml`

- Above `Connections {` (sets `logOpen`): A rebuild's real output belongs where it's visible no matter which sidebar category happens to be open when it runs, not buried on one settings page - it always shows fresh (never collapsed by default) the moment a rebuild starts, since that's exactly when someone wants to see it.
- Above `LogPanel {`: The real nixos-rebuild switch output, streamed live - sits at the bottom of the window regardless of which sidebar category is open, so starting a rebuild from Appearance doesn't mean switching to System just to watch it happen.

### `modules/desktop/settings/qml/ui/components/OptionRow.qml`

- `description` joins single line breaks: option descriptions come from the Nix source, where long strings are wrapped by hand, and keeping those breaks made every description wrap at the source's column instead of the row's width. Blank lines still separate paragraphs.

### `modules/desktop/settings/qml/ui/components/Select.qml`

- `DankDropdown` assigns its own `currentValue` when an entry is picked, which breaks the binding to the value shown on the trigger; the handler puts the binding back so the popup's highlight keeps following the real value.

### `modules/desktop/settings/qml/ui/pages/UsersPage.qml`

- Above `echoMode: secretField.passwordVisible ? TextInput.Normal : TextInput.Password`: DankTextField's own eye button only flips its `passwordVisible` property - it never touches echoMode itself (checked its source directly: no internal binding from one to the other, in this pin), so a hardcoded `echoMode: TextInput.Password` clicks the eye but never reveals anything. Bind echoMode to passwordVisible instead - the wiring the component clearly expects the caller to do.

---

[← AutoUpdate.nix](core-autoupdate.md) · [Index](CONFIGURATION.md) · [Niri.nix →](desktop-niri.md)

---

[← Index](CONFIGURATION.md)
