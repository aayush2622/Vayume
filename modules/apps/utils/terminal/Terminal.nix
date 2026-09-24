{ self, ... }: {
  flake.appDescriptions.Terminal = "kitty terminal, zsh, starship prompt, and fastfetch on launch.";

  flake.homeModules.apps.Terminal =
    {
      pkgs,
      lib,
      config,
      vayumeTheme,
      ...
    }:
    let
      theme = vayumeTheme;

      fastfetchImageExts = [
        "png"
        "jpg"
        "jpeg"
        "webp"
        "icon"
      ];
      fastfetchImageFiles = builtins.filter (
        f: lib.any (ext: lib.hasSuffix ".${ext}" (lib.toLower f)) fastfetchImageExts
      ) (builtins.attrNames (builtins.readDir ./images));
      fastfetchImagePaths = map (f: "${./images}/${f}") fastfetchImageFiles;

      starshipSettings = {
        add_newline = false;
        command_timeout = 300;
        scan_timeout = 30;
        format = "$username$directory$git_branch$git_status$nix_shell$cmd_duration$character";

        username = {
          style_user = "bold blue";
          format = "[$user]($style) ";
          show_always = true;
        };

        directory = {
          style = "bold cyan";
          truncation_length = 3;
          truncation_symbol = "…/";
          read_only = " 󰌾";
          read_only_style = "red";
        };

        git_branch = {
          format = "[ $branch]($style) ";
          style = "bold purple";
        };

        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
          style = "bold yellow";
        };

        nix_shell = {
          format = "[󱄅 $state]($style) ";
          style = "bold blue";
          impure_msg = "shell";
          pure_msg = "pure";
        };

        cmd_duration = {
          min_time = 2000;
          format = "[󰔛 $duration]($style) ";
          style = "bold yellow";
        };

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
        };
      };

      fastfetchRule = kind: {
        type = "custom";
        format =
          if kind == "top" then
            "╭${lib.concatStrings (lib.replicate 64 "─")}╮"
          else
            "╰${lib.concatStrings (lib.replicate 64 "─")}╯";
      };

      keyed = color: attrs: attrs // { keyColor = color; };

      fastfetchModules = [
        { type = "title"; }
        {
          type = "separator";
          string = "─";
        }
        (fastfetchRule "top")
        (keyed "red" {
          type = "os";
          format = "{3} {12}";
        })
        (keyed "cyan" {
          type = "host";
          format = "{5} {1}";
        })
        (keyed "red" { type = "kernel"; })
        (keyed "yellow" { type = "uptime"; })
        (keyed "yellow" { type = "shell"; })
        (keyed "yellow" {
          type = "terminal";
          format = "{5}";
        })
        (keyed "yellow" {
          type = "command";
          key = "WM";
          keyIcon = "󱗃";
          text = "echo \"\${XDG_SESSION_DESKTOP:-$XDG_CURRENT_DESKTOP}\"";
        })
        (keyed "green" {
          type = "display";
          key = "Display";
          format = "{1}x{2} @ {3}Hz";
        })
        (fastfetchRule "bottom")
        (fastfetchRule "top")
        (keyed "blue" { type = "cpu"; })
        (keyed "blue" {
          type = "gpu";
          format = "{1} {2} ({3})";
        })
        (keyed "magenta" { type = "memory"; })
        (keyed "magenta" { type = "swap"; })
        (keyed "red" {
          type = "disk";
          key = "Disk";
          folders = "/";
        })
        (keyed "green" {
          type = "battery";
          key = "Battery";
        })
        (fastfetchRule "bottom")
        {
          type = "colors";
          paddingLeft = 2;
          symbol = "circle";
        }
      ];
    in
    {
      programs.kitty = {
        enable = true;

        font = {
          name = theme.font;
          size = theme.fontSize;
        };

        settings = {
          confirm_os_window_close = 0;
          window_padding_width = 10;
          hide_window_decorations = "yes";
          cursor_trail = 1;

          background_opacity = "0.65";
          dynamic_background_opacity = "yes";

          scrollback_lines = 20000;
          enable_audio_bell = "no";
          copy_on_select = "clipboard";
          strip_trailing_spaces = "smart";
          mouse_hide_wait = "2.0";
          url_style = "curly";
          disable_ligatures = "cursor";
          repaint_delay = 8;
          input_delay = 1;
          sync_to_monitor = "yes";
          allow_remote_control = "no";

          tab_bar_min_tabs = 2;
          tab_bar_edge = "bottom";
          tab_bar_style = "powerline";
          tab_powerline_style = "round";
          tab_title_template = "{index}: {title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
        };

        keybindings = {
          "ctrl+shift+enter" = "launch --cwd=current";
          "ctrl+shift+t" = "launch --cwd=current --type=tab";
        };

        extraConfig = ''
          include dank-tabs.conf
          include dank-theme.conf
        '';

        shellIntegration.enableZshIntegration = true;
      };

      programs.eza = {
        enable = true;
        enableZshIntegration = true;
        icons = "auto";
        git = true;
      };

      home.packages = [ pkgs.cava ];

      programs.btop = {
        enable = true;
        settings.color_theme = "matugen";
      };

      vayume.matugenTemplates = {
        btop = ''
          [templates.btop]
          input_path = '${config.home.homeDirectory}/.config/matugen/templates/btop-matugen.theme'
          output_path = '${config.home.homeDirectory}/.config/btop/themes/matugen.theme'
          post_hook = 'pkill -USR2 btop || true'
        '';

        cava = ''
          [templates.cava]
          input_path = '${config.home.homeDirectory}/.config/matugen/templates/cava-colors.ini'
          output_path = '${config.home.homeDirectory}/.config/cava/config'
          post_hook = 'pkill -USR1 cava'
        '';
      };

      home.file = {
        ".config/matugen/templates/btop-matugen.theme".text = self.matugenTemplates.btop;
        ".config/matugen/templates/cava-colors.ini".text = self.matugenTemplates.cava;
      };

      home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
      home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = starshipSettings;
      };

      vayume.zsh = {
        enable = true;

        snippets.pluginUpdateCheck = {
          order = 1500;
          text = ''
            vayume_check_plugin_updates_preexec() {
              case "$1" in
                *nixos-rebuild*|*"home-manager switch"*|*"nix build"*|*"nix flake"*|*"nix run"*) ;;
                *) return 0 ;;
              esac
              local stamp="''${XDG_STATE_HOME:-$HOME/.local/state}/vayume/plugin-check"
              if [[ -f $stamp && -z "$(find "$stamp" -mmin +360 2>/dev/null)" ]]; then
                return 0
              fi
              mkdir -p "''${stamp:h}"
              : > "$stamp"
              timeout 10s vayume check-plugin-updates --report-only
              ( timeout 300s vayume check-plugin-updates --resolve-hashes >/dev/null 2>&1 & )
            }
            autoload -Uz add-zsh-hook
            add-zsh-hook preexec vayume_check_plugin_updates_preexec
          '';
        };

        snippets.greeting = {
          order = 2000;
          text = ''
            vayume_greet() {
              [[ -n $KITTY_WINDOW_ID && -t 1 ]] || return 0
              local id="$KITTY_PID-$KITTY_WINDOW_ID"
              [[ $VAYUME_GREETED == "$id" ]] && return 0
              export VAYUME_GREETED="$id"
              local images=(${lib.concatStringsSep " " (map (p: "'${p}'") fastfetchImagePaths)})
              if (( ''${#images[@]} > 0 )); then
                local img="''${images[$(( RANDOM % ''${#images[@]} + 1 ))]}"
                local cols=26 rows=13 w h
                if [[ "$(od -An -tx1 -N4 "$img" 2>/dev/null | tr -d ' ')" == 89504e47 ]]; then
                  read -r w h < <(od -An -tu4 --endian=big -j16 -N8 "$img")
                  if (( w > 0 && h > 0 )); then
                    rows=$(( (cols * h / w + 1) / 2 ))
                    (( rows < 6 )) && rows=6
                    (( rows > 18 )) && rows=18
                  fi
                fi
                fastfetch \
                  --logo-type kitty-direct \
                  --logo "$img" \
                  --logo-width "$cols" \
                  --logo-height "$rows"
              else
                fastfetch
              fi
            }
            vayume_greet
          '';
        };
      };

      programs.fastfetch = {
        enable = true;

        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

          logo.padding.right = 3;

          display = {
            separator = "  ";
            key = {
              type = "both";
              width = 13;
            };
            color = {
              keys = "blue";
              title = "cyan";
            };
          };

          modules = fastfetchModules;
        };
      };
    };
}
