[Index](CONFIGURATION.md)

---

The command-line half of "developer machine" - the tools no single language or editor owns.

## `modules/apps/development/devTools/DevTools.nix`

`git` isn't listed here - it's already installed system-wide, since
flakes need it available regardless of which apps anyone's picked.

`claude-code` is the CLI (`claude`) - just the binary, no API key or
provider config here.

**It is built from a release manifest kept in this repo, not nixpkgs'
pin.** nixpkgs trails Anthropic's release feed by days to weeks, and newer
models are gated on the CLI version ("Update Claude Code to use this
model"). `claude-code-manifest.json` is the same file nixpkgs itself
consumes, fetched straight from the feed, and passed to the stock package
through `.override { manifest = ...; }` - so the build, wrapper and
sandbox tools are nixpkgs' own, only the version and checksums differ.
To bump it: `curl -fsSL https://downloads.claude.ai/claude-code-releases/latest`
for the version, then fetch
`.../<version>/manifest.zst.json` over `claude-code-manifest.json`. The
VS Code extension is a separate package, see [VS Code](apps-dev-vscode.md). Point it at a provider through
[cc-switch](apps-dev-ccswitch.md) instead of hand-editing
`~/.claude/settings.json`.

---

[← languages/*/*.nix](apps-dev-languages.md) · [Index](CONFIGURATION.md) · [CcSwitch.nix →](apps-dev-ccswitch.md)
