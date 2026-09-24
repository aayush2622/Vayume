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
            };
          }
        );
      };

      config.vayume.settingsGroups = {
        Network = {
          icon = "lan";
          description = "DNS, Tor and network-stack hardening for the whole machine.";
        };
        Performance = {
          icon = "speed";
          description = "Memory, disk, kernel and gaming tuning.";
        };
        Distrobox = {
          icon = "deployed_code";
          description = "The Ubuntu containers behind `vayume box`.";
        };
      };

      config.vayume.settingsMeta =
        let
          entry = label: icon: { inherit label icon; };
          box = label: icon: {
            inherit label icon;
            group = "Distrobox";
          };
        in
        {
          "network.dns.provider" = entry "DNS provider" "dns";
          "network.dns.overTls" = entry "DNS over TLS" "lock";
          "network.dns.ipv6" = entry "IPv6 DNS servers" "language";
          "network.hardening.enable" = entry "Network hardening" "shield";
          "network.randomizeMac" = entry "Randomize Wi-Fi MAC" "shuffle";
          "network.tor.enable" = entry "Route everything through Tor" "vpn_lock";
          "network.tor.includeContainers" = entry "Include containers in Tor" "deployed_code";
          "performance.enable" = entry "System tuning" "speed";
          "performance.gaming" = entry "Gaming tuning" "sports_esports";
          "performance.kernel" = entry "Kernel" "memory";
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
