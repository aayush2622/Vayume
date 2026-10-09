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
        {
          dirName = "Dart";
          id = "Dart";
        }
        {
          dirName = "Flutter Enhancement Suite";
          id = "de.mariushoefler.flutter_enhancement_suite";
        }
        {
          dirName = "flutter-intellij";
          id = "io.flutter";
        }
        {
          dirName = "flutter-intl";
          id = "com.localizely.flutter-intl";
        }
      ];
    };
    zed = {
      extensions = [
        "dart"
        "flutter-snippets"
      ];
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

  flake.appMeta.Flutter = {
    description = "Flutter/Dart SDK and editor integrations.";
    label = "Flutter / Dart";
    icon = "";
    symbol = "flutter_dash";
    section = "Languages";
  };

  flake.homeModules.apps.Flutter =
    {
      self,
      pkgs,
      lib,
      ...
    }:
    let

      harfbuzzIcu = pkgs.harfbuzz.override { withIcu = true; };

      webviewTransitiveDeps = with pkgs; [
        libseccomp
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        libinput
        systemd
        expat
        libwebp
        icu
        libxml2
        libxslt
        lcms2
        woff2
        harfbuzz
        libgcrypt
        libgpg-error
        libjxl
        libavif
        libtasn1
        hyphen
        libjpeg
        libpng
        dbus
      ];

      otherPluginDeps = with pkgs; [
        alsa-lib
        xz
        libva
        libvdpau
        gnutls
        libunwind
        libarchive
        libpulseaudio
        libXScrnSaver
        libXv
      ];

      webviewDeps = with pkgs; [
        webkitgtk_4_1
        libsoup_3
        glib-networking
        gtk3
        libepoxy
        libsecret
        wayland
        libxkbcommon
        libglvnd
        libgbm
        libdrm
        mesa
      ];

      buildTools = with pkgs; [
        pkg-config
        ninja
        patchelf
      ];

      allDeps = webviewDeps ++ webviewTransitiveDeps ++ otherPluginDeps;

      envDeps = allDeps ++ [ harfbuzzIcu ];
      libPath = lib.makeLibraryPath envDeps;
    in
    {
      home.packages = with pkgs; [ flutter ] ++ allDeps ++ buildTools;

      home.sessionVariables.PKG_CONFIG_PATH = "${lib.makeSearchPath "lib/pkgconfig" (map lib.getDev envDeps)}:$PKG_CONFIG_PATH";

      home.sessionVariables.CMAKE_PREFIX_PATH = "${
        lib.concatMapStringsSep ":" (p: "${lib.getDev p}:${lib.getLib p}") envDeps
      }:$CMAKE_PREFIX_PATH";

      home.sessionVariables.CPATH = "${lib.makeSearchPath "include" (map lib.getDev envDeps)}:$CPATH";

      home.sessionVariables.NIX_LDFLAGS = "--disable-new-dtags ${
        lib.concatMapStringsSep " " (d: "-L${d} -rpath-link ${d} -rpath ${d}") (lib.splitString ":" libPath)
      } $NIX_LDFLAGS";

      home.sessionVariables.LD_LIBRARY_PATH = "${pkgs.addDriverRunpath.driverLink}/lib:${libPath}:$LD_LIBRARY_PATH";

      home.sessionVariables.FLUTTER_NIX_LIB_DIRS = libPath;

      home.sessionVariables.GIO_EXTRA_MODULES = "${pkgs.glib-networking}/lib/gio/modules:$GIO_EXTRA_MODULES";

      home.sessionVariablesExtra = ''
        unset NIX_CFLAGS_LINK
        NIX_LDFLAGS="''${NIX_LDFLAGS//-L\/usr\/lib32/}"
        NIX_LDFLAGS="''${NIX_LDFLAGS//-L\/usr\/lib/}"
        PKG_CONFIG_PATH="''${PKG_CONFIG_PATH//\/usr\/lib\/pkgconfig:/}"
        export NIX_LDFLAGS PKG_CONFIG_PATH
      '';

      home.file.".local/share/dart-sdk".source = "${pkgs.flutter}/bin/cache/dart-sdk";
      home.file.".local/share/flutter-sdk".source = "${pkgs.flutter}";
    };
}
