{ lib, ... }: {
  options.flake.matugenTemplates = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Raw matugen template content shared across app modules - see modules/desktop/Matugen.nix.";
  };

  config.flake.matugenTemplates = {
    gtk3 = builtins.readFile ./vendor/matugen-gtk/gtk3-colors.css.template;
    gtk4 = builtins.readFile ./vendor/matugen-gtk/gtk4-colors.css.template;

    zed = builtins.readFile ./vendor/matugen-zed/dank-zed-one-dark.json;

    discord = builtins.readFile ../apps/utils/vesktop/vendor/discord.css.template;

    # Spotifast's custom-theme format (docs/_reference/settings-and-files.md
    # in that repo, "Custom themes") - a flat "colors" map, not a nested
    # Material scheme like the old fastpotify-theming fork used, so every
    # key here is chosen for its closest Material tonal role rather than
    # translated one-to-one from the old template.
    spotifast = ''
      {
        "base": "{{mode}}",
        "colors": {
          "window": "{{colors.background.default.hex}}",
          "panel": "{{colors.surface_container_low.default.hex}}",
          "surface": "{{colors.surface_container.default.hex}}",
          "surface_hover": "{{colors.surface_container_high.default.hex}}",
          "surface_active": "{{colors.surface_container_highest.default.hex}}",
          "outline": "{{colors.outline.default.hex}}",
          "text": "{{colors.on_surface.default.hex}}",
          "secondary": "{{colors.on_surface_variant.default.hex}}",
          "dim": "{{colors.outline_variant.default.hex}}",
          "accent": "{{colors.primary.default.hex}}",
          "accent_hover": "{{colors.primary_fixed.default.hex}}",
          "on_accent": "{{colors.on_primary.default.hex}}",
          "danger": "{{colors.error.default.hex}}",
          "warning": "{{colors.tertiary.default.hex}}",
          "overlay": "{{colors.scrim.default.hex}}",
          "shadow": "{{colors.shadow.default.hex}}"
        }
      }
    '';

    btop = ''
      theme[main_bg]=""
      theme[main_fg]="{{colors.on_surface.default.hex}}"
      theme[title]="{{colors.primary.default.hex}}"
      theme[hi_fg]="{{colors.secondary.default.hex}}"
      theme[selected_bg]="{{colors.primary.default.hex}}"
      theme[selected_fg]="{{colors.on_primary.default.hex}}"
      theme[inactive_fg]="{{colors.on_surface_variant.default.hex}}"
      theme[proc_misc]="{{colors.tertiary.default.hex}}"
      theme[cpu_box]="{{colors.outline.default.hex}}"
      theme[mem_box]="{{colors.outline.default.hex}}"
      theme[net_box]="{{colors.outline.default.hex}}"
      theme[proc_box]="{{colors.outline.default.hex}}"
      theme[div_line]="{{colors.outline_variant.default.hex}}"
      theme[temp_start]="{{colors.secondary.default.hex}}"
      theme[temp_mid]="{{colors.primary.default.hex}}"
      theme[temp_end]="{{colors.error.default.hex}}"
      theme[cpu_start]="{{colors.secondary.default.hex}}"
      theme[cpu_mid]="{{colors.primary.default.hex}}"
      theme[cpu_end]="{{colors.error.default.hex}}"
      theme[free_start]="{{colors.secondary.default.hex}}"
      theme[free_mid]=""
      theme[free_end]="{{colors.secondary_container.default.hex}}"
      theme[cached_start]="{{colors.tertiary.default.hex}}"
      theme[cached_mid]=""
      theme[cached_end]="{{colors.tertiary_container.default.hex}}"
      theme[available_start]="{{colors.primary.default.hex}}"
      theme[available_mid]=""
      theme[available_end]="{{colors.primary_container.default.hex}}"
      theme[used_start]="{{colors.error.default.hex}}"
      theme[used_mid]=""
      theme[used_end]="{{colors.error_container.default.hex}}"
      theme[download_start]="{{colors.secondary.default.hex}}"
      theme[download_mid]="{{colors.primary.default.hex}}"
      theme[download_end]="{{colors.tertiary.default.hex}}"
      theme[upload_start]="{{colors.secondary.default.hex}}"
      theme[upload_mid]="{{colors.primary.default.hex}}"
      theme[upload_end]="{{colors.tertiary.default.hex}}"
    '';
    cava = ''
      [color]
      background = 'default'
      foreground = '{{colors.primary.default.hex}}'

      ; gradient = 0
      gradient = 1
      gradient_color_1 = '{{colors.primary_container.default.hex}}'
      gradient_color_2 = '{{colors.primary.default.hex}}'
      gradient_color_3 = '{{colors.on_primary_container.default.hex}}'

      horizontal_gradient = 0
      ; horizontal_gradient = 1
      horizontal_gradient_color_1 = '{{colors.primary_container.default.hex}}'
      horizontal_gradient_color_2 = '{{colors.primary.default.hex}}'
      horizontal_gradient_color_3 = '{{colors.on_primary_container.default.hex}}'
      horizontal_gradient_color_4 = '{{colors.primary.default.hex}}'
      horizontal_gradient_color_5 = '{{colors.primary_container.default.hex}}'
    '';

    heroic = ''
      body.matugen {
        --accent: {{colors.tertiary.default.hex}};
        --accent-overlay: {{colors.inverse_primary.default.hex}};

        --primary: {{colors.primary.default.hex}};
        --primary-hover: {{colors.primary_container.default.hex}};
        --navbar-accent: var(--primary);

        --background: {{colors.background.default.hex}};
        --body-background: {{colors.surface.default.hex}};
        --navbar-background: {{colors.surface_container.default.hex}};

        --background-darker: var(--background);
        --current-background: var(--body-background);
        --navbar-active-background: {{colors.surface_container_high.default.hex}};

        --gradient-body-background: linear-gradient(
          90deg,
          var(--background-darker) -32px,
          var(--body-background) 64px,
          var(--body-background) 100%
        );

        --input-background: var(--navbar-background);
        --modal-background: var(--body-background);
        --modal-border: var(--body-background);

        --success: {{colors.tertiary.default.hex}};
        --success-hover: {{colors.tertiary_container.default.hex}};
        --danger: {{colors.error.default.hex}};
        --danger-hover: {{colors.error_container.default.hex}};

        --text-default: {{colors.on_surface.default.hex}};
        --text-title: {{colors.on_surface.default.hex}};
        --text-secondary: {{colors.on_surface_variant.default.hex}};
        --text-tertiary: {{colors.on_tertiary.default.hex}};
        --text-hover: {{colors.primary.default.hex}};

        --action-icon: {{colors.on_surface.default.hex}};
        --action-icon-hover: {{colors.primary.default.hex}};
        --action-icon-active: {{colors.primary_container.default.hex}};
        --icons-background: {{colors.surface_variant.default.hex}};
        --icon-disabled: {{colors.on_surface_variant.default.hex}};

        --anticheat-denied: var(--danger);
        --anticheat-broken: var(--accent);
        --anticheat-running: var(--primary);
        --anticheat-supported: var(--success);
        --anticheat-planned: {{colors.secondary.default.hex}};

        --neutral-06: {{colors.on_surface_variant.default.hex}};
        --gamecard-title-color: {{colors.surface_container.default.hex}}cc;
        --secondary-button: var(--accent);
        --tertiary-button: var(--primary);
      }
    '';

    steam = ''
      /*
      * GTK 4 Colors
      * Converted from Matugen template
      */

      :root {
          --adw-accent-rgb: {{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }};
          --adw-accent-bg-rgb: {{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }};
          --adw-accent-fg-rgb: {{ colors.on_primary.default.red }} {{ colors.on_primary.default.green }} {{ colors.on_primary.default.blue }};

          --adw-window-bg-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
          --adw-window-fg-rgb: {{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }};

          --adw-headerbar-bg-rgb: {{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }};
          --adw-headerbar-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-popover-bg-rgb: {{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }};
          --adw-popover-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-view-bg-rgb: {{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }};
          --adw-view-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-card-bg-rgb: {{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }};
          --adw-card-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-sidebar-bg-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
          --adw-sidebar-fg-rgb: {{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }};
          --adw-sidebar-border-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
          --adw-sidebar-backdrop-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
      }
    '';

    wine = ''
      Windows Registry Editor Version 5.00

      [HKEY_CURRENT_USER\Software\Wine\X11 Driver]
      "Decorated"="N"

      [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes]
      "AppsUseClassicTheme"=dword:00000001

      [HKEY_CURRENT_USER\Control Panel\Colors]
      "ActiveBorder"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ActiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "AppWorkSpace"="{{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }}"
      "Background"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"

      "ButtonAlternativeFace"="{{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }}"
      "ButtonDkShadow"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonFace"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonHilight"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonLight"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonShadow"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "GradientActiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "GradientInactiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "GrayText"="{{ colors.secondary_container.default.red }} {{ colors.secondary_container.default.green }} {{ colors.secondary_container.default.blue }}"

      "Hilight"="{{ colors.primary_container.default.red }} {{ colors.primary_container.default.green }} {{ colors.primary_container.default.blue }}"
      "HilightText"="{{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }}"

      "InactiveBorder"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "InactiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "InactiveTitleText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "InfoText"="{{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }}"
      "InfoWindow"="{{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }}"

      "Menu"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "MenuBar"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "MenuHilight"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "MenuText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "Scrollbar"="{{ colors.surface_container_low.default.red }} {{ colors.surface_container_low.default.green }} {{ colors.surface_container_low.default.blue }}"
      "TitleText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "Window"="{{ colors.surface_container_low.default.red }} {{ colors.surface_container_low.default.green }} {{ colors.surface_container_low.default.blue }}"
      "WindowFrame"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "WindowText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"
    '';

    androidStudio = schemeName: ''
      <scheme name="${schemeName}" version="142" parent_scheme="Darcula">
        <metaInfo>
          <property name="created">Generated by matugen via DankMaterialShell</property>
          <property name="ide">idea</property>
          <property name="originalScheme">${schemeName}</property>
        </metaInfo>
        <colors>
          <option name="CARET_COLOR" value="{{colors.primary.default.hex_stripped}}" />
          <option name="CARET_ROW_COLOR" value="{{colors.surface_container.default.hex_stripped}}" />
          <option name="GUTTER_BACKGROUND" value="{{colors.surface.default.hex_stripped}}" />
          <option name="INDENT_GUIDE" value="{{colors.outline_variant.default.hex_stripped}}" />
          <option name="LINE_NUMBERS_COLOR" value="{{colors.on_surface_variant.default.hex_stripped}}" />
          <option name="RIGHT_MARGIN_COLOR" value="{{colors.outline_variant.default.hex_stripped}}" />
          <option name="SELECTION_BACKGROUND" value="{{colors.primary_container.default.hex_stripped}}" />
          <option name="SELECTION_FOREGROUND" value="{{colors.on_primary_container.default.hex_stripped}}" />
          <option name="TEARLINE_COLOR" value="{{colors.outline_variant.default.hex_stripped}}" />
        </colors>
        <!-- Code token colors are imported wholesale, verbatim, from
             the one-dark-theme plugin's own editor scheme file
             (one_dark.xml, the same file both the "One Dark" and
             "One Dark Islands" themeProviders point to) rather than
             a hand-picked subset or matugen placeholders - this
             covers every language the plugin styles (Java, Kotlin,
             XML, JSON, YAML, etc), not just Dart. DART_* keys are
             appended at the end since the Dart plugin predates this
             file and defines its own separate attribute keys the
             base One Dark scheme has no opinion on; parent_scheme
             stays "Darcula" (guaranteed to resolve) rather than
             "One Dark" itself, which the plugin only exposes as a
             themeProvider side-effect, not an independently
             resolvable named scheme. -->
        <attributes>
            <option name="ANNOTATION_ATTRIBUTE_NAME_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="ANNOTATION_NAME_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="APACHE_CONFIG.IDENTIFIER">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="BAD_CHARACTER">
              <value>
                <option name="BACKGROUND" value="9b3636"/>
              </value>
            </option>
            <option name="BASH.BINARY_DATA">
              <value>
                <option name="FOREGROUND" value=""/>
              </value>
            </option>
            <option name="BASH.CONDITIONAL">
              <value>
                <option name="FOREGROUND" value=""/>
              </value>
            </option>
            <option name="BASH.EXTERNAL_COMMAND">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="BASH.FUNCTION_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="BASH.HERE_DOC">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="BASH.HERE_DOC_END">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="BASH.HERE_DOC_START">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_OPERATION_SIGN" name="BASH.REDIRECTION"/>
            <option name="BASH.SHEBANG">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="BLADE_DIRECTIVE">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="BOOKMARKS_ATTRIBUTES">
              <value/>
            </option>
            <option name="BREADCRUMBS_CURRENT">
              <value>
                <option name="BACKGROUND" value="353a46"/>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="BREADCRUMBS_DEFAULT">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="BREADCRUMBS_HOVERED">
              <value>
                <option name="BACKGROUND" value="444b5a"/>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="BREADCRUMBS_INACTIVE">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="BREAKPOINT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="743d3d"/>
              </value>
            </option>
            <option name="BUILDOUT.KEY">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="CLASS_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.BOOLEAN">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.CLASS_NAME">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.EXPRESSIONS_SUBSTITUTION_MARK">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.FUNCTION">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.FUNCTION_BINDING">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option baseAttributes="JS.GLOBAL_VARIABLE" name="COFFEESCRIPT.GLOBAL_VARIABLE"/>
            <option name="COFFEESCRIPT.HEREGEX_CONTENT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.HEREGEX_ID">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.REGULAR_EXPRESSION_CONTENT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.REGULAR_EXPRESSION_FLAG">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.REGULAR_EXPRESSION_ID">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="COFFEESCRIPT.STRING">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="CONDITIONALLY_NOT_COMPILED">
              <value>
                <option name="FOREGROUND" value="59626f"/>
              </value>
            </option>
            <option name="CONSOLE_BLACK_OUTPUT">
              <value>
                <option name="FOREGROUND" value="000000"/>
              </value>
            </option>
            <option name="CONSOLE_BLUE_BRIGHT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CONSOLE_BLUE_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="CONSOLE_CYAN_BRIGHT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CONSOLE_CYAN_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="CONSOLE_DARKGRAY_OUTPUT">
              <value>
                <option name="FOREGROUND" value="464c55"/>
              </value>
            </option>
            <option name="CONSOLE_ERROR_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="CONSOLE_GRAY_OUTPUT">
              <value>
                <option name="ERROR_STRIPE_COLOR" value="21252b"/>
                <option name="FOREGROUND" value="646a73"/>
              </value>
            </option>
            <option name="CONSOLE_GREEN_BRIGHT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CONSOLE_GREEN_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="CONSOLE_MAGENTA_BRIGHT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CONSOLE_MAGENTA_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="CONSOLE_NORMAL_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="CONSOLE_RANGE_TO_EXECUTE">
              <value>
                <option name="EFFECT_COLOR" value="#5c6370"/>
              </value>
            </option>
            <option name="CONSOLE_RED_BRIGHT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CONSOLE_RED_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="CONSOLE_SYSTEM_OUTPUT">
              <value>
                <option name="FOREGROUND" value="e7f2ff"/>
              </value>
            </option>
            <option name="CONSOLE_USER_INPUT">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="CONSOLE_WHITE_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="CONSOLE_YELLOW_BRIGHT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CONSOLE_YELLOW_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="CONSTRUCTOR_CALL_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="CSS.COLOR">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="CSS.FUNCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="CSS.HASH">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="CSS.IDENT">
              <value>
                <option name="FOREGROUND" value="d39a63"/>
              </value>
            </option>
            <option name="CSS.IMPORTANT">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="CSS.KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="CSS.PROPERTY_NAME">
              <value/>
            </option>
            <option name="CSS.PROPERTY_VALUE">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="CSS.PSEUDO">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="CSS.TAG_NAME">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="CSS.URL">
              <value>
                <option name="EFFECT_COLOR" value="#d19a66"/>
                <option name="FOREGROUND" value="#d19a66"/>
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_1">
              <value>
                <option name="FOREGROUND" value="#f44747" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_2">
              <value>
                <option name="FOREGROUND" value="#61afef" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_3">
              <value>
                <option name="FOREGROUND" value="#98c379" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_4">
              <value>
                <option name="FOREGROUND" value="#56b6c2" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_5">
              <value>
                <option name="FOREGROUND" value="#c678dd" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_6">
              <value>
                <option name="FOREGROUND" value="#98c379" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_7">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_8">
              <value>
                <option name="FOREGROUND" value="#e06c75" />
              </value>
            </option>
            <option name="CSV_PLUGIN_COLUMN_COLORING_ATTRIBUTE_9">
              <value>
                <option name="FOREGROUND" value="#d19a66" />
              </value>
            </option>
            <option name="CTRL_CLICKABLE">
              <value>
                <option name="EFFECT_COLOR" value="#61afef"/>
                <option name="FOREGROUND" value="#61afef"/>
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="CUSTOM_KEYWORD1_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="CUSTOM_KEYWORD2_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="CUSTOM_KEYWORD3_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="CUSTOM_KEYWORD4_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="CUSTOM_STRING_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="CUSTOM_VALID_STRING_ESCAPE_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option baseAttributes="CLASS_NAME_ATTRIBUTES" name="Class"/>
            <option name="Clojure Atom">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="Clojure Character">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="Clojure Keyword">
              <value>
                <option name="FOREGROUND" value="df6a73"/>
              </value>
            </option>
            <option name="Clojure Line comment">
              <value>
                <option name="FOREGROUND" value="59626f"/>
              </value>
            </option>
            <option name="Clojure Literal">
              <value>
                <option name="FOREGROUND" value="fda5ff"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="Clojure Numbers">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="Clojure Strings">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="DART_ENUM_CONSTANT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="DART_INSTANCE_GETTER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DART_INSTANCE_SETTER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DART_LOCAL_FUNCTION_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DART_LOCAL_FUNCTION_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DART_STATIC_GETTER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DART_STATIC_SETTER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DEBUGGER_INLINED_VALUES">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="DEBUGGER_INLINED_VALUES_EXECUTION_LINE">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="DEBUGGER_INLINED_VALUES_MODIFIED">
              <value>
                <option name="FOREGROUND" value="ff8c00"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="DEFAULT_ATTRIBUTE">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="DEFAULT_BLOCK_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="DEFAULT_CLASS_NAME">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="DEFAULT_CLASS_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="DEFAULT_COMMA">
              <value/>
            </option>
            <option name="DEFAULT_CONSTANT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="DEFAULT_DOC_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="DEFAULT_DOC_COMMENT_TAG">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="DEFAULT_DOC_COMMENT_TAG_VALUE">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="DEFAULT_ENTITY">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="DEFAULT_FUNCTION_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DEFAULT_FUNCTION_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DEFAULT_GLOBAL_VARIABLE">
              <value>
                <option name="FOREGROUND" value="#e06c75" />
              </value>
            </option>
            <option name="DEFAULT_IDENTIFIER">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="DEFAULT_INSTANCE_FIELD">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="DEFAULT_INTERFACE_NAME">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="DEFAULT_INVALID_STRING_ESCAPE">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="FOREGROUND" value="#56b6c2"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="DEFAULT_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="DEFAULT_LABEL">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="DEFAULT_LINE_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="DEFAULT_METADATA">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="DEFAULT_NUMBER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="DEFAULT_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_LOCAL_VARIABLE" name="DEFAULT_REASSIGNED_LOCAL_VARIABLE"/>
            <option name="DEFAULT_REASSIGNED_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="DEFAULT_SEMICOLON">
              <value/>
            </option>
            <option name="DEFAULT_STATIC_FIELD">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="DEFAULT_STATIC_METHOD">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DEFAULT_STRING">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="DEFAULT_TEMPLATE_LANGUAGE_COLOR">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="DEFAULT_VALID_STRING_ESCAPE">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="DELETED_TEXT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="692424"/>
              </value>
            </option>
            <option name="DEPRECATED_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#abb2bf"/>
                <option name="EFFECT_TYPE" value="3"/>
              </value>
            </option>
            <option name="DIFF_CONFLICT">
              <value>
                <option name="BACKGROUND" value="913a3a"/>
                <option name="ERROR_STRIPE_COLOR" value="#e06c75"/>
              </value>
            </option>
            <option name="DIFF_DELETED">
              <value>
                <option name="BACKGROUND" value="353c46"/>
                <option name="ERROR_STRIPE_COLOR" value="#5c6370"/>
              </value>
            </option>
            <option name="DIFF_INSERTED">
              <value>
                <option name="BACKGROUND" value="2d4134"/>
                <option name="ERROR_STRIPE_COLOR" value="#98c379"/>
              </value>
            </option>
            <option name="DIFF_MODIFIED">
              <value>
                <option name="BACKGROUND" value="2c4957"/>
                <option name="ERROR_STRIPE_COLOR" value="#61afef"/>
              </value>
            </option>
            <option name="DJANGO_FILTER">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="DJANGO_TAG_NAME">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="DJANGO_TAG_START_END">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="DOCKER_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="DUPLICATE_FROM_SERVER">
              <value/>
            </option>
            <option name="EDITORCONFIG_VARIABLE">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="EJS_OPEN">
              <value>
                <option name="FOREGROUND" value="#98c379" />
              </value>
            </option>
            <option name="EJS_OPEN_EQ">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="EJS_OPEN_EQ_EQ">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="EJS_OPEN_EQ_GENERATOR">
              <value>
                <option name="FOREGROUND" value="#61afef" />
              </value>
            </option>
            <option name="EJS_OPEN_FILTER">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="EL.BOUNDS">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="ENUM_CONST">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="ERRORS_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="ERROR_STRIPE_COLOR" value="#f44747"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="EVALUATED_EXPRESSION_ATTRIBUTES">
              <value/>
            </option>
            <option name="EVALUATED_EXPRESSION_EXECUTION_LINE_ATTRIBUTES">
              <value/>
            </option>
            <option name="EXECUTIONPOINT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="c7c7ff"/>
                <option name="FOREGROUND" value="000000"/>
              </value>
            </option>
            <option name="FIRST SYMBOL IN LIST">
              <value>
                <option name="FOREGROUND" value="df6a73"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="FOLDED_TEXT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="313741"/>
                <option name="FOREGROUND" value="878e9b"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="FOLLOWED_HYPERLINK_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#c678dd"/>
                <option name="FOREGROUND" value="#c678dd"/>
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="GENERIC_SERVER_ERROR_OR_WARNING">
              <value>
                <option name="EFFECT_COLOR" value="ff8c00"/>
                <option name="ERROR_STRIPE_COLOR" value="ff8c00"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="GHERKIN_OUTLINE_PARAMETER_SUBSTITUTION">
              <value>
                <option name="FOREGROUND" value="#61afef" />
                <option name="FONT_TYPE" value="1" />
              </value>
            </option>
            <option name="GHERKIN_REGEXP_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="GHERKIN_TABLE_PIPE">
              <value/>
            </option>
            <option name="GO_BLOCK_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="GO_BUILTIN_CONSTANT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="GO_BUILTIN_FUNCTION_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="GO_BUILTIN_TYPE">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="GO_BUILTIN_TYPE_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_GLOBAL_VARIABLE" name="GO_BUILTIN_VARIABLE"/>
            <option name="GO_EXPORTED_FUNCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="GO_EXPORTED_FUNCTION_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="GO_FUNCTION_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="GO_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="GO_LINE_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="GO_LOCAL_FUNCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="GO_LOCAL_FUNCTION_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="GO_METHOD_RECEIVER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_IDENTIFIER" name="GO_PACKAGE"/>
            <option name="GO_TYPE_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="GQL_ID">
              <value/>
            </option>
            <option baseAttributes="METHOD_DECLARATION_ATTRIBUTES" name="Groovy method declaration"/>
            <option name="HAML_CLASS">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="HAML_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="HAML_FILTER">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_TEMPLATE_LANGUAGE_COLOR" name="HAML_FILTER_CONTENT"/>
            <option name="HAML_ID">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="HAML_RUBY_CODE">
              <value/>
            </option>
            <option name="HAML_STRING_INTERPOLATED">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="HAML_TAG">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="HAML_TAG_NAME">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="HAML_TEXT">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_TEMPLATE_LANGUAGE_COLOR" name="HAML_XHTML"/>
            <option name="HTML_ATTRIBUTE_NAME">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="HTML_ATTRIBUTE_VALUE">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="HTML_ENTITY_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_TAG" name="HTML_TAG"/>
            <option name="HTML_TAG_NAME">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="HTTP_REQUEST_INPUT_FILE">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="HTTP_REQUEST_MESSAGE_BODY">
              <value>
                <option name="FOREGROUND" value="#56b6c2" />
              </value>
            </option>
            <option name="HTTP_REQUEST_PARAMETER_NAME">
              <value>
                <option name="FOREGROUND" value="#98c379" />
              </value>
            </option>
            <option name="HTTP_REQUEST_PARAMETER_VALUE">
              <value>
                <option name="FOREGROUND" value="#56b6c2" />
              </value>
            </option>
            <option name="HTTP_REQUEST_VARIABLE_BRACES">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="HYPERLINK_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#c678dd"/>
                <option name="FOREGROUND" value="#c678dd"/>
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="IDENTIFIER_UNDER_CARET_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="353940"/>
                <option name="ERROR_STRIPE_COLOR" value="4d78cc" />
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="IMPLICIT_ANONYMOUS_CLASS_PARAMETER_ATTRIBUTES">
              <value/>
            </option>
            <option name="INACTIVE_HYPERLINK_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#abb2bf"/>
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="INFO_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#e5c07b"/>
                <option name="ERROR_STRIPE_COLOR" value="#e5c07b"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="INI.SECTION">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="INJECTED_LANGUAGE_FRAGMENT">
              <value>
                <option name="BACKGROUND" value="2d3139"/>
              </value>
            </option>
            <option name="INLAY_DEFAULT">
              <value>
                <option name="BACKGROUND" value="303640"/>
                <option name="FOREGROUND" value="#7e8491"/>
              </value>
            </option>
            <option name="INLINE_PARAMETER_HINT">
              <value>
                <option name="BACKGROUND" value="303640"/>
                <option name="FOREGROUND" value="#7e8491"/>
              </value>
            </option>
            <option name="INLINE_PARAMETER_HINT_CURRENT">
              <value>
                <option name="BACKGROUND" value="3d424b"/>
                <option name="FOREGROUND" value="#a0a7b4"/>
              </value>
            </option>
            <option name="INLINE_PARAMETER_HINT_HIGHLIGHTED">
              <value>
                <option name="BACKGROUND" value="3d424b"/>
                <option name="FOREGROUND" value="#a0a7b4"/>
              </value>
            </option>
            <option name="IVAR">
              <value>
                <option name="FOREGROUND" value="df6a73"/>
              </value>
            </option>
            <option name="JADE_FILE_PATH">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="JADE_FILTER_NAME">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_IDENTIFIER" name="JADE_JS_BLOCK"/>
            <option name="JADE_STATEMENTS">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="JADE_TAG_CLASS">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="JADE_TAG_ID">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="JAVA_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="JAVA_STRING">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="JAVA_VALID_STRING_ESCAPE">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="JS.ATTRIBUTE">
              <value>
                <option name="BACKGROUND" value="423535"/>
              </value>
            </option>
            <option name="JS.GLOBAL_FUNCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_GLOBAL_VARIABLE" name="JS.GLOBAL_VARIABLE"/>
            <option baseAttributes="DEFAULT_INSTANCE_METHOD" name="JS.INSTANCE_MEMBER_FUNCTION"/>
            <option baseAttributes="DEFAULT_LOCAL_VARIABLE" name="JS.LOCAL_VARIABLE"/>
            <option name="JS.MODULE_NAME">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="JS.REGEXP">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="JSON.KEYWORD">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="JSON.PROPERTY_KEY">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="JSP_DIRECTIVE_NAME">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="JUPYTER.SAUSAGE_BUTTON_APPEARANCE">
              <value>
                <option name="FOREGROUND" value="a0a7b4" />
                <option name="BACKGROUND" value="3d424b" />
              </value>
            </option>
            <option name="JUPYTER_SELECTED_CELL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="KOTLIN_ABSTRACT_CLASS">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option baseAttributes="ANNOTATION_NAME_ATTRIBUTES" name="KOTLIN_ANNOTATION"/>
            <option name="KOTLIN_BACKING_FIELD_VARIABLE">
              <value/>
            </option>
            <option name="KOTLIN_CLOSURE_DEFAULT_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="KOTLIN_DYNAMIC_FUNCTION_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="KOTLIN_DYNAMIC_PROPERTY_CALL">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="KOTLIN_ENUM_ENTRY">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="KOTLIN_FUNCTION_LITERAL_BRACES_AND_ARROW">
              <value/>
            </option>
            <option name="KOTLIN_LABEL">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="KOTLIN_MUTABLE_VARIABLE">
              <value>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="KOTLIN_NAMED_ARGUMENT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_STATIC_METHOD" name="KOTLIN_PACKAGE_FUNCTION_CALL"/>
            <option name="KOTLIN_SMART_CAST_RECEIVER">
              <value/>
            </option>
            <option name="KOTLIN_SMART_CAST_VALUE">
              <value/>
            </option>
            <option name="KOTLIN_SMART_CONSTANT">
              <value/>
            </option>
            <option name="KOTLIN_TYPE_ALIAS">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="KOTLIN_TYPE_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="KOTLIN_VARIABLE_AS_FUNCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="KOTLIN_VARIABLE_AS_FUNCTION_LIKE">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="LABEL">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="LESS_VARIABLE">
              <value>
                <option name="FOREGROUND" value="#e06c75" />
              </value>
            </option>
            <option name="LINE_FULL_COVERAGE">
              <value>
                <option name="FOREGROUND" value="354a3d"/>
              </value>
            </option>
            <option name="LINE_NONE_COVERAGE">
              <value>
                <option name="FOREGROUND" value="46333c"/>
              </value>
            </option>
            <option name="LINE_PARTIAL_COVERAGE">
              <value>
                <option name="FOREGROUND" value="2c4957"/>
              </value>
            </option>
            <option name="LIVE_TEMPLATE_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
              </value>
            </option>
            <option name="LOCALE.MSGCTXT_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="LOCALE.MSGID_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="LOCALE.MSGID_PLURAL_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="LOCALE.MSGSTR_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="LOCALE.MSGSTR_PLURAL_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="LOGCAT_ASSERT_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e06c75" />
                <option name="EFFECT_COLOR" value="ffffff" />
                <option name="EFFECT_TYPE" value="1" />
              </value>
            </option>
            <option name="LOGCAT_DEBUG_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#56b6c2" />
              </value>
            </option>
            <option name="LOGCAT_INFO_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#98c379" />
              </value>
            </option>
            <option name="LOGCAT_VERBOSE_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#61afef" />
              </value>
            </option>
            <option name="LOGCAT_WARNING_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="LOG_DEBUG_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="LOG_ERROR_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="LOG_INFO_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="LOG_VERBOSE_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="LOG_WARNING_OUTPUT">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="List/map to object conversion">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="MACRONAME">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="MAGIC_MEMBER_ACCESS">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_TEMPLATE_LANGUAGE_COLOR" name="MAKO.SUBSTITUTION"/>
            <option name="MAKO.TAG">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="MARKDOWN_BOLD">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="MARKDOWN_CODE_SPAN">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="MARKDOWN_CODE_SPAN_MARKER">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="MARKDOWN_HEADER_LEVEL_1">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="MARKDOWN_HEADER_LEVEL_2">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="MARKDOWN_HEADER_LEVEL_3">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="MARKDOWN_HEADER_LEVEL_4">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="MARKDOWN_HEADER_LEVEL_5">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="MARKDOWN_HEADER_LEVEL_6">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="MARKDOWN_ITALIC">
              <value>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="MARKDOWN_LINK_TITLE">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="MARKDOWN_TABLE_SEPARATOR">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="MARKED_FOR_REMOVAL_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="EFFECT_TYPE" value="3"/>
              </value>
            </option>
            <option name="MATCHED_BRACE_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="515a6b"/>
              </value>
            </option>
            <option name="MESSAGE_ARGUMENT">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="NG.BANANA_BINDING_ATTR_NAME">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="NG.EVENT_BINDING_ATTR_NAME">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="NG.PROPERTY_BINDING_ATTR_NAME">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="NG.TEMPLATE_BINDINGS_ATTR_NAME">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="NOT_USED_ELEMENT_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="7f8591"/>
              </value>
            </option>
            <option name="OC.CLASS_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="OC.CONDITIONALLY_NOT_COMPILED">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="OC.CPP_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="OC.DIRECTIVE">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="OC.LABEL">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="OC.MACRONAME">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="OC.MACRO_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="OC.MESSAGE_ARGUMENT">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="OC.METHOD_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="OC.OVERLOADED_OPERATOR">
              <value/>
            </option>
            <option name="OC.PROPERTY">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="OC.PROPERTY_ATTRIBUTE">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="OC.PROTOCOL_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="OC.STRUCT_FIELD">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="OC.STRUCT_LIKE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="OC.TYPEDEF">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="OC_FORMAT_TOKEN">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="PHP_ALIAS_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="PHP_CONSTANT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="PHP_EXEC_COMMAND_ID">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="PHP_HEREDOC_ID">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="PHP_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="PHP_PREDEFINED SYMBOL">
              <value>
                <option name="FOREGROUND" value="#61afef" />
              </value>
            </option>
            <option name="PHP_SCRIPTING_BACKGROUND">
              <value/>
            </option>
            <option baseAttributes="DEFAULT_LOCAL_VARIABLE" name="PHP_VAR"/>
            <option name="PROPERTIES.INVALID_STRING_ESCAPE">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="FOREGROUND" value="#56b6c2"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="PROPERTIES.KEY">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_OPERATION_SIGN" name="PROPERTIES.KEY_VALUE_SEPARATOR"/>
            <option name="PROPERTIES.VALID_STRING_ESCAPE">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="PROTOCOL_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="PUPPET_CLASS">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="PUPPET_HEREDOC_TAGS">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="PUPPET_REGEX">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="PUPPET_VARIABLE">
              <value/>
            </option>
            <option name="PY.ANNOTATION">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="PY.BUILTIN_NAME">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="PY.DECORATOR">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="PY.KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="PY.KEYWORD_ARGUMENT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="PY.PREDEFINED_DEFINITION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="PY.PREDEFINED_USAGE">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="PY.SELF_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="PY.STRING">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="PY.STRING.B">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="RDOC_DIRECTIVE">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="RDOC_EMAIL">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="RDOC_HEADINGS">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="RDOC_IDENTIFIER">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="RDOC_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="RDOC_URL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="REGEXP.BRACES">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="REGEXP.BRACKETS">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="REGEXP.CHAR_CLASS">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="REGEXP.ESC_CHARACTER">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="REGEXP.META">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="REGEXP.PARENTHS">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="REGEXP.QUOTE_CHARACTER">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="REGEXP.REDUNDANT_ESCAPE">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="REST.EXPLICIT">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="REST.FIELD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="REST.FIXED">
              <value>
                <option name="BACKGROUND" value="3d424b"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_IDENTIFIER" name="REST.INLINE"/>
            <option name="REST.INTERPRETED">
              <value>
                <option name="BACKGROUND" value="3c4b33"/>
              </value>
            </option>
            <option name="REST.SECTION.HEADER">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option baseAttributes="HTML_COMMENT" name="RHTML_COMMENT_ID"/>
            <option name="RHTML_EXPRESSION_END_ID">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="RHTML_EXPRESSION_START_ID">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="RHTML_OMIT_NEW_LINE_ID">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="RMARKDOWN_CHUNK">
              <value>
                <option name="BACKGROUND" value="2d3139" />
              </value>
            </option>
            <option name="RHTML_SCRIPTING_BACKGROUND_ID">
              <value/>
            </option>
            <option name="RHTML_SCRIPTLET_END_ID">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="RHTML_SCRIPTLET_START_ID">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="RUBY_BAD_CHARACTER">
              <value>
                <option name="BACKGROUND" value="9b3636"/>
              </value>
            </option>
            <option name="RUBY_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="RUBY_CONSTANT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="RUBY_CONSTANT_DECLARATION">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="RUBY_ESCAPE_SEQUENCE">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="RUBY_EXPR_IN_STRING">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_GLOBAL_VARIABLE" name="RUBY_GVAR"/>
            <option name="RUBY_HEREDOC_CONTENT">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="RUBY_HEREDOC_ID">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="RUBY_INVALID_ESCAPE_SEQUENCE">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="FOREGROUND" value="#56b6c2"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="RUBY_LINE_CONTINUATION">
              <value/>
            </option>
            <option name="RUBY_LOCAL_VAR_ID">
              <value>
                <option name="FOREGROUND" value="#d19a66" />
              </value>
            </option>
            <option baseAttributes="DEFAULT_INSTANCE_METHOD" name="RUBY_METHOD_NAME"/>
            <option name="RUBY_NTH_REF">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="RUBY_NUMBER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_STATIC_METHOD" name="RUBY_PARAMDEF_CALL"/>
            <option name="RUBY_PARAMETER_ID">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="RUBY_REGEXP">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_STATIC_METHOD" name="RUBY_SPECIFIC_CALL"/>
            <option name="RUBY_SYMBOL">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="RUBY_WORDS">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="RUNTIME_ERROR">
              <value>
                <option name="EFFECT_COLOR" value="ff8c00"/>
                <option name="ERROR_STRIPE_COLOR" value="#f44747"/>
                <option name="EFFECT_TYPE" value="5"/>
              </value>
            </option>
            <option name="ReSharper.ASP_NET_MVC_ACTION">
              <value/>
            </option>
            <option name="ReSharper.ASP_NET_MVC_AREA">
              <value/>
            </option>
            <option name="ReSharper.ASP_NET_MVC_CONTROLLER">
              <value/>
            </option>
            <option name="ReSharper.ASP_NET_MVC_VIEW">
              <value/>
            </option>
            <option name="ReSharper.ASP_NET_MVC_VIEW_COMPONENT">
              <value/>
            </option>
            <option name="ReSharper.ASP_NET_RUN_AT_ATTRIBUTE">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="ReSharper.BRACE_OUTLINE">
              <value>
                <option name="EFFECT_COLOR" value="#abb2bf"/>
              </value>
            </option>
            <option name="ReSharper.FORMAT_STRING_ITEM">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="ReSharper.FORMAT_STRING_ITEM_2">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="ReSharper.HINT">
              <value>
                <option name="EFFECT_COLOR" value="#61afef"/>
                <option name="EFFECT_TYPE" value="5"/>
              </value>
            </option>
            <option name="ReSharper.IL_INSTRUCTION">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="ReSharper.IL_TARGET_CODE_LABEL">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="ReSharper.IL_VIEWER_SYNCHRONIZATION">
              <value/>
            </option>
            <option name="ReSharper.MATCHED_FORMAT_STRING_ITEM">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="ReSharper.OUTLINED_ENTITY">
              <value>
                <option name="EFFECT_COLOR" value="#abb2bf"/>
              </value>
            </option>
            <option name="ReSharper.STRING_ESCAPE_CHARACTER_2">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option baseAttributes="CSS.COMMENT" name="SASS_COMMENT"/>
            <option name="SASS_MIXIN">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="SASS_VARIABLE" baseAttributes="DEFAULT_INSTANCE_FIELD" />
            <option name="SEARCH_RESULT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="42557b"/>
                <option name="EFFECT_COLOR" value="457dff"/>
              </value>
            </option>
            <option name="SLIM_BAD_CHARACTER">
              <value>
                <option name="BACKGROUND" value="f2777a"/>
                <option name="FOREGROUND" value="272b33"/>
              </value>
            </option>
            <option name="SLIM_CLASS">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="SLIM_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
              </value>
            </option>
            <option name="SLIM_DOCTYPE_KWD">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="SLIM_FILTER">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="SLIM_ID">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="SLIM_INTERPOLATION">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_PARENTHS" name="SLIM_PARENTHS"/>
            <option baseAttributes="DEFAULT_TEMPLATE_LANGUAGE_COLOR" name="SLIM_RUBY_CODE"/>
            <option name="SLIM_STATIC_CONTENT">
              <value>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="SLIM_STRING_INTERPOLATED">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="SLIM_TAG">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="SLIM_TAG_ATTR_KEY">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="SQL_COLUMN" name="SQL_OUTER_QUERY_COLUMN"/>
            <option baseAttributes="DEFAULT_PREDEFINED_SYMBOL" name="SQL_SYNTHETIC_ENTITY"/>
            <option name="STATIC_FINAL_FIELD_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_STATIC_METHOD" name="STATIC_METHOD_ATTRIBUTES"/>
            <option name="STATIC_METHOD_IMPORTED_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="STYLUS_VARIABLE">
              <value/>
            </option>
            <option name="SUGGESTION">
              <value>
                <option name="EFFECT_COLOR" value="#61afef"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="SWIFT_ATTRIBUTE_ARGUMENT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="SWIFT_EXTERNAL_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="SWIFT_SHEBANG_COMMENT">
              <value>
                <option name="FOREGROUND" value="#5c6370"/>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option baseAttributes="STATIC_METHOD_ATTRIBUTES" name="Static method access"/>
            <option name="Static property reference ID">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="TEMPLATE_VARIABLE_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="TEXT">
              <value>
                <option name="BACKGROUND" value="{{colors.surface.default.hex_stripped}}"/>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option name="TERMINAL_COMMAND_TO_RUN_USING_IDE">
              <value>
                <option name="FOREGROUND" value="BBBBBB" />
                <option name="BACKGROUND" value="40503c" />
              </value>
            </option>
            <option name="TEXT_SEARCH_RESULT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="42557b"/>
                <option name="EFFECT_COLOR" value="457dff"/>
                <option name="ERROR_STRIPE_COLOR" value="457dff"/>
              </value>
            </option>
            <option name="TODO_DEFAULT_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="ff8c00"/>
              </value>
            </option>
            <option name="TS.MODULE_NAME">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="TS.TYPE_GUARD">
              <value>
                <option name="BACKGROUND" value="2A3B33"/>
              </value>
            </option>
            <option name="TS.TYPE_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="TYPEDEF">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="TYPE_PARAMETER_NAME_ATTRIBUTES">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="TYPO">
              <value>
                <option name="EFFECT_COLOR" value="#98c379"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="UNMATCHED_BRACE_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="583535"/>
              </value>
            </option>
            <option name="Unresolved reference access">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="VELOCITY_DIRECTIVE">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
                <option name="FONT_TYPE" value="1" />
              </value>
            </option>
            <option name="VELOCITY_KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="VELOCITY_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#61afef" />
              </value>
            </option>
            <option name="VELOCITY_SCRIPTING_BACKGROUND">
              <value>
                <option name="BACKGROUND" value="282c34" />
              </value>
            </option>
            <option name="WARNING_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="ff8c00"/>
                <option name="ERROR_STRIPE_COLOR" value="ff8c00"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="353940"/>
                <option name="ERROR_STRIPE_COLOR" value="4d78cc" />
                <option name="EFFECT_TYPE" value="1"/>
              </value>
            </option>
            <option name="WRITE_SEARCH_RESULT_ATTRIBUTES">
              <value>
                <option name="BACKGROUND" value="42557b"/>
                <option name="EFFECT_COLOR" value="457dff"/>
              </value>
            </option>
            <option name="WRONG_REFERENCES_ATTRIBUTES">
              <value>
                <option name="EFFECT_COLOR" value="#f44747"/>
                <option name="ERROR_STRIPE_COLOR" value="#f44747"/>
                <option name="EFFECT_TYPE" value="2"/>
              </value>
            </option>
            <option name="XML_ATTRIBUTE_NAME">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="XML_ENTITY_REFERENCE">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="XML_NS_PREFIX">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="XML_PROLOGUE">
              <value>
                <option name="BACKGROUND" value="282c34"/>
                <option name="FOREGROUND" value="#abb2bf"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_TAG" name="XML_TAG"/>
            <option name="XML_TAG_NAME">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="XPATH.KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="XPATH.XPATH_NAME">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_LOCAL_VARIABLE" name="XPATH.XPATH_VARIABLE"/>
            <option name="YAML_ANCHOR">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="YAML_SCALAR_KEY">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="YAML_SCALAR_LIST">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="YAML_SCALAR_VALUE">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="YAML_TEXT">
              <value>
                <option name="FOREGROUND" value="#98c379"/>
              </value>
            </option>
            <option name="com.plan9.IDENTIFIER">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="com.plan9.INSTRUCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="com.plan9.KEYWORD">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="com.plan9.LABEL">
              <value>
                <option name="FONT_TYPE" value="1"/>
              </value>
            </option>
            <option name="com.plan9.PSEUDO_INSTRUCTION">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="com.plan9.REGISTER">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="org.rust.DOC_LINK">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="org.rust.ENUM_VARIANT">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_FUNCTION_CALL" name="org.rust.FUNCTION_CALL"/>
            <option name="org.rust.LIFETIME">
              <value>
                <option name="FOREGROUND" value="#56b6c2"/>
              </value>
            </option>
            <option name="org.rust.MACRO">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option name="org.rust.METHOD_CALL">
              <value>
                <option name="FOREGROUND" value="#61afef"/>
              </value>
            </option>
            <option baseAttributes="DEFAULT_IDENTIFIER" name="org.rust.MUT_BINDING"/>
            <option name="org.rust.MUT_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#d19a66"/>
              </value>
            </option>
            <option name="org.rust.PRIMITIVE_TYPE">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="org.rust.Q_OPERATOR">
              <value/>
            </option>
            <option name="org.rust.SELF_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#c678dd"/>
              </value>
            </option>
            <option name="org.rust.TYPE_ALIAS">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
                <option name="FONT_TYPE" value="2"/>
              </value>
            </option>
            <option name="org.rust.TYPE_PARAMETER">
              <value>
                <option name="FOREGROUND" value="#e5c07b"/>
              </value>
            </option>
            <option name="org.rust.UNSAFE_CODE">
              <value/>
            </option>
            <option name="osmorc.attributeName">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="osmorc.directiveName">
              <value>
                <option name="FOREGROUND" value="#e06c75"/>
              </value>
            </option>
            <option name="DEFAULT_TEMPLATE_LANGUAGE_COLOR">
              <value>
                <option name="FOREGROUND" value="#e5c07b" />
              </value>
            </option>
            <option name="DART_KEYWORD">
              <value>
                <option name="FOREGROUND" value="c678dd" />
              </value>
            </option>
            <option name="DART_STRING">
              <value>
                <option name="FOREGROUND" value="98c379" />
              </value>
            </option>
            <option name="DART_VALID_STRING_ESCAPE">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_INVALID_STRING_ESCAPE">
              <value>
                <option name="FOREGROUND" value="f44747" />
              </value>
            </option>
            <option name="DART_SYMBOL_LITERAL">
              <value>
                <option name="FOREGROUND" value="98c379" />
              </value>
            </option>
            <option name="DART_NUMBER">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_LINE_COMMENT">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_BLOCK_COMMENT">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_DOC_COMMENT">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_ANNOTATION">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_ERROR">
              <value>
                <option name="FOREGROUND" value="f44747" />
              </value>
            </option>
            <option name="DART_WARNING">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_BAD_CHARACTER">
              <value>
                <option name="FOREGROUND" value="f44747" />
              </value>
            </option>
            <option name="DART_CLASS">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_MIXIN">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_EXTENSION">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_EXTENSION_TYPE">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_TYPE_ALIAS">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_FUNCTION_TYPE_ALIAS">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_TYPE_PARAMETER">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_TYPE_NAME_DYNAMIC">
              <value>
                <option name="FOREGROUND" value="e5c07b" />
              </value>
            </option>
            <option name="DART_ENUM_CONSTANT">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_IDENTIFIER">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_INSTANCE_FIELD_DECLARATION">
              <value>
                <option name="FOREGROUND" value="e06c75" />
              </value>
            </option>
            <option name="DART_INSTANCE_FIELD_REFERENCE">
              <value>
                <option name="FOREGROUND" value="e06c75" />
              </value>
            </option>
            <option name="DART_STATIC_FIELD_DECLARATION">
              <value>
                <option name="FOREGROUND" value="e06c75" />
              </value>
            </option>
            <option name="DART_LOCAL_VARIABLE_DECLARATION">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_LOCAL_VARIABLE_REFERENCE">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_PARAMETER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_PARAMETER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="d19a66" />
              </value>
            </option>
            <option name="DART_IMPORT_PREFIX">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_LIBRARY_NAME">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_LABEL">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_INSTANCE_GETTER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_INSTANCE_METHOD_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_INSTANCE_METHOD_TEAR_OFF">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_INSTANCE_SETTER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_GETTER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_GETTER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_METHOD_DECLARATION">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_METHOD_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_METHOD_TEAR_OFF">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_SETTER_DECLARATION">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_STATIC_SETTER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_TOP_LEVEL_GETTER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_TOP_LEVEL_SETTER_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_LOCAL_FUNCTION_DECLARATION">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_LOCAL_FUNCTION_REFERENCE">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_LOCAL_FUNCTION_TEAR_OFF">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_CONSTRUCTOR">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_CONSTRUCTOR_TEAR_OFF">
              <value>
                <option name="FOREGROUND" value="61afef" />
              </value>
            </option>
            <option name="DART_PARENTH">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_BRACKETS">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_BRACES">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_COMMA">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_DOT">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_SEMICOLON">
              <value>
                <option name="FOREGROUND" value="5c6370" />
              </value>
            </option>
            <option name="DART_COLON">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_FAT_ARROW">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
            <option name="DART_OPERATION_SIGN">
              <value>
                <option name="FOREGROUND" value="abb2bf" />
              </value>
            </option>
          </attributes>
      </scheme>
    '';

    androidStudioTheme = schemeName: colorSchemeName: ''
      {
        "name": "${schemeName}",
        "dark": true,
        "author": "Generated by matugen via DankMaterialShell",
        "parentTheme": "Islands Dark",
        "editorScheme": "${colorSchemeName}",
        "colors": {
          "accentColor": "{{colors.primary.default.hex}}",
          "backgroundColor": "{{colors.background.default.hex}}",
          "panelColor": "{{colors.surface_container.default.hex}}",
          "borderColor": "{{colors.outline_variant.default.hex}}",
          "infoForeground": "{{colors.on_surface_variant.default.hex}}",
          "foregroundColor": "{{colors.on_background.default.hex}}",
          "notificationBackground": "{{colors.surface_container_high.default.hex}}",
          "selectionBackground": "{{colors.primary_container.default.hex}}",
          "selectionForeground": "{{colors.on_primary_container.default.hex}}",
          "borderTransparent": "#00000000",
          "hoverBackground": "{{colors.surface_container_high.default.hex}}",
          "errorColor": "{{colors.error.default.hex}}",
          "onAccentColor": "{{colors.on_primary.default.hex}}",
          "selectionInactiveBackground": "{{colors.surface_container.default.hex}}",
          "trackColor": "{{colors.surface_container_lowest.default.hex}}",
          "surfaceLow": "{{colors.surface_container_low.default.hex}}"
        },
        "ui":
      {
        "*": {
          "background": "backgroundColor",
          "foreground": "foregroundColor",
          "borderColor": "borderColor",
          "separatorColor": "borderColor",
          "hoverBackground": "hoverBackground",
          "selectionBackground": "selectionBackground",
          "selectionForeground": "selectionForeground",
          "selectionInactiveBackground": "selectionInactiveBackground",
          "inactiveBackground": "backgroundColor",
          "disabledBackground": "backgroundColor",
          "acceleratorForeground": "foregroundColor",
          "errorForeground": "errorColor",
          "focusColor": "backgroundColor",
          "focusedBorderColor": "accentColor"
        },
        "Islands": 1,
        "Island": {
          "arc": 28,
          "arc.compact": 16,
          "borderWidth": 5,
          "borderWidth.compact": 4,
          "borderColor": "panelColor",
          "inactiveAlpha": 0,
          "inactiveAlphaInStatusBar": {
            "os.mac": 0.2,
            "os.windows": 0,
            "os.linux": 0.15
          }
        },
        "MainWindow.background": "backgroundColor",
        "MainWindow.Tab": {
          "background": "surfaceLow",
          "selectedBackground": "selectionBackground",
          "hoverBackground": "hoverBackground",
          "separatorColor": "borderColor"
        },
        "MainToolbar": {
          "background": "backgroundColor",
          "inactiveBackground": "backgroundColor",
          "borderColor": "borderTransparent",
          "Dropdown": {
            "hoverBackground": "hoverBackground"
          }
        },
        "Component": {
          "arc": 16,
          "focusColor": "accentColor"
        },
        "ToolWindow": {
          "background": "panelColor",
          "borderColor": "panelColor",
          "Button": {
            "hoverBackground": "selectionBackground",
            "selectedBackground": "hoverBackground",
            "selectedForeground": "foregroundColor"
          },
          "Header": {
            "background": "panelColor",
            "inactiveBackground": "panelColor",
            "borderColor": "backgroundColor"
          },
          "HeaderTab": {
            "underlineColor": "accentColor",
            "inactiveUnderlineColor": "borderTransparent",
            "hoverBackground": "selectionBackground",
            "hoverInactiveBackground": "hoverBackground",
            "selectedBackground": "selectionBackground",
            "selectedInactiveBackground": "hoverBackground"
          },
          "Stripe": {
            "background": "backgroundColor",
            "borderColor": "borderTransparent",
            "Button": {
              "hoverBackground": "selectionBackground",
              "selectedBackground": "hoverBackground",
              "selectedForeground": "foregroundColor"
            }
          }
        },
        "StripeToolbar.Button": {
          "size": "37,40",
          "leftStripeIcon.padding": "5,5,5,2",
          "rightStripeIcon.padding": "5,2,5,5",
          "leftStripeIcon.padding.compact": "4,5,4,3",
          "rightStripeIcon.padding.compact": "4,3,4,5",
          "leftStripeIconWithName.padding": "4,6,4,2",
          "rightStripeIconWithName.padding": "4,2,4,6",
          "leftStripeIconWithName.padding.compact": "3,4,3,2",
          "rightStripeIconWithName.padding.compact": "3,2,3,4",
          "leftStripeTextOffset": 2,
          "leftStripeTextOffset.compact": 0,
          "rightStripeTextOffset": -2,
          "rightStripeTextOffset.compact": 0
        },
        "StatusBar": {
          "background": "backgroundColor",
          "borderColor": "borderTransparent",
          "hoverBackground": "selectionBackground",
          "Widget.hoverBackground": "hoverBackground"
        },
        "EditorTabs": {
          "background": "surfaceLow",
          "underlinedBorderColor": "focusedBorderColor",
          "underlinedTabBackground": "focusedBorderColor",
          "underlinedTabForeground": "foregroundColor",
          "underlineColor": "accentColor",
          "inactiveUnderlinedTabBorderColor": "borderColor",
          "inactiveUnderlinedTabBackground": "backgroundColor",
          "hoverBackground": "selectionBackground",
          "inactiveUnderlineColor": "accentColor",
          "tabInsets": "-7,8,-7,8",
          "tabInsets.compact": "-2,6,-2,4",
          "verticalTabInsets": "-2,10,-2,10",
          "verticalTabInsets.compact": "0,10,0,10"
        },
        "RunWidget": {
          "background": "hoverBackground",
          "foreground": "foregroundColor",
          "iconColor": "accentColor",
          "hoverBackground": "borderColor",
          "pressedBackground": "infoForeground",
          "separatorColor": "borderColor"
        },
        "FileColor": {
          "Yellow": "#3d3026",
          "Green": "#1c261c"
        },
        "NavBar": {
          "borderColor": "borderTransparent"
        },
        "Borders": {
          "color": "borderColor",
          "ContrastBorderColor": "borderColor"
        },
        "ActionButton": {
          "hoverBackground": "hoverBackground",
          "hoverBorderColor": "hoverBackground",
          "pressedBackground": "borderColor",
          "pressedBorderColor": "borderColor"
        },
        "Button": {
          "foreground": "infoForeground",
          "startBackground": "hoverBackground",
          "endBackground": "hoverBackground",
          "startBorderColor": "borderColor",
          "endBorderColor": "borderColor",
          "focusedBorderColor": "infoForeground",
          "default": {
            "foreground": "onAccentColor",
            "startBackground": "accentColor",
            "endBackground": "accentColor",
            "startBorderColor": "accentColor",
            "endBorderColor": "accentColor",
            "focusedBorderColor": "accentColor",
            "focusColor": "accentColor"
          }
        },
        "ComboBox": {
          "nonEditableBackground": "borderColor",
          "background": "borderColor",
          "selectionBackground": "accentColor",
          "ArrowButton": {
            "iconColor": "foregroundColor",
            "disabledIconColor": "selectionInactiveBackground",
            "nonEditableBackground": "borderColor"
          }
        },
        "Popup": {
          "background": "hoverBackground",
          "Header.activeBackground": "hoverBackground",
          "separatorColor": "panelColor",
          "Advertiser.background": "hoverBackground",
          "Advertiser.borderColor": "hoverBackground",
          "Advertiser.foreground": "infoForeground",
          "borderColor": "panelColor",
          "Toolbar.background": "hoverBackground"
        },
        "CompletionPopup": {
          "background": "hoverBackground",
          "selectionBackground": "selectionInactiveBackground",
          "matchForeground": "accentColor"
        },
        "Editor": {
          "background": "backgroundColor",
          "foreground": "foregroundColor",
          "shortcutForeground": "accentColor"
        },
        "Editor.Toolbar.borderColor": "borderColor",
        "EditorPane.inactiveBackground": "backgroundColor",
        "List": {
          "selectionBackground": "accentColor",
          "selectionForeground": "onAccentColor"
        },
        "Notification": {
          "background": "hoverBackground",
          "borderColor": "panelColor"
        },
        "NotificationsToolwindow.Notification.hoverBackground": "hoverBackground",
        "NotificationsToolwindow.newNotification.background": "backgroundColor",
        "Panel.background": "backgroundColor",
        "Plugins": {
          "background": "backgroundColor",
          "hoverBackground": "selectionBackground",
          "SectionHeader.background": "selectionBackground"
        },
        "ProgressBar": {
          "trackColor": "trackColor",
          "progressColor": "accentColor",
          "indeterminateStartColor": "accentColor",
          "indeterminateEndColor": "accentColor"
        },
        "SearchEverywhere": {
          "Header.background": "backgroundColor",
          "Tab": {
            "selectedForeground": "foregroundColor",
            "selectedBackground": "selectionBackground"
          }
        },
        "TabbedPane": {
          "underlineColor": "accentColor",
          "contentAreaColor": "selectionBackground",
          "hoverColor": "selectionBackground"
        },
        "Table": {
          "background": "panelColor",
          "stripeColor": "selectionInactiveBackground",
          "selectionForeground": "selectionForeground",
          "gridColor": "infoForeground",
          "selectionBackground": "hoverBackground"
        },
        "Tree": {
          "selectionBackground": "accentColor",
          "modifiedItemForeground": "accentColor",
          "selectionInactiveForeground": "foregroundColor",
          "rowHeight": 20
        },
        "VersionControl": {
          "Log.Commit": {
            "currentBranchBackground": "selectionInactiveBackground",
            "hoveredBackground": "hoverBackground"
          }
        },
        "NewClass": {
          "Panel.background": "hoverBackground",
          "SearchField.background": "hoverBackground",
          "separatorColor": "panelColor"
        },
        "AlertDialog.background": "hoverBackground",
        "WelcomeScreen": {
          "borderColor": "borderColor",
          "separatorColor": "selectionInactiveBackground",
          "SidePanel.background": "panelColor",
          "Details.background": "backgroundColor",
          "Projects": {
            "actions.background": "selectionBackground"
          }
        }
      }
      }
    '';
  };
}
