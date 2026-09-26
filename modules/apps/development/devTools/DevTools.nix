{
  flake.appMeta.DevTools = {
    description = "GitHub CLI, lazygit, docker-compose, and the Claude Code CLI.";
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
