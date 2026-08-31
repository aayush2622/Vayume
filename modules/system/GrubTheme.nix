{ inputs, ... }: {
  flake.nixosModules.GrubTheme = { lib, ... }: {
    imports = [ inputs.elegant-grub2-themes.nixosModules.default ];

    boot.loader.elegant-grub2-theme = {
      enable = true;
      theme = "wave";
      type = "window";
      side = "left";
      color = "dark";
      screen = "1080p";
    };

    boot.loader.grub.gfxmodeBios = lib.mkForce "1920x1080,auto";
  };
}
