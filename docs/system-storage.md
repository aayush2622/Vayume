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

Read-only, about half a second. Shows the filesystem, the regenerable caches with sizes, the biggest other caches (managed by their apps and never touched), the size of the trash and the largest downloads, coredumps, journal size and how many system generations exist. `--full` also scans your project folders for build output and counts the Nix garbage `gc` would delete (slower). Each section is sorted largest first, and paths too long for the column are shortened in the middle so the sizes stay aligned. It is also a button on the Storage page in Vayume Settings, next to a bar showing how full the disk is.

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
