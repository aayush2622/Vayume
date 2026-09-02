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
      theme = config.vayori.theme;

      registryPlugins = pkgs.callPackage "${inputs.dms-plugin-registry}/nix/default.nix" { };

      assertPatched = file: needle: ''
        grep -qF ${lib.escapeShellArg needle} "${file}" || {
          echo "patch verification failed: ${lib.escapeShellArg needle} not found in ${file} (upstream source likely changed - update the patch in dms.nix)" >&2
          exit 1
        }
      '';

      assertPatchedLine = file: line: needle: ''
        sed -n '${toString line}p' "${file}" | grep -qF ${lib.escapeShellArg needle} || {
          echo "patch verification failed: line ${toString line} of ${file} doesn't say ${lib.escapeShellArg needle} (upstream source likely changed - update the patch in dms.nix)" >&2
          exit 1
        }
      '';

      mkPatchedPlugin =
        name: src: patchScript:
        pkgs.runCommand "dms-plugin-${name}-patched" { } ''
          cp -r ${src} $out
          chmod -R u+w $out
          ${patchScript}
        '';

      nixMonitorPatched = mkPatchedPlugin "nixMonitor" registryPlugins.nixMonitor ''
        sed -i '110s/Theme\.primary$/Theme.widgetIconColor/' $out/NixMonitor.qml
        ${assertPatchedLine "$out/NixMonitor.qml" 110 "Theme.widgetIconColor"}
      '';

      dankAsusControlCenterPatched =
        mkPatchedPlugin "dankAsusControlCenter" registryPlugins.dankAsusControlCenter
          ''
            substituteInPlace $out/DankAsusControlCenter.qml \
              --replace-quiet "size: root.showBatteryIcon ? 18 : Theme.iconSize * 0.85" "size: root.showBatteryIcon ? 18 : root.iconSize"
            sed -i '521s/spacing: 4$/spacing: Theme.spacingXS/' $out/DankAsusControlCenter.qml
            ${assertPatched "$out/DankAsusControlCenter.qml" "size: root.showBatteryIcon ? 18 : root.iconSize"}
            ${assertPatchedLine "$out/DankAsusControlCenter.qml" 521 "Theme.spacingXS"}
          '';

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

      vayoriHomeByUser = lib.concatMapStringsSep "\n" (
        name: ''"${name}") echo "${config.users.users.${name}.home}" ;;''
      ) (builtins.attrNames config.vayori.users);

      vayoriRebuildScript = pkgs.writeShellScript "vayori-rebuild" ''
        homeDir="$(case "''${SUDO_USER:-$USER}" in
        ${vayoriHomeByUser}
          *) echo "$HOME" ;;
        esac)"
        flakeDir=""
        for d in "$homeDir/vayori" "$homeDir/dotfiles" "$homeDir/.dotfiles" /etc/nixos; do
          [ -f "$d/flake.nix" ] && flakeDir="$d" && break
        done
        if [ -z "$flakeDir" ]; then
          echo "vayori flake not found (checked $homeDir/vayori, $homeDir/dotfiles, $homeDir/.dotfiles, /etc/nixos) - edit rebuildCommand in dms.nix if it lives elsewhere"
          exit 1
        fi
        ${pkgs.git}/bin/git config --global --add safe.directory "$flakeDir"
        exec nixos-rebuild switch --flake "path:$flakeDir#${config.networking.hostName}"
      '';

      vayoriGcScript = pkgs.writeShellScript "vayori-gc" "exec nix-collect-garbage -d";
    in
    {
      services.accounts-daemon.enable = true;

      security.sudo.extraRules =
        map
          (name: {
            users = [ name ];
            commands = [
              {
                command = "${vayoriRebuildScript}";
                options = [ "NOPASSWD" ];
              }
              {
                command = "${vayoriGcScript}";
                options = [ "NOPASSWD" ];
              }
            ];
          })
          (
            builtins.filter (name: builtins.elem "wheel" config.vayori.users.${name}.extraGroups) (
              builtins.attrNames config.vayori.users
            )
          );

      home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (
        name: { pkgs, lib, ... }: {
          imports = [
            inputs.dms.homeModules.dank-material-shell
            inputs.dms-plugin-registry.nixosModules.default
          ];
          home.packages = [ materialOSIcons ];
          home.sessionVariables.QS_ICON_THEME = "MaterialOS";
          xdg.configFile = {
            "DankMaterialShell/settings.json".force = true;
            "DankMaterialShell/plugin_settings.json".force = true;

            "DankMaterialShell/plugins/NixMonitor/config.json" = {
              force = true;
              text = builtins.toJSON {
                generationsCommand = [
                  "sh"
                  "-c"
                  "ls -d /nix/var/nix/profiles/per-user/$(whoami)/home-manager-*-link 2>/dev/null | wc -l"
                ];
                storeSizeCommand = [
                  "sh"
                  "-c"
                  "du -sh /nix/store 2>/dev/null | cut -f1"
                ];
                rebuildCommand = [
                  "sh"
                  "-c"
                  "sudo ${vayoriRebuildScript} 2>&1"
                ];
                gcCommand = [
                  "sh"
                  "-c"
                  "sudo ${vayoriGcScript} 2>&1"
                ];
                updateInterval = 300;
              };
            };
          };
          home.activation.seedDmsSession =
            let
              defaultSession = pkgs.writeText "dms-default-session.json" (
                builtins.toJSON {
                  configVersion = 4;
                  wallpaperPath = "${./../assets/wallpapers}/wallhaven-w5xdzx.jpg";
                  wallpaperCyclingFolderPath = "${./../assets/wallpapers}";
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

            dgop.package = inputs.dgop.packages.${pkgs.system}.default;

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
                  borderWidth = 0;
                  itemHeight = 472;
                  selectedScale = 106;
                  expandMultiplier = 118;
                  cornerRadius = 3;
                  overlayOpacity = 84;
                };
              };

              dankAsusControlCenter = {
                enable = true;
                src = lib.mkForce dankAsusControlCenterPatched;
                settings = {
                  showBatteryIcon = false;
                  useThemeColors = true;
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

              nixMonitor = {
                enable = true;
                src = lib.mkForce nixMonitorPatched;
                settings = {
                  showGenerations = true;
                  showStoreSize = true;
                  gcThresholdGB = 50;
                  checkUpdates = true;
                  nixpkgsChannel = "nixos-unstable";
                  updateCheckInterval = 3600;
                };
              };
            };

            settings = {

              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";

              matugenScheme = "scheme-content";

              cornerRadius = 12;

              useAutoLocation = true;

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
                  id = "diskUsage";
                  enabled = true;
                  width = 50;
                  mountPath = "/";
                  showMountPath = true;
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
                  hideOnKeyPress = false;
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
                    {
                      id = "nixMonitor";
                      enabled = true;
                    }
                    "systemTray"
                    "clipboard"
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

                    {
                      id = "dankAsusControlCenter";
                      enabled = true;
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

              configVersion = 13;
            };
          };
        }
      );
    };
}
