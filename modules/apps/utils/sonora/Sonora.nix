{
  flake.appMeta.Sonora = {
    description = "Sonora, a native music client for Spotify, YouTube Music, Deezer, Subsonic and local files.";
    label = "Sonora";
    icon = "sonora";
    symbol = "library_music";
    section = "Music";
  };

  flake.homeModules.apps.Sonora =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      home.packages = [
        inputs.sonora.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
