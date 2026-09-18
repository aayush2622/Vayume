{
  description = "Vayume - a NixOS flake config built around niri and DankMaterialShell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    spotifast.url = "github:crmne/spotifast";
    spotifast.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nix-jetbrains-plugins.url = "github:nix-community/nix-jetbrains-plugins";
    nix-jetbrains-plugins.inputs.nixpkgs.follows = "nixpkgs";

    elegant-grub2-themes.url = "git+https://github.com/vinceliuice/Elegant-grub2-themes";
    elegant-grub2-themes.inputs.nixpkgs.follows = "nixpkgs";
    elegant-grub2-themes.inputs.elegant-grub2-theme-src.url = "git+https://github.com/vinceliuice/Elegant-grub2-themes";

    dms.url = "github:AvengeMedia/DankMaterialShell/stable";
    dms.inputs.nixpkgs.follows = "nixpkgs";

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  
    danksession = {
      url = "github:alcxyz/DankSession/v0.3.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hytale-launcher.url = "github:JPyke3/hytale-launcher-nix";
    hytale-launcher.inputs.nixpkgs.follows = "nixpkgs";

    nix-wpe-webkit-bin.url = "github:aayush2622/nix-wpe-webkit-bin";
    nix-wpe-webkit-bin.inputs.nixpkgs.follows = "nixpkgs";

    zsh-autosuggestions = {
      url = "github:zsh-users/zsh-autosuggestions";
      flake = false;
    };
    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };
    zsh-256color = {
      url = "github:chrissicool/zsh-256color";
      flake = false;
    };
    zsh-you-should-use = {
      url = "github:MichaelAquilina/zsh-you-should-use";
      flake = false;
    };
  };

  outputs = inputs:
  inputs.flake-parts.lib.mkFlake
  { inherit inputs; }
  (inputs.import-tree ./modules);


}
