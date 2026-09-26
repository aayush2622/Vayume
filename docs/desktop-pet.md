[Index](CONFIGURATION.md)

---

A pixel pet that lives on the screen: it naps, wanders, chases the pointer if you want, and can be picked up and dropped anywhere.

## `modules/desktop/pet/Pet.nix`

- **Its own Quickshell instance, not a DMS widget.** `vayume-pet` is a
  user service running `qs -p` on a small config built into the store
  (`shell/shell.qml`, `shell/Pet.qml`, the skin and a generated
  `data.js`), bound to `graphical-session.target` like the other session
  services. It doesn't touch DMS at all and keeps running if DMS
  restarts. It uses nixpkgs' `quickshell`, the same 0.3.1 that DMS runs.
- **One full-screen transparent layer, with an input mask the shape of the
  pet.** The pet can go anywhere on the output without moving a surface,
  and dragging is plain item movement inside the window. The mask is a
  Quickshell `Region` whose children are rectangles traced from the
  sprite: `trace.py` reads each 32x32 frame's alpha, grows it by one
  pixel (easier to grab), and merges equal horizontal runs on
  consecutive rows into rectangles (about 20 per frame). The shell
  creates `Region`s for every frame once and swaps the set whenever the
  frame changes, each bound to the pet's position and scale. A click
  anywhere outside the drawn pixels, even inside the pet's square, goes
  to whatever is underneath.
- **Sprites.** The sheets are the oneko set from
  [kyrie25/Spicetify-Oneko](https://github.com/kyrie25/Spicetify-Oneko)
  (MIT): `classic`, `dog`, `maia`, `tora` and `vaporwave`, fetched at a
  pinned commit. `kuroneko` inverts the colours at build time, the way
  that project does with a CSS filter. Only the chosen skin is built in.
  [wayland-vpets](https://github.com/furudbat/wayland-vpets) was
  considered and not used: it is a keyboard-reactive strip fixed to a
  screen edge and can't be dragged.
- **What it does.** Sits, washes, scratches the wall when it ends up
  against a screen edge, gets tired and sleeps, and in `wander` mode walks
  to random spots in eight directions. Click it for hearts, double-click
  to put it to sleep or wake it, and drag it: while carried it paws
  against the direction you pull, as in the Spicetify version, and looks
  startled once you drop it. Hovering shows its name tag if it has a
  name. Its position is kept in `~/.local/state/vayume-pet/pet.json` as
  screen fractions, so it comes back where you left it. Not in
  `Quickshell.statePath`: that directory is keyed by the config's path,
  which is a new store path after every rebuild.
- **It gets out of the way of fullscreen apps**, even on the `overlay`
  layer, which would otherwise draw over a fullscreen game or video. On
  Hyprland the pet hides while the active workspace of its monitor has a
  fullscreen window (`Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen`)
  and a toplevel on that screen reports the real fullscreen state -
  `hasFullscreen` alone is also true for maximized windows. Elsewhere it
  hides while the focused toplevel on its screen is fullscreen
  (`ToplevelManager`). Hidden, it fades out and its input mask is empty, so
  clicks go to the app; it keeps its place and comes back when fullscreen
  ends. Checked in headless sway by fullscreening a window; the Hyprland
  branch was not exercised there.
- **`follow` is Hyprland only.** Wayland gives a client the pointer only
  while it's over that client's surface, so the pet asks Hyprland for
  the cursor (`j/cursorpos` on its IPC socket) ten times a second while
  in this mode, and runs after it like the original oneko. On niri
  there's no equivalent, so the pet just sits and does idle things.

### Options (`vayume.desktop.pet`, the Desktop pet page in Settings)

The page opens with an animated preview of the saved skin, colours and name
(drawn from `/etc/vayume/pet-skins`, which this module fills with every skin
plain and inverted), then the options in three cards: **Your pet** (show,
name, skin, kuroneko, size), **Behaviour** (movement, activity, speed,
bubbles) and **Placement** (layer, monitor, hide over fullscreen apps).

| Option | Default | |
|---|---|---|
| `enable` | `false` | run the service |
| `skin` | `classic` | `classic`, `dog`, `maia`, `tora`, `vaporwave` |
| `kuroneko` | `false` | inverted colours |
| `size` | `3` | pixel scale, 1-8 (3 = 96 px) |
| `speed` | `10` | pixels per step, ten steps a second |
| `behaviour` | `wander` | `wander`, `follow`, `stay` |
| `activity` | `normal` | `lazy`, `normal`, `playful`: how often it does something and how long it naps |
| `layer` | `top` | `bottom` (desktop only, under windows), `top` (over windows, under fullscreen), `overlay` |
| `name` | `""` | name tag on hover |
| `bubbles` | `true` | hearts, z's and ! |
| `monitor` | `""` | output name; empty is the first one |
| `hideInFullscreen` | `true` | fade out and stop catching clicks while a fullscreen app is on the pet's screen, on every layer |

Every option is baked into the store config, so a change applies on the
next rebuild, which restarts the service.

Checked in a headless sway session with the built config: frames,
hearts, sleep bubbles and the carried pose render, and the mask's
rectangles move with the pet. Every skin and its kuroneko variant were
traced. Real clicks through the mask and `follow` under Hyprland were not
exercised there.

---

[← SddmTheme.nix](desktop-sddm.md) · [Index](CONFIGURATION.md) · [Misc.nix →](system-misc.md)
