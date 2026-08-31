{ self, inputs, lib, ... }:
let
  androidStudioAutoPlugins = [
    { dirName = "Catppuccin Theme"; id = "com.github.catppuccin.jetbrains"; }
    { dirName = "claude-code-jetbrains-plugin"; id = "com.anthropic.code.plugin"; }
    { dirName = "git-worktree-manager"; id = "com.purringlabs.gitworktree.git-worktree-manager"; }
    { dirName = "JetBrains-Discord-Integration"; id = "dev.azn9.plugins.discord"; }
    { dirName = "lsp4ij"; id = "com.redhat.devtools.lsp4ij"; }
    { dirName = "one-dark-theme"; id = "com.markskelton.one-dark-theme"; }
    { dirName = "vcs-perforce"; id = "PerforceDirectPlugin"; }
    { dirName = "vcs-svn"; id = "Subversion"; }
  ];

  wakatimeManualPlugin = {
    dirName = "WakaTime.jar"; id = "com.wakatime.intellij.plugin"; version = "16.1.2"; hash = "sha256-KnHRvFUtsH4vJDF+YhSoP7YpV52Jqoe2AiMwORDiPOQ="; isJar = true;
  };

  otherManualPluginsSpec = [
    { dirName = "github-copilot-intellij"; id = "com.github.copilot"; version = "1.16.1-251"; hash = "sha256-LM2pLbOyOc2R3E90LSlbBxiGNWkzqG5pimKxvswaPQg="; }
  ];

  androidStudioManualPluginsSpec = [ wakatimeManualPlugin ] ++ otherManualPluginsSpec;
in {
  flake.pluginPins.AndroidStudio = androidStudioManualPluginsSpec
    ++ (lib.concatMap (l: l.androidStudio.manualPlugins or [ ]) (lib.attrValues self.devLanguages));

  flake.homeModules.apps.AndroidStudio = { pkgs, lib, config, vayoriTheme, vayoriApps, vayoriSecrets, ... }:
  let
    hasWakatime = vayoriSecrets.WAKATIME_API_KEY != "REPLACE_ME";

    languageAndroidStudio = lib.mapAttrsToList (_: l: l.androidStudio or { }) (self.enabledDevLanguages vayoriApps);

    allAutoPlugins = androidStudioAutoPlugins ++ (lib.concatMap (v: v.autoPlugins or [ ]) languageAndroidStudio);
    allManualPluginsSpec = otherManualPluginsSpec
      ++ lib.optional hasWakatime wakatimeManualPlugin
      ++ (lib.concatMap (v: v.manualPlugins or [ ]) languageAndroidStudio);

    configDataDir = "AndroidStudio2026.1.3";
    pluginsDir = ".local/share/Google/${configDataDir}";
    optionsDir = ".config/Google/${configDataDir}/options";
    colorsDir = ".config/Google/${configDataDir}/colors";

    matugenDirRel = ".config/matugen";
    matugenDir = "${config.home.homeDirectory}/${matugenDirRel}";
    matugenSchemeName = "DankMatugen";
    matugenTemplatePath = "${matugenDir}/templates/android-studio-colors.icls";
    matugenOutputPath = "${config.home.homeDirectory}/${colorsDir}/${matugenSchemeName}.icls";

    fetchJbPlugin = { id, version, hash, isJar ? false }:
      let
        src = pkgs.fetchurl {
          url = "https://plugins.jetbrains.com/plugin/download?pluginId=${id}&version=${version}";
          inherit hash;
        };
      in
      if isJar then src
      else pkgs.runCommand "jetbrains-plugin-${id}" { } ''
        mkdir -p $out
        cd $out
        ${pkgs.unzip}/bin/unzip -q ${src}
      '';

    androidStudioBuild = pkgs.androidStudioPackages.stable.version;
    jbAutoPluginsAtBuild = inputs.nix-jetbrains-plugins.plugins.${pkgs.stdenv.hostPlatform.system}."android-studio".${androidStudioBuild};

    manualPluginFiles = lib.listToAttrs (map
      (p:
        let
          plugin = fetchJbPlugin { inherit (p) id version hash; isJar = p.isJar or false; };
          source = if (p.isJar or false) then plugin else "${plugin}/${p.dirName}";
        in
        lib.nameValuePair "${pluginsDir}/${p.dirName}" { inherit source; })
      allManualPluginsSpec);

    autoPluginFiles = lib.listToAttrs (map
      (p: lib.nameValuePair "${pluginsDir}/${p.dirName}" { source = jbAutoPluginsAtBuild.${p.id}; })
      allAutoPlugins);

    pluginFiles = manualPluginFiles // autoPluginFiles;

    androidStudioOptions = {
      "editor-font.xml" = ''
        <application>
          <component name="DefaultFont">
            <option name="VERSION" value="1" />
            <option name="FONT_SIZE" value="14" />
            <option name="FONT_SIZE_2D" value="14.0" />
            <option name="FONT_FAMILY" value="${vayoriTheme.font}" />
            <option name="FONT_BOLD_SUB_FAMILY" value="Regular" />
            <option name="LINE_SPACING" value="1.0" />
          </component>
        </application>
      '';

      "laf.xml" = ''
        <application>
          <component name="LafManager">
            <laf themeId="71b26d33-3d44-42f4-8166-31b17c762b32" />
          </component>
        </application>
      '';

      "colors.scheme.xml" = ''
        <application>
          <component name="EditorColorsManagerImpl">
            <global_color_scheme name="${matugenSchemeName}" />
          </component>
        </application>
      '';

      "one_dark_config.xml" = ''
        <application>
          <component name="OneDarkConfig">
            <option name="version" value="5.14.2" />
          </component>
        </application>
      '';

      "vim_settings.xml" = ''
        <application>
          <component name="VimSettings">
            <state version="7" enabled="true" />
          </component>
        </application>
      '';
    };

    optionFiles = lib.mapAttrs'
      (name: text: lib.nameValuePair "${optionsDir}/${name}" { inherit text; })
      androidStudioOptions;

    matugenIclsTemplate = self.matugenTemplates.androidStudio matugenSchemeName;

    matugenFiles = {
      "${matugenDirRel}/templates/android-studio-colors.icls" = { text = matugenIclsTemplate; };
    };

    androidStudioWithFcc =
      if builtins.elem "FreeClaudeCode" vayoriApps then
        pkgs.symlinkJoin {
          name = "android-studio-with-fcc";
          paths = [ pkgs.androidStudioPackages.stable ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/android-studio \
              ${lib.concatStringsSep " " (lib.mapAttrsToList (n: v: "--set ${n} ${lib.escapeShellArg v}") self.freeClaudeCode.clientEnv)}
          '';
        }
      else
        pkgs.androidStudioPackages.stable;
  in {
    home.packages = with pkgs; [
      androidStudioWithFcc
      jdk17
      android-tools
    ];

    home.sessionVariables = {
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
      ANDROID_HOME = "$HOME/Android/Sdk";
    } // lib.optionalAttrs (builtins.elem "ZenBrowser" vayoriApps) {
      CHROME_EXECUTABLE = "zen";
    };

    home.file = pluginFiles // optionFiles // matugenFiles;

    home.activation.androidStudioWakatimeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString hasWakatime ''
        run ${pkgs.crudini}/bin/crudini --set "$HOME/.wakatime.cfg" settings api_key ${lib.escapeShellArg vayoriSecrets.WAKATIME_API_KEY}
      ''
    );

    vayori.matugenTemplates.androidStudio = ''
      [templates.androidStudio]
      input_path = '${matugenTemplatePath}'
      output_path = '${matugenOutputPath}'
    '';
  };
}
