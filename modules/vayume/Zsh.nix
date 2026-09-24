{
  self,
  inputs,
  lib,
  ...
}:
{
  flake.nixosModules.Zsh.config.home-manager.sharedModules = [ self.homeModules.Zsh ];

  flake.homeModules.Zsh =
    { config, ... }:
    let
      cfg = config.vayume.zsh;

      pluginText = p: ''
        ${p.init}
        ${lib.optionalString (p.completions != null) "fpath+=(${p.src}/${p.completions})"}
        source ${p.src}/${p.file}
        ${p.post}
      '';

      parts =
        lib.mapAttrsToList (_: p: {
          inherit (p) order;
          text = pluginText p;
        }) cfg.plugins
        ++ lib.mapAttrsToList (_: s: { inherit (s) order text; }) cfg.snippets;

      sorted = lib.sort (a: b: a.order < b.order) parts;

      highlight = cfg.plugins.zsh-syntax-highlighting or null;
    in
    {
      options.vayume.zsh = {
        enable = lib.mkEnableOption "the vayume zsh setup: cached completion, keybindings, and the ordered plugin list";

        plugins = lib.mkOption {
          default = { };
          description = ''
            zsh plugins, sourced from the Nix store in `order` (lowest
            first). Other modules add their own with
            `vayume.zsh.plugins.<name> = { src = ...; };` - see
            docs/core-zsh.md for the order ranges.
          '';
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  src = lib.mkOption {
                    type = lib.types.path;
                    description = "Directory the plugin is sourced from.";
                  };
                  file = lib.mkOption {
                    type = lib.types.str;
                    default = "${name}.plugin.zsh";
                    description = "File in `src` to source.";
                  };
                  order = lib.mkOption {
                    type = lib.types.int;
                    default = 500;
                    description = "Load position; lower loads first. 100-499 early, 500-899 normal, 1000 for zsh-syntax-highlighting, which must be last of the plugins.";
                  };
                  init = lib.mkOption {
                    type = lib.types.lines;
                    default = "";
                    description = "Shell run before the plugin is sourced - the place for its configuration variables.";
                  };
                  post = lib.mkOption {
                    type = lib.types.lines;
                    default = "";
                    description = "Shell run after the plugin is sourced - keybindings and settings that need its widgets to exist.";
                  };
                  completions = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Directory in `src` added to `fpath` for the plugin's completions.";
                  };
                };
              }
            )
          );
        };

        snippets = lib.mkOption {
          default = { };
          description = ''
            Shell fragments placed in the same ordered stream as the
            plugins. Use an order below 100 for core configuration, 900 to
            1500 for hooks that need the plugins loaded, and 2000 or more
            for things that should run last (a greeting).
          '';
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                order = lib.mkOption {
                  type = lib.types.int;
                  default = 1500;
                  description = "Position in the stream; lower runs first.";
                };
                text = lib.mkOption {
                  type = lib.types.lines;
                  description = "Shell code.";
                };
              };
            }
          );
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion =
              highlight == null || lib.all (p: p.order <= highlight.order) (lib.attrValues cfg.plugins);
            message = "vayume.zsh: zsh-syntax-highlighting must have the highest order of all plugins - it wraps the widgets that exist when it loads, so anything loaded after it is not highlighted.";
          }
        ];

        vayume.zsh.plugins = {
          zsh-256color = {
            src = lib.mkDefault inputs.zsh-256color;
            order = lib.mkDefault 100;
          };

          zsh-autosuggestions = {
            src = lib.mkDefault inputs.zsh-autosuggestions;
            order = lib.mkDefault 500;
            init = ''
              ZSH_AUTOSUGGEST_STRATEGY=(history completion)
              ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
              ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
              ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(forward-word)
            '';
            post = ''
              bindkey '^ ' autosuggest-accept
            '';
          };

          you-should-use = {
            src = lib.mkDefault inputs.zsh-you-should-use;
            order = lib.mkDefault 600;
            init = ''
              YSU_MESSAGE_POSITION="after"
              YSU_HARDCORE=0
            '';
          };

          zsh-syntax-highlighting = {
            src = lib.mkDefault inputs.zsh-syntax-highlighting;
            order = lib.mkDefault 1000;
            init = ''
              ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
              ZSH_HIGHLIGHT_MAXLENGTH=300
            '';
            post = ''
              ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
              ZSH_HIGHLIGHT_STYLES[path]='underline'
            '';
          };
        };

        vayume.zsh.snippets.core = {
          order = 50;
          text = ''
            setopt INTERACTIVE_COMMENTS COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU NO_BEEP NO_FLOW_CONTROL

            zstyle ':completion:*' menu select
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
            zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
            zstyle ':completion:*' group-name '''
            zstyle ':completion:*:descriptions' format '%F{blue}%d%f'
            zstyle ':completion:*' use-cache yes
            zstyle ':completion:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

            typeset -g -A key
            key[Home]="''${terminfo[khome]}"
            key[End]="''${terminfo[kend]}"
            key[Insert]="''${terminfo[kich1]}"
            key[Delete]="''${terminfo[kdch1]}"
            key[Up]="''${terminfo[kcuu1]}"
            key[Down]="''${terminfo[kcud1]}"
            key[Left]="''${terminfo[kcub1]}"
            key[Right]="''${terminfo[kcuf1]}"
            key[PageUp]="''${terminfo[kpp]}"
            key[PageDown]="''${terminfo[knp]}"
            key[ShiftTab]="''${terminfo[kcbt]}"

            autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
            zle -N up-line-or-beginning-search
            zle -N down-line-or-beginning-search

            [[ -n "''${key[Home]}" ]] && bindkey -- "''${key[Home]}" beginning-of-line
            [[ -n "''${key[End]}" ]] && bindkey -- "''${key[End]}" end-of-line
            [[ -n "''${key[Insert]}" ]] && bindkey -- "''${key[Insert]}" overwrite-mode
            [[ -n "''${key[Delete]}" ]] && bindkey -- "''${key[Delete]}" delete-char
            [[ -n "''${key[Up]}" ]] && bindkey -- "''${key[Up]}" up-line-or-beginning-search
            [[ -n "''${key[Down]}" ]] && bindkey -- "''${key[Down]}" down-line-or-beginning-search
            [[ -n "''${key[Left]}" ]] && bindkey -- "''${key[Left]}" backward-char
            [[ -n "''${key[Right]}" ]] && bindkey -- "''${key[Right]}" forward-char
            [[ -n "''${key[PageUp]}" ]] && bindkey -- "''${key[PageUp]}" beginning-of-buffer-or-history
            [[ -n "''${key[PageDown]}" ]] && bindkey -- "''${key[PageDown]}" end-of-buffer-or-history
            [[ -n "''${key[ShiftTab]}" ]] && bindkey -- "''${key[ShiftTab]}" reverse-menu-complete

            bindkey '^[[A' up-line-or-beginning-search
            bindkey '^[OA' up-line-or-beginning-search
            bindkey '^[[B' down-line-or-beginning-search
            bindkey '^[OB' down-line-or-beginning-search
            bindkey '^[[1;5C' forward-word
            bindkey '^[[1;5D' backward-word
            bindkey '^H' backward-kill-word
            bindkey '^[[3;5~' kill-word

            if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
              autoload -Uz add-zle-hook-widget
              vayume_application_mode_start() { echoti smkx }
              vayume_application_mode_stop() { echoti rmkx }
              add-zle-hook-widget -Uz zle-line-init vayume_application_mode_start
              add-zle-hook-widget -Uz zle-line-finish vayume_application_mode_stop
            fi
          '';
        };

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = false;
          syntaxHighlighting.enable = false;

          completionInit = ''
            autoload -Uz compinit
            () {
              setopt local_options extended_glob
              local dump="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
              mkdir -p "''${dump:h}"
              if [[ -n $dump(#qN.mh+24) ]]; then
                compinit -d "$dump"
              else
                compinit -C -d "$dump"
              fi
            }
          '';

          history = {
            size = 50000;
            save = 50000;
            ignoreAllDups = true;
            ignoreSpace = true;
            share = true;
            extended = true;
          };

          initContent = lib.mkOrder 900 (lib.concatMapStringsSep "\n" (x: x.text) sorted);
        };
      };
    };
}
