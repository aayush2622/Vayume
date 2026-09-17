{
  flake.appDescriptions.DevTools = "GitHub CLI, lazygit, docker-compose, and the Claude Code CLI.";

  flake.homeModules.apps.DevTools = { pkgs, ... }: {
    home.packages = with pkgs; [
      gh
      lazygit
      docker-compose
      claude-code
    ];
  };
}
