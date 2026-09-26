{
  flake.nixosModules.GrubTheme =
    { pkgs, lib, ... }:
    {
      boot.loader.grub = {
        theme = import ./_grubTheme.nix {
          inherit pkgs;
          wallpaper = ../assets/wallpapers/blue-girl-among-flowers.jpg;
        };
        splashImage = null;
        gfxmodeEfi = "auto";
        gfxmodeBios = lib.mkForce "1920x1080,auto";
      };
    };
}
