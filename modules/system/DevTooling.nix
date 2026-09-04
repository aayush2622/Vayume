{
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
}
