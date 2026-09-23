{ self, pkgs, lib, config, ... }:
let
  repoDiscovery = self.vayumeLib.repoDiscovery;
  keepGenerations = 5;

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
      [ -f "$d/flake.nix" ] && flakeDir=$(cd -P "$d" && pwd) && break
    done
    if [ -z "$flakeDir" ]; then
      echo "vayume flake not found (checked $homeDir/{${lib.concatStringsSep "," repoDiscovery.relativeDirs}}, ${lib.concatStringsSep ", " repoDiscovery.absoluteDirs}) - add its location to repoDiscovery in modules/lib/VayumeLib.nix" >&2
      exit 1
    fi
    ${pkgs.git}/bin/git config --global --get-all safe.directory 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qxF "$flakeDir" \
      || ${pkgs.git}/bin/git config --global --add safe.directory "$flakeDir"
    exec nixos-rebuild switch --flake "path:$flakeDir#${config.networking.hostName}"
  '';

  vayumeGcScript = pkgs.writeShellScript "vayume-gc" ''
    set -eu
    nix-env -p /nix/var/nix/profiles/system --delete-generations +${toString keepGenerations}
    nix-collect-garbage
    exec /nix/var/nix/profiles/system/bin/switch-to-configuration boot
  '';

  vayumeRebuildCommand = pkgs.writeShellApplication {
    name = "vayume-rebuild";
    text = ''
      [ "$#" -eq 0 ] || { echo "usage: vayume rebuild (takes no arguments - runs a real nixos-rebuild switch)" >&2; exit 2; }
      exec sudo -n ${vayumeRebuildScript}
    '';
  };

  vayumeGcCommand = pkgs.writeShellApplication {
    name = "vayume-gc";
    text = ''
      [ "$#" -eq 0 ] || { echo "usage: vayume gc (takes no arguments - keeps the newest ${toString keepGenerations} system generations, deletes older ones, collects garbage)" >&2; exit 2; }
      exec sudo -n ${vayumeGcScript}
    '';
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

  vayume.commands = {
    rebuild = {
      command = lib.getExe vayumeRebuildCommand;
      description = "nixos-rebuild switch from wherever the repo lives (wheel users, no password)";
    };
    gc = {
      command = lib.getExe vayumeGcCommand;
      description = "Delete all but the newest ${toString keepGenerations} system generations and collect garbage";
      confirm = true;
    };
  };
}
