[Index](CONFIGURATION.md)

---

Password management, wired through `rbw` instead of the official GUI client.

## `modules/apps/utils/bitwarden/Bitwarden.nix`

Just the desktop app - nixpkgs calls it `bitwarden-desktop`, not
`bitwarden` (that name throws a "this package got renamed" error if you
try it). Signing in and syncing still needs doing once by hand; Nix just
makes sure the app itself is there.

**`programs.rbw`** is a separate CLI vault, unrelated to the desktop
app's own login - it's what the Bitwarden launcher plugin in DMS actually
talks to behind the scenes. Its account email now comes from
`vayoriSecrets.RBW_EMAIL` (see
[core/Users.nix](core-users.md)) rather than a manual
`rbw config set email`, merged into `~/.config/rbw/config.json` every
rebuild via `jq`, leaving everything else already in that file
untouched - not through `programs.rbw.settings` directly, since that
writes an immutable store-linked file and a value that changes per
machine should never sit in one of those. `rbw login` (the actual vault
unlock) still needs doing by hand - the master password itself never
goes through Nix, or anywhere else in this repo. That one stays a
manual, interactive step on purpose.

**No real email, no config write.** The whole `rbwEmail` activation
script is wrapped in `lib.optionalString (vayoriSecrets.RBW_EMAIL !=
"REPLACE_ME")` - `programs.rbw` still gets enabled either way (the CLI
itself doesn't need an email to exist), but `rbw`'s config file is left
exactly as it is rather than getting seeded with a literal
`"REPLACE_ME"` as the account email.

---

[← Thunar.nix](apps-utils-thunar.md) · [Index](CONFIGURATION.md) · [StateBackup.nix →](apps-utils-statebackup.md)
