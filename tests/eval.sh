#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

nix_() { nix --extra-experimental-features 'nix-command flakes' "$@"; }
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
eval_drv() { nix_ eval --option allow-import-from-derivation false --raw "$@"; echo; }

step "copying tracked files to $work"
git -C "$repo" ls-files -z --cached --others --exclude-standard \
  | (cd "$repo" && xargs -0 cp --parents -t "$work")

fill_examples() {
  local host f
  for host in "$work"/modules/hosts/*/; do
    for f in _hardware.nix _config.nix; do
      [ -f "$host$f" ] || cp "$host$f.example" "$host$f"
    done
  done
}
fill_examples

step "shell scripts"
bash -n "$work/install.sh"
nix_ run --inputs-from "$work" nixpkgs#shellcheck -- "$work/install.sh" "$work/tests/eval.sh"

hosts=$(nix_ eval --json "path:$work#nixosConfigurations" --apply builtins.attrNames | tr -d '[]"' | tr ',' ' ')
for host in $hosts; do
  step "host $host (example config)"
  eval_drv "path:$work#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
done

for state in true false; do
  step "Diablo with every app enable = $state"
  eval_drv --impure --expr "
    let
      f = builtins.getFlake \"path:$work\";
      lib = f.inputs.nixpkgs.lib;
      sys = f.nixosConfigurations.Diablo.extendModules {
        modules = [ { vayume.apps = lib.mapAttrs (_: _: { enable = lib.mkForce $state; }) f.homeModules.apps; } ];
      };
    in sys.config.system.build.toplevel.drvPath"
done

step "install.sh end to end (new host CiHost)"
printf '%s\n' ci "" y audio y hunter2 hunter2 "" hello y wk_key me@example.com n \
  | "$work/install.sh" --host CiHost --system x86_64-linux --skip-hardware --no-rebuild
cp "$work/modules/hosts/CiHost/_hardware.nix.example" "$work/modules/hosts/CiHost/_hardware.nix"
[ "$(stat -c %a "$work/modules/hosts/CiHost/_config.nix")" = 600 ] || { echo "_config.nix is not 0600" >&2; exit 1; }
eval_drv "path:$work#nixosConfigurations.CiHost.config.system.build.toplevel.drvPath"

step "vm apps (every host)"
nix_ eval --json "path:$work#apps.x86_64-linux" --apply 'builtins.mapAttrs (_: a: a.program)'
echo

step "all checks passed"
