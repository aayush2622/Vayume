# Vendored Zen theming sources

Third-party files, copied in verbatim so the build needs no network and no
hash pinning. Nothing here is this repo's own work.

| Path | Upstream | Revision | Licence |
| --- | --- | --- | --- |
| `fx-autoconfig/` | [parazeeknova/doty](https://github.com/parazeeknova/doty), `modules/features/applications/zen/fx-autoconfig` | `11e911a238c74fe40c4ea03acdf3acf7cebce89d` | MIT |
| `wabi/` | [parazeeknova/zen-wabi](https://github.com/parazeeknova/zen-wabi) | `4b42ce351504f95de53aaf57d6bf70df85e0dd53` | MIT |

`fx-autoconfig/chrome/utils/` and `fx-autoconfig/program/config.js` originate
from [MrOtherGuy/fx-autoconfig](https://github.com/MrOtherGuy/fx-autoconfig)
(**MPL-2.0**) and keep their own file headers - leave those intact.

**Why vendored rather than fetched:** the JS in `zen-wabi` is committed as
symlinks into the author's private dotfiles tree, so it cannot be fetched
from that repo at all (GitHub's ZIP export turns the dangling links into
text files containing the link target). `doty` is where the real files
live, and it is a ~1.3 GB repository, so pulling it as a flake input to
reach ~90 KB of JavaScript is not worth it.

To update: re-copy from the revisions above and bump this table.
