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
          <property name="last-view" type="string" value="ThunarDetailsView"/>
          <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_100_PERCENT"/>
          <property name="last-details-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_38_PERCENT"/>
          <property name="last-window-width" type="int" value="1100"/>
          <property name="last-window-height" type="int" value="700"/>
          <property name="last-window-maximized" type="bool" value="false"/>
          <property name="last-side-pane" type="string" value="ThunarShortcutsPane"/>
          <property name="last-show-hidden" type="bool" value="true"/>
          <property name="last-statusbar-visible" type="bool" value="true"/>
          <property name="last-details-view-fixed-columns" type="bool" value="true"/>

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

      # Thunar's sidebar auto-lists the XDG special dirs (created by
      # Baseline.nix's xdg.userDirs) under "Places" once they exist on
      # disk - but it reads the classic ~/.gtk-bookmarks for its
      # user-pinnable "Bookmarks" section, and starts with that file
      # empty. Seeding it means Downloads/Documents/etc. show up
      # immediately rather than depending on activation-order timing
      # between folder creation and the sidebar's own directory scan.
      gtkBookmarks = pkgs.writeText "gtk-bookmarks" (lib.concatStringsSep "\n" [
        "file://${config.xdg.userDirs.desktop}"
        "file://${config.xdg.userDirs.documents}"
        "file://${config.xdg.userDirs.download}"
        "file://${config.xdg.userDirs.music}"
        "file://${config.xdg.userDirs.pictures}"
        "file://${config.xdg.userDirs.videos}"
      ]);

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
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "thunar.desktop";
          "x-directory/normal" = "thunar.desktop";
        };
      };

      # Seeded once rather than symlinked from the store: Thunar rewrites
      # both of these itself - the preferences on every window resize or
      # view change, the bookmarks on every sidebar add/remove - and a
      # read-only symlink makes every one of those writes fail. Same
      # pattern as seedDmsSession in Dms.nix.
      home.activation.seedThunarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"
        if [ ! -e "$dest" ]; then
          run mkdir -p "$(dirname "$dest")"
          run cp "${thunarXml}" "$dest"
          run chmod u+w "$dest"
        fi

        bookmarks="$HOME/.gtk-bookmarks"
        if [ ! -e "$bookmarks" ]; then
          run cp "${gtkBookmarks}" "$bookmarks"
          run chmod u+w "$bookmarks"
        fi
      '';
    };
}
