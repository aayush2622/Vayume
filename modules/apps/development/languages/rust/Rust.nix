{ ... }: {
  flake.devLanguages.Rust = {
    vscode = {
      nixpkgsExtensions = [
        "rust-lang.rust-analyzer"
      ];
    };
    zed = {
      tasks = [
        {
          label = "Rust: Cargo run";
          command = "cargo run";
          cwd = "$ZED_WORKTREE_ROOT";
          tags = [ "run" ];
        }
        {
          label = "Rust: Run current file (rustc)";
          command = ''bin="$(mktemp)" && rustc -O "$ZED_FILE" -o "$bin" && "$bin"'';
          cwd = "$ZED_DIRNAME";
          tags = [ "run" ];
        }
      ];
    };
  };

  flake.homeModules.apps.Rust = { pkgs, ... }: {
    home.packages = with pkgs; [
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
    ];
  };
}
