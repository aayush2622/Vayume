{ self, inputs, ... }: {
  flake.homeModules.apps.Terminal = { pkgs, lib, config, vayoriTheme, ... }:
  let
    theme = vayoriTheme;

    fastfetchImageExts = [ "png" "jpg" "jpeg" "webp" "icon" ];
    fastfetchImageFiles = builtins.filter
      (f: lib.any (ext: lib.hasSuffix ".${ext}" (lib.toLower f)) fastfetchImageExts)
      (builtins.attrNames (builtins.readDir ./images));
    fastfetchImagePaths = map (f: "${./images}/${f}") fastfetchImageFiles;

    zshPlugins = [
      { name = "zsh-autosuggestions"; src = inputs.zsh-autosuggestions; }
      { name = "zsh-256color"; src = inputs.zsh-256color; }
      { name = "you-should-use"; src = inputs.zsh-you-should-use; }
      { name = "zsh-syntax-highlighting"; src = inputs.zsh-syntax-highlighting; }
    ];

    starshipSettings = {
      add_newline = false;
      format = "$username$directory$git_branch$git_status$cmd_duration$character";

      username = {
        style_user = "bold blue";
        format = "[$user]($style) ";
        show_always = true;
      };

      directory = {
        style = "bold cyan";
        truncation_length = 3;
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "bold purple";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "bold yellow";
      };

      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
        style = "bold yellow";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };

    fastfetchModules = [
      { type = "custom"; format = "╭──────────────────────────────────────────╮"; }
      { type = "chassis"; key = " 󰇺 Chassis"; format = "{1} {2} {3}"; keyColor = "cyan"; }
      { type = "os"; key = " 󰣇 OS"; format = "{2}"; keyColor = "red"; }
      { type = "kernel"; key = " 󰒓 Kernel"; format = "{2}"; keyColor = "red"; }
      { type = "packages"; key = " 󰏗 Packages"; keyColor = "green"; }
      { type = "display"; key = " 󰍹 Display"; format = "{1}x{2} @ {3}Hz [{7}]"; keyColor = "green"; }
      { type = "terminal"; key = " 󰆍 Terminal"; keyColor = "yellow"; }
      { type = "wm"; key = " 󱗃 WM"; format = "{2}"; keyColor = "yellow"; }
      { type = "custom"; format = "╰──────────────────────────────────────────╯"; }
      "break"
      { type = "title"; key = " 󰀄"; format = "{6} {7} {8}"; keyColor = "cyan"; }
      { type = "custom"; format = "╭──────────────────────────────────────────╮"; }
      { type = "cpu"; key = " 󰍛 CPU"; format = "{1} @ {7}"; keyColor = "blue"; }
      { type = "gpu"; key = " 󰊴 GPU"; format = "{1} {2}"; keyColor = "blue"; }
      { type = "gpu"; key = " 󰘚 Driver"; format = "{3}"; keyColor = "magenta"; }
      { type = "memory"; key = " 󰍛 Memory"; keyColor = "magenta"; }
      { type = "disk"; key = " 󱦟 OS Age"; folders = "/"; format = "{days} days"; keyColor = "red"; }
      { type = "uptime"; key = " 󱫐 Uptime"; keyColor = "yellow"; }
      { type = "custom"; format = "╰──────────────────────────────────────────╯"; }
      { type = "colors"; paddingLeft = 2; symbol = "circle"; }
      "break"
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

        tab_bar_min_tabs = 1;
        tab_bar_edge = "bottom";
        tab_bar_style = "separator";
        tab_separator = " | ";
        tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
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

    vayori.matugenTemplates = {
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

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = starshipSettings;
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;

      plugins = zshPlugins;

      oh-my-zsh = {
        enable = true;

        plugins = [
          "sudo"
          "git"
          "colorize"
        ];
      };

      initContent = ''
        # ─────────────────────────────────────────────
        # Plugin update check
        # ─────────────────────────────────────────────

        vayori_check_plugin_updates_preexec() {
          case "$1" in
            *nixos-rebuild*|*"home-manager switch"*|*"nix build"*|*"nix flake"*|*"nix run"*)
              timeout 10s vayori-check-plugin-updates
              ;;
          esac
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook preexec vayori_check_plugin_updates_preexec

        # ─────────────────────────────────────────────
        # Fastfetch
        # ─────────────────────────────────────────────

        # Image list is computed once at build time (see fastfetchImagePaths) -
        # no filesystem walk on every new shell, just an array pick.
        FASTFETCH_IMAGES=(${lib.concatStringsSep " " (map (p: "'${p}'") fastfetchImagePaths)})
        FASTFETCH_IMAGE=""
        if [ ''${#FASTFETCH_IMAGES[@]} -gt 0 ]; then
          FASTFETCH_IMAGE="''${FASTFETCH_IMAGES[$RANDOM % ''${#FASTFETCH_IMAGES[@]}]}"
        fi
        if [ -n "$FASTFETCH_IMAGE" ]; then
          fastfetch \
            --logo-type kitty \
            --logo "$FASTFETCH_IMAGE" \
            --logo-width 32 \
            --logo-height 16
        else
          fastfetch
        fi
      '';
    };
    programs.fastfetch = {
      enable = true;

      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

        display.separator = " 󰁔 ";

        modules = fastfetchModules;
      };
    };
  };
}
