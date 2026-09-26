{ lib, ... }:
{
  options.vayume.desktop.barStyle = lib.mkOption {
    type = lib.types.enum [
      "classic"
      "m3"
    ];
    default = "classic";
    description = ''
      Look of the DMS top bar. `classic` is a thin transparent strip inside
      the screen frame; `m3` drops the frame and floats each widget as its
      own rounded Material 3 pill off the screen edge. Takes effect on the
      next rebuild.
    '';
  };

  config.vayume.settingsGroups.Desktop = {
    icon = "desktop_windows";
    description = "How the shell itself looks.";
  };

  config.vayume.settingsMeta."desktop.barStyle" = {
    label = "Bar style";
    icon = "toolbar";
  };
}
