{ self, inputs, lib, ... }:
let
  vscodeAutoExtensions = [
    { publisher = "chadalen"; name = "vscode-jetbrains-icon-theme"; }
    { publisher = "codista"; name = "vscode-autosave"; }
    { publisher = "icrawl"; name = "discord-vscode"; }
    { publisher = "janisdd"; name = "vscode-edit-csv"; }
    { publisher = "mjstudio"; name = "db-viewer"; }
    { publisher = "mohsen1"; name = "prettify-json"; }
    { publisher = "narasimapandiyan"; name = "jetbrainsmono"; }
    { publisher = "yandeu"; name = "five-server"; }
  ];
in {
  flake.pluginPins.Vscode = lib.concatMap (l: l.vscode.manualExtensions or [ ]) (lib.attrValues self.devLanguages);

  flake.homeModules.apps.Vscode = { pkgs, lib, vayoriTheme, vayoriApps, vayoriSecrets, ... }:
  let
    hasWakatime = vayoriSecrets.WAKATIME_API_KEY != "REPLACE_ME";

    languageVscode = lib.mapAttrsToList (_: l: l.vscode or { }) (self.enabledDevLanguages vayoriApps);

    resolveNixpkgsExtension = dotted:
      lib.attrByPath (lib.splitString "." dotted)
        (throw "Vscode.nix: pkgs.vscode-extensions.${dotted} does not exist")
        pkgs.vscode-extensions;

    languageNixpkgsExtensions =
      map resolveNixpkgsExtension
        (lib.unique (lib.concatMap (v: v.nixpkgsExtensions or [ ]) languageVscode));
    languageMarketplaceExtensions =
      lib.unique (lib.concatMap (v: v.marketplaceExtensions or [ ]) languageVscode);
    languageManualExtensions =
      lib.concatMap (v: v.manualExtensions or [ ]) languageVscode;
    languageSettings =
      lib.foldl' lib.recursiveUpdate { } (map (v: v.settings or { }) languageVscode);

    nixpkgsExtensions = with pkgs.vscode-extensions; [
      anthropic.claude-code
      catppuccin.catppuccin-vsc
      eamodio.gitlens
      formulahendry.code-runner
      github.vscode-github-actions
      github.vscode-pull-request-github
      k--kato.intellij-idea-keybindings
      mechatroner.rainbow-csv
      mskelton.one-dark-theme
      oderwat.indent-rainbow
      pkief.material-icon-theme
      zainchen.json
    ] ++ languageNixpkgsExtensions ++ lib.optional hasWakatime pkgs.vscode-extensions.wakatime.vscode-wakatime;

    manualMarketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace languageManualExtensions;
    autoMarketplaceExtensions = map (e: pkgs.vscode-marketplace.${e.publisher}.${e.name}) (vscodeAutoExtensions ++ languageMarketplaceExtensions);
    marketplaceExtensions = manualMarketplaceExtensions ++ autoMarketplaceExtensions;

    vscodeSettings = lib.recursiveUpdate ({
      "security.workspace.trust.untrustedFiles" = "open";
      "files.autoSave" = "onWindowChange";

      "editor.fontFamily" = vayoriTheme.font;
      "editor.fontLigatures" = true;
      "editor.fontSize" = 15;
      "editor.fontWeight" = "normal";
      "editor.smoothScrolling" = true;
      "editor.hover.delay" = 300;
      "editor.parameterHints.enabled" = true;
      "editor.renderWhitespace" = "boundary";
      "editor.renderControlCharacters" = false;
      "editor.guides.indentation" = true;
      "editor.unicodeHighlight.nonBasicASCII" = false;

      "editor.gotoLocation.multipleDefinitions" = "goto";
      "editor.gotoLocation.multipleDeclarations" = "goto";
      "editor.foldingStrategy" = "indentation";
      "editor.showFoldingControls" = "always";

      "workbench.colorTheme" = "Dynamic Base16 DankShell";
      "workbench.iconTheme" = "vscode-jetbrains-icon-theme-2023-dark";
      "workbench.editor.showIcons" = true;
      "workbench.editor.enablePreview" = false;
      "workbench.editor.tabSizing" = "shrink";
      "workbench.editor.tabCloseButton" = "right";
      "workbench.editor.highlightModifiedTabs" = true;
      "workbench.editor.tabActionLocation" = "right";
      "workbench.secondarySideBar.defaultVisibility" = "hidden";
      "workbench.list.smoothScrolling" = true;
      "workbench.editorAssociations" = {
        "*.copilotmd" = "vscode.markdown.preview.editor";
        "{git,gitlens,chat-editing-snapshot-text-model,copilot,git-graph,git-graph-3}:/**/*.qrc" = "default";
        "*.qrc" = "qt-core.qrcEditor";
      };

      "explorer.compactFolders" = false;
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;

      "errorLens.enabled" = true;
      "errorLens.fontWeight" = "bold";
      "errorLens.messageBackgroundMode" = "message";

      "github.copilot.nextEditSuggestions.enabled" = true;
      "github.copilot.enable" = {
        "*" = true;
        plaintext = false;
        markdown = false;
        scminput = false;
        python = false;
        cpp = false;
        html = false;
        css = false;
        javascript = false;
        qml = false;
        c = false;
      };

      "editor.tokenColorCustomizations" = {
        textMateRules = [
          { scope = "comment"; settings.fontStyle = "italic"; }
          {
            scope = [
              "entity.name.type" "entity.other.inherited-class" "keyword.other.type"
              "punctuation.definition.annotation" "storage.modifier.import" "storage.modifier.package"
              "storage.type.annotation" "storage.type.built-in" "storage.type.generic"
              "storage.type.java" "storage.type.groovy" "storage.type.primitive"
              "support.class" "support.other.namespace" "support.type" "variable.language.this"
            ];
            settings.foreground = "#e5c07b";
          }
          {
            scope = [
              "constant.other.character-class" "entity.name.tag" "heading" "meta.object-literal.key"
              "punctuation.definition.list.begin.markdown" "punctuation.definition.list.end.markdown"
              "punctuation.definition.template-expression" "punctuation.section.embedded"
              "support.type.property-name" "variable.object.property" "variable.other.enummember"
            ];
            settings.foreground = "#e06c75";
          }
          { scope = [ "constant.character.escape" "keyword.operator" "markup.underline.link" "string.regexp" "string.url" ]; settings.foreground = "#56b6c2"; }
          { scope = [ "entity.name.function" "entity.other.attribute-name.id.css" "meta.function-call.generic" "string.other.link" "support.function" "variable.language.super" ]; settings.foreground = "#61afef"; }
          { scope = [ "meta.brace" "punctuation.accessor" "punctuation.definition.block" "punctuation.separator" "support.type.property-name.css" ]; settings.foreground = "#abb2bf"; }
          { scope = [ "markup.inline" "markup.quote" "source.ini" "string.other.link.description" "string" ]; settings.foreground = "#98c379"; }
          { scope = [ "comment" ]; settings.foreground = "#5c6370"; }
          { scope = [ "keyword.operator.new" "keyword" "markup.italic" "punctuation.definition.block.tag" "storage.modifier" "storage.type" ]; settings.foreground = "#c678dd"; }
          { scope = [ "constant" "entity.other.attribute-name" "keyword.operator.quantifier.regexp" "markup.bold" "support.constant" "variable.other.constant" "variable.parameter" ]; settings.foreground = "#d19a66"; }
          { scope = [ "markup.quote" "markup.italic" ]; settings.fontStyle = "italic"; }
          { scope = [ "heading" "markup.bold" ]; settings.fontStyle = "bold"; }
        ];
      };

      "editor.semanticTokenColorCustomizations" = {
        enabled = true;
        rules = {
          enumMember = "#d19a66";
          property = "#e06c75";
          "variable.defaultLibrary" = "#e5c07b";
        };
      };

      "database-client.autoSync" = true;

      "code-runner.runInTerminal" = true;

      "claudeCode.preferredLocation" = "panel";

      "git.enableSmartCommit" = true;
      "git.autofetch" = true;
      "git.confirmSync" = false;
    } // lib.optionalAttrs (builtins.elem "FreeClaudeCode" vayoriApps) {
      "claudeCode.disableLoginPrompt" = true;
      "claudeCode.environmentVariables" =
        lib.mapAttrsToList (name: value: { inherit name value; }) self.freeClaudeCode.clientEnv;
    }) languageSettings;

    vscodeKeybindings = [
      {
        key = "ctrl+y";
        command = "-editor.action.deleteLines";
        when = "editorTextFocus && !editorReadonly";
      }
    ];

    dmsVscodeThemeVersion = "0.0.3";
    dmsVscodeThemeExtId = "danklinux.dms-theme-${dmsVscodeThemeVersion}";
    dmsVscodeThemeSrc = pkgs.runCommand "dms-theme-vscode-extension" { } ''
      mkdir -p $out
      cd $out
      ${pkgs.unzip}/bin/unzip -q ${inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell}/share/quickshell/dms/matugen/dms-theme.vsix
    '';
  in {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      profiles.default = {
        userSettings = vscodeSettings;
        keybindings = vscodeKeybindings;
        extensions = nixpkgsExtensions ++ marketplaceExtensions;
      };
    };

    home.activation.installDmsVscodeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      extDir="$HOME/.vscode/extensions/${dmsVscodeThemeExtId}"
      if [ ! -f "$extDir/package.json" ]; then
        run rm -rf "$extDir"
        run mkdir -p "$extDir"
        run cp -rL "${dmsVscodeThemeSrc}/extension/." "$extDir/"
        run chmod -R u+w "$extDir"
      fi
    '';

    home.activation.vscodeWakatimeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString hasWakatime ''
        run ${pkgs.crudini}/bin/crudini --set "$HOME/.wakatime.cfg" settings api_key ${lib.escapeShellArg vayoriSecrets.WAKATIME_API_KEY}
      ''
    );
  };
}
