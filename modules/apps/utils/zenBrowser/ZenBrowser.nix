{ inputs, ... }:
let
  zenExtensionsSpec = [
    { name = "uBlock Origin"; slug = "ublock-origin"; guid = "uBlock0@raymondhill.net"; }
    { name = "Bitwarden Password Manager"; slug = "bitwarden-password-manager"; guid = "{446900e4-71c2-419f-a6a7-df9c091e268b}"; }
    { name = "Buster: Captcha Solver for Humans"; slug = "buster-captcha-solver"; guid = "{e58d3966-3d76-4cd9-8552-1582fbc800c1}"; }
    { name = "Chrome Mask"; slug = "chrome-mask"; guid = "chrome-mask@overengineer.dev"; }
    { name = "Claude Counter"; slug = "claude-counter"; guid = "{cf7799c8-d878-41ff-8005-167bee7ab3d6}"; }
    { name = "Zen Internet"; slug = "zen-internet"; guid = "{91aa3897-2634-4a8a-9092-279db23a7689}"; }
    { name = "ClearURLs"; slug = "clearurls"; guid = "{74145f27-f039-47ce-a470-a662b129930a}"; }
    { name = "Cookie Quick Manager"; slug = "cookie-quick-manager"; guid = "{60f82f00-9ad5-4de5-b31c-b16a47c51558}"; }
    { name = "Dark Reader"; slug = "darkreader"; guid = "addon@darkreader.org"; }
    { name = "Enable Picture-in-Picture"; slug = "enable-picture-in-picture"; guid = "{31a4c81b-add0-4ce4-b6e4-b54dcb0f4d1b}"; }
    { name = "Enhancer for YouTube"; slug = "enhancer-for-youtube"; guid = "enhancerforyoutube@maximerf.addons.mozilla.org"; }
    { name = "FastForward"; slug = "fastforwardteam"; guid = "addon@fastforward.team"; }
    { name = "MAL-Sync"; slug = "mal-sync"; guid = "{c84d89d9-a826-4015-957b-affebd9eb603}"; }
    { name = "Return YouTube Dislike"; slug = "return-youtube-dislikes"; guid = "{762f9885-5a13-4abd-9c77-433dcd38b8fd}"; }
    { name = "SponsorBlock for YouTube"; slug = "sponsorblock"; guid = "sponsorBlocker@ajay.app"; }
    { name = "Tampermonkey"; slug = "tampermonkey"; guid = "firefox@tampermonkey.net"; }
    { name = "Vimium"; slug = "vimium-ff"; guid = "{d7742d87-e61d-4b78-b8a1-b469842139fa}"; }
  ];

  zenModsSpec = {
    "Better Tab Indicators" = "664c54f9-d97d-410b-a479-23dd8a08a628";
    "Cleaned URL bar" = "a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec";
    "Smaller Compact Mode" = "5941aefd-67b0-453d-9b62-9071a31cbb0d";
    "No Sidebar Scrollbar" = "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8";
    "Transparent Zen" = "642854b5-88b4-4c40-b256-e035532109df";
    "Custom uiFont" = "e74cb40a-f3b8-445a-9826-1b1b6e41b846";
    "Extensions List" = "181e41d4-dfd3-410d-9a73-561381a2f77d";
    "Better CtrlTab Panel" = "72f8f48d-86b9-4487-acea-eb4977b18f21";
  };
in {
  flake.pluginPins.ZenBrowser = {
    extensions = zenExtensionsSpec;
    mods = zenModsSpec;
  };

  flake.homeModules.apps.ZenBrowser = { pkgs, lib, vayoriTheme, ... }:
  let
    theme = vayoriTheme;

    mkPrefLines = fn: prefs: lib.concatLines (
      lib.mapAttrsToList (name: value: "${fn}(${builtins.toJSON name}, ${builtins.toJSON value});") prefs
    );

    zenPrefs = {
      "extensions.autoDisableScopes" = 0;
      "extensions.pocket.enabled" = false;
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };

    zenExtensions = zenExtensionsSpec;

    guidOf = name: (lib.findFirst (e: e.name == name)
      (throw "zen-browser.nix: no zenExtensions entry named \"${name}\"")
      zenExtensions).guid;

    zen-browser = pkgs.wrapFirefox
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
      {
        extraPrefs = mkPrefLines "lockPref" zenPrefs;

        extraPolicies = {
          DisableTelemetry = true;
          ExtensionSettings = builtins.listToAttrs (map (e: {
            name = e.guid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${e.slug}/latest.xpi";
              installation_mode = "normal_installed";
            };
          }) zenExtensions);
        };
      };

    zenModsRoot = "https://raw.githubusercontent.com/zen-browser/theme-store/main";
    zenModsBaseUrl = "${zenModsRoot}/themes";
    zenModsIndexUrl = "${zenModsRoot}/themes.json";

    zenMods = zenModsSpec;

    zenSidebarExtensionIds = lib.concatStringsSep "," (
      map guidOf [ "Bitwarden Password Manager" "MAL-Sync" ]
    );

    zenUserPrefs = {
      "zen.urlbar.behavior" = "float";
      "zen.view.compact.enable-at-startup" = true;
      "zen.view.compact.hide-toolbar" = true;
      "zen.view.compact.should-enable-at-startup" = true;
      "zen.view.use-single-toolbar" = false;
      "zen.widget.linux.transparency" = true;
      "zen.view.window.scheme" = 0;

      "sidebar.visibility" = "hide-sidebar";
      "sidebar.installed.extensions" = zenSidebarExtensionIds;
      "sidebar.main.tools" = zenSidebarExtensionIds;

      "browser.tabs.allow_transparent_browser" = true;
      "browser.tabs.loadInBackground" = false;
      "browser.toolbars.bookmarks.visibility" = "always";
      "browser.newtabpage.enabled" = false;
      "browser.ml.enable" = true;

      "signon.rememberSignons" = false;
      "network.prefetch-next" = false;
      "privacy.popups.showBrowserMessage" = false;

      "font.name.serif.x-western" = theme.font;
      "layout.css.prefers-color-scheme.content-override" = 0;

      "mod.cleanedurlbar.customcolor" = "hsl(0 0 10)";
      "mod.cleanedurlbar.customselectcolor" = "rgba(80, 80, 250, 0.75)";
      "mod.cleanedurlbar.customselectfontcolor" = "rgba(255,255,255,1)";
      "mod.cleanedurlbar.customtransparency" = "40%";

      "mod.sameerasw_zen_animations" = "1";
      "mod.sameerasw.zen_bg_blur" = "3px";
      "mod.sameerasw.zen_bg_color_enabled" = false;
      "mod.sameerasw.zen_bg_img_enabled" = false;
      "mod.sameerasw.zen_bg_img_not_fullscreen" = false;
      "mod.sameerasw.zen_bg_img" = "url('https://github.com/sameerasw/my-internet/blob/main/wallpapers/zen-coral-01.jpeg?raw=true')";
      "mod.sameerasw.zen_bg_opacity" = "0.8";
      "mod.sameerasw_zen_compact_sidebar_type" = "0";
      "mod.sameerasw.zen_compact_sidebar_width" = "165px";
      "mod.sameerasw_zen_empty_tab_logo" = "0";
      "mod.sameerasw_zen_light_tint" = "2";
      "mod.sameerasw.zen_no_shadow" = false;
      "mod.sameerasw.zen_notab_img_enabled" = true;
      "mod.sameerasw.zen_notab_img_invert" = false;
      "mod.sameerasw.zen_notab_img_opacity" = "1";
      "mod.sameerasw.zen_notab_img_saturate" = false;
      "mod.sameerasw.zen_notab_img_size" = "150px";
      "mod.sameerasw.zen_notab_img" = "url('https://github.com/sameerasw/my-internet/blob/main/wave-light.png?raw=true')";
      "mod.sameerasw.zen_tab_switch_anim" = true;
      "mod.sameerasw.zen_trackpad_anim" = false;
      "mod.sameerasw.zen_transparency_color" = "#00000000";
      "mod.sameerasw.zen_transparent_glance_enabled" = true;
      "mod.sameerasw.zen_transparent_sidebar_enabled" = true;
      "mod.sameerasw.zen_urlbar_zoom_anim" = false;

      "psu.better_ctrltab.background" = "light-dark(rgba(144, 144, 144, 0.94), rgba(22, 22, 22, 0.92))";
      "psu.better_ctrltab.padding" = "16px";
      "psu.better_ctrltab.preview_border_color" = "light-dark(rgba(255, 255, 255, 0.1), rgba(1, 1, 1, 0.1))";
      "psu.better_ctrltab.preview_border_width" = "1px";
      "psu.better_ctrltab.preview_favicon_outdent" = "12px";
      "psu.better_ctrltab.preview_favicon_size" = "36px";
      "psu.better_ctrltab.preview_focus_background" = "light-dark(rgba(77, 77, 77, 0.8), rgba(204, 204, 204, 0.33))";
      "psu.better_ctrltab.preview_font_size" = "13px";
      "psu.better_ctrltab.preview_letter_spacing" = "0px";
      "psu.better_ctrltab.roundness" = "28px";
      "psu.better_ctrltab.shadow_size" = "18px";
      "psu.better_ctrltab.zoom" = "0.8";
      "network.trr.mode" = 2;
      "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
      "theme.custom_uifont.custom" = theme.font;
      "theme.custom_uifont.default" = "Custom";
      "theme.custom_uifont.shadow" = "none";
      "theme.nosidebarscrollbar.before125b" = true;
      "theme.smaller_compact_mode.sidebar_height" = "50";

      "uc.tabs.custom_color_hex" = "#ffffff";
      "uc.tabs.dim_unloaded" = false;
    };

    zenUserJs = pkgs.writeText "user.js" (mkPrefLines "user_pref" zenUserPrefs);
  in
  {
    home.packages = [ zen-browser ];

    home.activation.zenBrowserConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      fetch_if_missing() {
        if [ -f "$1" ]; then
          echo "  already have $3, skipping"
        else
          echo "  downloading $3..."
          run ${pkgs.curl}/bin/curl -fsSL --retry 2 --max-time 15 -o "$1" "$2" || true
        fi
      }

      ZEN_BASE="$HOME/.zen"
      PROFILE_DIR="$ZEN_BASE/default"
      run mkdir -p "$ZEN_BASE"
      if [ -f "$PROFILE_DIR/times.json" ]; then
        echo "Zen profile already exists, skipping -CreateProfile"
      else
        echo "Creating Zen Browser profile (launches the browser once under a virtual display, up to 120s)..."
        run ${pkgs.coreutils}/bin/timeout 120s ${pkgs.xvfb-run}/bin/xvfb-run -a ${lib.getExe zen-browser} -CreateProfile "default $PROFILE_DIR" >/dev/null 2>&1 || true
        if [ -f "$PROFILE_DIR/times.json" ]; then
          echo "Zen profile created."
        else
          echo "Zen profile creation did not finish in time - mods/settings will be skipped this run, retried next rebuild."
        fi
      fi

      if [ -f "$PROFILE_DIR/times.json" ]; then
        run mkdir -p "$PROFILE_DIR/chrome"
        run ln -sf "$HOME/.config/DankMaterialShell/zen.css" "$PROFILE_DIR/chrome/userChrome.css"
        run ln -sf ${zenUserJs} "$PROFILE_DIR/user.js"

        echo "Fetching Zen mods index..."
        ZEN_MODS_INDEX="$(mktemp)"
        if run ${pkgs.curl}/bin/curl -fsSL --retry 2 --max-time 15 -o "$ZEN_MODS_INDEX" "${zenModsIndexUrl}"; then
          run ${pkgs.jq}/bin/jq --argjson ids ${lib.escapeShellArg (builtins.toJSON (builtins.attrValues zenMods))} '
            to_entries
            | map(select(.key as $k | $ids | index($k) != null))
            | map(.value += {enabled: true})
            | from_entries
          ' "$ZEN_MODS_INDEX" > "$PROFILE_DIR/zen-themes.json"
        else
          echo "  could not reach the mods index, skipping"
        fi
        rm -f "$ZEN_MODS_INDEX"

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: id: ''
          echo "Zen mod: ${name}"
          run mkdir -p "$PROFILE_DIR/chrome/zen-themes/${id}"
          fetch_if_missing "$PROFILE_DIR/chrome/zen-themes/${id}/chrome.css" "${zenModsBaseUrl}/${id}/chrome.css" "${name} (chrome.css)"
          fetch_if_missing "$PROFILE_DIR/chrome/zen-themes/${id}/preferences.json" "${zenModsBaseUrl}/${id}/preferences.json" "${name} (preferences.json)"
        '') zenMods)}
      fi
    '';
  };
}
