{ ... }: {
  flake.devLanguages.Python = {
    vscode = {
      nixpkgsExtensions = [
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-python.debugpy"
        "ms-python.vscode-python-envs"
      ];
      marketplaceExtensions = [
        { publisher = "kevinrose"; name = "vsc-python-indent"; }
        { publisher = "njqdev"; name = "vscode-python-typehint"; }
      ];
    };
    androidStudio = {
      autoPlugins = [
        { dirName = "python-ce"; id = "PythonCore"; }
      ];
    };
    zed = {
      tasks = [
        {
          label = "Python: Run current file";
          command = ''python3 "$ZED_FILE"'';
          cwd = "$ZED_DIRNAME";
          tags = [ "run" ];
        }
      ];
    };
  };

  flake.homeModules.apps.Python = { pkgs, ... }: {
    home.packages = with pkgs; [ python3 ];
  };
}
