{ self, inputs, ... }:
let
  requireLocalFile = path: name:
    if builtins.pathExists path
    then path
    else throw ''
      modules/hosts/Diablo/${name} is missing.

      It's gitignored on purpose (real machine-specific data) and required -
      copy the template and fill it in:

        cp modules/hosts/Diablo/${name}.example modules/hosts/Diablo/${name}

      See docs/core-hardware.md or docs/core-users.md for what belongs
      in it.
    '';
in {
  flake.nixosConfigurations.Diablo = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = [
      inputs.home-manager.nixosModules.home-manager

      self.nixosModules.VayoriUsers
      self.nixosModules.Niri
      self.nixosModules.Hyprland
      self.nixosModules.Dms
      self.nixosModules.Fonts
      self.nixosModules.Portals
      self.nixosModules.SddmTheme
      self.nixosModules.GrubTheme
      self.nixosModules.DevTooling
      self.nixosModules.Zram
      self.nixosModules.Network
      self.nixosModules.Waydroid
      self.nixosModules.VmTesting
      self.nixosModules.PluginUpdateCheck

      (requireLocalFile ./_hardware.nix "_hardware.nix")
      (requireLocalFile ./_user.nix "_user.nix")

      ({ pkgs, lib, config, ... }:
      let
        cursorEnvVars = {
          XCURSOR_THEME = config.vayori.theme.cursorTheme;
          XCURSOR_SIZE = toString config.vayori.theme.cursorSize;
          XCURSOR_PATH = "${config.vayori.theme.cursorPackage}/share/icons";
        };
      in
      {
        options.vayori.theme = lib.mkOption {
          description = "System-wide look & feel - one place to set the font, cursor theme, and icon theme, used everywhere they're needed.";
          default = { };
          type = lib.types.submodule {
            options = {
              font = lib.mkOption {
                type = lib.types.str;
                default = "JetBrainsMono Nerd Font";
                description = "UI/monospace font family, used by fontconfig, GTK, kitty, and DMS.";
              };
              fontPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.nerd-fonts.jetbrains-mono;
                description = "Package providing `font`.";
              };
              fontSize = lib.mkOption {
                type = lib.types.int;
                default = 11;
              };

              cursorTheme = lib.mkOption {
                type = lib.types.str;
                default = "Bibata-Modern-Ice";
                description = "Xcursor theme name, used by GTK, SDDM, and XCURSOR_THEME.";
              };
              cursorPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.bibata-cursors;
                description = "Package providing `cursorTheme`.";
              };
              cursorSize = lib.mkOption {
                type = lib.types.int;
                default = 24;
              };

              iconTheme = lib.mkOption {
                type = lib.types.str;
                default = "Adwaita";
                description = "GTK icon theme name.";
              };
              iconPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.adwaita-icon-theme;
                description = "Package providing `iconTheme`.";
              };
            };
          };
        };

        config = {
          # One line per app under modules/apps/ - type `vayori.apps.` in an
          # editor with Nix LSP support and every available app shows up by
          # name. `false` entries are kept, not deleted, so it's visible at
          # a glance which apps exist but are off, not just missing.
          vayori.apps = {
            # development
            Vscode.enable = true;
            AndroidStudio.enable = true;
            Zed.enable = true;
            DevTools.enable = true;
            FreeClaudeCode.enable = false;

            Cpp.enable = true;
            Rust.enable = false;
            Kotlin.enable = true;
            Flutter.enable = false;
            Nix.enable = true;
            Qt.enable = true;
            Python.enable = true;

            # gaming
            Gaming.enable = true;

            # utils
            Terminal.enable = true;
            Nautilus.enable = false;
            Thunar.enable = true;
            ZenBrowser.enable = true;
            Vesktop.enable = true;
            Spicetify.enable = true;
            Bitwarden.enable = true;
            StateBackup.enable = true;
            Distrobox.enable = true;
          };

          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];

          nix.settings.auto-optimise-store = true;
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 30d";
          };
          documentation.nixos.enable = false;

          boot.loader = {
            efi.canTouchEfiVariables = true;
            systemd-boot.enable = false;
            grub = {
              enable = true;
              efiSupport = true;
              device = "nodev";
              useOSProber = true;
            };
          };

          networking.hostName = "Diablo";
          networking.networkmanager.enable = true;

          # DNS resolver, the Tor toggle behind the control-center
          # widget, and the network-stack hardening sysctls. See
          # docs/system-network.md.
          vayori.network = {
            dns = {
              provider = "cloudflare";
              overTls = "opportunistic";
              ipv6 = true;
            };

            tor = {
              enable = true;
              includeContainers = true;
            };

            hardening.enable = true;

            # Breaks MAC-authenticated networks and captive portals that
            # remember you - off unless you actually want that trade.
            randomizeMac = false;
          };

          time.timeZone = "Asia/Kolkata";
          i18n.defaultLocale = "en_IN";
          i18n.extraLocaleSettings = {
            LC_ADDRESS = "en_IN";
            LC_IDENTIFICATION = "en_IN";
            LC_MEASUREMENT = "en_IN";
            LC_MONETARY = "en_IN";
            LC_NAME = "en_IN";
            LC_NUMERIC = "en_IN";
            LC_PAPER = "en_IN";
            LC_TELEPHONE = "en_IN";
            LC_TIME = "en_IN";
          };

          services.xserver.xkb = {
            layout = "us";
            variant = "";
          };

          hardware.bluetooth.enable = true;
          services.upower.enable = true;

          services.printing.enable = true;

          programs.gamemode.enable = true;
          programs.steam.enable = true;
          programs.nix-ld.enable = true;

          programs.appimage = {
            enable = true;
            binfmt = true;
          };

          boot.kernelModules = [ "ntsync" ];
          services.udev.extraRules = ''
            KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
          '';

          boot.kernel.sysctl = {
            "kernel.sched_cfs_bandwidth_slice_us" = 3000;
            "net.ipv4.tcp_fin_timeout" = 5;
            "kernel.split_lock_mitigate" = 0;
            "vm.max_map_count" = 2147483642;
          };

          services.pulseaudio.enable = false;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };

          services.udisks2.enable = true;
          programs.dconf.enable = true;
          services.gvfs.enable = true;
          services.tumbler.enable = true;

          environment.systemPackages = with pkgs; [
            gsettings-desktop-schemas
            vim
            wget
            curl
            git
            unzip
            zip
            htop
            btop
            ripgrep
            fd
            fzf
            tree
            killall
            gnumake
            nixfmt
            nil
            cliphist
            wl-clipboard
            grim
            slurp
            hyprshot
            hyprpicker
            playerctl
            brightnessctl
            pavucontrol
            adwaita-icon-theme
            config.vayori.theme.cursorPackage
          ];
          environment.sessionVariables = {
            inherit (cursorEnvVars) XCURSOR_THEME XCURSOR_SIZE;

            GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
          };

          services.displayManager.sddm.settings.Theme = {
            CursorTheme = config.vayori.theme.cursorTheme;
            CursorSize = config.vayori.theme.cursorSize;
          };

          services.displayManager.sddm.settings.General.GreeterEnvironment =
            "XCURSOR_THEME=${cursorEnvVars.XCURSOR_THEME},XCURSOR_SIZE=${cursorEnvVars.XCURSOR_SIZE},XCURSOR_PATH=${cursorEnvVars.XCURSOR_PATH}";

          systemd.services.display-manager.environment = cursorEnvVars;

          system.stateVersion = "25.11";
        };
      })
    ];
  };
}
