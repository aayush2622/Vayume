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

      # Same "before/inside/after" discipline as appsAwk, but for a flat
      # `<block> = { field = value; };` shape (no dotted `.enable`
      # suffix) that may not exist in the file at all yet - buffers every
      # line so a missing block can still be appended before the file's
      # own final closing brace, decided only once the whole file (and
      # whether the block was ever found) is known.
      themeAwk = pkgs.writeText "vayume-config-theme.awk" ''
        BEGIN { state = 0; depth = 0; found = 0; n = 0 }
        { n++; buf[n] = $0 }
        END {
          for (i = 1; i <= n; i++) {
            line = buf[i]
            if (state == 0 && line ~ /vayume\.theme[ \t]*=[ \t]*\{/) {
              state = 1
              match(line, /^[ \t]*/)
              indent = substr(line, 1, RLENGTH) "  "
              depth += gsub(/\{/, "{", line)
              depth -= gsub(/\}/, "}", line)
              buf[i] = line
              continue
            }
            if (state == 1) {
              depth += gsub(/\{/, "{", line)
              depth -= gsub(/\}/, "}", line)
              if (depth <= 0) {
                if (!found) {
                  insertBefore[i] = indent field " = " value ";"
                  found = 1
                }
                state = 2
                continue
              }
              if (!found && line ~ ("^[ \t]*" field "[ \t]*=")) {
                buf[i] = indent field " = " value ";"
                found = 1
                continue
              }
            }
          }

          if (!found) {
            insertBeforeFinal = "  vayume.theme = {\n    " field " = " value ";\n  };"
          }

          for (i = 1; i <= n; i++) {
            if (i in insertBefore) print insertBefore[i]
            if (i == n && insertBeforeFinal != "") print insertBeforeFinal
            print buf[i]
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
            theme get                     current font/fontSize/cursorTheme/iconTheme (JSON)
            theme set <fontSize|cursorTheme> <value> [--if-unmodified-since <epoch>]
                                           edit one theme field, validated + atomic
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
              "with (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume; [ apps theme.fontSize theme.cursorTheme ]" \
              >/dev/null
          }

          check_since() {
            local since mtime
            since=$1
            [ -n "$since" ] || return 0
            mtime=$(stat -c %Y "$config_file")
            if [ "$since" != "$mtime" ]; then
              echo "vayume-config: $config_file changed since it was last read (reload before editing)" >&2
              exit 3
            fi
          }

          # Applies a temp file (already-edited content) atomically, then
          # validates the result for real and rolls back on failure -
          # shared by every "set" command so there's one place that
          # understands "safe write", not one copy per field kind.
          apply_edit() {
            local tmp
            tmp=$1
            cp -p "$config_file" "$config_file.bak"
            mv "$tmp" "$config_file"

            if validate_config_file; then
              rm -f "$config_file.bak"
              return 0
            else
              mv "$config_file.bak" "$config_file"
              echo "vayume-config: new configuration failed to evaluate - reverted $config_file" >&2
              return 1
            fi
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
            local name value since tmp
            name=''${1:?app name required}
            value=''${2:?true or false required}
            since=""
            if [ "''${3:-}" = "--if-unmodified-since" ]; then
              since=''${4:?epoch required after --if-unmodified-since}
            fi
            case "$value" in true|false) ;; *) echo "vayume-config: value must be true or false" >&2; exit 2;; esac
            check_since "$since"

            tmp="$config_file.vayume-config.tmp"
            if ! awk -v mode=set -v target="$name" -v value="$value" -f ${appsAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg name "$name" --arg value "$value" \
                '{ok: true, name: $name, enabled: ($value == "true")}'
            else
              exit 1
            fi
          }

          cmd_theme_get() {
            nix eval --impure --json --expr \
              "with (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.theme; { inherit font fontSize cursorTheme iconTheme; }"
          }

          # cursorTheme's valid values genuinely depend on which names the
          # *current* cursorPackage ships - queried live rather than
          # hardcoded, so this never drifts from whatever Theme.nix's
          # default (or a host's own override) actually is.
          cmd_theme_set() {
            local field value since tmp cursorPackage validNames
            field=''${1:?field required}
            value=''${2:?value required}
            since=""
            if [ "''${3:-}" = "--if-unmodified-since" ]; then
              since=''${4:?epoch required after --if-unmodified-since}
            fi
            check_since "$since"

            case "$field" in
              fontSize)
                case "$value" in
                  *[!0-9]* | "") echo "vayume-config: fontSize must be a positive integer" >&2; exit 2;;
                esac
                [ "$value" -gt 0 ] || { echo "vayume-config: fontSize must be a positive integer" >&2; exit 2; }
                ;;
              cursorTheme)
                cursorPackage=$(nix eval --impure --raw --expr \
                  "(builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.theme.cursorPackage")
                validNames=$(find "$cursorPackage/share/icons" -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null)
                if ! grep -qxF "$value" <<<"$validNames"; then
                  echo "vayume-config: '$value' isn't a cursor theme the current cursorPackage ships. Options:" >&2
                  while IFS= read -r n; do echo "  $n" >&2; done <<<"$validNames"
                  exit 2
                fi
                value="\"$value\""
                ;;
              *)
                echo "vayume-config: unsupported theme field '$field' (fontSize, cursorTheme)" >&2
                exit 2
                ;;
            esac

            tmp="$config_file.vayume-config.tmp"
            awk -v field="$field" -v value="$value" -f ${themeAwk} "$config_file" > "$tmp"

            if apply_edit "$tmp"; then
              jq -n --arg field "$field" --arg value "$value" '{ok: true, field: $field, value: $value}'
            else
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
            theme)
              shift
              case "''${1:-}" in
                get) cmd_theme_get;;
                set) shift; cmd_theme_set "$@";;
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
