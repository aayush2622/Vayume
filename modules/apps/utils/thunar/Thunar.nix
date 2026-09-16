{
  flake.homeModules.apps.Thunar =
    { pkgs, lib, config, ... }:
    let
      # Plugins have to be baked in with an override rather than listed
      # alongside as separate packages - Thunar only looks for them
      # inside its own prefix, which is exactly what nixpkgs' own
      # programs.thunar module does too.
      thunarWithPlugins = pkgs.thunar.override {
        thunarPlugins = with pkgs; [
          thunar-archive-plugin
          thunar-media-tags-plugin
          thunar-volman
        ];
      };

      # Thunar is an XFCE app: it reads xfconf, not dconf, and ships no
      # gsettings schemas at all. Anything under org/xfce/thunar in
      # dconf.settings is silently ignored - these property names and
      # enum values were read out of the Thunar binary itself.
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

          <!-- Without this, "Delete" (permanent, no Trash) only shows in
               the right-click menu while Shift is held - this pins it
               there all the time, next to "Move to Trash". -->
          <property name="misc-show-delete-action" type="bool" value="true"/>

          <!-- Client-side decorations, so the window follows the GTK
               theme instead of drawing an XFCE-styled titlebar that
               matugen never touches. -->
          <property name="misc-use-csd" type="bool" value="true"/>
        </channel>
      '';

      # A dedicated script instead of an inline `bash -c '...' -- %f` -
      # Thunar substitutes %f with a single shell-quoted argument and
      # parses the whole command line itself before spawning it, so
      # handing it a plain executable + one argument avoids stacking our
      # own quoting on top of Thunar's.
      copyPathScript = pkgs.writeShellScript "thunar-copy-path" ''
        exec ${pkgs.wl-clipboard}/bin/wl-copy -- "$1"
      '';

      # Thunar's custom actions (right-click menu items beyond the
      # built-ins) live in their own plain XML file, not xfconf - Thunar
      # just re-reads it, no xfconfd restart needed.
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
        </actions>
      '';

      # Thunar's sidebar "Places" bookmarks come from GTK3's own bookmark
      # file, ~/.config/gtk-3.0/bookmarks - NOT the legacy ~/.gtk-bookmarks
      # (still readable by some apps, but Thunar/GTK3 don't write or read
      # it anymore). Listed here so Downloads/Documents/etc. show up
      # without the user having to drag each one into the sidebar by hand.
      # Desktop is deliberately left out - GTK's places sidebar already
      # pins it automatically, and adding it here just duplicates the row.
      standardBookmarkDirs = [
        config.xdg.userDirs.documents
        config.xdg.userDirs.download
        config.xdg.userDirs.music
        config.xdg.userDirs.pictures
        config.xdg.userDirs.videos
      ];

      # GTK's own file-chooser dialog is dconf-backed and separate from
      # Thunar's preferences - this is what every GTK open/save dialog
      # reads, Thunar or not.
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

        # Tumbler is enabled system-wide in Host.nix; these are the
        # backends it shells out to, and without them thumbnails are
        # silently blank for anything that isn't a plain image.
        ffmpegthumbnailer
        poppler-utils
        libgsf
        webp-pixbuf-loader
        xfconf

        # For the "Copy Path" custom action below.
        wl-clipboard
      ];

      dconf.settings = {
        "org/gtk/settings/file-chooser" = baseFileChooserSettings;
        "org/gtk/gtk4/settings/file-chooser" = baseFileChooserSettings // {
          view-type = "list";
        };
      };

      # `enable` isn't implied by setting `defaultApplications` - it
      # defaults to false in home-manager, and without it this whole
      # block is silently inert and no mimeapps.list ever gets written.
      #
      # The code/text mimetypes below are what extensions on this
      # machine's shared-mime-info database actually resolve to right
      # now (checked with `xdg-mime query filetype`, not guessed) -
      # notably .ts is "text/vnd.trolltech.linguist" and .tsx is
      # "application/x-tiled-tsx" here, both Qt/Tiled leftovers with
      # nothing TypeScript about the name. Doesn't matter for double-
      # click behaviour (Thunar dispatches on the resolved mimetype
      # either way, so .ts/.tsx still open in VS Code) - just don't be
      # confused re-reading this list later.
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "thunar.desktop";
          "x-directory/normal" = "thunar.desktop";

          "text/plain" = "code.desktop";
          "text/markdown" = "code.desktop";
          "text/x-python" = "code.desktop";
          "text/javascript" = "code.desktop";
          "text/vnd.trolltech.linguist" = "code.desktop"; # .ts
          "application/x-tiled-tsx" = "code.desktop"; # .tsx
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

        # One-time cleanup: an earlier version of this seed added a
        # bare, unlabelled Desktop bookmark - remove exactly that line
        # (never a user's own labelled one) since GTK already pins
        # Desktop in Places on its own.
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
