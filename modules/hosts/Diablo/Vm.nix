{ self, ... }:
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

      nix.gc.automatic = lib.mkForce false;

      services.displayManager.sddm.settings.General.GreeterEnvironment = lib.mkForce
        "XCURSOR_THEME=${config.vayori.theme.cursorTheme},XCURSOR_SIZE=${toString config.vayori.theme.cursorSize},XCURSOR_PATH=${config.vayori.theme.cursorPackage}/share/icons,QT_QUICK_BACKEND=software";

      virtualisation = {
        memorySize = 6144;
        cores = 4;
        diskSize = 16384;
        qemu.package = qemuWithHostGL;
        qemu.options = [
          "-display" "gtk,gl=on"
          "-device" "virtio-vga-gl"
        ];
      };
    };
  };

  perSystem =
    { pkgs, lib, ... }:
    let
      vm = self.nixosConfigurations.Diablo.config.system.build.vm;
      diskSize = self.nixosConfigurations.Diablo.config.virtualisation.vmVariant.virtualisation.diskSize;
    in
    {
      apps.vm = {
        type = "app";
        program = lib.getExe (pkgs.writeShellScriptBin "vayori-vm" ''
          set -eu

          IMG="''${VAYORI_VM_IMAGE:-''${XDG_CACHE_HOME:-$HOME/.cache}/vayori/Diablo.qcow2}"
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$IMG")"

          if [ "''${1:-}" = "--fresh" ] || [ "''${1:-}" = "-f" ]; then
            echo "Discarding $IMG for a clean boot."
            ${pkgs.coreutils}/bin/rm -f "$IMG"
            shift
          fi

          if [ -f "$IMG" ]; then
            have=$(${pkgs.qemu}/bin/qemu-img info --output=json "$IMG" 2>/dev/null \
              | ${pkgs.jq}/bin/jq -r '."virtual-size" // 0')
            want=$(( ${toString diskSize} * 1024 * 1024 ))
            if [ "''${have:-0}" -lt "$want" ]; then
              echo "Existing image is $(( have / 1024 / 1024 ))M but diskSize is now ${toString diskSize}M."
              echo "Recreating it - the runner never resizes an image it did not just create."
              ${pkgs.coreutils}/bin/rm -f "$IMG"
            fi
          fi

          echo "Disk image: $IMG"
          exec ${pkgs.coreutils}/bin/env NIX_DISK_IMAGE="$IMG" ${vm}/bin/run-Diablo-vm "$@"
        '');
      };
    };

}
