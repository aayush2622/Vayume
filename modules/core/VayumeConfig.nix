{ self, ... }: {
  flake.nixosModules.VayumeConfig =
    { pkgs, lib, config, ... }:
    let
      repoDiscovery = self.vayumeLib.repoDiscovery;
      hostName = config.networking.hostName;

      candidateDirs =
        map (d: ''"$HOME/${d}"'') repoDiscovery.relativeDirs
        ++ map (d: ''"${d}"'') repoDiscovery.absoluteDirs;
      candidateDirsDisplay =
        map (d: "~/${d}") repoDiscovery.relativeDirs
        ++ repoDiscovery.absoluteDirs;

      # state machine over the *whole file*, not just a running brace
      # count - state 0 (before the block), 1 (inside it), 2 (after it,
      # for good) - so a later unrelated `foo.enable = true;` (there are
      # several, e.g. hardware.bluetooth, pipewire.alsa) is never
      # mistaken for one of vayume.apps's entries once the block has
      # closed. state only ever moves forward.
      appsAwk = pkgs.writeText "vayume-config-apps.awk" ''
        BEGIN {
          state = 0; depth = 0; found = 0;
          nameRe = "^[ \t]*" target "\\.enable[ \t]*=[ \t]*(true|false);";
        }
        {
          line = $0

          if (state == 0 && line ~ /vayume\.apps[ \t]*=[ \t]*\{/) {
            state = 1
            match(line, /^[ \t]*/)
            indent = substr(line, 1, RLENGTH) "  "
            depth += gsub(/\{/, "{", line)
            depth -= gsub(/\}/, "}", line)
            if (mode == "set") print line
            next
          }

          if (state == 1) {
            depth += gsub(/\{/, "{", line)
            depth -= gsub(/\}/, "}", line)

            if (depth <= 0) {
              if (mode == "set" && !found) {
                print indent target ".enable = " value ";"
                found = 1
              }
              if (mode == "set") print line
              state = 2
              next
            }

            if (mode == "list") {
              if (line ~ /^[ \t]*[A-Za-z][A-Za-z0-9]*\.enable[ \t]*=[ \t]*(true|false);/) {
                m = line
                sub(/^[ \t]*/, "", m)
                sub(/\.enable.*$/, "", m)
                v = line
                sub(/^.*=[ \t]*/, "", v)
                sub(/;.*$/, "", v)
                print m " " v
              }
              next
            }

            if (mode == "set") {
              if (!found && line ~ nameRe) {
                sub(/(true|false);/, value ";", line)
                found = 1
              }
              print line
              next
            }
          }

          if (mode == "set") print line
        }
        END {
          if (mode == "set" && state == 0) {
            print "vayume-config: no vayume.apps block found" > "/dev/stderr"
            exit 1
          }
          if (mode == "set" && !found) {
            print "vayume-config: could not locate or insert " target " in the vayume.apps block" > "/dev/stderr"
            exit 1
          }
        }
      '';

      vayumeConfigScript = pkgs.writeShellApplication {
        name = "vayume-config";
        runtimeInputs = with pkgs; [ gnugrep gawk jq git nix coreutils ];
        text = ''
          usage() {
            cat >&2 <<'EOF'
          usage: vayume-config <command> [args]

          commands:
            repo                          repo path, git branch, dirty state (JSON)
            apps list                     every vayume.apps.* module and its state (JSON)
            apps set <Name> <true|false> [--if-unmodified-since <epoch>]
                                           toggle one app in _config.nix, validated + atomic
            validate                      re-evaluate _config.nix, report pass/fail
          EOF
            exit 2
          }

          discover_repo() {
            for d in ${lib.concatStringsSep " " candidateDirs}; do
              if [ -f "$d/flake.nix" ]; then
                echo "$d"
                return 0
              fi
            done
            echo "vayume-config: repo not found (checked ${lib.concatStringsSep ", " candidateDirsDisplay})" >&2
            return 1
          }

          flake_dir=$(discover_repo)
          config_file="$flake_dir/modules/hosts/${hostName}/_config.nix"

          [ -f "$config_file" ] || {
            echo "vayume-config: $config_file missing - copy _config.nix.example and fill it in (see docs/getting-started.md)" >&2
            exit 1
          }

          validate_config_file() {
            nix eval --impure --json --expr \
              "(builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.apps" \
              >/dev/null
          }

          cmd_repo() {
            local branch dirty
            branch=$(git -C "$flake_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(no git)")
            if git -C "$flake_dir" rev-parse --git-dir >/dev/null 2>&1 \
              && [ -n "$(git -C "$flake_dir" status --porcelain 2>/dev/null)" ]; then
              dirty=true
            else
              dirty=false
            fi
            jq -n --arg path "$flake_dir" --arg branch "$branch" --argjson dirty "$dirty" \
              --arg configFile "$config_file" \
              '{path: $path, branch: $branch, dirty: $dirty, configFile: $configFile}'
          }

          cmd_apps_list() {
            local available configured categories cat dir name
            available=$(nix eval --impure --json --expr \
              "builtins.attrNames (builtins.getFlake \"path:$flake_dir\").homeModules.apps")
            configured=$(awk -v mode=list -f ${appsAwk} "$config_file" \
              | jq -R -s '
                  split("\n") | map(select(length > 0) | split(" ")) |
                  map({(.[0]): (.[1] == "true")}) | add // {}
                ')

            categories="{}"
            for cat in development gaming utils; do
              dir="$flake_dir/modules/apps/$cat"
              [ -d "$dir" ] || continue
              while IFS= read -r name; do
                [ -n "$name" ] || continue
                categories=$(jq --arg n "$name" --arg c "$cat" '. + {($n): $c}' <<<"$categories")
              done < <(find "$dir" -name "*.nix" -printf "%f\n" | sed -E 's/\.nix$//')
            done

            jq -n --argjson available "$available" --argjson configured "$configured" --argjson categories "$categories" '
              $available | map(. as $n | {
                name: $n,
                enabled: ($configured[$n] // false),
                configured: ($configured | has($n)),
                category: ($categories[$n] // "utils")
              })
            '
          }

          cmd_apps_set() {
            local name value since mtime tmp
            name=''${1:?app name required}
            value=''${2:?true or false required}
            since=""
            if [ "''${3:-}" = "--if-unmodified-since" ]; then
              since=''${4:?epoch required after --if-unmodified-since}
            fi
            case "$value" in true|false) ;; *) echo "vayume-config: value must be true or false" >&2; exit 2;; esac

            mtime=$(stat -c %Y "$config_file")
            if [ -n "$since" ] && [ "$since" != "$mtime" ]; then
              echo "vayume-config: $config_file changed since it was last read (reload before editing)" >&2
              exit 3
            fi

            tmp="$config_file.vayume-config.tmp"
            if ! awk -v mode=set -v target="$name" -v value="$value" -f ${appsAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            cp -p "$config_file" "$config_file.bak"
            mv "$tmp" "$config_file"

            if validate_config_file; then
              rm -f "$config_file.bak"
              jq -n --arg name "$name" --arg value "$value" \
                '{ok: true, name: $name, enabled: ($value == "true")}'
            else
              mv "$config_file.bak" "$config_file"
              echo "vayume-config: new configuration failed to evaluate - reverted $config_file" >&2
              exit 1
            fi
          }

          cmd_validate() {
            if validate_config_file; then
              jq -n '{ok: true}'
            else
              jq -n '{ok: false}'
              exit 1
            fi
          }

          [ "$#" -ge 1 ] || usage
          case "$1" in
            repo) cmd_repo;;
            apps)
              shift
              case "''${1:-}" in
                list) cmd_apps_list;;
                set) shift; cmd_apps_set "$@";;
                *) usage;;
              esac
              ;;
            validate) cmd_validate;;
            *) usage;;
          esac
        '';
      };
    in
    {
      home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (_: {
        home.packages = [ vayumeConfigScript ];
      });
    };
}
