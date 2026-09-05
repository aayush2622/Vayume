# Vendored: matugen-themes GTK theme

Source: https://github.com/InioX/matugen-themes, pull request
[#161](https://github.com/InioX/matugen-themes/pull/161)
("feat: new gtk3/4 template for more complete theming").

Taken from the PR's head branch, `SakibShahariar/matugen-themes`, at commit
`a30b72762494391b33073b8db4420a364d664fa6`. Licence: MIT (upstream repo).

The PR was still **open, not merged**, when these were vendored - which is
part of why they're copied in rather than fetched. The other reason is the
same one that applies to every other vendored tree in this repo: a build
that reaches the network at eval time isn't reproducible.

## What each file is

| File | Kind | Rendered to |
| --- | --- | --- |
| `gtk3-colors.css.template` | matugen template, 50 vars | `~/.cache/vayori/gtk3-colors.css` |
| `gtk4-colors.css.template` | matugen template, 121 vars | `~/.config/gtk-4.0/colors.css` |
| `gtk3.css` | static, 6251 lines | the rotating theme's `gtk.css`/`gtk-dark.css` |
| `gtk4.css` | static, 9973 lines | `~/.config/gtk-4.0/gtk.css` |

The two `.css` files are static stylesheets (no `{{ }}` anywhere); they
carry the widget styling and reference the `@define-color` names that the
two templates generate. Each one opens with `@import url("colors.css")` -
a **relative** import, so a rendered `colors.css` has to sit in the same
directory as the stylesheet importing it. That's what makes them drop into
the rotating theme directory cleanly, with no path rewriting.

## Where this deviates from the PR's own instructions

Upstream's "Option 2" puts `gtk3.css` at `~/.config/gtk-3.0/gtk.css` with
`colors.css` next to it. This repo does that for GTK4 but **not** for GTK3,
because that layout cannot live-reload GTK3 - `~/.config/gtk-3.0/gtk.css`
is read once at process start and never re-read (verified directly, see
[docs/desktop.md](../../../../docs/desktop.md#modulesdesktopbaselinenix)),
so an already-open app keeps its launch-time colors no matter what the
post_hook does. GTK3 gets the same stylesheet through the rotating named
theme instead, which is the one path GTK3 does re-read.
