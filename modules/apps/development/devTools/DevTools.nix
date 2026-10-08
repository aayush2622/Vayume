{
  flake.appMeta.DevTools = {
    description = "GitHub CLI, lazygit, docker-compose, and the Claude Code CLI.";
    label = "Developer tools";
    icon = "github-desktop";
    symbol = "build";
    section = "Tools";
  };

  flake.homeModules.apps.DevTools =
    { pkgs, lib, ... }:
    let
      # release manifest kept in this repo, not nixpkgs' pin - see docs/apps-dev-devtools.md
      claude-code = pkgs.claude-code.override {
        manifest = lib.importJSON ./claude-code-manifest.json;
      };
    in
    {
      home.packages = with pkgs; [
        gh
        lazygit
        docker-compose
        claude-code
      ];
    };
}
