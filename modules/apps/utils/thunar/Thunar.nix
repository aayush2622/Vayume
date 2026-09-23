{
  flake.appDescriptions.Thunar = "Thunar file manager with archive, media-tags, and volume-management plugins.";

  flake.homeModules.apps.Thunar =
    { pkgs, lib, config, self, ... }:
    let
      terminal = builtins.head (self.vayumeLib.mkDesktopActions pkgs).terminal;

      thunarWithPlugins = pkgs.thunar.override {
        thunarPlugins = with pkgs; [
          thunar-archive-plugin
          thunar-media-tags-plugin
          thunar-volman
        ];
      };

      thunarXml = pkgs.writeText "thunar.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="thunar" version="1.0">
          <property name="last-view" type="string" value="ThunarIconView"/>
          <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_100_PERCENT"/>
          <property name="last-details-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_38_PERCENT"/>
          <property name="last-window-width" type="int" value="1100"/>
          <property name="last-window-height" type="int" value="700"/>
          <property name="last-window-maximized" type="bool" value="false"/>
          <property name="last-side-pane" type="string" value="ThunarShortcutsPane"/>
          <property name="last-show-hidden" type="bool" value="true"/>
          <property name="last-statusbar-visible" type="bool" value="true"/>
          <property name="last-details-view-fixed-columns" type="bool" value="true"/>
          <property name="last-restore-tabs" type="bool" value="true"/>

          <property name="misc-single-click" type="bool" value="false"/>
          <property name="misc-folders-first" type="bool" value="true"/>
          <property name="misc-thumbnail-draw-frames" type="bool" value="false"/>
          <property name="misc-confirm-move-to-trash" type="bool" value="true"/>
          <property name="misc-volume-management" type="bool" value="true"/>
          <property name="misc-recursive-search" type="string" value="THUNAR_RECURSIVE_SEARCH_LOCAL"/>
          <property name="misc-remember-geometry" type="bool" value="true"/>

          <property name="misc-show-delete-action" type="bool" value="true"/>
          <property name="misc-use-csd" type="bool" value="true"/>
        </channel>
      '';

      copyPathScript = pkgs.writeShellScript "thunar-copy-path" ''
        exec ${pkgs.wl-clipboard}/bin/wl-copy -- "$1"
      '';

      ucaXml = pkgs.writeText "uca.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <actions>
          <action>
            <icon>edit-copy</icon>
            <name>Copy Path</name>
            <unique-id>1700000000000001-1</unique-id>
            <command>${copyPathScript} %f</command>
            <description>Copy the selected file's path to the clipboard</description>
            <patterns>*</patterns>
            <directories/>
            <audio-files/>
            <image-files/>
            <other-files/>
            <text-files/>
            <video-files/>
          </action>
          <action>
            <icon>utilities-terminal</icon>
            <name>Open Terminal Here</name>
            <unique-id>1700000000000002-1</unique-id>
            <command>${terminal} --directory %f</command>
            <description>Open a terminal in this folder</description>
            <patterns>*</patterns>
            <startup-notify/>
            <directories/>
          </action>
        </actions>
      '';

      standardBookmarkDirs = [
        config.xdg.userDirs.documents
        config.xdg.userDirs.download
        config.xdg.userDirs.music
        config.xdg.userDirs.pictures
        config.xdg.userDirs.videos
      ];

      baseFileChooserSettings = {
        sort-directories-first = true;
        show-hidden = true;
        location-mode = "path-bar";
        clock-format = "12h";
        date-format = "regular";
        sort-column = "name";
        sort-order = "ascending";
      };
    in
    {
      home.packages = with pkgs; [
        thunarWithPlugins

        ffmpegthumbnailer
        poppler-utils
        libgsf
        webp-pixbuf-loader
        xfconf

        wl-clipboard
      ];

      dconf.settings = {
        "org/gtk/settings/file-chooser" = baseFileChooserSettings;
        "org/gtk/gtk4/settings/file-chooser" = baseFileChooserSettings // {
          view-type = "list";
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "thunar.desktop";
          "x-directory/normal" = "thunar.desktop";

          "text/plain" = "code.desktop";
          "text/markdown" = "code.desktop";
          "text/x-python" = "code.desktop";
          "text/javascript" = "code.desktop";
          "text/vnd.trolltech.linguist" = "code.desktop";
          "application/x-tiled-tsx" = "code.desktop";
          "application/json" = "code.desktop";
          "application/yaml" = "code.desktop";
          "application/toml" = "code.desktop";
          "application/x-shellscript" = "code.desktop";
          "text/x-csrc" = "code.desktop";
          "text/x-chdr" = "code.desktop";
          "text/x-c++src" = "code.desktop";
          "text/x-c++hdr" = "code.desktop";
          "text/rust" = "code.desktop";
          "text/x-go" = "code.desktop";
          "text/html" = "code.desktop";
          "text/css" = "code.desktop";
          "application/xml" = "code.desktop";
          "text/x-log" = "code.desktop";
          "text/x-lua" = "code.desktop";
          "application/x-ruby" = "code.desktop";
          "application/x-php" = "code.desktop";
          "application/sql" = "code.desktop";
        };
      };

      
      systemd.user.services.xfconfd = {
        Unit.Description = "Xfce configuration service";
        Service = {
          Type = "dbus";
          BusName = "org.xfce.Xfconf";
          ExecStart = "${pkgs.xfconf}/lib/xfce4/xfconf/xfconfd";
        };
      };

      home.file = {
        ".local/share/xfce4/helpers/kitty.desktop".text = ''
          [Desktop Entry]
          NoDisplay=true
          Version=1.0
          Encoding=UTF-8
          Type=X-XFCE-Helper
          X-XFCE-Category=TerminalEmulator
          X-XFCE-Commands=kitty
          X-XFCE-CommandsWithParameter=kitty %s
          Icon=kitty
          Name=kitty
        '';

        ".config/xfce4/helpers.rc".text = ''
          TerminalEmulator=kitty
        '';
      };

      
      home.activation.seedThunarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"
        if ! ${pkgs.diffutils}/bin/cmp -s "${thunarXml}" "$dest"; then
          run mkdir -p "$(dirname "$dest")"

          ${pkgs.procps}/bin/pkill -x xfconfd || true
          for _ in $(${pkgs.coreutils}/bin/seq 1 50); do
            ${pkgs.procps}/bin/pgrep -x xfconfd >/dev/null 2>&1 || break
            ${pkgs.coreutils}/bin/sleep 0.02
          done

          run cp -f "${thunarXml}" "$dest"
          run chmod u+w "$dest"
        fi

        bookmarks="$HOME/.config/gtk-3.0/bookmarks"
        run mkdir -p "$(dirname "$bookmarks")"
        run touch "$bookmarks"

        ${pkgs.gnused}/bin/sed -i \
          '\|^file://${config.xdg.userDirs.desktop}$|d' \
          "$bookmarks"

        for dir in ${lib.concatStringsSep " " (map lib.escapeShellArg standardBookmarkDirs)}; do
          uri="file://$dir"
          if ! ${pkgs.gnugrep}/bin/grep -qF "$uri" "$bookmarks"; then
            echo "$uri" >> "$bookmarks"
          fi
        done

        ucaDest="$HOME/.config/Thunar/uca.xml"
        if ! ${pkgs.diffutils}/bin/cmp -s "${ucaXml}" "$ucaDest"; then
          run mkdir -p "$(dirname "$ucaDest")"
          run cp -f "${ucaXml}" "$ucaDest"
          run chmod u+w "$ucaDest"
        fi
      '';
    };
}
