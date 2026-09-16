{ self, ... }: {
  flake.nixosModules.DmsRebuild =
    { pkgs, lib, config, ... }:
    let
      repoDiscovery = self.vayumeLib.repoDiscovery;

      vayumeHomeByUser = lib.concatMapStringsSep "\n" (
        name: ''"${name}") echo "${config.users.users.${name}.home}" ;;''
      ) (builtins.attrNames config.vayume.users);

      vayumeRebuildScript = pkgs.writeShellScript "vayume-rebuild" ''
        homeDir="$(case "''${SUDO_USER:-$USER}" in
        ${vayumeHomeByUser}
          *) echo "$HOME" ;;
        esac)"
        flakeDir=""
        for d in ${lib.concatStringsSep " " (
          map (d: ''"$homeDir/${d}"'') repoDiscovery.relativeDirs
          ++ map (d: ''"${d}"'') repoDiscovery.absoluteDirs
        )}; do
          [ -f "$d/flake.nix" ] && flakeDir="$d" && break
        done
        if [ -z "$flakeDir" ]; then
          echo "vayume flake not found (checked $homeDir/{${lib.concatStringsSep "," repoDiscovery.relativeDirs}}, ${lib.concatStringsSep ", " repoDiscovery.absoluteDirs}) - edit rebuildCommand in Rebuild.nix if it lives elsewhere"
          exit 1
        fi
        ${pkgs.git}/bin/git config --global --add safe.directory "$flakeDir"
        exec nixos-rebuild switch --flake "path:$flakeDir#${config.networking.hostName}"
      '';

      vayumeGcScript = pkgs.writeShellScript "vayume-gc" "exec nix-collect-garbage -d";

      vayumeRebuildCommand = pkgs.writeShellApplication {
        name = "vayume-rebuild";
        text = ''exec sudo -n ${vayumeRebuildScript} "$@"'';
      };

      vayumeGcCommand = pkgs.writeShellApplication {
        name = "vayume-gc";
        text = ''exec sudo -n ${vayumeGcScript} "$@"'';
      };
    in
    {
      security.sudo.extraRules =
        map
          (name: {
            users = [ name ];
            commands = [
              {
                command = "${vayumeRebuildScript}";
                options = [ "NOPASSWD" ];
              }
              {
                command = "${vayumeGcScript}";
                options = [ "NOPASSWD" ];
              }
            ];
          })
          (
            builtins.filter (name: builtins.elem "wheel" config.vayume.users.${name}.extraGroups) (
              builtins.attrNames config.vayume.users
            )
          );

      home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (_: {
        home.packages = [
          vayumeRebuildCommand
          vayumeGcCommand
        ];
      });
    };
}
