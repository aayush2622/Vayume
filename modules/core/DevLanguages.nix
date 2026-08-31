{ self, lib, ... }: {
  options.flake.devLanguages = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = ''
      Editor contributions published by each modules/apps/development/languages/<lang>
      module, keyed by the same name used in vayori.apps (e.g. `Rust`, `Cpp`).

      Each entry is a plain attrset (no fixed schema enforced here - editors read
      what they understand and ignore the rest), conventionally shaped like:

        {
          vscode = {
            nixpkgsExtensions = [ "publisher.name" ... ];   # pkgs.vscode-extensions.<dotted>
            marketplaceExtensions = [ { publisher; name; } ... ];  # pkgs.vscode-marketplace
            manualExtensions = [ { name; publisher; version; hash; } ... ]; # fetchurl-pinned
            settings = { ... };   # merged into VSCode's userSettings
          };
          androidStudio = {
            autoPlugins = [ { dirName; id; } ... ];   # nix-jetbrains-plugins
            manualPlugins = [ { dirName; id; version; hash; isJar ? false; } ... ]; # fetchurl-pinned
          };
        }

      Editors (Vscode.nix, AndroidStudio.nix, Zed.nix) filter `self.devLanguages`
      down to whichever language app names are actually in `vayori.apps` before
      reading any of this, so removing a language app strips its
      extensions/plugins from every editor automatically - editors never
      hardcode a language's existence. They do it via `self.enabledDevLanguages`
      below rather than each repeating the filter themselves.
    '';
  };

  options.flake.enabledDevLanguages = lib.mkOption {
    type = lib.types.functionTo (lib.types.lazyAttrsOf lib.types.unspecified);
    default = vayoriApps: { };
    description = ''
      `vayoriApps -> devLanguages`, filtered down to just the languages
      actually enabled for this host. The one filter every editor module
      needs, shared here instead of each repeating
      `lib.filterAttrs (name: _: builtins.elem name vayoriApps) self.devLanguages`.
    '';
  };

  config.flake.enabledDevLanguages =
    vayoriApps: lib.filterAttrs (name: _: builtins.elem name vayoriApps) self.devLanguages;
}
