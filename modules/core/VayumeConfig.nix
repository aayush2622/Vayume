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

      # Replaces one scalar field (fullName/hashedPassword/extraGroups/
      # secrets - always a whole-value replace, computed by the caller
      # from the live, already-resolved value rather than text-surgering
      # a list/attrset in place) inside one named user's own block under
      # `vayume.users`. `value` arrives via $USERS_AWK_VALUE, an
      # environment variable, not a `-v` assignment - awk's `-v` runs the
      # same backslash-escape processing as a string literal in the
      # program source, which would silently undo the caller's own Nix
      # escaping (`\"` collapsing back to `"`, `\$` warning and
      # collapsing to `$`) before this script ever saw it. Streams line
      # by line like appsAwk (no need to buffer - the target user's block
      # is already known to exist, from the same `users list` read that
      # produced the value being written), but the field being replaced
      # may itself have been multi-line (`extraGroups`/`secrets` commonly
      # are in a hand-edited `_config.nix`) - `phase 6` consumes exactly
      # as many further lines as the old value's own brackets/braces
      # still have open, so no orphaned continuation lines are left
      # behind as garbage after the single-line replacement is printed.
      usersAwk = pkgs.writeText "vayume-config-users.awk" ''
        BEGIN {
          value = ENVIRON["USERS_AWK_VALUE"]
          phase = 0; depthUsers = 0; depthUser = 0
          foundUserOpen = 0; foundField = 0
          userIndent = ""
          userRe = "^[ \t]*" user "[ \t]*=[ \t]*\\{"
          fieldRe = "^[ \t]*" fieldName "[ \t]*="
        }
        function braceDelta(l) { return gsub(/\{/, "{", l) - gsub(/\}/, "}", l) }
        function bracketDelta(l) { return gsub(/\[/, "[", l) - gsub(/\]/, "]", l) }
        {
          line = $0

          if (phase == 0) {
            if (line ~ /vayume\.users[ \t]*=[ \t]*\{/) {
              phase = 1
              depthUsers += braceDelta(line)
            }
            print line
            next
          }

          if (phase == 1) {
            if (depthUsers == 1 && !foundUserOpen && line ~ userRe) {
              foundUserOpen = 1
              phase = 2
              match(line, /^[ \t]*/); userIndent = substr(line, 1, RLENGTH) "  "
              depthUsers += braceDelta(line)
              depthUser = 1
              print line
              next
            }
            depthUsers += braceDelta(line)
            print line
            next
          }

          if (phase == 2) {
            delta = braceDelta(line)

            if (!foundField && depthUser == 1 && line ~ fieldRe) {
              print userIndent fieldName " = " value ";"
              foundField = 1
              bdelta = bracketDelta(line)
              if (delta > 0 || bdelta > 0) {
                phase = 6
                skipBrace = delta
                skipBracket = bdelta
              } else {
                depthUser += delta
              }
              next
            }

            depthUser += delta
            if (depthUser <= 0) {
              if (!foundField) print userIndent fieldName " = " value ";"
              phase = 3
            }
            print line
            next
          }

          if (phase == 6) {
            skipBrace += braceDelta(line)
            skipBracket += bracketDelta(line)
            if (skipBrace <= 0 && skipBracket <= 0) phase = 2
            next
          }

          print line
        }
        END {
          if (!foundUserOpen) {
            print "vayume-config: user " user " not found in vayume.users block" > "/dev/stderr"
            exit 1
          }
        }
      '';

      # Inserts one whole new `<user> = <value>;` entry just before
      # `vayume.users`'s own closing brace - same buffered
      # find-the-block's-end approach as themeAwk, but there's no
      # "block doesn't exist yet" fallback: unlike `vayume.theme` (always
      # optional), `vayume.users` is required by every real _config.nix
      # (Host.nix refuses to evaluate without one), so it's always
      # already there to insert into.
      usersAddAwk = pkgs.writeText "vayume-config-users-add.awk" ''
        BEGIN {
          value = ENVIRON["USERS_AWK_VALUE"]
          phase = 0; depth = 0; n = 0
        }
        function braceDelta(l) { return gsub(/\{/, "{", l) - gsub(/\}/, "}", l) }
        { n++; buf[n] = $0 }
        END {
          for (i = 1; i <= n; i++) {
            line = buf[i]
            if (phase == 0 && line ~ /vayume\.users[ \t]*=[ \t]*\{/) {
              phase = 1
              match(line, /^[ \t]*/)
              indent = substr(line, 1, RLENGTH) "  "
              depth += braceDelta(line)
              buf[i] = line
              continue
            }
            if (phase == 1) {
              depth += braceDelta(line)
              if (depth <= 0) {
                insertBefore[i] = indent user " = " value ";"
                phase = 2
              }
            }
          }
          if (phase != 2) {
            print "vayume-config: no vayume.users block found" > "/dev/stderr"
            exit 1
          }
          for (i = 1; i <= n; i++) {
            if (i in insertBefore) print insertBefore[i]
            print buf[i]
          }
        }
      '';

      # Deletes one user's whole `<user> = { ... };` entry outright -
      # every line from its opening brace through the matching close,
      # inclusive. Same phase/depth tracking as usersAwk's field lookup,
      # just suppressing lines instead of rewriting one.
      usersRemoveAwk = pkgs.writeText "vayume-config-users-remove.awk" ''
        BEGIN {
          phase = 0; depthUsers = 0; depthUser = 0
          foundUserOpen = 0
          userRe = "^[ \t]*" user "[ \t]*=[ \t]*\\{"
        }
        function braceDelta(l) { return gsub(/\{/, "{", l) - gsub(/\}/, "}", l) }
        {
          line = $0

          if (phase == 0) {
            if (line ~ /vayume\.users[ \t]*=[ \t]*\{/) {
              phase = 1
              depthUsers += braceDelta(line)
            }
            print line
            next
          }

          if (phase == 1) {
            if (depthUsers == 1 && !foundUserOpen && line ~ userRe) {
              foundUserOpen = 1
              phase = 2
              depthUsers += braceDelta(line)
              depthUser = 1
              next
            }
            depthUsers += braceDelta(line)
            print line
            next
          }

          if (phase == 2) {
            depthUser += braceDelta(line)
            if (depthUser <= 0) phase = 3
            next
          }

          print line
        }
        END {
          if (!foundUserOpen) {
            print "vayume-config: user " user " not found in vayume.users block" > "/dev/stderr"
            exit 1
          }
        }
      '';

      vayumeConfigScript = pkgs.writeShellApplication {
        name = "vayume-config";
        runtimeInputs = with pkgs; [ gnugrep gawk jq git nix coreutils fontconfig mkpasswd ];
        text = ''
          usage() {
            cat >&2 <<'EOF'
          usage: vayume-config <command> [args]

          commands:
            repo                          repo path, branch, dirty/rebuild-pending state (JSON)
            apps list                     every vayume.apps.* module and its state (JSON)
            apps set <Name> <true|false> [--if-unmodified-since <epoch>]
                                           toggle one app in _config.nix, validated + atomic
            development list              dev languages/editors/tools + editor integrations (JSON)
            theme get                     current font/fontSize/cursorTheme/iconTheme (JSON)
            theme set <fontSize|cursorTheme|font> <value> [--if-unmodified-since <epoch>]
                                           edit one theme field, validated + atomic
            users list                    every vayume.users.* profile + groupOptions (JSON)
            users add <user> [fullName] [--if-unmodified-since <epoch>]
            users remove <user> [--if-unmodified-since <epoch>]
                                           edits _config.nix only - the account itself is
                                           only actually deleted on the next rebuild
            users set-name <user> <fullName> [--if-unmodified-since <epoch>]
            users set-secret <user> <WAKATIME_API_KEY|RBW_EMAIL> <value> [--if-unmodified-since <epoch>]
            users set-group <user> <group> <true|false> [--if-unmodified-since <epoch>]
                                           <group> must already exist on this system
            users set-package <user> <attrPath> <true|false> [--if-unmodified-since <epoch>]
                                           <attrPath> (e.g. "blender", "nodePackages.pnpm")
                                           must resolve to a real package in this flake's nixpkgs
            users set-password <user> [--if-unmodified-since <epoch>]
                                           reads the new plaintext password from stdin,
                                           hashes it (mkpasswd -m sha-512), never touches argv
            packages search <query>       matching nixpkgs packages: [{path, pname, version, description}]
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

          # Deliberately forces every field this CLI can actually write,
          # not just `apps`/`theme` - a broken `users` edit (bad string
          # escaping, a stray brace) would otherwise sail through this
          # check unevaluated (Nix is lazy; nothing here touches `users`
          # unless something asks for it) and only surface at the next
          # real rebuild. Skips `shell`/`extraPackages`/`avatar`
          # deliberately - those are package/path-typed, not something
          # this CLI ever writes, and forcing them would mean evaluating
          # every user's shell package on every single apps/theme toggle
          # too, not just on a users edit. `packages`'s own bool values
          # get the same cheap force `secrets`' string values do - real
          # package resolution (attrByPath into nixpkgs) only happens
          # once something actually asks for `home.packages`, same
          # "don't force what nothing needs yet" reasoning.
          validate_config_file() {
            nix eval --impure --json --expr \
              "with (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume; [ apps theme.fontSize theme.cursorTheme ] ++ builtins.attrValues (builtins.mapAttrs (_: u: [ u.fullName u.hashedPassword u.extraGroups (builtins.attrValues u.secrets) (builtins.attrValues u.packages) ]) users)" \
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

          # Every value this CLI writes into `_config.nix` ends up inside
          # a Nix double-quoted string literal it builds itself - has to
          # neutralize backslash, double-quote, and dollar (Nix
          # interpolates a dollar immediately followed by an open brace
          # in double-quoted strings; an unescaped dollar ahead of
          # user-typed text could turn a display name or password hash
          # into an arbitrary evaluated expression) before that happens.
          # Unlike cursorTheme/font, `fullName`/secrets/password values
          # are genuinely arbitrary text, not picked from a
          # live-validated enum, so this can't be skipped the way it was
          # for those.
          nix_escape() {
            local s=$1
            s=''${s//\\/\\\\}
            s=''${s//\"/\\\"}
            s=''${s//\$/\\$}
            printf '%s' "$s"
          }

          # Usernames flow into an awk ERE (vayume-config-users.awk's
          # `userRe`) and, for a couple of set commands, straight into a
          # `nix eval --expr` string too - real Linux usernames are
          # already restricted to this charset, so this both blocks awk
          # metacharacter/nix-string injection and gives a clear error
          # for a typo'd name instead of a silent no-match.
          validate_username() {
            case "$1" in
              [a-z_][a-z0-9_-]*) ;;
              *) echo "vayume-config: invalid username '$1'" >&2; exit 2 ;;
            esac
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
            local branch dirty rebuildPending genMtime cfgMtime
            branch=$(git -C "$flake_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(no git)")
            if git -C "$flake_dir" rev-parse --git-dir >/dev/null 2>&1 \
              && [ -n "$(git -C "$flake_dir" status --porcelain 2>/dev/null)" ]; then
              dirty=true
            else
              dirty=false
            fi

            # /run/current-system's own mtime moves forward on every successful
            # switch (it's re-symlinked even when the target is unchanged) - a
            # cheap, restart-safe stand-in for "has _config.nix changed since
            # the last rebuild", no extra nix eval needed.
            cfgMtime=$(stat -c %Y "$config_file")
            genMtime=$(stat -L -c %Y /run/current-system 2>/dev/null || echo 0)
            [ "$cfgMtime" -gt "$genMtime" ] && rebuildPending=true || rebuildPending=false

            jq -n --arg path "$flake_dir" --arg branch "$branch" --argjson dirty "$dirty" \
              --arg configFile "$config_file" --arg hostName "${hostName}" \
              --argjson rebuildPending "$rebuildPending" \
              '{path: $path, branch: $branch, dirty: $dirty, configFile: $configFile,
                hostName: $hostName, rebuildPending: $rebuildPending}'
          }

          cmd_apps_list() {
            local data available descriptions configured categories cat dir name
            data=$(nix eval --impure --json --expr \
              "let self = builtins.getFlake \"path:$flake_dir\"; in { available = builtins.attrNames self.homeModules.apps; descriptions = self.appDescriptions; }")
            available=$(jq '.available' <<<"$data")
            descriptions=$(jq '.descriptions' <<<"$data")
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

            jq -n --argjson available "$available" --argjson configured "$configured" \
              --argjson categories "$categories" --argjson descriptions "$descriptions" '
              $available | map(. as $n | {
                name: $n,
                enabled: ($configured[$n] // false),
                configured: ($configured | has($n)),
                category: ($categories[$n] // "utils"),
                description: ($descriptions[$n] // "")
              })
            '
          }

          # Languages/editors/tools are already three separate directories
          # (modules/apps/development/{languages,editors,devTools,ccSwitch}) -
          # this just reads that existing structure rather than repeating a
          # kind label per app. `integrations` is the intersection of
          # `flake.devLanguages.<lang>`'s own editor keys (which editors that
          # language contributes extensions/plugins to) with whichever
          # editors are actually enabled right now - real data already
          # produced by DevLanguages.nix, not something invented for the UI.
          cmd_development_list() {
            local configured available descriptions data languages editors tools integrations
            configured=$(awk -v mode=list -f ${appsAwk} "$config_file" \
              | jq -R -s '
                  split("\n") | map(select(length > 0) | split(" ")) |
                  map({(.[0]): (.[1] == "true")}) | add // {}
                ')

            # devLanguages.<lang>'s own keys are the editor's lowercase-first
            # form (vscode, androidStudio - matching AndroidStudio.nix/etc.'s
            # own contribution, not the capitalized app name), so `available`
            # doubles as both the vendor-file filter below and the
            # lowercase-key -> real-app-name map for `integrations`.
            data=$(nix eval --impure --json --expr \
              "let self = builtins.getFlake \"path:$flake_dir\"; in { available = builtins.attrNames self.homeModules.apps; integrations = builtins.mapAttrs (_: v: builtins.attrNames v) self.devLanguages; descriptions = self.appDescriptions; }")
            available=$(jq '.available' <<<"$data")
            integrations=$(jq '.integrations' <<<"$data")
            descriptions=$(jq '.descriptions' <<<"$data")

            languages=$(find "$flake_dir/modules/apps/development/languages" -name "*.nix" -printf "%f\n" 2>/dev/null | sed -E 's/\.nix$//' | sort)
            editors=$(find "$flake_dir/modules/apps/development/editors" -name "*.nix" -printf "%f\n" 2>/dev/null | sed -E 's/\.nix$//' | sort)
            tools=$(find "$flake_dir/modules/apps/development/devTools" "$flake_dir/modules/apps/development/ccSwitch" \
              -name "*.nix" -printf "%f\n" 2>/dev/null | sed -E 's/\.nix$//' | sort)

            jq -n \
              --argjson available "$available" \
              --argjson languages "$(printf '%s' "$languages" | jq -R -s 'split("\n") | map(select(length > 0))')" \
              --argjson editors "$(printf '%s' "$editors" | jq -R -s 'split("\n") | map(select(length > 0))')" \
              --argjson tools "$(printf '%s' "$tools" | jq -R -s 'split("\n") | map(select(length > 0))')" \
              --argjson configured "$configured" --argjson integrations "$integrations" --argjson descriptions "$descriptions" '
                def realAppsOnly: map(select(. as $n | $available | index($n) != null));
                def entry: { name: ., enabled: ($configured[.] // false), description: ($descriptions[.] // "") };
                ($languages | realAppsOnly) as $languages |
                ($editors | realAppsOnly) as $editors |
                ($tools | realAppsOnly) as $tools |
                ($editors | map(select($configured[.] == true))) as $enabledEditors |
                {
                  languages: ($languages | map(. as $lang | entry + {
                    integrations: (($integrations[$lang] // []) | map(ascii_downcase) as $keys |
                      $enabledEditors | map(select(. as $e | $keys | index($e | ascii_downcase) != null)))
                  })),
                  editors: ($editors | map(entry)),
                  tools: ($tools | map(entry))
                }
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

          # cursorTheme's valid values genuinely depend on which names the
          # *current* cursorPackage ships - queried live rather than
          # hardcoded, so this never drifts from whatever Theme.nix's
          # default (or a host's own override) actually is. Shared by
          # `theme get` (so a UI never has to hardcode its own copy of
          # this list either) and `theme set`'s validation.
          cursor_options() {
            local cursorPackage
            if [ "$#" -gt 0 ]; then
              cursorPackage=$1
            else
              cursorPackage=$(nix eval --impure --raw --expr \
                "(builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.theme.cursorPackage")
            fi
            find "$cursorPackage/share/icons" -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null | sort
          }

          # Same live-package-contents trick as cursor_options - a font
          # family name is only meaningful together with whatever
          # fontPackage currently is, and one package can ship several real
          # families (nerd-fonts variants: with/without ligatures, mono vs
          # proportional spacing) - fc-scan reads what's actually in each
          # font file rather than guessing from the package name.
          font_options() {
            local fontPackage
            if [ "$#" -gt 0 ]; then
              fontPackage=$1
            else
              fontPackage=$(nix eval --impure --raw --expr \
                "(builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.theme.fontPackage")
            fi
            find "$fontPackage" \( -iname "*.ttf" -o -iname "*.otf" \) -print0 2>/dev/null \
              | xargs -r -0 -I{} fc-scan --format '%{family[0]}\n' {} 2>/dev/null | sort -u
          }

          cmd_theme_get() {
            local base cursorOptions fontOptions
            base=$(nix eval --impure --json --expr \
              "with (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.theme; { inherit font fontSize cursorTheme iconTheme; cursorPath = builtins.toString cursorPackage; fontPath = builtins.toString fontPackage; }")
            cursorOptions=$(cursor_options "$(jq -er '.cursorPath' <<<"$base")" | jq -R -s 'split("\n") | map(select(length > 0))')
            fontOptions=$(font_options "$(jq -er '.fontPath' <<<"$base")" | jq -R -s 'split("\n") | map(select(length > 0))')
            jq -n --argjson base "$base" \
              --argjson cursorOptions "$cursorOptions" \
              --argjson fontOptions "$fontOptions" \
              '$base | del(.cursorPath, .fontPath) | . + {cursorOptions: $cursorOptions, fontOptions: $fontOptions}'
          }

          # Best-effort, not persisted state - the value written to
          # _config.nix by cmd_theme_set is what survives a rebuild or a
          # fresh login; this just makes an already-running session look
          # right immediately, same idea as the matugen GTK color-scheme
          # post_hook in Baseline.nix. `hyprctl setcursor` (a plain
          # top-level hyprctl verb, not `hyprctl dispatch` - the Lua-based
          # dispatch rebind this repo's Hyprland config uses for keybinds
          # has no bearing on it, confirmed directly) live-updates every
          # Wayland client using the cursor-shape protocol; `gsettings`
          # covers GTK apps that read their cursor theme from dconf
          # instead. Neither reaches XWayland or an already-running
          # process that cached XCURSOR_THEME at its own startup, and
          # niri has no equivalent runtime call at all right now - this
          # is Hyprland-only in practice, silently a no-op elsewhere.
          apply_cursor_live() {
            local theme size
            theme=$1
            size=$(nix eval --impure --raw --expr \
              "toString (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.theme.cursorSize" 2>/dev/null) || return 0
            if command -v hyprctl >/dev/null 2>&1; then
              hyprctl setcursor "$theme" "$size" >/dev/null 2>&1 || true
            fi
            if command -v gsettings >/dev/null 2>&1; then
              gsettings set org.gnome.desktop.interface cursor-theme "$theme" >/dev/null 2>&1 || true
              gsettings set org.gnome.desktop.interface cursor-size "$size" >/dev/null 2>&1 || true
            fi
          }

          cmd_theme_set() {
            local field value since tmp validNames rawValue
            field=''${1:?field required}
            value=''${2:?value required}
            rawValue=$value
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
                validNames=$(cursor_options)
                if ! grep -qxF "$value" <<<"$validNames"; then
                  echo "vayume-config: '$value' isn't a cursor theme the current cursorPackage ships. Options:" >&2
                  while IFS= read -r n; do echo "  $n" >&2; done <<<"$validNames"
                  exit 2
                fi
                value="\"$value\""
                ;;
              font)
                validNames=$(font_options)
                if ! grep -qxF "$value" <<<"$validNames"; then
                  echo "vayume-config: '$value' isn't a family the current fontPackage ships. Options:" >&2
                  while IFS= read -r n; do echo "  $n" >&2; done <<<"$validNames"
                  exit 2
                fi
                value="\"$value\""
                ;;
              *)
                echo "vayume-config: unsupported theme field '$field' (fontSize, cursorTheme, font)" >&2
                exit 2
                ;;
            esac

            tmp="$config_file.vayume-config.tmp"
            awk -v field="$field" -v value="$value" -f ${themeAwk} "$config_file" > "$tmp"

            if apply_edit "$tmp"; then
              if [ "$field" = "cursorTheme" ]; then
                apply_cursor_live "$rawValue"
              fi
              jq -n --arg field "$field" --arg value "$value" '{ok: true, field: $field, value: $value}'
            else
              exit 1
            fi
          }

          # Curated on purpose, not the full `config.users.groups`
          # attrset - that includes every group anything on the system
          # ever defines (systemd services, dbus, ...), most of which
          # are meaningless to toggle per-user here. Anything already in
          # use by some user's real `extraGroups` right now is included
          # too, so an unusual-but-already-applied group never
          # disappears from the option list just because it isn't on
          # the hardcoded shortlist. `defined`/`current` are both real,
          # live data from the two callers below - never guessed.
          group_options() {
            local defined current
            defined=$1
            current=$2
            jq -n --argjson defined "$defined" --argjson current "$current" '
              (["wheel","networkmanager","video","input","audio","docker","adbusers","podman"] + $current) | unique
              | map(select(. as $g | $defined | index($g) != null)) | sort
            '
          }

          cmd_users_list() {
            local data base defined currentGroups groupOptions
            data=$(nix eval --impure --json --expr \
              "let c = (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config; in {
                 users = builtins.mapAttrs (_: u: {
                   inherit (u) fullName extraGroups secrets packages;
                   hasPassword = u.hashedPassword != null;
                   avatar = if u.avatar == null then null else toString u.avatar;
                 }) c.vayume.users;
                 definedGroups = builtins.attrNames c.users.groups;
               }")
            base=$(jq '.users' <<<"$data")
            defined=$(jq '.definedGroups' <<<"$data")
            currentGroups=$(jq -c '[.[].extraGroups[]] | unique' <<<"$base")
            groupOptions=$(group_options "$defined" "$currentGroups")
            jq -n --argjson users "$base" --argjson groupOptions "$groupOptions" '{users: $users, groupOptions: $groupOptions}'
          }

          # `extraGroups`/`secrets` are always replaced as one whole new
          # value, never text-surgered element-by-element - each setter
          # below reads the current, already-resolved value straight
          # from `nix eval`, edits it in jq, then hands
          # vayume-config-users.awk one complete Nix literal to drop in.
          # Simpler and safer than in-place list/attrset surgery, and it
          # can't silently drop a default the way writing just the one
          # changed element could (extraGroups's own mkOption default -
          # networkmanager/video/input - only applies when the option is
          # never set in _config.nix at all; writing a partial list
          # there replaces it outright, same as any Nix module option).
          cmd_users_set_name() {
            local user value since nixValue tmp
            user=''${1:?user required}
            value=''${2:?value required}
            since=""
            if [ "''${3:-}" = "--if-unmodified-since" ]; then
              since=''${4:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            case "$value" in *$'\n'*) echo "vayume-config: fullName can't contain a newline" >&2; exit 2;; esac
            check_since "$since"

            nixValue="\"$(nix_escape "$value")\""
            tmp="$config_file.vayume-config.tmp"
            if ! USERS_AWK_VALUE="$nixValue" awk -v user="$user" -v fieldName=fullName -f ${usersAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" --arg value "$value" '{ok: true, user: $user, fullName: $value}'
            else
              exit 1
            fi
          }

          cmd_users_set_secret() {
            local user key value since current merged nixValue tmp
            user=''${1:?user required}
            key=''${2:?secret key required}
            value=''${3:?value required}
            since=""
            if [ "''${4:-}" = "--if-unmodified-since" ]; then
              since=''${5:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            case "$key" in
              WAKATIME_API_KEY|RBW_EMAIL) ;;
              *) echo "vayume-config: unsupported secret key '$key' (WAKATIME_API_KEY, RBW_EMAIL)" >&2; exit 2;;
            esac
            case "$value" in *$'\n'*) echo "vayume-config: secret value can't contain a newline" >&2; exit 2;; esac
            check_since "$since"

            current=$(nix eval --impure --json --expr \
              "(builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.users.\"$(nix_escape "$user")\".secrets")
            merged=$(jq --arg k "$key" --arg v "$value" '. + {($k): $v}' <<<"$current")

            nixValue="{ "
            while IFS=$'\t' read -r k v; do
              nixValue+="\"$(nix_escape "$k")\" = \"$(nix_escape "$v")\"; "
            done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' <<<"$merged")
            nixValue+="}"

            tmp="$config_file.vayume-config.tmp"
            if ! USERS_AWK_VALUE="$nixValue" awk -v user="$user" -v fieldName=secrets -f ${usersAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" --arg key "$key" '{ok: true, user: $user, key: $key}'
            else
              exit 1
            fi
          }

          cmd_users_set_group() {
            local user group enabled since data defined current validGroups newList nixValue tmp
            user=''${1:?user required}
            group=''${2:?group required}
            enabled=''${3:?true or false required}
            since=""
            if [ "''${4:-}" = "--if-unmodified-since" ]; then
              since=''${5:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            case "$enabled" in true|false) ;; *) echo "vayume-config: value must be true or false" >&2; exit 2;; esac
            check_since "$since"

            data=$(nix eval --impure --json --expr \
              "let c = (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config; in {
                 definedGroups = builtins.attrNames c.users.groups;
                 currentGroups = c.vayume.users.\"$(nix_escape "$user")\".extraGroups;
               }")
            defined=$(jq '.definedGroups' <<<"$data")
            current=$(jq '.currentGroups' <<<"$data")

            validGroups=$(group_options "$defined" "$current")
            if ! jq -e --arg g "$group" 'index($g) != null' <<<"$validGroups" >/dev/null; then
              echo "vayume-config: '$group' isn't a known/available group. Options:" >&2
              jq -r '.[]' <<<"$validGroups" | while IFS= read -r n; do echo "  $n" >&2; done
              exit 2
            fi

            if [ "$enabled" = "true" ]; then
              newList=$(jq --arg g "$group" '. + [$g] | unique' <<<"$current")
            else
              newList=$(jq --arg g "$group" 'map(select(. != $g))' <<<"$current")
            fi
            nixValue="[ $(jq -r 'map("\"" + . + "\"") | join(" ")' <<<"$newList") ]"

            tmp="$config_file.vayume-config.tmp"
            if ! USERS_AWK_VALUE="$nixValue" awk -v user="$user" -v fieldName=extraGroups -f ${usersAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" --arg group "$group" --argjson enabled "$enabled" \
                '{ok: true, user: $user, group: $group, enabled: $enabled}'
            else
              exit 1
            fi
          }

          # Every path search returns, and every path this accepts, is a
          # dotted chain of plain identifiers (attr.paths.like.this) -
          # rejecting anything else before it ever reaches a `pkgs.$path`
          # interpolation below is what makes that interpolation safe
          # without its own escaping: there's nothing in the accepted
          # charset an attribute-selector expression can misuse.
          validate_package_path() {
            case "$1" in
              [a-zA-Z_]*)
                case "$1" in
                  *[!a-zA-Z0-9_.-]*) return 1 ;;
                  *) return 0 ;;
                esac
                ;;
              *) return 1 ;;
            esac
          }

          # Same live-validation-before-write discipline as
          # cmd_users_set_group's group list, against the exact nixpkgs
          # this flake is pinned to (not whatever channel/registry the
          # machine happens to have) - a typo'd or nonexistent path is
          # rejected here, never silently written and left to fail at the
          # next rebuild instead.
          cmd_users_set_package() {
            local user path enabled since exists current merged nixValue tmp
            user=''${1:?user required}
            path=''${2:?package attribute path required}
            enabled=''${3:?true or false required}
            since=""
            if [ "''${4:-}" = "--if-unmodified-since" ]; then
              since=''${5:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            case "$enabled" in true|false) ;; *) echo "vayume-config: value must be true or false" >&2; exit 2;; esac
            check_since "$since"

            if ! validate_package_path "$path"; then
              echo "vayume-config: invalid package attribute path '$path'" >&2
              exit 2
            fi

            exists=$(nix eval --impure --raw --expr \
              "let pkgs = (builtins.getFlake \"path:$flake_dir\").inputs.nixpkgs.legacyPackages.\"${pkgs.stdenv.hostPlatform.system}\"; v = pkgs.$path or null; in if v != null && (v.type or \"\") == \"derivation\" then \"true\" else \"false\"" 2>/dev/null || echo false)
            if [ "$exists" != "true" ]; then
              echo "vayume-config: '$path' isn't a package in this flake's nixpkgs" >&2
              exit 2
            fi

            current=$(nix eval --impure --json --expr \
              "(builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.users.\"$(nix_escape "$user")\".packages")
            merged=$(jq --arg k "$path" --argjson v "$enabled" '. + {($k): $v}' <<<"$current")

            nixValue="{ "
            while IFS=$'\t' read -r k v; do
              nixValue+="\"$(nix_escape "$k")\" = $v; "
            done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' <<<"$merged")
            nixValue+="}"

            tmp="$config_file.vayume-config.tmp"
            if ! USERS_AWK_VALUE="$nixValue" awk -v user="$user" -v fieldName=packages -f ${usersAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" --arg path "$path" --argjson enabled "$enabled" \
                '{ok: true, user: $user, path: $path, enabled: $enabled}'
            else
              exit 1
            fi
          }

          # Searches the exact nixpkgs this flake is pinned to (its
          # already-fetched store path, not a separately-resolved
          # `nixpkgs` flake registry entry that could be a different
          # revision) so a result this returns is guaranteed to be
          # addable - nothing found here could fail
          # cmd_users_set_package's own existence check right after.
          # `nix search` builds and caches a name/description index the
          # first time it runs against a given nixpkgs revision - that
          # first search can take a while over the whole of nixpkgs,
          # every one after is fast.
          cmd_packages_search() {
            local query nixpkgsPath results
            query=''${1:?search query required}
            nixpkgsPath=$(nix eval --impure --raw --expr \
              "(builtins.getFlake \"path:$flake_dir\").inputs.nixpkgs.outPath")
            results=$(nix search --json "path:$nixpkgsPath" "$query" 2>/dev/null || echo '{}')
            jq '[
              to_entries[]
              | {
                  path: (.key | sub("^legacyPackages\\.[^.]+\\."; "")),
                  pname: .value.pname,
                  version: .value.version,
                  description: (.value.description // "")
                }
            ] | sort_by(.path) | .[0:50]' <<<"$results"
          }

          # Reads the new password from stdin, never argv - argv is
          # visible to every other process on the machine via /proc
          # (ps, etc.), stdin isn't. The DMS plugin writes it over a
          # Quickshell Process's own stdin pipe the same way; a person
          # at a terminal just pipes or types it in.
          cmd_users_set_password() {
            local user since newPassword hash nixValue tmp
            user=''${1:?user required}
            since=""
            if [ "''${2:-}" = "--if-unmodified-since" ]; then
              since=''${3:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            check_since "$since"

            IFS= read -r newPassword || { echo "vayume-config: no password read from stdin" >&2; exit 2; }
            [ -n "$newPassword" ] || { echo "vayume-config: password can't be empty" >&2; exit 2; }

            hash=$(printf '%s' "$newPassword" | mkpasswd -m sha-512 -s)
            unset newPassword
            nixValue="\"$(nix_escape "$hash")\""
            unset hash

            tmp="$config_file.vayume-config.tmp"
            if ! USERS_AWK_VALUE="$nixValue" awk -v user="$user" -v fieldName=hashedPassword -f ${usersAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" '{ok: true, user: $user}'
            else
              exit 1
            fi
          }

          # New user gets nothing but fullName - extraGroups/hashedPassword
          # are left unset so userSubmodule's own defaults apply
          # (networkmanager/video/input, "changeme" initial password),
          # same as _config.nix.example's "random" entry.
          cmd_users_add() {
            local user fullName since exists nixValue tmp
            user=''${1:?user required}
            fullName=''${2:-}
            since=""
            if [ "''${3:-}" = "--if-unmodified-since" ]; then
              since=''${4:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            check_since "$since"

            exists=$(nix eval --impure --raw --expr \
              "if builtins.hasAttr \"$(nix_escape "$user")\" (builtins.getFlake \"path:$flake_dir\").nixosConfigurations.${hostName}.config.vayume.users then \"true\" else \"false\"")
            if [ "$exists" = "true" ]; then
              echo "vayume-config: user '$user' already exists" >&2
              exit 2
            fi

            # Multi-line on purpose, matching every hand-written entry in
            # _config.nix.example - a one-line `{ fullName = "..."; }`
            # here would open and close its own braces on the single line
            # usersRemoveAwk expects to find just the user's opening line
            # on, throwing off its brace-depth tracking and eating the
            # next real line (vayume.users's own closing brace) along
            # with it on a later removal.
            printf -v nixValue '{\n      fullName = "%s";\n    }' "$(nix_escape "''${fullName:-$user}")"

            tmp="$config_file.vayume-config.tmp"
            if ! USERS_AWK_VALUE="$nixValue" awk -v user="$user" -f ${usersAddAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" '{ok: true, user: $user}'
            else
              exit 1
            fi
          }

          # Only edits _config.nix - doesn't touch the running system.
          # NixOS's own declarative user management (mutableUsers = false)
          # is what actually deletes the Linux account, and only on the
          # next rebuild; this command alone never removes a home
          # directory or logs anyone out.
          cmd_users_remove() {
            local user since tmp
            user=''${1:?user required}
            since=""
            if [ "''${2:-}" = "--if-unmodified-since" ]; then
              since=''${3:?epoch required after --if-unmodified-since}
            fi
            validate_username "$user"
            check_since "$since"

            tmp="$config_file.vayume-config.tmp"
            if ! awk -v user="$user" -f ${usersRemoveAwk} "$config_file" > "$tmp"; then
              rm -f "$tmp"
              exit 1
            fi

            if apply_edit "$tmp"; then
              jq -n --arg user "$user" '{ok: true, user: $user}'
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
            development)
              shift
              case "''${1:-}" in
                list) cmd_development_list;;
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
            users)
              shift
              case "''${1:-}" in
                list) cmd_users_list;;
                add) shift; cmd_users_add "$@";;
                remove) shift; cmd_users_remove "$@";;
                set-name) shift; cmd_users_set_name "$@";;
                set-secret) shift; cmd_users_set_secret "$@";;
                set-group) shift; cmd_users_set_group "$@";;
                set-package) shift; cmd_users_set_package "$@";;
                set-password) shift; cmd_users_set_password "$@";;
                *) usage;;
              esac
              ;;
            packages)
              shift
              case "''${1:-}" in
                search) shift; cmd_packages_search "$@";;
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
