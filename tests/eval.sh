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

host0=$(basename "$(find "$work/modules/hosts" -mindepth 1 -maxdepth 1 -type d | sort | head -1)")
mapfile -t users0 < <(nix_ eval --json "path:$work#nixosConfigurations.$host0.config.vayume.users" --apply builtins.attrNames | jq -r '.[]')
user1=${users0[0]}
user2=${users0[1]}

step "shell scripts"
bash -n "$work/install.sh"
nix_ run --inputs-from "$work" nixpkgs#shellcheck -- "$work/install.sh" "$work/tests/eval.sh"

step "markdown links"
broken=0
while IFS= read -r -d '' f; do
  while IFS= read -r link; do
    target=${link%%#*}
    case $target in "" | http* | mailto:*) continue ;; esac
    [ -e "$(dirname "$f")/$target" ] || { echo "$f: broken link $link" >&2; broken=1; }
  done < <(grep -o '](\([^)[:space:]]*\))' "$f" | sed 's/^](//; s/)$//')
done < <(find "$work" -name '*.md' -print0)
[ "$broken" = 0 ]

step "app registries agree (homeModules.apps / appDescriptions / devLanguages / pluginPins)"
nix_ eval --impure --json --expr "
  let
    f = builtins.getFlake \"path:$work\";
    notApp = reg: builtins.filter (n: !(f.homeModules.apps ? \${n})) (builtins.attrNames reg);
    problems = {
      noDescription = builtins.filter (n: !(f.appDescriptions ? \${n})) (builtins.attrNames f.homeModules.apps);
      descriptionWithoutApp = notApp f.appDescriptions;
      languageWithoutApp = notApp f.devLanguages;
      pinsWithoutApp = notApp f.pluginPins;
    };
  in if builtins.all (l: l == [ ]) (builtins.attrValues problems) then \"ok\" else throw (builtins.toJSON problems)"
echo

hosts=$(nix_ eval --json "path:$work#nixosConfigurations" --apply builtins.attrNames | tr -d '[]"' | tr ',' ' ')
for host in $hosts; do
  step "host $host (example config)"
  eval_drv "path:$work#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
done

for state in true false; do
  step "$host0 with every app enable = $state"
  eval_drv --impure --expr "
    let
      f = builtins.getFlake \"path:$work\";
      lib = f.inputs.nixpkgs.lib;
      sys = f.nixosConfigurations.$host0.extendModules {
        modules = [ { vayume.apps = lib.mapAttrs (_: _: { enable = lib.mkForce $state; }) f.homeModules.apps; } ];
      };
    in sys.config.system.build.toplevel.drvPath"
done

step "vayume command: no stray vayume-* binaries, help lists subcommands"
stray=$(nix_ eval --impure --raw --expr "
  let f = builtins.getFlake \"path:$work\"; c = f.nixosConfigurations.$host0.config;
      names = map (p: p.name or \"\") (c.home-manager.users.$user1.home.packages ++ c.environment.systemPackages);
  in toString (builtins.filter (n: builtins.match \"vayume-.*\" n != null) names)")
[ -z "$stray" ] || { echo "vayume-* packages on PATH (register them in vayume.commands instead): $stray" >&2; exit 1; }
vc=$(nix_ build --no-link --print-out-paths --impure --expr "
  let f = builtins.getFlake \"path:$work\";
  in builtins.head (builtins.filter (p: (p.name or \"\") == \"vayume\")
    f.nixosConfigurations.$host0.config.home-manager.users.$user1.home.packages)")/bin/vayume
"$vc" help | grep -q '^  config ' || { echo "vayume help has no config" >&2; exit 1; }
"$vc" --has config

step "vayume config against the example _config.nix"
vc_home=$(mktemp -d)
ln -s "$work" "$vc_home/vayume"
cfg="$work/modules/hosts/$host0/_config.nix"
cfg_before=$(mktemp)
cp "$cfg" "$cfg_before"
chmod 644 "$cfg"
vc_() { HOME="$vc_home" "$vc" config "$@"; }
expect_fail() { if vc_ "$@" 2>/dev/null; then echo "vayume-config $* should have failed" >&2; exit 1; fi; }
vc_ repo | jq -e '.hostName == "'"$host0"'"' >/dev/null
vc_ theme set fontSize 13 | jq -e '.ok' >/dev/null
expect_fail theme set fontSize abc
expect_fail apps set 'Foo.bar' true
expect_fail users set-name "$user1; rm" x
vc_ users add bob "Bob B" | jq -e '.ok' >/dev/null
vc_ users set-group bob wheel true | jq -e '.ok' >/dev/null
expect_fail users remove random-but-missing
vc_ users remove "$user2" | jq -e '.ok' >/dev/null
echo hunter2 | vc_ users set-password bob | jq -e '.ok' >/dev/null
expect_fail defaults set editor zeditor
vc_ apps set Zed true | jq -e '.ok' >/dev/null
vc_ apps list | jq -e 'map(select(.name == "Zed"))[0].enabled' >/dev/null
vc_ defaults set editor zeditor | jq -e '.ok' >/dev/null
vc_ defaults get | jq -e '.[] | select(.role == "editor") | .effective == "zeditor"' >/dev/null
vc_ defaults set editor auto | jq -e '.ok' >/dev/null
expect_fail defaults set shell kitty
vc_ validate | jq -e '.ok' >/dev/null
[ "$(stat -c %a "$cfg")" = 600 ] || { echo "vayume-config changed _config.nix's mode" >&2; exit 1; }
[ -z "$(find "$(dirname "$cfg")" -name '_config.nix.*' ! -name '*.example')" ] || { echo "vayume-config left temp files" >&2; exit 1; }
vc_ theme get | jq -e '.fontSize == 13' >/dev/null
echo "ok"
cp "$cfg_before" "$cfg"
rm -rf "$vc_home" "$cfg_before"

step "install.sh end to end (new host CiHost)"
printf '%s\n' ci "" y audio y hunter2 hunter2 "" hello y wk_key me@example.com n \
  | "$work/install.sh" --host CiHost --system x86_64-linux --skip-hardware --no-rebuild
cp "$work/modules/hosts/CiHost/_hardware.nix.example" "$work/modules/hosts/CiHost/_hardware.nix"
[ "$(stat -c %a "$work/modules/hosts/CiHost/_config.nix")" = 600 ] || { echo "_config.nix is not 0600" >&2; exit 1; }
eval_drv "path:$work#nixosConfigurations.CiHost.config.system.build.toplevel.drvPath"
[ "$(nix_ eval --raw "path:$work#nixosConfigurations.CiHost.config.networking.hostName")" = CiHost ] || { echo "host name is not taken from the folder" >&2; exit 1; }

step "nix flake check (every system, no builds)"
if ! out=$(nix_ flake check --no-build --all-systems "path:$work" 2>&1); then
  printf '%s\n' "$out" >&2
  exit 1
fi

step "vm apps (every host)"
nix_ eval --json "path:$work#apps.x86_64-linux" --apply 'builtins.mapAttrs (_: a: a.program)'
echo

step "all checks passed"
