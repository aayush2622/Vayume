{
  flake.nixosModules.VmTesting = { pkgs, lib, config, ... }:
  let
    qemuWithHostGL = pkgs.symlinkJoin {
      name = "qemu-host-gl";
      paths = [ pkgs.qemu_kvm ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/qemu-system-x86_64 \
          --set GBM_BACKENDS_PATH /usr/lib/gbm \
          --set LIBGL_DRIVERS_PATH /usr/lib/dri \
          --set __EGL_VENDOR_LIBRARY_DIRS /usr/share/glvnd/egl_vendor.d \
          --suffix LD_LIBRARY_PATH : /usr/lib:/usr/lib/dri:/usr/lib/gbm
      '';
    };
  in {
    virtualisation.vmVariant = {
      services.xserver.videoDrivers = lib.mkForce [ ];
      services.asusd.enable = lib.mkForce false;
      services.supergfxd.enable = lib.mkForce false;

      users.users.root.hashedPassword = lib.mkForce "";

      boot.resumeDevice = lib.mkVMOverride "";

      services.displayManager.sddm.settings.General.GreeterEnvironment = lib.mkForce
        "XCURSOR_THEME=${config.vayori.theme.cursorTheme},XCURSOR_SIZE=${toString config.vayori.theme.cursorSize},XCURSOR_PATH=${config.vayori.theme.cursorPackage}/share/icons,QT_QUICK_BACKEND=software";

      virtualisation = {
        memorySize = 6144;
        cores = 4;
        qemu.package = qemuWithHostGL;
        qemu.options = [
          "-display" "gtk,gl=on"
          "-device" "virtio-vga-gl"
        ];
      };
    };
  };
}
