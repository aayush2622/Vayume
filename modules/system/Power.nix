{ self, ... }:
{
  flake.nixosModules.Power =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.vayume.power;
    in
    {
      options.vayume.power = {
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
        services.logind.settings.Login = {
          HandlePowerKey = cfg.powerButton;
          HandleLidSwitch = cfg.lidClose;
          HandleLidSwitchExternalPower = cfg.lidClose;
          HandleLidSwitchDocked = "ignore";
        };

        vayume.settingsGroups."Screen & sleep" = {
          order = 1;
          icon = "bedtime";
          description = "When the screen locks, turns off, and the system goes to sleep on idle.";
          page = "power";
        };

        vayume.settingsGroups."Power buttons" = {
          order = 2;
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
            "power.idleLock" = e "Screen & sleep" "Lock screen after idle" "lock_clock" 1;
            "power.idleScreenOff" = e "Screen & sleep" "Screen off after idle" "tv_off" 2;
            "power.idleSuspend" = e "Screen & sleep" "Sleep after idle" "bedtime" 3;
            "power.powerButton" = e "Power buttons" "Power button" "power_settings_new" 1;
            "power.lidClose" = e "Power buttons" "Lid close" "laptop" 2;
          };
      };
    };
}
