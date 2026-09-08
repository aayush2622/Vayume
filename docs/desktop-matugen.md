[Index](CONFIGURATION.md)

---

One wallpaper in, dozens of app-specific color files out - the shared template registry every themed app in this repo draws from.

## `modules/desktop/Matugen.nix`

One shared attrset, one entry per themed app, each holding the raw
template content (a theme file, a CSS stylesheet, a Windows registry
file, an IDE color scheme) that would otherwise get duplicated inline in
every app's own module. Needed its own explicit option declaration to
actually merge correctly - it's not one of flake-parts' built-in outputs,
so nothing combines it automatically without that (shows up as a
harmless "unknown flake output" notice from `nix flake check` - purely
informational, not a failure).

Every app module reads its own entry straight off the shared flake
output - no extra plumbing needed, same pattern already used for other
shared inputs. Each app module still owns two things itself: writing that
content out to its own file under the matugen templates folder (matugen
doesn't care where this lives, it's this repo's own choice), and
registering the actual output path and any post-processing hook - those
depend on the real user's home directory at runtime, so they can't be
plain shared strings the way the template bodies themselves can.

**The Android Studio template is a function, not a plain string** -
because the color scheme file needs its own name baked into itself in a
couple of places, a value Android Studio's own module already computes
locally for other reasons anyway. Called with that name as an argument
rather than hardcoding the same string twice in two different files.

Every template here except Vesktop's was ported byte-for-byte from
[InioX/matugen-themes](https://github.com/InioX/matugen-themes) - only
the wiring (where it gets written, what it's called) is specific to this
repo. Vesktop's is different: there's no InioX template for it, so it's
the real machine's own hand-curated QuickCSS theme with matugen values
spliced in instead - see its own section for the full story on that one.

---

[← Baseline.nix](desktop-baseline.md) · [Index](CONFIGURATION.md) · [SddmTheme.nix →](desktop-sddm.md)
