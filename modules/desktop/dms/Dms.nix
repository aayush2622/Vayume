{ inputs, ... }:

{
  flake.nixosModules.Dms =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      theme = config.vayume.theme;

      materialOSIcons = pkgs.stdenvNoCC.mkDerivation {
        pname = "materialos-icon-theme";
        version = "unstable-2026-08-27";
        src = pkgs.fetchFromGitHub {
          owner = "materialos";
          repo = "Linux-Icon-Pack";
          rev = "7ff36403cb38c0f5b7231df717a2efd373c94b6c";
          hash = "sha256-iLhaCdH1RlElMoWvmArTcX+VUubcyIX5k9vHBV9rU9Q=";
        };
        installPhase = ''
          mkdir -p $out/share/icons
          cp -r Icons/MaterialOS $out/share/icons/MaterialOS
        '';
      };
    in
    {
      services.accounts-daemon.enable = true;

      home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (
        name:
        {
          pkgs,
          lib,
          config,
          ...
        }:
        {
          imports = [
            inputs.dms.homeModules.dank-material-shell
            inputs.dms-plugin-registry.nixosModules.default
            inputs.danksession.homeManagerModules.default
          ];
          home.packages = [
            materialOSIcons
            pkgs.swayidle
          ];
          home.sessionVariables.QS_ICON_THEME = "MaterialOS";

          home.activation.materialOSIconFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            iconDir="$HOME/.local/share/icons/MaterialOS"
            run rm -rf "$iconDir"
            run mkdir -p "$iconDir"
            run ${pkgs.coreutils}/bin/cp -rL --no-preserve=mode ${materialOSIcons}/share/icons/MaterialOS/. "$iconDir/"
            run ${pkgs.coreutils}/bin/cp -rL --no-preserve=mode "$HOME/.nix-profile/share/icons/hicolor/." "$iconDir/" 2>/dev/null || true
            run ${pkgs.gnused}/bin/sed -i -e "/^Hidden=true/d" -e "s/^Name=.*/Name=MaterialOS/" "$iconDir/index.theme" 2>/dev/null || true
          '';

          services.dankSession = {
            enable = true;
            package = inputs.danksession.packages.${pkgs.system}.default;
            autoStart = true;
          };

          systemd.user.services.vayume-idle-lock = {
            Unit = {
              Description = "Lock the screen after 10 minutes idle";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 600 '${config.programs.dank-material-shell.package}/bin/dms ipc call lock lock'";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
          xdg.configFile = {
            "DankMaterialShell/settings.json".force = true;
            "DankMaterialShell/plugin_settings.json".force = true;
          };
          home.activation.seedDmsSession =
            let
              defaultSession = pkgs.writeText "dms-default-session.json" (
                builtins.toJSON {
                  configVersion = 4;
                  wallpaperPath = "${./../../assets/wallpapers}/wallhaven-w5xdzx.jpg";
                  wallpaperCyclingFolderPath = "${./../../assets/wallpapers}";
                }
              );
            in
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              sessionFile="$HOME/.local/state/DankMaterialShell/session.json"
              if [ ! -e "$sessionFile" ]; then
                run mkdir -p "$(dirname "$sessionFile")"
                run cp "${defaultSession}" "$sessionFile"
                run chmod u+w "$sessionFile"
              fi
            '';

          programs.dank-material-shell = {
            enable = true;

            systemd = {
              enable = true;
              restartIfChanged = true;
            };

            enableSystemMonitoring = true;
            enableDynamicTheming = true;
            enableAudioWavelength = true;

            plugins = {
              wallpaperCarousel = {
                enable = true;

                settings = {
                  enabled = true;
                  wallpaperDirectory = "${./../../assets/wallpapers}";

                  borderWidth = 0;
                  itemHeight = 472;
                  selectedScale = 106;
                  expandMultiplier = 118;
                  cornerRadius = 3;
                  overlayOpacity = 84;
                };
              };

              dankQuickSearch = {
                enable = true;
                settings = {
                  trigger = "!";
                  defaultEngine = "duckduckgo";
                };
              };

              dankBitwarden = {
                enable = true;
                settings = {
                  trigger = "[";
                  noTrigger = false;
                  loginAction = "copy:password";
                  cardAction = "copy:number";
                  identityAction = "copy:name";
                  sshKeyAction = "copy:public_key";
                };
              };

              spotifyMatugen.enable = true;

              pureLyrics.enable = true;

              fullscreenPowerMenu.enable = true;

              nixPackageRunner = {
                enable = true;
                settings.runSourceMode = "latest_unstable";
              };

              screenshotPlus.enable = true;
            };

            settings = {

              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";

              matugenScheme = "scheme-content";

              cornerRadius = 12;

              useAutoLocation = true;

              lockBeforeSuspend = true;

              matugenTemplateZenBrowser = false;
              matugenTemplateZed = false;

              blurEnabled = true;

              blurredWallpaperLayer = true;
              blurWallpaperOnOverview = true;

              controlCenterShowMicPercent = true;

              controlCenterWidgets = [
                {
                  id = "volumeSlider";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "brightnessSlider";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "wifi";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "bluetooth";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "audioOutput";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "audioInput";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "nightMode";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "darkMode";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "idleInhibitor";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "plugin_tor";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "diskUsage";
                  enabled = true;
                  width = 50;
                  mountPath = "/";
                  showMountPath = true;
                }
                {
                  id = "plugin_dankAsusControlCenter";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "plugin_vayumeSettings";
                  enabled = true;
                  width = 50;
                }
              ];

              showWorkspaceIndex = true;

              appIdSubstitutions = [ ];

              filePickerUsageHistory = {
                code = {
                  count = 1;
                  lastUsed = 1787340048369;
                  name = "Visual Studio Code";
                };
              };

              appDrawerSectionViewModes = {
                apps = "list";
              };

              cursorSettings = {
                theme = "System Default";
                size = 24;

                niri = {
                  hideWhenTyping = false;
                  hideAfterInactiveMs = 0;
                };

                hyprland = {
                  hideOnKeyPress = true;
                  hideOnTouch = false;
                  inactiveTimeout = 0;
                };

                mango = {
                  cursorHideTimeout = 0;
                };
              };

              fontFamily = theme.font;
              monoFontFamily = theme.font;

              gtkThemingEnabled = true;
              qtThemingEnabled = true;

              terminalsAlwaysDark = true;

              showDock = true;
              dockAutoHide = true;

              dockPosition = 3;

              dockSpacing = 12;
              dockMargin = 10;

              dockBorderEnabled = true;
              dockBorderColor = "secondary";

              dockLauncherEnabled = true;

              osdPowerProfileEnabled = true;

              barConfigs = [
                {
                  id = "default";
                  name = "Main Bar";

                  enabled = true;
                  position = 0;

                  screenPreferences = [ "all" ];
                  showOnLastDisplay = true;

                  leftWidgets = [
                    "launcherButton"
                    "workspaceSwitcher"

                    {
                      id = "focusedWindow";
                      enabled = true;
                      focusedWindowSize = 1;
                      focusedWindowCompactMode = true;
                      focusedWindowShowIcon = true;
                    }
                  ];

                  centerWidgets = [
                    {
                      id = "music";
                      enabled = true;
                      mediaSize = 0;
                    }

                    {
                      id = "clock";
                      enabled = true;
                      clockCompactMode = false;
                    }

                    "weather"
                  ];

                  rightWidgets = [
                    "systemTray"
                    "cpuUsage"
                    "memUsage"

                    "notificationButton"

                    {
                      id = "battery";
                      enabled = true;
                      showBatteryPercent = true;
                      showBatteryPercentOnlyOnBattery = false;
                      showBatteryTime = false;
                      batteryPillStyle = false;
                      batteryPillPercentSign = false;
                    }

                    "controlCenterButton"
                  ];

                  spacing = 4;
                  innerPadding = 3;

                  barInsetPadding = -1;
                  bottomGap = 0;

                  transparency = 0.50;
                  widgetTransparency = 1;

                  squareCorners = false;
                  noBackground = true;

                  maximizeWidgetIcons = false;
                  maximizeWidgetText = false;

                  removeWidgetPadding = false;
                  widgetPadding = 8;

                  gothCornersEnabled = false;
                  gothCornerRadiusOverride = false;
                  gothCornerRadiusValue = 12;

                  borderEnabled = false;
                  borderColor = "surfaceText";
                  borderOpacity = 1;
                  borderThickness = 1;

                  widgetOutlineEnabled = false;
                  widgetOutlineColor = "primary";
                  widgetOutlineOpacity = 1;
                  widgetOutlineThickness = 1;

                  fontScale = 1;
                  iconScale = 1;

                  autoHide = false;
                  autoHideStrict = false;
                  autoHideDelay = 250;

                  showOnWindowsOpen = false;
                  openOnOverview = false;

                  visible = true;

                  popupGapsAuto = true;
                  popupGapsManual = 4;

                  maximizeDetection = true;

                  useOverlayLayer = false;

                  scrollEnabled = true;
                  scrollXBehavior = "column";
                  scrollYBehavior = "workspace";

                  shadowIntensity = 0;
                  shadowOpacity = 60;
                  shadowColorMode = "default";
                  shadowCustomColor = "#000000";

                  clickThrough = false;

                  hoverPopouts = false;
                  hoverPopoutDelay = 150;
                }
              ];

              desktopClockCustomColor = {
                r = 1;
                g = 1;
                b = 1;
                a = 1;

                hsvHue = -1;
                hsvSaturation = 0;
                hsvValue = 1;

                hslHue = -1;
                hslSaturation = 0;
                hslLightness = 1;

                valid = true;
              };

              systemMonitorCustomColor = {
                r = 1;
                g = 1;
                b = 1;
                a = 1;

                hsvHue = -1;
                hsvSaturation = 0;
                hsvValue = 1;

                hslHue = -1;
                hslSaturation = 0;
                hslLightness = 1;

                valid = true;
              };

              desktopWidgetInstances = [
                {
                  id = "dw_1788083196111_hpk1tmarl";
                  widgetType = "pureLyrics";
                  name = "Pure Lyrics";
                  enabled = true;

                  config = {
                    displayPreferences = [ "all" ];
                    showOnOverlay = false;
                    showOnOverview = false;
                    clickThrough = true;
                    borderOpacity = 0;
                    backgroundOpacity = 0;
                    colorMode = "primary";
                    lineCount = "5";
                    fontSize = 35;
                    textAlign = "center";
                    showOnOverviewOnly = false;
                    syncPositionAcrossScreens = true;
                  };

                  positions._synced = {
                    x = 0;
                    width = 9999;
                    height = 253;
                  };
                }

                {
                  id = "dw_1789200000000_cavaviz01";
                  widgetType = "cavaVisualizer";
                  name = "Cava Visualizer";
                  enabled = true;

                  config = {
                    vizMode = "curve-outline";
                    curvePoints = 24;
                    curveLineWidth = 3;
                    barCount = 20;
                    barSpacing = 4;
                    barWidth = 0;
                    orientation = "bottom";
                    sensitivity = 100;
                    channels = "mono";
                    colorChoice = "primary";
                    silenceTimeout = 5;
                    bgOpacity = 0;
                    opacity = 100;
                    syncPositionAcrossScreens = true;
                  };
                  positions._synced = {
                    x = 0;
                    y = 0.9;
                    width = 9999;
                    height = 120;
                  };
                }
              ];

              builtInPluginSettings = {
                dms_settings_search = {
                  trigger = "?";
                };

                dms_clipboard_search = {
                  trigger = "cb";
                };
              };

              clipboardClickToPaste = true;
              frameEnabled = true;
              frameOpacity = 0.45;
              configVersion = 13;
            };
          };
        }
      );
    };
}
