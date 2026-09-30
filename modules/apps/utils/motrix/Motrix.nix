{
  flake.appMeta.Motrix = {
    description = "Motrix, a full-featured download manager.";
    label = "Motrix";
    icon = "motrix";
    symbol = "download";
    section = "Internet";
  };

  flake.homeModules.apps.Motrix =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.motrix ];
    };
}
