let
  cppManualExtensionsSpec = [
    { name = "cpp-extentions-pack"; publisher = "boundarystudio"; version = "0.3.0"; hash = "sha256-UX7+sjlqfWUINtye2XYOndMvya2j0TMXEUbnJ9CDBig="; }
  ];
in {
  flake.devLanguages.Cpp = {
    vscode = {
      nixpkgsExtensions = [
        "ms-vscode.cpptools"
        "ms-vscode.cpptools-extension-pack"
        "ms-vscode.cmake-tools"
        "twxs.cmake"
        "vadimcn.vscode-lldb"
      ];
      marketplaceExtensions = [
        { publisher = "danielpinto8zz6"; name = "c-cpp-compile-run"; }
        { publisher = "ms-vscode"; name = "cpp-devtools"; }
        { publisher = "ms-vscode"; name = "cpptools-themes"; }
      ];
      manualExtensions = cppManualExtensionsSpec;
      settings = {
        "[cpp]" = {
          "editor.defaultFormatter" = "ms-vscode.cpptools";
          "editor.formatOnSave" = true;
        };
        "C_Cpp.clang_format_style" = "file";
        "C_Cpp.clang_format_fallbackStyle" = "Google";
      };
    };
    zed = {
      extensions = [ "neocmake" ];
    };
  };

  flake.homeModules.apps.Cpp = { pkgs, ... }: {
    home.packages = with pkgs; [
      clang-tools
      cmake
      gdb
    ];
  };
}
