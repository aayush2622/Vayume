{ self, lib, ... }:
let
  commandsOption = lib.mkOption {
    default = { };
    description = ''
      Subcommands of the single `vayume` command - see
      docs/core-commands.md. A module registers one here instead of
      putting its own vayume-<name> binary on PATH.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path of the executable; arguments after the subcommand are passed through.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            description = "One line, shown in `vayume help`, the menu, and completion.";
          };
          usage = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Argument synopsis. Empty means the command takes no arguments, so the menu runs it straight away.";
          };
          confirm = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Ask before running it from the menu or the Vayume Settings panel (destructive or slow commands).";
          };
          panel = lib.mkOption {
            default = null;
            description = "Show the command as a button in Vayume Settings, on the page named by `page` (or under an app when `app` is set). Only for commands that need no typed arguments; `args` are passed as given.";
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  label = lib.mkOption {
                    type = lib.types.str;
                    description = "Button label.";
                  };
                  icon = lib.mkOption {
                    type = lib.types.str;
                    default = "play_arrow";
                    description = "Material Symbols icon name.";
                  };
                  args = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Arguments the button passes after the command name.";
                  };
                  app = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Name of a vayume.apps.<Name> module. The button is then shown under that app in Applications, and `page` is ignored.";
                  };
                  page = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Vayume Settings page the button goes on (`appearance`, `applications`, `network`, `performance`, `storage`, `updates`, ...). An unknown or unset page puts it under Updates > Other tools.";
                  };
                  group = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Card the button is grouped in on that page. Unset uses the page's own tools card.";
                  };
                };
              }
            );
          };
        };
      }
    );
  };
in
{
  flake.nixosModules.Commands = {
    options.vayume.commands = commandsOption;
    config.home-manager.sharedModules = [ self.homeModules.Commands ];
  };

  flake.homeModules.Commands =
    {
      pkgs,
      config,
      osConfig,
      ...
    }:
    let
      commands = (osConfig.vayume.commands or { }) // config.vayume.commands;
      names = lib.sort lib.lessThan (builtins.attrNames commands);

      prefixOf = name: builtins.head (lib.splitString "-" name);
      isGrouped =
        name:
        let
          prefix = prefixOf name;
        in
        prefix != name
        && (commands ? ${prefix} || builtins.length (builtins.filter (n: prefixOf n == prefix) names) > 1);
      display =
        name:
        if isGrouped name then "${prefixOf name} ${lib.removePrefix "${prefixOf name}-" name}" else name;

      table = lib.concatMapStrings (name: ''
        cmd[${lib.escapeShellArg name}]=${lib.escapeShellArg commands.${name}.command}
        shown[${lib.escapeShellArg name}]=${lib.escapeShellArg (display name)}
        usage[${lib.escapeShellArg name}]=${lib.escapeShellArg commands.${name}.usage}
        desc[${lib.escapeShellArg name}]=${lib.escapeShellArg commands.${name}.description}
        confirm[${lib.escapeShellArg name}]=${if commands.${name}.confirm then "1" else "0"}
      '') names;

      catalog = pkgs.writeText "vayume-commands.json" (
        builtins.toJSON (
          map (name: {
            inherit name;
            shown = display name;
            inherit (commands.${name})
              description
              usage
              confirm
              panel
              ;
          }) names
        )
      );

      completion = pkgs.writeTextDir "share/zsh/site-functions/_vayume" ''
        #compdef vayume
        local -a subcommands
        subcommands=(
        ${
          lib.concatMapStrings (
            name: "  ${lib.escapeShellArg "${name}:${commands.${name}.description}"}\n"
          ) names
        })
        if (( CURRENT == 2 )); then
          _describe 'vayume command' subcommands
        else
          _files
        fi
      '';

      dispatcher = pkgs.writeShellApplication {
        name = "vayume";
        runtimeInputs = [
          pkgs.fzf
          pkgs.coreutils
        ];
        text = ''
          declare -A cmd shown usage desc confirm
          ${table}
          names=(${lib.concatMapStringsSep " " lib.escapeShellArg names})

          list() {
            echo "usage: vayume [<command> [args...]]   (no arguments: pick from a menu)"
            echo
            for n in "''${names[@]}"; do
              printf '  %-24s %s\n' "''${shown[$n]}" "''${desc[$n]}"
              [ -z "''${usage[$n]}" ] || printf '  %-24s vayume %s %s\n' "" "''${shown[$n]}" "''${usage[$n]}"
            done
          }

          run() {
            local n=$1
            shift
            exec "''${cmd[$n]}" "$@"
          }

          menu() {
            local line n args reply
            local -a argv
            line=$(
              for n in "''${names[@]}"; do
                printf '%s\t%-22s %s\n' "$n" "''${shown[$n]}" "''${desc[$n]}"
              done | fzf --delimiter='\t' --with-nth=2 --prompt='vayume > ' \
                --height=~60% --layout=reverse --border=rounded \
                --header='Enter: run   Esc: quit'
            ) || exit 0
            n=''${line%%$'\t'*}
            args=""
            if [ -n "''${usage[$n]}" ]; then
              echo "vayume ''${shown[$n]} ''${usage[$n]}"
              read -e -r -p "vayume ''${shown[$n]} " args
            fi
            if [ "''${confirm[$n]}" = 1 ]; then
              read -r -p "Run 'vayume ''${shown[$n]} $args'? [y/N] " reply
              case "$reply" in y|Y) ;; *) echo "Aborted."; exit 1 ;; esac
            fi
            eval "argv=($args)"
            run "$n" "''${argv[@]}"
          }

          case "''${1:-}" in
            "")
              if [ -t 0 ] && [ -t 1 ]; then menu; else list; fi
              ;;
            -h|--help|help|list)
              list
              ;;
            --has)
              [ -n "''${cmd[''${2:-}]+x}" ]
              ;;
            --json)
              cat ${catalog}
              ;;
            *)
              if [ "$#" -ge 2 ] && [ -n "''${cmd[$1-$2]+x}" ]; then
                n="$1-$2"
                shift 2
              elif [ -n "''${cmd[$1]+x}" ]; then
                n=$1
                shift
              else
                echo "vayume: unknown command '$1'" >&2
                echo >&2
                list >&2
                exit 2
              fi
              run "$n" "$@"
              ;;
          esac
        '';
      };
    in
    {
      options.vayume.commands = commandsOption;
      config.home.packages = [
        dispatcher
        completion
      ];
    };
}
