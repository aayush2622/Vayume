{
  flake.homeModules.apps.Nautilus = { pkgs, ... }:
  let
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
      nautilus

      nautilus-open-any-terminal
      sushi
      file-roller

      tinysparql
      localsearch

      ffmpegthumbnailer
      poppler
      librsvg
      webp-pixbuf-loader
    ];
    dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";

        recursive-search = "local-only";
        search-filter-time-type = "last_modified";

        show-image-thumbnails = "always";
        show-directory-item-counts = "local-only";
        thumbnail-limit = 200;

        show-delete-permanently = true;
        show-create-link = true;

        click-policy = "double";

        mouse-use-extra-buttons = true;
        open-folder-on-dnd-hover = true;

        migrated-gtk-settings = true;
      };

      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "standard";
      };

      "org/gnome/nautilus/list-view" = {
        default-zoom-level = "small";
        default-visible-columns = [ "name" "size" "type" "date_modified" ];
      };

      "org/gnome/nautilus/window-state" = {
        maximized = true;
      };

      "org/gnome/desktop/media-handling" = {
        automount = true;
        automount-open = true;
        autorun-never = true;
      };

      "com/github/stunkymonkey/nautilus-open-any-terminal" = {
        terminal = "kitty";
        new-tab = true;
      };

      "org/gtk/settings/file-chooser" = baseFileChooserSettings;

      "org/gtk/gtk4/settings/file-chooser" = baseFileChooserSettings // {
        view-type = "list";
      };
    };
  };
}
