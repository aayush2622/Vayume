{ lib, ... }: {
  options.flake.matugenTemplates = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Raw matugen template content shared across app modules - see modules/desktop/Matugen.nix.";
  };

  config.flake.matugenTemplates = {
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
    gtk = ''
      /*
      * GTK Colors
      * Generated with Matugen
      */

      @define-color accent_color {{colors.primary_fixed_dim.default.hex}};
      @define-color accent_fg_color {{colors.on_primary_fixed.default.hex}};
      @define-color accent_bg_color {{colors.primary_fixed_dim.default.hex}};
      @define-color window_bg_color {{colors.surface_dim.default.hex}};
      @define-color window_fg_color {{colors.on_surface.default.hex}};
      @define-color headerbar_bg_color {{colors.surface_dim.default.hex}};
      @define-color headerbar_fg_color {{colors.on_surface.default.hex}};
      @define-color popover_bg_color {{colors.surface_dim.default.hex}};
      @define-color popover_fg_color {{colors.on_surface.default.hex}};
      @define-color view_bg_color {{colors.surface.default.hex}};
      @define-color view_fg_color {{colors.on_surface.default.hex}};
      @define-color card_bg_color {{colors.surface.default.hex}};
      @define-color card_fg_color {{colors.on_surface.default.hex}};
      @define-color sidebar_bg_color @window_bg_color;
      @define-color sidebar_fg_color @window_fg_color;
      @define-color sidebar_border_color @window_bg_color;
      @define-color sidebar_backdrop_color @window_bg_color;
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
        <attributes>
          <option name="TEXT">
            <value>
              <option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" />
              <option name="BACKGROUND" value="{{colors.background.default.hex_stripped}}" />
            </value>
          </option>
          <option name="DEFAULT_KEYWORD">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_STRING">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_NUMBER">
            <value><option name="FOREGROUND" value="{{colors.secondary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_FUNCTION_CALL">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_FUNCTION_DECLARATION">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_CLASS_NAME">
            <value><option name="FOREGROUND" value="{{colors.secondary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_INSTANCE_FIELD">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_CONSTANT">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_IDENTIFIER">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_OPERATION_SIGN">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_BRACES">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_DOT">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_SEMICOLON">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_LINE_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_BLOCK_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_DOC_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_TEMPLATE_LANGUAGE_COLOR">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
        </attributes>
      </scheme>
    '';
  };
}
