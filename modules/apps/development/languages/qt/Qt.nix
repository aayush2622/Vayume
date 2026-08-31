{ ... }: {
  flake.devLanguages.Qt = {
    vscode = {
      marketplaceExtensions = [
        { publisher = "theqtcompany"; name = "qt-core"; }
        { publisher = "theqtcompany"; name = "qt-qml"; }
      ];
      settings = {
        "qt-qml.qmlls.useQmlImportPathEnvVar" = true;
        "qt-core.additionalQtPaths" = [
          { name = "Qt-5.15.18-linux-g++_from_PATH"; path = "/usr/bin/qmake"; }
        ];
      };
    };
    zed = {
      extensions = [ "qml" ];
    };
  };

  flake.homeModules.apps.Qt = { pkgs, ... }: {
    home.packages = with pkgs; [ kdePackages.qtdeclarative ];
  };
}
