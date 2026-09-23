[Index](CONFIGURATION.md)

---

The one thing in this repo that isn't declarative on purpose - real, irreplaceable session state, backed up on demand instead of managed.

## `modules/apps/utils/stateBackup/StateBackup.nix`

One canonical folder - `~/.config/vayume/session` - for every app's real
login/session state (Zen Browser's profile, Vesktop, VS Code/Zed account
sign-ins, the JetBrains/Android Studio data dir, rbw's own session, the
Bitwarden desktop app's local storage, cc-switch's provider configs - see
[core.md](core-users.md)), plus one command to move that
folder around safely. Fixed under `$HOME`, on purpose - completely
independent of wherever this flake repo happens to be checked out, so
it's the same folder whether the repo lives at `~/vayume`, got cloned
somewhere else entirely, or isn't even on disk right now (restoring a
backup doesn't need the repo present at all).

What's in it (`statePaths`):

| Path | Why |
| --- | --- |
| `.zen/default`, `.config/vesktop`, `.config/Code`, `.config/zed`, `.config/JetBrains`, `.local/share/Google` | browser / Discord / editor profiles |
| `.local/share/keyrings` | the GNOME keyring - where VS Code, Zed and other libsecret apps actually keep their sign-in tokens, so without it the editor profiles come back logged out |
| `.ssh`, `.gnupg` | keys |
| `.config/gh`, `.android` | GitHub CLI auth, adb's authorized key |
| `.config/rbw`, `.cache/rbw`, `.config/Bitwarden` | password manager sessions |
| `.config/spotify`, `.local/share/spotifast` | Spotify (Spicetify) login, Spotifast app state |
| `.config/heroic`, `.config/lutris` | Epic/GOG logins and launcher config (not the games themselves) |
| `.cc-switch` | Claude Code provider configs |
| `.local/state/DankMaterialShell` | DMS session state - wallpaper and the like |

Deliberately left out: anything that's a cache or re-downloadable
(`~/.gradle`, Zed's downloaded toolchains, Lutris runners), and
Waydroid's Android data - big, and `vayume waydroid android11` wipes it
with `rm -rf`, which on a symlink would only remove the link. `.ssh`,
`.gnupg` and `keyrings` (`privatePaths`) are forced to `0700` after
linking, the permission ssh and gpg expect.

**`home.activation.linkSessionState`** runs on every rebuild, and
deliberately runs *before* Home Manager links its own files
(`lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]`). A
stale symlink left over from a previous project name (pointing at
`…/<oldname>/session/<p>`) would otherwise make HM's own `linkGeneration`
die with `mkdir: File exists` / `ln: No such file or directory` -
running this entry first repairs those links before HM ever gets to
them. For each path in the list above, it symlinks the app's real config
location into `~/.config/vayume/session/<same path>` instead of leaving
it where the app would normally put it - so that one folder becomes the
single thing that ever needs to move for a fresh install to come back
already logged into everything.

If the project itself was renamed, the same activation entry does a
one-shot migration: it derives the *old* session directory from a
managed link's own target (no list of old names to maintain) and moves
the whole thing across in one shot, but only while there's no session
state of its own yet. Per-path, a link that's merely wrong or dangling -
typically a leftover from that previous name - gets its real data pulled
along into `session/` if the link still resolves to something outside
`SESSION_DIR` and nothing is already held for that app; otherwise it
just starts fresh.

- **Self-healing, not "run once and hope."** A path that's already a
  symlink is left alone - a cheap, near-zero-cost no-op on every
  subsequent rebuild. A path that's still real, un-migrated data gets
  *moved* (not copied-and-abandoned) into `session/` before the symlink
  goes in, so nothing ends up duplicated in two places or silently
  ignored. Checked this against real scenarios, not just read through
  the logic: migrating a machine with real existing data, re-running on
  already-migrated state (clean no-op), and a brand new `$HOME` picking
  up a pre-populated `session/` folder and coming up already logged in.
- **Nothing about the app-specific paths in this list was verified
  against a live app the way most of this repo's other claims were** -
  there's no way to actually launch Zed/VS Code/Android Studio and watch
  where they store auth tokens in this environment. Standard, well-known
  locations, not guesses, but worth a quick check against the real
  thing.

**`vayume app-state backup <file>` / `restore <file>`** turns that same
folder into a single password-encrypted archive and back - AES-256-CBC,
keyed via PBKDF2 (SHA-256, 10000 iterations) from a passphrase typed at
the prompt, never passed as a CLI argument (that'd leak through process
listings/shell history). For a same-trust move - a USB drive only you
touch, say - a plain `cp -r ~/.config/vayume/session` is just as valid
and a lot faster; this command exists for moving that folder somewhere
*less* trusted (cloud sync, email to yourself) without shipping it in
the clear.

- **The password is confirmed twice on backup, once on restore** - a
  typo locking you out of your own backup is a worse failure mode than
  a few extra keystrokes. A wrong password on restore fails loudly
  (openssl's own AEAD/padding check rejects it) rather than silently
  producing garbage - checked this for real, including confirming the
  session folder is left completely untouched on a failed restore, not
  partially overwritten.
- **Restore never clobbers outright.** It decrypts and unpacks into a
  temporary directory first, only swapping it into place after
  confirming the archive actually contained a real `session/` folder -
  and if `~/.config/vayume/session` already exists, it gets moved aside
  with a timestamp suffix instead of being deleted, so a restore never
  destroys data by mistake.
- **That temporary directory sits next to the session folder**
  (`~/.config/vayume/.session-restore.*`), not in `/tmp`. `/tmp` is
  tmpfs - RAM - and a browser profile can run to gigabytes; it's also a
  different filesystem, so the final `mv` used to be a slow copy that
  could die halfway and leave a half-restored session. On the same
  filesystem it's a single atomic rename.
- **An empty backup password is refused**, since it would produce an
  "encrypted" archive anyone can open.

---

[← Bitwarden.nix](apps-utils-bitwarden.md) · [Index](CONFIGURATION.md) · [Terminal.nix →](apps-utils-terminal.md)
