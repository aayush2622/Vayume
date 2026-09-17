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

  flake.appDescriptions.Flutter = "Flutter/Dart SDK and editor integrations.";

  flake.homeModules.apps.Flutter = { self, pkgs, lib, ... }:
    let
    
      wpewebkit = self.vayumeLib.loadOrBuild { inherit self pkgs; } "wpewebkit"
        (pkgs.callPackage ./_vendor/wpewebkit/package.nix { });

   
      wpeDeps = with pkgs; [
        wpewebkit
        libwpe
        libwpe-fdo
        gtk3
        libepoxy
        libsecret
        wayland
        libxkbcommon
        libglvnd
      ];

    
      buildTools = with pkgs; [ pkg-config ninja patchelf ];


      otherPluginDeps = with pkgs; [
        alsa-lib
        xz
        libva
        libvdpau
        gnutls
        libunwind
        libarchive
        libpulseaudio
        xorg.libXScrnSaver
        xorg.libXv
      ];

      allDeps = wpeDeps ++ otherPluginDeps;
    in {
      home.packages = with pkgs; [ flutter ] ++ allDeps ++ buildTools;

      home.sessionVariables.PKG_CONFIG_PATH =
        "${lib.makeSearchPath "lib/pkgconfig" (map lib.getDev allDeps)}:$PKG_CONFIG_PATH";

      home.sessionVariables.CMAKE_PREFIX_PATH =
        "${lib.concatMapStringsSep ":" (p: "${lib.getDev p}:${lib.getLib p}") allDeps}:$CMAKE_PREFIX_PATH";

      home.sessionVariables.CPATH =
        "${lib.makeSearchPath "include" (map lib.getDev allDeps)}:$CPATH";

      home.sessionVariables.FLUTTER_NIX_LIB_DIRS =
        lib.concatMapStringsSep ":" (p: "${lib.getLib p}/lib") allDeps;

      home.file.".local/share/dart-sdk".source = "${pkgs.flutter}/bin/cache/dart-sdk";
      home.file.".local/share/flutter-sdk".source = "${pkgs.flutter}";
    };
}
