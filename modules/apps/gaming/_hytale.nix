
{ inputs, pkgs, lib, gamesDir, ... }:
{
  home.packages = [ inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  home.file."Games/Hytale/.keep".text = "";

  # The launcher hardcodes ~/.local/share/Hytale (no setting to
  # redirect it) for its self-updated binary, update-hash file, and by
  # default the game itself - symlink that into gamesDir instead of
  # patching the launcher, so everything it ever writes lands under
  # ~/Games. Idempotent: a real directory from a prior run gets moved
  # in once, then every later activation just sees the symlink.
  home.activation.hytaleGamesFolder = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DATA_DIR="$HOME/.local/share/Hytale"
    GAMES_HYTALE_DIR=${lib.escapeShellArg "${gamesDir}/Hytale"}
    run mkdir -p "$GAMES_HYTALE_DIR"

    if [ -L "$DATA_DIR" ]; then
      : # already redirected
    elif [ -d "$DATA_DIR" ]; then
      echo "Moving existing $DATA_DIR into $GAMES_HYTALE_DIR"
      run ${pkgs.coreutils}/bin/cp -a "$DATA_DIR/." "$GAMES_HYTALE_DIR/"
      run ${pkgs.coreutils}/bin/rm -rf "$DATA_DIR"
      run ln -s "$GAMES_HYTALE_DIR" "$DATA_DIR"
    else
      run mkdir -p "$(dirname "$DATA_DIR")"
      run ln -s "$GAMES_HYTALE_DIR" "$DATA_DIR"
    fi
  '';
}
