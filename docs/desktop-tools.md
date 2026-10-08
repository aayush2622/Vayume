[Index](CONFIGURATION.md)

---

The launcher, clipboard history and power menu - the everyday pieces that don't care which shell is running.

## `modules/desktop/DesktopTools.nix`

Applied to every user, like [Theming.nix](desktop-theming.md). Each piece is a small `vayume-*` script that the niri and Hyprland binds call, so the keybinds never name the program behind them.

- **Launcher and clipboard are one rofi theme.** The layout copies DMS's own launcher: an outlined search pill, a header with a result count, two-line rows with big icons, a tinted selected row, mode chips and a key-hint footer. fuzzel can't draw two-line rows, tabs or a footer, which is why it was dropped. `vayume-launcher` opens rofi's combined mode (apps and open windows) with Apps and Files as separate tabs.
- **Colors come from matugen, layout is static.** `config.rasi` is a whole-file matugen template, like every other themed app, written to `~/.config/rofi/config.rasi` by DMS's custom-template system on each theme change. Until the first run rofi uses its default theme and the clipboard script skips its override.
- **The clipboard theme is a thin override.** `clipboard.rasi` only changes the header, placeholder and hints, and has to `@import` the main config first: `-theme` replaces the theme rather than layering on top, so without the import the clipboard window came up as plain default rofi.
- **Both binds toggle.** Each script starts with `pkill -x rofi`, so pressing either key while any rofi window is open closes it instead of stacking a second one.
- **Image entries get thumbnails.** `vayume-clipboard` decodes each image entry once into `~/.cache/vayume/cliphist-thumbs` and hands rofi the path through its row-icon syntax. Thumbnails older than a week are deleted on the next open. Text rows get the theme's generic text icon.
- **Tab switches modes.** rofi's own Tab bindings (next/previous element) are unbound so Tab and Shift+Tab can cycle the mode chips, matching DMS.
- **Known gaps against DMS's launcher.** No Plugins tab and no list/grid toggle. The Files tab browses directories, it doesn't search an index. A row with no description shows a blank second line.
- **`rofi-blur`** in [Hyprland.nix](desktop-hyprland.md) gives rofi the same blurred backdrop as DMS's own surfaces.
- **The power menu is wlogout**, themed the same way. Its lock button calls `vayume-lock`, which currently asks DMS to lock.

---

[← Pet.nix](desktop-pet.md) · [Index](CONFIGURATION.md) · [Misc.nix →](system-misc.md)
