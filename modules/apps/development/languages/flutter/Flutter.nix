{ ... }: {
  flake.devLanguages.Flutter = {
    vscode = {
      nixpkgsExtensions = [
        "dart-code.dart-code"
        "dart-code.flutter"
      ];
      settings = {
        "[dart]" = {
          "editor.formatOnSave" = true;
          "editor.formatOnType" = true;
          "editor.rulers" = [ 80 ];
          "editor.selectionHighlight" = false;
          "editor.tabCompletion" = "onlySnippets";
          "editor.wordBasedSuggestions" = "off";
        };
        "dart.lineLength" = 80;
        "dart.showTodos" = true;
        "dart.analysisServerFolding" = true;
        "dart.debugExternalPackageLibraries" = true;
        "dart.debugSdkLibraries" = true;
      };
    };
    androidStudio = {
      autoPlugins = [
        { dirName = "Dart"; id = "Dart"; }
        { dirName = "Flutter Enhancement Suite"; id = "de.mariushoefler.flutter_enhancement_suite"; }
        { dirName = "flutter-intellij"; id = "io.flutter"; }
        { dirName = "flutter-intl"; id = "com.localizely.flutter-intl"; }
      ];
    };
    zed = {
      extensions = [ "dart" "flutter-snippets" ];
      tasks = [
        {
          label = "Dart: Run current file";
          command = ''dart run "$ZED_FILE"'';
          cwd = "$ZED_DIRNAME";
          tags = [ "run" ];
        }
        {
          label = "Flutter: Run";
          command = "flutter run";
          cwd = "$ZED_WORKTREE_ROOT";
          tags = [ "run" ];
        }
      ];
    };
  };

  flake.homeModules.apps.Flutter = { pkgs, ... }: {
    home.packages = with pkgs; [ flutter ];
  };
}
