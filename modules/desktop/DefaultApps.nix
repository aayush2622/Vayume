{ self, lib, ... }:
let
  roles = lib.filterAttrs (_: action: action ? label) self.vayumeLib.desktopActions;
  pickable = role: builtins.filter (c: c.app != null) roles.${role}.choices;
in
{
  flake.nixosModules.DefaultApps =
    { config, ... }:
    let
      appEnabled = app: config.vayume.apps.${app}.enable or false;

      resolved = lib.mapAttrs (
        role: action:
        let
          choices = map (c: {
            inherit (c) id label app desktop;
            enabled = appEnabled c.app;
          }) (pickable role);
          chosen = config.vayume.defaultApps.${role};
          automatic = lib.findFirst (c: c.enabled) null choices;
          effective =
            if chosen != null then lib.findFirst (c: c.id == chosen) null choices else automatic;
        in
        {
          inherit (action) label mimeTypes;
          inherit chosen choices;
          automatic = automatic.id or null;
          effective = effective.id or null;
          desktop = effective.desktop or null;
          effectiveEnabled = effective.enabled or false;
        }
      ) roles;

      mimeDefaults = lib.foldl' (
        acc: r:
        acc // lib.optionalAttrs (r.desktop != null) (lib.genAttrs r.mimeTypes (_: r.desktop))
      ) { } (builtins.attrValues resolved);
    in
    {
      options.vayume.defaultApps = lib.mapAttrs (
        role: action:
        lib.mkOption {
          type = lib.types.nullOr (lib.types.enum (map (c: c.id) (pickable role)));
          default = null;
          example = (builtins.head (pickable role)).id;
          description = ''
            ${action.label} to use for its keybind and as the default
            for its file types: one of ${lib.concatMapStringsSep ", " (c: "\"${c.id}\" (vayume.apps.${c.app})") (pickable role)}.
            null picks the first of those that's enabled.
          '';
        }
      ) roles;

      options.vayume.defaultAppsResolved = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        readOnly = true;
        description = "What each vayume.defaultApps role resolves to - read by vayume config and Vayume Settings.";
      };

      config = {
        vayume.defaultAppsResolved = resolved;

        assertions = lib.mapAttrsToList (role: r: {
          assertion = r.chosen == null || r.effectiveEnabled;
          message =
            let
              app = (lib.findFirst (c: c.id == r.chosen) { app = "?"; } r.choices).app;
            in
            "vayume.defaultApps.${role} = \"${toString r.chosen}\" needs vayume.apps.${app}.enable = true (or set it back to null).";
        }) resolved;

        environment.etc."vayume/default-apps".text = lib.concatStrings (
          lib.mapAttrsToList (role: r: lib.optionalString (r.effective != null) "${role}=${r.effective}\n") resolved
        );

        home-manager.sharedModules = [
          {
            xdg.mimeApps = {
              enable = true;
              defaultApplications = mimeDefaults;
            };
          }
        ];
      };
    };
}
