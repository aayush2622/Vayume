{ ... }: {
  flake.devLanguages.Qt = {
    vscode = {
      marketplaceExtensions = [
        { publisher = "theqtcompany"; name = "qt-core"; }
        { publisher = "theqtcompany"; name = "qt-qml"; }
      ];
      settings = pkgs: {
        "qt-qml.qmlls.useQmlImportPathEnvVar" = true;
        "qt-qml.qmlls.customExePath" = "${pkgs.kdePackages.qtdeclarative}/bin/qmlls";
        "qt-qml.doNotAskForQmllsDownload" = true;
        "qt-core.additionalQtPaths" = [
          {
            name = "Qt-${pkgs.kdePackages.qtbase.version}-nixpkgs";
            path = "${pkgs.kdePackages.qtbase}/bin/qmake6";
          }
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
