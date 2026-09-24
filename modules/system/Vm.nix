{ self, ... }:
{
  flake.nixosModules.VmTesting = { pkgs, lib, config, ... }:
  let
    qemuWithHostGL = pkgs.symlinkJoin {
      name = "qemu-host-gl";
      paths = [ pkgs.qemu_kvm ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/qemu-system-x86_64 --run '
          if [ ! -e /run/opengl-driver ] && [ -d /usr/lib/dri ]; then
            export GBM_BACKENDS_PATH=/usr/lib/gbm
            export LIBGL_DRIVERS_PATH=/usr/lib/dri
            export __EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d
            export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/lib:/usr/lib/dri:/usr/lib/gbm"
          fi'
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
        "XCURSOR_THEME=${config.vayume.theme.cursorTheme},XCURSOR_SIZE=${toString config.vayume.theme.cursorSize},XCURSOR_PATH=${config.vayume.theme.cursorPackage}/share/icons,QT_QUICK_BACKEND=software";

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
      mkVmApp = hostName:
        let
          host = self.nixosConfigurations.${hostName};
          vm = host.config.system.build.vm;
          diskSize = host.config.virtualisation.vmVariant.virtualisation.diskSize;
        in
        {
          type = "app";
          meta.description = "Boot ${hostName} in a throwaway QEMU VM (--fresh for a clean disk)";
          program = lib.getExe (pkgs.writeShellScriptBin "vayume-vm-${hostName}" ''
            set -eu

            IMG="''${VAYUME_VM_IMAGE:-''${XDG_CACHE_HOME:-$HOME/.cache}/vayume/${hostName}.qcow2}"
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
            exec ${pkgs.coreutils}/bin/env NIX_DISK_IMAGE="$IMG" ${vm}/bin/run-${host.config.system.name}-vm "$@"
          '');
        };
    in
    {
      apps =
        lib.mapAttrs' (name: _: lib.nameValuePair "vm-${name}" (mkVmApp name)) self.nixosConfigurations
        // lib.optionalAttrs (self.nixosConfigurations != { }) {
          vm = mkVmApp (builtins.head (builtins.attrNames self.nixosConfigurations));
        };
    };
}
