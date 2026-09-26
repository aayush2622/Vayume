{
  flake.appDescriptions.DevTools = "GitHub CLI, lazygit, docker-compose, and the Claude Code CLI.";
  flake.appMeta.DevTools = {
    label = "Developer tools";
    icon = "github-desktop";
    symbol = "build";
    section = "Tools";
  };

  flake.homeModules.apps.DevTools = { pkgs, ... }: {
    home.packages = with pkgs; [
      gh
      lazygit
      docker-compose
      claude-code
    ];
  };
}
