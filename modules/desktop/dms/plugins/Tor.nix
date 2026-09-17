# Registers the DMS control-center widget for the Tor toggle. The Tor
# service itself, its iptables rules, and the `vayume-tor` CLI the widget
# shells out to by bare name (relying on PATH) all still live in
# modules/system/network/Network.nix - that's a networking concern, not a
# DMS one, and the widget has no Nix-level reference to it, just a runtime
# PATH dependency, so there's nothing to share across the two files.
{
  flake.nixosModules.DmsPluginTor = { lib, config, ... }:
    lib.mkIf config.vayume.network.tor.enable {
      home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
        # DMS only loads a plugin whose id has `enabled: true` in
        # plugin_settings.json, generated solely from
        # `programs.dank-material-shell.plugins` - dropping the widget's
        # files alone leaves it on disk but never loaded.
        programs.dank-material-shell.plugins.tor = {
          enable = true;
          src = ./tor;
        };
      });
    };
}
