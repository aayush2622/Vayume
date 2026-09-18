{ inputs, ... }: {
  flake.nixosModules.Zram = { ... }: {
    zramSwap.enable = true;
  };

  flake.nixosModules.DevTooling = { lib, ... }: {
    virtualisation.docker.enable = true;
    virtualisation.libvirtd.enable = lib.mkDefault false;

    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
    };

    users.groups.adbusers = { };
  };

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
