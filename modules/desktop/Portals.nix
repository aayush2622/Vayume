{
  flake.nixosModules.Portals = { pkgs, lib, ... }: {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];

      config = {
        common.default = [ "gtk" ];
        niri = {
          default = lib.mkForce [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
        hyprland = {
          default = lib.mkForce [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        };
      };
    };

    security.polkit.enable = true;
  };
}
