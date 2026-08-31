{ self, inputs, ... }: {
  flake.nixosModules.VayoriUsers = { config, lib, pkgs, ... }:
  let
    defaultUserSecrets = {
      WAKATIME_API_KEY = "REPLACE_ME";
      RBW_EMAIL = "REPLACE_ME";
      PROVIDERS = {
        NVIDIA_NIM_API_KEY = "REPLACE_ME";
      };
    };

    cfg = config.vayori.users;

    availableApps = builtins.attrNames self.homeModules.apps;

    userSubmodule = lib.types.submodule ({ name, ... }: {
      options = {
        fullName = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Display name (GECOS).";
        };

        hashedPassword = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Hashed password (mkpasswd -m sha-512). Set this from
            _user.nix (a gitignored file that lives next to Host.nix,
            never committed - see docs/core.md), not a tracked Nix file,
            so the repo has zero personal data in it and stays safe to
            publish. Leave unset to fall back to initialPassword
            "changeme" (run `passwd` after first login).
          '';
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "networkmanager" "video" "input" ];
          description = "Add \"wheel\" here for sudo access, \"adbusers\" for Android debugging, etc.";
        };

        secrets = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Seeds this user's ~/.config/vayori/session/secrets.json the
            first time their home-manager activation runs (see
            seedVayoriSecrets below). Left-out keys - or the whole
            attrset - fall back to "REPLACE_ME" placeholders instead.
            Same trust model as the file it seeds: plain values, no
            encryption layer, fine given _user.nix is already gitignored
            and root/owner-only on disk.
          '';
        };

        avatar = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Optional path to a .face avatar image (Noctalia profile card + qylock).";
        };

        shell = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zsh;
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Any one-off packages just for this user, e.g. `[ pkgs.blender ]`.";
        };
      };
    });
  in {
    options.vayori.users = lib.mkOption {
      type = lib.types.attrsOf userSubmodule;
      default = { };
      description = ''
        One entry per person using this machine. Set from
        modules/hosts/<name>/_user.nix (see docs/core.md) - a gitignored
        file, required, not a Nix-declared block here, so the repo has
        zero personal data in it and stays safe to publish. Fine to set
        directly in a tracked host file instead if you'd rather commit
        real users to git - not recommended for a public repo.
      '';
    };

    options.vayori.apps = lib.mkOption {
      type = lib.types.listOf (lib.types.enum availableApps);
      default = [ ];
      description = "Which optional app modules (from modules/apps/) EVERYONE on this machine gets. Options: ${lib.concatStringsSep ", " availableApps}";
    };

    config = lib.mkIf (cfg != { }) {
      users.mutableUsers = false;

      users.users = lib.mapAttrs (name: u: {
        isNormalUser = true;
        description = u.fullName;
        extraGroups = u.extraGroups;
        shell = u.shell;
      } // (if u.hashedPassword != null
            then { hashedPassword = u.hashedPassword; }
            else { initialPassword = "changeme"; }
          )) cfg;

      programs.zsh.enable = true;

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs self; vayoriTheme = config.vayori.theme; vayoriApps = config.vayori.apps; };
      home-manager.backupFileExtension = "backup";

      home-manager.users = lib.mapAttrs (name: u: { lib, pkgs, ... }: let
        userSecrets = if u.secrets != { } then u.secrets else defaultUserSecrets;
        secretsSeed = pkgs.writeText "vayori-secrets-seed.json" (builtins.toJSON userSecrets);
      in {
        imports = [
          self.homeModules.Baseline
        ] ++ (map (app: self.homeModules.apps.${app}) config.vayori.apps);

        home.stateVersion = config.system.stateVersion;
        home.packages = u.extraPackages;
        home.file = lib.mkIf (u.avatar != null) {
          ".face".source = u.avatar;
        };

        home.activation.seedVayoriSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          SECRETS_FILE="$HOME/.config/vayori/session/secrets.json"
          if [ ! -f "$SECRETS_FILE" ]; then
            run mkdir -p "$(dirname "$SECRETS_FILE")"
            run cp ${secretsSeed} "$SECRETS_FILE"
            run chmod 600 "$SECRETS_FILE"
          fi
        '';
      }) cfg;

      systemd.services = lib.mapAttrs' (name: u: lib.nameValuePair "home-manager-${name}" {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig.TimeoutStartSec = lib.mkForce "180sec";
      }) cfg;
    };
  };
}
