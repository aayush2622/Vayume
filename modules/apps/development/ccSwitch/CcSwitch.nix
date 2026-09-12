{
  flake.homeModules.apps.CcSwitch = { pkgs, ... }: {
    home.packages = [ pkgs.cc-switch ];
  };
}
