{
  flake.nixosModules.Pet =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.vayume.desktop.pet;

      skinRev = "c1fb39b0239ebe5b74f6a645e2945a122b6ea7db";
      skinHashes = {
        classic = "0vg60x3nksicb09gmp2v5pzccz9h4893dpxqiaq24vzfp276iigl";
        dog = "1afljcvd4dv44apgpg7gr3k8h7yzvirdb6ykpga7wmypw030c6av";
        maia = "14gc6gh2ndjzl23jfdl37diqfl6bk7qns319pccxnjx83ar5rj1n";
        tora = "1z1czkb32plq3y7jlfrj4jyrdd4hvy390zbhvl59w3vsx29lx67p";
        vaporwave = "1mk9fnf1z4nvx1xzzs9cqz8m31h5afhwnfz7ka1629xfpvq9x56f";
      };
      skin = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kyrie25/Spicetify-Oneko/${skinRev}/assets/oneko/oneko-${cfg.skin}.gif";
        sha256 = skinHashes.${cfg.skin};
      };

      petConfig = pkgs.writeText "pet-config.json" (
        builtins.toJSON {
          inherit (cfg)
            size
            speed
            behaviour
            activity
            layer
            name
            bubbles
            monitor
            ;
        }
      );

      petShell =
        pkgs.runCommand "desktop-pet-shell"
          {
            nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.pillow ])) ];
          }
          ''
            mkdir -p $out
            cp ${./shell}/*.qml $out/
            python3 ${./trace.py} ${skin} ${if cfg.kuroneko then "1" else "0"} ${petConfig} $out
          '';
    in
    {
      options.vayume.desktop.pet = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Show a pixel pet on the desktop that naps, wanders and can be dragged around.";
        };
        skin = lib.mkOption {
          type = lib.types.enum (builtins.attrNames skinHashes);
          default = "classic";
          description = "Which oneko sprite sheet to use.";
        };
        kuroneko = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Invert the skin's colours, so the white cat becomes a black one.";
        };
        size = lib.mkOption {
          type = lib.types.ints.between 1 8;
          default = 3;
          description = "Pixel scale of the 32x32 sprite; 3 draws the pet 96 pixels tall.";
        };
        speed = lib.mkOption {
          type = lib.types.ints.between 2 40;
          default = 10;
          description = "Pixels the pet moves per step (ten steps a second) when walking or chasing.";
        };
        behaviour = lib.mkOption {
          type = lib.types.enum [
            "wander"
            "follow"
            "stay"
          ];
          default = "wander";
          description = "`wander` strolls around the screen on its own, `follow` chases the mouse pointer (Hyprland only; elsewhere it sits still), `stay` never walks off by itself.";
        };
        activity = lib.mkOption {
          type = lib.types.enum [
            "lazy"
            "normal"
            "playful"
          ];
          default = "normal";
          description = "How often the pet does something on its own and how long it naps.";
        };
        layer = lib.mkOption {
          type = lib.types.enum [
            "bottom"
            "top"
            "overlay"
          ];
          default = "top";
          description = "`bottom` keeps the pet on the desktop under windows, `top` shows it over windows but under fullscreen ones, `overlay` over everything.";
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Name shown in a tag above the pet while the pointer is over it. Empty shows no tag.";
        };
        bubbles = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Draw hearts when petted, z's while asleep and a ! when startled.";
        };
        monitor = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Output the pet lives on, such as eDP-1. Empty uses the first one.";
        };
      };

      config = lib.mkMerge [
        {
          vayume.settingsGroups."Desktop pet" = {
            icon = "pets";
            description = "A pixel cat (or dog) living on your screen.";
          };
          vayume.settingsMeta =
            lib.mapAttrs' (n: v: lib.nameValuePair "desktop.pet.${n}" (v // { group = "Desktop pet"; }))
              {
                enable = {
                  label = "Show the pet";
                  icon = "pets";
                };
                skin = {
                  label = "Skin";
                  icon = "palette";
                };
                kuroneko = {
                  label = "Kuroneko (inverted colours)";
                  icon = "invert_colors";
                };
                size = {
                  label = "Size";
                  icon = "zoom_in";
                };
                speed = {
                  label = "Speed";
                  icon = "speed";
                };
                behaviour = {
                  label = "Behaviour";
                  icon = "directions_walk";
                };
                activity = {
                  label = "Activity";
                  icon = "bolt";
                };
                layer = {
                  label = "Layer";
                  icon = "layers";
                };
                name = {
                  label = "Name";
                  icon = "badge";
                };
                bubbles = {
                  label = "Hearts and bubbles";
                  icon = "favorite";
                };
                monitor = {
                  label = "Monitor";
                  icon = "monitor";
                };
              };
        }

        (lib.mkIf cfg.enable {
          home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
            systemd.user.services.vayume-pet = {
              Unit = {
                Description = "Desktop pet";
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${pkgs.quickshell}/bin/qs -p ${petShell}";
                Restart = "on-failure";
                RestartSec = 2;
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
          });
        })
      ];
    };
}
