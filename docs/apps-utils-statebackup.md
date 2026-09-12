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

**`home.activation.linkSessionState`** runs on every rebuild. For each
path in the list above, it symlinks the app's real config location into
`~/.config/vayume/session/<same path>` instead of leaving it where the
app would normally put it - so that one folder becomes the single thing
that ever needs to move for a fresh install to come back already logged
into everything.

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

**`vayume-app-state backup <file>` / `restore <file>`** turns that same
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

---

[← Bitwarden.nix](apps-utils-bitwarden.md) · [Index](CONFIGURATION.md) · [Terminal.nix →](apps-utils-terminal.md)
