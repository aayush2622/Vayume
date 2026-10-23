{ self, ... }:
{
  flake.nixosModules.Power =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.vayume.power;
      lidSleep = if cfg.lidClose == "hibernate" then "hibernate" else "suspend";
      resuspend = pkgs.writeShellScript "vayume-lid-resuspend" ''
        grep=${pkgs.gnugrep}/bin/grep
        $grep -q closed /proc/acpi/button/lid/*/state || exit 0
        for status in /sys/class/drm/*/status; do
          case "$status" in
            *eDP* | *LVDS* | *DSI*) continue ;;
          esac
          if $grep -q '^connected' "$status"; then exit 0; fi
        done
        exec ${pkgs.systemd}/bin/systemctl ${lidSleep}
      '';
    in
    {
      options.vayume.power = {
        usbWakeup = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Let USB devices, such as a mouse or an external keyboard, wake the laptop from sleep. Off by default, so a mouse that is clicked or knocked while the lid is closed cannot wake it inside a bag and drain the battery.";
        };

        ultraSaver = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Ultra power saver: turns off animations, blur, shadows, rounded corners, window transparency, the desktop pet, desktop widgets, the audio visualizer, weather and matugen re-theming, and runs the shell at low priority, so apps get everything. The power profile is left alone. Takes effect immediately from Vayume Settings.";
        };

        idleLock = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 600;
          description = "Seconds of idle before the screen locks. 0 to disable automatic locking.";
        };

        idleScreenOff = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 660;
          description = "Seconds of idle before the screen turns off. 0 to disable. Set higher than idleLock.";
        };

        idleSuspend = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 0;
          description = "Seconds of idle before the system suspends. 0 to disable.";
        };

        powerButton = lib.mkOption {
          type = lib.types.enum [
            "suspend"
            "hibernate"
            "poweroff"
            "lock"
            "ignore"
          ];
          default = "suspend";
          description = "What happens when the power button is pressed.";
        };

        lidClose = lib.mkOption {
          type = lib.types.enum [
            "suspend"
            "hibernate"
            "lock"
            "ignore"
          ];
          default = "suspend";
          description = "What happens when the laptop lid is closed.";
        };
      };

      config = {
        services.udev.extraRules = lib.mkIf (!cfg.usbWakeup) ''
          ACTION=="add|change", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
        '';

        powerManagement.resumeCommands =
          lib.mkIf
            (builtins.elem cfg.lidClose [
              "suspend"
              "hibernate"
            ])
            "${pkgs.systemd}/bin/systemd-run --no-block --collect --unit=vayume-lid-resuspend --on-active=6 ${resuspend}";

        services.logind.settings.Login = {
          HandlePowerKey = cfg.powerButton;
          HandleLidSwitch = cfg.lidClose;
          HandleLidSwitchExternalPower = cfg.lidClose;
          HandleLidSwitchDocked = "ignore";
          LidSwitchIgnoreInhibited = "yes";
        };

        vayume.settingsGroups."Ultra power saver" = {
          order = 1;
          icon = "battery_saver";
          description = "Strips the eye candy so the apps get all the power.";
          page = "power";
        };

        vayume.settingsGroups."Screen & sleep" = {
          order = 2;
          icon = "bedtime";
          description = "When the screen locks, turns off, and the system goes to sleep on idle.";
          page = "power";
        };

        vayume.settingsGroups."Power buttons" = {
          order = 3;
          icon = "power_settings_new";
          description = "What pressing the power button or closing the laptop lid does.";
          page = "power";
        };

        vayume.settingsMeta =
          let
            e = group: label: icon: order: {
              inherit
                group
                label
                icon
                order
                ;
            };
          in
          {
            "power.ultraSaver" = e "Ultra power saver" "Ultra power saver" "battery_saver" 1;
            "power.idleLock" = e "Screen & sleep" "Lock screen after idle" "lock_clock" 1;
            "power.idleScreenOff" = e "Screen & sleep" "Screen off after idle" "tv_off" 2;
            "power.idleSuspend" = e "Screen & sleep" "Sleep after idle" "bedtime" 3;
            "power.powerButton" = e "Power buttons" "Power button" "power_settings_new" 1;
            "power.lidClose" = e "Power buttons" "Lid close" "laptop" 2;
            "power.usbWakeup" = e "Power buttons" "USB devices wake the laptop" "mouse" 3;
          };
      };
    };
}
