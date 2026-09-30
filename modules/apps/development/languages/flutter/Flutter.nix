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
      inputs,
      self,
      pkgs,
      lib,
      ...
    }:
    let

      harfbuzzIcu = pkgs.harfbuzz.override { withIcu = true; };

      wpeTransitiveDeps = with pkgs; [
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

      wpewebkitUnpatched = inputs.nix-wpe-webkit-bin.packages.${pkgs.stdenv.hostPlatform.system}.default;

      wpewebkit = pkgs.stdenvNoCC.mkDerivation {
        pname = "wpewebkit-patched";
        version = wpewebkitUnpatched.version;
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs =
          wpeTransitiveDeps
          ++ [ harfbuzzIcu ]
          ++ (with pkgs; [
            libwpe
            libwpe-fdo
            libsoup_3
            at-spi2-core
            gtk3
            libepoxy
            libsecret
            wayland
            libxkbcommon
            libglvnd
            libgbm
            libdrm
            mesa
          ])
          ++ otherPluginDeps;
        installPhase = ''
          mkdir -p $out
          cp -r ${wpewebkitUnpatched}/* $out/
          chmod -R u+w $out

          for f in $out/lib/pkgconfig/*.pc; do
            sed -i "s|${wpewebkitUnpatched}|$out|g" "$f"
          done
        '';
      };

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
        libgbm
        libdrm
        mesa
      ];

      buildTools = with pkgs; [
        pkg-config
        ninja
        patchelf
      ];

      allDeps = wpeDeps ++ wpeTransitiveDeps ++ otherPluginDeps;

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

      home.file.".local/share/dart-sdk".source = "${pkgs.flutter}/bin/cache/dart-sdk";
      home.file.".local/share/flutter-sdk".source = "${pkgs.flutter}";
    };
}
