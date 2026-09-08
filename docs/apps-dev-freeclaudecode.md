[Index](CONFIGURATION.md)

---

A free-tier model wired into every editor's own AI assistant, and the open-ended provider list that makes it work with whichever one you actually have a key for.

## `modules/apps/development/freeClaudeCode/FreeClaudeCode.nix`

Wires [Free Claude Code](https://github.com/Alishahryar1/free-claude-code)
(FCC) - a local proxy that lets Claude Code talk to non-Anthropic model
providers instead of the paid API - into the CLI, the VS Code extension,
and Android Studio's plugin.

- **Deliberately not a from-scratch Nix package.** FCC needs a recent
  Python and around 20 dependencies, several of which aren't packaged in
  nixpkgs at all, and it moves fast enough that hash-pinning the whole
  thing would be constant upkeep for no real benefit. Instead, `uv` gets
  installed declaratively and the actual clone-and-sync work happens in
  its own one-shot systemd service - `uv` manages the Python interpreter
  itself, nothing extra needed for that. Same trade-off already made
  elsewhere in this repo for Zen Browser's mod-fetching: a real network
  dependency for something too fast-moving to fully pin, not the norm
  everywhere else.
- **That setup work deliberately does *not* run inline during
  activation** - it used to, and that was a real, observed bug: syncing
  Python plus twenty packages ran synchronously inside the main
  activation service, blocking the entire rebuild on it, and on a slow
  connection could run past home-manager's own activation timeout and
  kill the *whole* rebuild, not just this one app's setup. Watched this
  actually happen in testing. Fixed by moving the heavy lifting to its
  own service and having activation just kick it off in the background -
  activation returns immediately no matter how long the sync takes, and
  the actual server waits for a real, finished sync before it starts,
  whether that start comes from the background kick or a later login.
- **The server itself runs as a normal user service**, restarting
  automatically on failure with a generous retry budget - mostly a
  leftover safety net from before the setup got split out, kept because
  it's cheap insurance against a slow first start.
- **The home-manager activation timeout got tuned down to 30 seconds**
  from the 5-minute default - and that number is worth double-checking
  if a rebuild ever ends up failing with a timeout in the logs. A live
  VM test at that value did show activation getting killed a little over
  20 seconds in, before some steps had even run - so on a slow first
  activation, this really can cut things short. It's a real trade-off,
  not obviously the right number forever.
- **The API-config file's base scaffold is seeded once and never
  overwritten - the provider keys are a different story.** Checked FCC's
  own source to confirm this exact path (not the cloned repo's own
  `.env`) is what the running server actually reads live config from,
  and what its own admin UI writes settings back into. Force-declaring
  the *whole file* the way some other config files in this repo are
  managed would fight that admin UI for ownership - so the scaffold
  (`MODEL`, `PROXY_AUTH_ENABLED`, the auth token, `FCC_OPEN_BROWSER`) is
  only written if the file doesn't exist yet, same "seed once" pattern
  as the Papirus icon copy elsewhere. Provider API keys are handled
  separately, and *do* re-sync every rebuild: `PROVIDERS` from
  `vayumeSecrets` (see [core/Users.nix](core-users.md) for
  the full schema) is first filtered down to entries that aren't still
  `"REPLACE_ME"` (`lib.filterAttrs`), then that survivors-only set gets
  baked into a flat `KEY=value` file at eval time and merged into `.env`
  as its own line per entry - a provider nobody's given a real key
  disables itself, rather than writing a key that would just fail every
  request. Keyed by whatever name is already in `PROVIDERS` - FCC itself
  supports 17+ providers, each needing its own correctly-named key
  (`NVIDIA_NIM_API_KEY`, `OPENROUTER_API_KEY`, `DEEPSEEK_API_KEY`, and so
  on, straight from FCC's own naming, not something this repo invents),
  so this is a real loop over however many real keys are actually there,
  not three hardcoded ones. Verified for real: four providers merged
  correctly, then a fifth added and one existing key changed, re-ran
  clean with no stale duplicates and no lines lost; with none set at
  all, the generated file comes out empty and nothing gets written.
  Generating a key itself still isn't something this repo can do for
  you - grab one from whichever provider and drop it into `PROVIDERS`,
  or set it through FCC's own admin UI instead.
- **Claude Code's own state file gets one specific flag merged in** -
  documented upstream as the fix for Claude Code still prompting a real
  Anthropic login even with FCC's URL/token already set. Merged in with
  `jq`, not overwritten outright, since this file is Claude Code's real
  session state and a full overwrite would either destroy that or fight
  the CLI for ownership of a file it's constantly writing to itself.
- **JetBrains' own agent registry gets the same careful, merge-only
  treatment** - it's a shared, IDE-wide file that could list other
  unrelated agents, so the merge only ever touches the one entry this
  setup cares about, additively, so it can't clobber anything else
  already registered there.
- **Android Studio gets covered a more direct way, separately** - the
  JetBrains-wide registry patch above targets JetBrains' generic
  mechanism for this, but whether Anthropic's own dedicated plugin
  actually reads that same registry is genuinely unverified upstream.
  So Android Studio also gets the wrapped-binary treatment described in
  its own section - more reliable anyway, since whatever the plugin
  spawns as a subprocess just inherits the wrapped process's environment
  through normal OS process inheritance, regardless of which internal
  mechanism the plugin actually uses to read its config.
- **None of this is wired system-wide, on purpose.** The FCC connection
  details only get set inside VS Code's own settings, the JetBrains
  registry, and Android Studio's wrapped binary specifically - never as
  a plain session-wide environment variable, which would silently
  redirect *every* terminal's real `claude` command through FCC too and
  break normal, properly-authenticated Claude Code usage everywhere
  else. FCC ships its own separate launcher for terminal use instead,
  which only sets these variables for itself.
- **Only Claude Code gets wired up here** - FCC's own installer offers
  hookups for several other agent CLIs too, each with its own
  third-party installer script. None of that runs; only what Claude Code
  actually needs gets installed.
- **The connection details live in exactly one shared place**, not
  copied into three separate files - it used to be copied, and that was
  a real bug: turning FCC off in `vayume.apps` left VS Code and Android
  Studio still pointed at a proxy that was never actually started, with
  no error, just a Claude Code integration silently trying to talk to a
  dead port instead of falling back to the real API. Fixed by
  publishing the connection info from one shared place and having both
  editors check whether FCC is actually enabled before using it -
  verified in both directions: built with FCC on (nothing changed), then
  built again with it stripped from `vayume.apps` and confirmed both
  editors cleanly fell back to their plain, unwrapped configuration.
- **Android Studio's `CHROME_EXECUTABLE = "zen"` got the identical
  fix, for the identical reason** - it only gets set when Zen Browser is
  actually enabled, since otherwise it'd point at a binary that doesn't
  exist. A repo-wide check for this exact pattern - one app module
  hardcoding another app's binary, URL, or port - turned up only these
  two real cases.

---

[← DevTools.nix](apps-dev-devtools.md) · [Index](CONFIGURATION.md) · [Gaming.nix →](apps-gaming.md)
