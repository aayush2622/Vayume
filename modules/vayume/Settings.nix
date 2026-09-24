{ self, lib, ... }:
{
  flake.vayumeLib.labels = lib.mapAttrs (_: label: { inherit label; });

  flake.nixosModules.Settings =
    { ... }:
    {
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
              hidden = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Leave this option out of the settings list.";
              };
            };
          }
        );
      };

      config.vayume.settingsMeta =
        self.vayumeLib.labels {
          "network.dns.provider" = "DNS provider";
          "network.dns.overTls" = "DNS over TLS";
          "network.dns.ipv6" = "IPv6 DNS servers";
          "network.hardening.enable" = "Network hardening";
          "network.randomizeMac" = "Randomize Wi-Fi MAC";
          "network.tor.enable" = "Route everything through Tor";
          "network.tor.includeContainers" = "Include containers in Tor";
          "performance.enable" = "System tuning";
          "performance.gaming" = "Gaming tuning";
          "performance.kernel" = "Kernel";
        }
        //
          lib.mapAttrs'
            (
              name: label:
              lib.nameValuePair "ubuntuBox.${name}" {
                inherit label;
                group = "Distrobox";
              }
            )
            {
              count = "Number of boxes";
              name = "Box name";
              image = "Container image";
              isolateHome = "Isolated home";
              homeDir = "Home directory";
              unshare = "Unshared namespaces";
              fuse = "FUSE access";
              shmSize = "Shared memory size";
              aptPackages = "apt packages";
              x11Apps = "X11 apps";
              exportApps = "Exported apps";
            };
    };
}
