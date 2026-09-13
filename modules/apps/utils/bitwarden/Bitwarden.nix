{
  flake.homeModules.apps.Bitwarden = { pkgs, lib, vayumeSecrets, ... }:
  let
    hasEmail = vayumeSecrets.RBW_EMAIL != "REPLACE_ME";
  in
  {
    # pinentry-gtk2 was removed from nixpkgs (deprecated GTK2 engine) -
    # pinentry-gnome3 is upstream's suggested replacement and fits this
    # GTK3/adw-gtk3 desktop better anyway.
    home.packages = [ pkgs.bitwarden-desktop pkgs.pinentry-gnome3 ];

    programs.rbw = {
      enable = true;
    };

    home.activation.rbwEmail = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString hasEmail ''
        CONFIG_FILE="$HOME/.config/rbw/config.json"
        EMAIL=${lib.escapeShellArg vayumeSecrets.RBW_EMAIL}

        run mkdir -p "$(dirname "$CONFIG_FILE")"

        if [ ! -f "$CONFIG_FILE" ]; then
          run sh -c "printf '{}' > '$CONFIG_FILE'"
        fi

        CONFIG_TMP="$(mktemp)"

        ${pkgs.jq}/bin/jq \
          --arg email "$EMAIL" \
          '.email = $email' \
          "$CONFIG_FILE" > "$CONFIG_TMP" \
          && run cp "$CONFIG_TMP" "$CONFIG_FILE"

        rm -f "$CONFIG_TMP"
      ''
    );
  };
}
