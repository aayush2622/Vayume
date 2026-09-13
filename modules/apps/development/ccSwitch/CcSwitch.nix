{
  flake.homeModules.apps.CcSwitch =
    { pkgs, lib, ... }:
    let
      # Only the plain UI/behavior toggles - not currentProviderClaude
      # (references a row in cc-switch's own SQLite providers table,
      # which this module deliberately doesn't touch - see the README)
      # and not localMigrations (the app's own one-time-migration
      # bookkeeping, timestamped and meaningless to pin).
      ccSwitchSettings = pkgs.writeText "cc-switch-settings.json" (
        builtins.toJSON {
          showInTray = true;
          minimizeToTrayOnClose = true;
          launchOnStartup = true;
          enableClaudePluginIntegration = true;

          # Matches Terminal.nix - the one terminal actually installed here.
          preferredTerminal = "kitty";
        }
      );
    in
    {
      home.packages = [ pkgs.cc-switch ];

      # Seeded once, like gtkBookmarks in Thunar.nix - NOT force-
      # reconciled on every switch the way thunar.xml is, because this
      # file is meant to stay freely user-editable through cc-switch's
      # own UI afterward, and it rewrites the whole file itself on
      # every change there. A read-only store symlink (plain home.file)
      # would make every one of those writes fail; re-copying on every
      # switch would stomp on anything changed since through the app.
      # Just gives a fresh profile the same sane starting point this
      # machine already has instead of cc-switch's stock defaults.
      home.activation.seedCcSwitchSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.cc-switch/settings.json"
        if [ ! -e "$dest" ]; then
          run mkdir -p "$(dirname "$dest")"
          run cp ${ccSwitchSettings} "$dest"
          run chmod u+w "$dest"
        fi
      '';
    };
}
