[Index](CONFIGURATION.md)

---

Spotify, recolored to match everything else, the same way Zen and GTK are.

## `modules/apps/utils/spicetify/Spicetify.nix`

**Custom font**: Spotify's client reads its UI font from a CSS custom
property, not plain `font-family`, so the theme CSS sets it explicitly
to the shared theme font and pulls the font package in as a dependency
of the themed build. The theme's own options get merged with, not
replaced by, this override - safe since Spicetify's theme option takes a
freeform attrset.

---

[← ZenBrowser.nix](apps-utils-zenbrowser.md) · [Index](CONFIGURATION.md) · [Nautilus.nix →](apps-utils-nautilus.md)
