[Index](CONFIGURATION.md)

---

A native GUI for pointing Claude Code (and Codex, Gemini CLI, OpenCode, and
a few others) at a different API provider, without hand-editing their
config files.

## `modules/apps/development/ccSwitch/CcSwitch.nix`

Just the app - [cc-switch](https://github.com/farion1231/cc-switch) is
properly packaged in nixpkgs (`pkgs.cc-switch`, a Rust/Tauri build), so
this module is nothing more than installing it. Adding providers,
switching between them, and its own local-proxy/failover mode all happen
through cc-switch's own UI and its own state (`~/.cc-switch/cc-switch.db`)
- there's no Nix-side config for any of that.

**Replaces the old [Free Claude Code](https://github.com/Alishahryar1/free-claude-code)
module.** That one cloned FCC's Python proxy with `uv`, ran it as a user
service, and `jq`-patched VS Code/Android Studio/Claude Code's own config
files to point at `localhost:8082`. cc-switch does the same underlying job
- getting Claude Code talking to a non-Anthropic provider - through an
actively-maintained, already-packaged desktop app instead, so none of that
service/patching machinery lives in this repo any more. The `PROVIDERS`
secrets bag that only ever existed to feed FCC's provider API keys is gone
too - see [core/Users.nix](core-users.md); add a provider straight through
cc-switch's own UI instead.

---

[← DevTools.nix](apps-dev-devtools.md) · [Index](CONFIGURATION.md) · [Gaming.nix →](apps-gaming.md)
