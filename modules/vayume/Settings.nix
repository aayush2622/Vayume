{ self, lib, ... }:
{
  flake.vayumeLib.labels = lib.mapAttrs (_: label: { inherit label; });

  flake.nixosModules.Settings =
    { options, config, ... }:
    {
      config.environment.etc."vayume/settings.json".text = builtins.toJSON (
        import ./_settings.nix { inherit lib options config; }
      );

      options.vayume.settingsMeta = lib.mkOption {
        default = { };
        description = ''
          Optional presentation overrides for the generic settings list in
          Vayume Settings, keyed by option path below `vayume.` (for example
          `"network.tor.enable"`). Every `vayume.*` option shows up there
          without an entry; add one only to change the label, move it to
          another group, or hide it. See docs/core-settings.md.
        '';
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              label = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Name shown instead of the one derived from the option path.";
              };
              group = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Group (card title) shown instead of the first path segment.";
              };
              icon = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Material Symbols icon name shown beside the setting.";
              };
              app = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Name of a vayume.apps.<Name> module. The setting is then shown under that app in Applications instead of on the All Settings page.";
              };
              order = lib.mkOption {
                type = lib.types.int;
                default = 100;
                description = "Position inside its group; lower comes first, ties keep the option path order.";
              };
              hidden = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Leave this option out of the settings list.";
              };
            };
          }
        );
      };

      options.vayume.settingsGroups = lib.mkOption {
        default = { };
        description = ''
          Optional icon and one-line description for a group (card) in the
          settings list, keyed by the group's displayed name. See
          docs/core-settings.md.
        '';
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              icon = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Material Symbols icon name shown in the group's title.";
              };
              description = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "One line under the group's title.";
              };
              order = lib.mkOption {
                type = lib.types.int;
                default = 100;
                description = "Position of the card on its page; lower comes first, ties sort by name.";
              };
              page = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Vayume Settings page the group is shown on (`appearance`, `pet`, `network`, `performance`, `storage`, `updates`, ...). An unknown or unset page puts it under Updates > Other settings.";
              };
            };
          }
        );
      };

      config.vayume.settingsGroups = {
        DNS = {
          order = 1;
          icon = "dns";
          description = "Which resolver the whole machine asks, and how.";
          page = "network";
        };
        Tor = {
          order = 2;
          icon = "vpn_lock";
          description = "Send all traffic through the Tor network.";
          page = "network";
        };
        Privacy = {
          order = 3;
          icon = "shield";
          description = "Harden the network stack and hide the Wi-Fi hardware address.";
          page = "network";
        };
        Kernel = {
          order = 1;
          icon = "memory";
          description = "Which Linux kernel the system boots.";
          page = "performance";
        };
        Tuning = {
          order = 2;
          icon = "speed";
          description = "Memory, disk and scheduler tuning, plus extras for games.";
          page = "performance";
        };
        "Build output" = {
          order = 1;
          icon = "cleaning_services";
          description = "Where the cleanup looks for build folders it may delete (node_modules, target, .venv...).";
          page = "storage";
        };
      };

      config.vayume.settingsMeta =
        let
          entry = group: label: icon: order: {
            inherit
              group
              label
              icon
              order
              ;
          };
          box = label: icon: {
            inherit label icon;
            app = "Distrobox";
          };
        in
        {
          "network.dns.provider" = entry "DNS" "DNS provider" "dns" 1;
          "network.dns.overTls" = entry "DNS" "DNS over TLS" "lock" 2;
          "network.dns.ipv6" = entry "DNS" "IPv6 DNS servers" "language" 3;
          "network.hardening.enable" = entry "Privacy" "Network hardening" "shield" 1;
          "network.randomizeMac" = entry "Privacy" "Randomize Wi-Fi MAC" "shuffle" 2;
          "network.tor.enable" = entry "Tor" "Route everything through Tor" "vpn_lock" 1;
          "network.tor.includeContainers" = entry "Tor" "Include containers in Tor" "deployed_code" 2;
          "storage.projectDirs" = entry "Build output" "Project folders" "folder_open" 1;
          "performance.enable" = entry "Tuning" "System tuning" "speed" 1;
          "performance.gaming" = entry "Tuning" "Gaming tuning" "sports_esports" 2;
          "performance.kernel" = entry "Kernel" "Kernel" "memory" 1;
          "ubuntuBox.count" = box "Number of boxes" "numbers";
          "ubuntuBox.name" = box "Box name" "badge";
          "ubuntuBox.image" = box "Container image" "image";
          "ubuntuBox.isolateHome" = box "Isolated home" "home";
          "ubuntuBox.homeDir" = box "Home directory" "folder";
          "ubuntuBox.unshare" = box "Unshared namespaces" "lock_open";
          "ubuntuBox.fuse" = box "FUSE access" "usb";
          "ubuntuBox.shmSize" = box "Shared memory size" "memory_alt";
          "ubuntuBox.aptPackages" = box "apt packages" "inventory_2";
          "ubuntuBox.x11Apps" = box "X11 apps" "desktop_windows";
          "ubuntuBox.exportApps" = box "Exported apps" "ios_share";
        };
    };
}
