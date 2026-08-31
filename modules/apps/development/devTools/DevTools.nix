{
  flake.homeModules.apps.DevTools = { pkgs, ... }: {
    home.packages = with pkgs; [
      gh
      lazygit
      docker-compose
    ];
  };
}
