[Index](CONFIGURATION.md)

---

Where the disk space goes, what the system now does about it automatically, and two commands for the rest: a read-only report and a cleaner that asks before deleting anything.

## `modules/system/Storage.nix`

### What a survey of this machine found

Measured before changing anything: the root filesystem (btrfs, `/` and `/home` are subvolumes of one 110 GB volume) was 84% used with 18 GB free. The Nix store was not the problem - only 1.4 GB of it was unreferenced. The space was elsewhere:

| What | Size | Kind |
| --- | --- | --- |
| Trash | 7.1 GB | your data |
| Build output in project folders (`.venv`, Flutter `build`, `.dart_tool`) | about 12.5 GB | regenerable |
| `~/.cache` | 8.7 GB | mostly regenerable |
| Downloads (a 3.7 GB installer ISO, videos) | 7.2 GB | your data |
| Coredumps in `/var/lib/systemd/coredump` | 1.2 GB | crash dumps up to 12 days old |
| Papirus/Tela icon themes in `~/.local/share/icons` | 1.7 GB | unmanaged copies; the repo's icon theme is Adwaita |

So there is no system setting that frees 20 GB; most of it is your data and your projects. What is automatic is what is safe to be automatic, and the rest is a report and an explicit, confirmed clean.

### Automatic

- **Coredumps are capped** (`systemd.coredump.settings.Coredump`: `MaxUse=200M`, `KeepFree=2G`), and `vayume gc` also removes dumps older than 7 days and trims the journal to 300 MB, since the cap only takes effect at the next crash.
- **Nix garbage collection runs weekly with `--delete-older-than 14d`** (was 30d), and `vayume gc` still keeps the newest 5 system generations.
- **btrfs scrub runs monthly** on `/` when the root filesystem is btrfs (`services.btrfs.autoScrub`), catching silent corruption early. It reads every block, so it takes minutes and some I/O once a month.
- **`documentation.info` and `documentation.doc` are off** (man pages stay); they are rarely opened and regenerate nothing.
- **`noatime`** on the btrfs mounts, in `_hardware.nix` (and its template): with the default `relatime` every first read of a day rewrites the file's metadata, which on a copy-on-write filesystem is pure churn. It applies with the next switch. It is in the hardware file, not a module, because mount options belong to the volume; a module cannot add an option to a filesystem it does not know exists.
- Already on from before: weekly `fstrim`, `compress=zstd:3`, `discard=async`, `min-free`/`max-free` so a build cleans up rather than filling the disk, and a 500 MB journal.

### `vayume disk`

Read-only. It accounts for the whole disk, so a run takes about a minute (the Nix store alone is 40 seconds of `du`); nothing past the filesystem line prints until that scan is done, then the rest appears at once. `--quick` is the old half-second report without the first section, `--full` adds the project-folder scan and the Nix roots list, and `--top N` changes how many rows each list shows (15 by default; the rows left out are summed into one "N smaller ..." line, so every total is still complete). Sizes are space actually allocated per file (`du` blocks, so a sparse download counts what it really uses), before the filesystem's own compression.

1. **Filesystem**: `df` used, size and free.
2. **Where all the space goes**: the Nix store, your home and the rest of `/`, each with its total and its percent of the total counted. The store is split into what the current system and your profiles use, what old generations and other roots keep alive, and unreferenced garbage (package sizes, so slightly more than the store takes after hard-linking). Home lists its biggest entries, and any entry over 1 GB is opened one or two levels down (`~/.config` shows `vayume` and, below it, `cache` and `session`). System files lists `/var` and friends the same way. It ends with the total counted, what `df` says is used, and the difference: `du` cannot see btrfs compression or shared extents, so on a `compress=zstd` disk the counted total is larger than the used space, and the gap is what compression and sharing save.
3. **Regenerable caches**, **Other caches**, **Your data** (trash, all of Downloads and its largest files) and **System** (coredumps, journal, generations), each with its own total.
4. **All the sections above**: the four totals and their sum. These sections are subsets of the home and system lines in part 2, not extra space.
5. With `--full`: project build artifacts with a total, and the GC roots that keep the most of the store alive (each root's closure, so they overlap and do not add up).

### `vayume clean`

Always lists what it will delete with sizes, and asks unless `--yes` is given. Without a terminal it refuses rather than guess.

- `vayume clean caches` removes a fixed list of caches that rebuild themselves: `~/.cache/{vscode-cpptools,appimage-run,thumbnails,pip,pnpm,yarn,go-build,nix}` and `~/.npm/_cacache`. Browser, Spotify and Android Studio caches are deliberately not on the list.
- `vayume clean trash [days]` permanently deletes everything trashed more than that many days ago (default 30), via `trash-empty`. It is not automatic: the trash is yours.
- `vayume clean artifacts` finds regenerable build output under `vayume.storage.projectDirs` (default `Development`, `Projects`, `Code`) and deletes it after confirmation. A folder only counts if its project file is next to it: `node_modules` with `package.json`, `target` with `Cargo.toml`, `build` and `.dart_tool` with `pubspec.yaml`; `.venv` always. A `build` folder in a project with no `pubspec.yaml` is left alone.

The panel's "Clean regenerable caches" button runs `caches --yes` after its own confirm click. Trash and artifacts are terminal-only on purpose.

### What it does not do

- It does not touch Downloads, the trash, or the Papirus/Tela copies: they are yours. `vayume disk` shows them.
- It does not enable btrfs deduplication or `compress-force`; the gain on a mostly-already-compressed disk is small and dedup daemons cost memory and I/O.
- The Nix store itself is left to `gc`. Deleting old generations is the only large store saving left, and it depends on how far back you want to roll.

---

[← Performance.nix](system-performance.md) · [Index](CONFIGURATION.md) · [Network.nix →](system-network.md)
