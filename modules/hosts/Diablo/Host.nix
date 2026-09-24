{ self, inputs, ... }:
let
  hostName = baseNameOf ./.;
  requireLocalFile =
    path: name:
    if builtins.pathExists path then
      path
    else
      throw ''
        modules/hosts/${hostName}/${name} is missing.

        It's gitignored on purpose (real machine-specific data) and required -
        copy the template and fill it in:

          cp modules/hosts/${hostName}/${name}.example modules/hosts/${hostName}/${name}

        See docs/core-hardware.md or docs/core-users.md for what belongs
        in it.
      '';
in
{
  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = [
      inputs.home-manager.nixosModules.home-manager

      self.nixosModules.Users
      self.nixosModules.Theme
      self.nixosModules.Config
      self.nixosModules.Commands
      self.nixosModules.DefaultApps
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
      (requireLocalFile ./_config.nix "_config.nix")

      (
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          cursorEnvVars = {
            XCURSOR_THEME = config.vayume.theme.cursorTheme;
            XCURSOR_SIZE = toString config.vayume.theme.cursorSize;
            XCURSOR_PATH = "${config.vayume.theme.cursorPackage}/share/icons";
          };
        in
        {
          config = {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
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

            networking.hostName = hostName;
            networking.networkmanager.enable = true;

            vayume.network = {
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

            hardware.bluetooth = {
              enable = true;
              powerOnBoot = true;
              settings = {
                General = {
                  Experimental = "330859bc-7506-492d-9370-9a6f0614037f";
                  FastConnectable = true;
                  JustWorksRepairing = "always";
                  MultiProfile = "multiple";
                };
              };
            };
            services.upower.enable = true;

            services.printing.enable = true;

            programs.gamemode.enable = config.vayume.apps.Gaming.enable;
            programs.steam.enable = config.vayume.apps.Gaming.enable;
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
              wireplumber.extraConfig."51-bluez" = {
                "monitor.bluez.properties" = {

                  "bluez5.autoswitch-profile" = false;
                  "bluez5.enable-sbc-xq" = true;
                  "bluez5.enable-msbc" = true;
                  "bluez5.enable-hw-volume" = true;
                  "bluez5.codecs" = [
                    "ldac"
                    "aptx_hd"
                    "aptx"
                    "aac"
                    "sbc_xq"
                    "sbc"
                  ];
                };
                "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = false;
                "monitor.bluez.rules" = [
                  {
                    matches = [ { "node.name" = "~bluez_output.*"; } ];
                    actions.update-props."session.suspend-timeout-seconds" = 2;
                  }
                ];
              };
            };

            services.udisks2.enable = true;
            programs.dconf.enable = true;
            services.gvfs.enable = true;
            services.tumbler.enable = true;

            services.gnome.gnome-keyring.enable = true;
            security.pam.services.sddm.enableGnomeKeyring = true;
            security.pam.services.login.enableGnomeKeyring = true;
            security.pam.services.dankshell.enableGnomeKeyring = true;

            security.sudo.extraConfig = ''
              Defaults timestamp_type=global
              Defaults timestamp_timeout=15
            '';
            environment.systemPackages = with pkgs; [
              gsettings-desktop-schemas

              # CLI
              vim
              wget
              curl
              git
              file
              which
              jq
              ripgrep
              fd
              fzf
              tree
              htop
              btop
              lsof
              killall
              procps
              psmisc

              # Archives
              unzip
              zip

              # Build / Nix
              gnumake
              nixfmt
              nil

              # Hardware
              pciutils
              usbutils

              # Disk / Filesystems
              btrfs-progs
              dosfstools
              gptfdisk
              parted
              smartmontools

              # Wayland
              cliphist
              wl-clipboard
              grim
              slurp
              hyprshot
              hyprpicker

              # Desktop
              playerctl
              brightnessctl
              pavucontrol
              adwaita-icon-theme

              config.vayume.theme.cursorPackage
            ];
            environment.sessionVariables = {
              inherit (cursorEnvVars) XCURSOR_THEME XCURSOR_SIZE;

              GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
            };

            services.displayManager.sddm.settings.Theme = {
              CursorTheme = config.vayume.theme.cursorTheme;
              CursorSize = config.vayume.theme.cursorSize;
            };

            services.displayManager.sddm.settings.General.GreeterEnvironment =
              "XCURSOR_THEME=${cursorEnvVars.XCURSOR_THEME},XCURSOR_SIZE=${cursorEnvVars.XCURSOR_SIZE},XCURSOR_PATH=${cursorEnvVars.XCURSOR_PATH}";

            systemd.services.display-manager.environment = cursorEnvVars;

            system.stateVersion = "25.11";
          };
        }
      )
    ];
  };
}
