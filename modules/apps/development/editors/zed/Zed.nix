{ self, ... }: {
  flake.homeModules.apps.Zed = { pkgs, lib, vayoriTheme, vayoriApps, vayoriSecrets, ... }:
  let
    hasWakatime = vayoriSecrets.WAKATIME_API_KEY != "REPLACE_ME";

    enabledLanguages = lib.filterAttrs (name: _: builtins.elem name vayoriApps) self.devLanguages;
    languageZed = lib.mapAttrsToList (_: l: l.zed or { }) enabledLanguages;

    languageExtensions = lib.unique (lib.concatMap (v: v.extensions or [ ]) languageZed);
    languageSettings = lib.foldl' lib.recursiveUpdate { } (map (v: v.settings or { }) languageZed);

    extensions = [
      "catppuccin"
      "catppuccin-icons"
      "color-highlight"
      "discord-presence"
      "html"
      "one-dark-pro-enhanced"
      "toml"
    ] ++ languageExtensions ++ lib.optional hasWakatime "wakatime";

    settings = lib.recursiveUpdate {
      git = {
        inline_blame.show_commit_summary = true;
        branch_picker.show_author_name = true;
        disable_git = false;
      };
      git_panel.dock = "left";
      autosave = "on_focus_change";
      icon_theme = "Catppuccin Mocha";
      cli_default_open_behavior = "existing_window";
      project_panel.dock = "left";
      ui_font_weight = 400.0;
      ui_font_family = vayoriTheme.font;
      buffer_font_family = vayoriTheme.font;
      ui_font_size = 16;
      buffer_font_size = 15;
      base_keymap = "JetBrains";
      theme = "DankShell Dark";
      session.trust_all_worktrees = true;
      agent = {
        default_model = {
          provider = "copilot_chat";
          model = "gpt-5-mini";
          enable_thinking = true;
          effort = "high";
        };
        favorite_models = [ ];
        model_parameters = [ ];
      };
      agent_servers = {
        "codex-acp".type = "registry";
        "github-copilot-cli".type = "registry";
      };
    } languageSettings;
  in {
    programs.zed-editor = {
      enable = true;
      inherit extensions;
      userSettings = settings;
    };

    home.activation.zedWakatimeKey = lib.hm.dag.entryAfter [ "writeBoundary" "zedSettingsActivation" ] (
      lib.optionalString hasWakatime ''
        SETTINGS_FILE="$HOME/.config/zed/settings.json"
        WAKATIME_KEY=${lib.escapeShellArg vayoriSecrets.WAKATIME_API_KEY}
        SETTINGS_TMP="$(mktemp)"

        ${pkgs.jq}/bin/jq \
          --arg key "$WAKATIME_KEY" \
          '.lsp.wakatime.initialization_options."api-key" = $key' \
          "$SETTINGS_FILE" > "$SETTINGS_TMP" \
          && run cp "$SETTINGS_TMP" "$SETTINGS_FILE"

        rm -f "$SETTINGS_TMP"
      ''
    );
  };
}
