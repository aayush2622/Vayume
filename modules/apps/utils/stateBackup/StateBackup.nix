{
  flake.homeModules.apps.StateBackup = { pkgs, lib, ... }:
  let
    statePaths = [
      ".zen/default"
      ".config/vesktop"
      ".config/Code"
      ".config/zed"
      ".local/share/Google"
      ".config/JetBrains"
      ".config/rbw"
      ".cache/rbw"
      ".config/Bitwarden"
      ".fcc"
    ];

    pathsBashArray = builtins.concatStringsSep " " (map (p: "\"${p}\"") statePaths);

    stateBackupScript = pkgs.writeShellScriptBin "vayori-app-state" ''
      set -euo pipefail

      SESSION_DIR="$HOME/.config/vayori/session"

      usage() {
        echo "usage: vayori-app-state backup <output-file>" >&2
        echo "       vayori-app-state restore <input-file>" >&2
        echo "" >&2
        echo "Every app's real login/session state (Zen Browser profile, Vesktop," >&2
        echo "VS Code/Zed accounts, rbw session, Bitwarden desktop, Free Claude" >&2
        echo "Code's .env, ...) lives at" >&2
        echo "~/.config/vayori/session - always that same fixed path, regardless" >&2
        echo "of where this flake is checked out." >&2
        echo "Apps are symlinked there automatically (see linkSessionState), so" >&2
        echo "it's already the one folder that has to move for a fresh install" >&2
        echo "to come back already logged in. Copy the whole folder directly" >&2
        echo "for a same-trust move, or use backup/restore for a password-" >&2
        echo "encrypted archive - AES-256, keyed via PBKDF2-SHA256 from a" >&2
        echo "passphrase you type, safe to put somewhere less trusted than a" >&2
        echo "direct folder copy would be." >&2
        exit 1
      }

      [ "$#" -eq 2 ] || usage
      MODE="$1"
      TARGET_FILE="$2"

      case "$MODE" in
        backup|restore) ;;
        *) usage ;;
      esac

      case "$MODE" in
        backup)
          [ -d "$SESSION_DIR" ] || { echo "nothing at $SESSION_DIR yet - nothing to back up" >&2; exit 1; }

          read -rs -p "Backup password: " PASSWORD; echo
          read -rs -p "Confirm password: " PASSWORD_CONFIRM; echo
          if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            echo "passwords didn't match" >&2
            exit 1
          fi

          ${pkgs.gnutar}/bin/tar -C "$(dirname "$SESSION_DIR")" -cf - "$(basename "$SESSION_DIR")" \
            | ${pkgs.openssl}/bin/openssl enc -aes-256-cbc -pbkdf2 -md sha256 -salt \
                -pass fd:3 -out "$TARGET_FILE" 3<<< "$PASSWORD"
          chmod 600 "$TARGET_FILE"
          echo "backed up $SESSION_DIR -> $TARGET_FILE (encrypted)"
          ;;

        restore)
          [ -f "$TARGET_FILE" ] || { echo "no such file: $TARGET_FILE" >&2; exit 1; }

          read -rs -p "Backup password: " PASSWORD; echo

          TMP_EXTRACT="$(mktemp -d)"
          trap 'rm -rf "$TMP_EXTRACT"' EXIT

          if ! ${pkgs.openssl}/bin/openssl enc -d -aes-256-cbc -pbkdf2 -md sha256 \
                -pass fd:3 -in "$TARGET_FILE" 3<<< "$PASSWORD" \
                | ${pkgs.gnutar}/bin/tar -C "$TMP_EXTRACT" -xf -; then
            echo "restore failed - wrong password, or a corrupt/not-an-archive file" >&2
            exit 1
          fi

          if [ ! -d "$TMP_EXTRACT/session" ]; then
            echo "restore failed - archive didn't contain a session folder" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$SESSION_DIR")"

          if [ -d "$SESSION_DIR" ]; then
            BACKUP_OF_OLD="$SESSION_DIR.bak.$(date +%s)"
            mv "$SESSION_DIR" "$BACKUP_OF_OLD"
            echo "existing $SESSION_DIR moved aside to $BACKUP_OF_OLD, just in case"
          fi

          mv "$TMP_EXTRACT/session" "$SESSION_DIR"
          echo "restored $TARGET_FILE -> $SESSION_DIR"
          echo "re-run a rebuild (or just re-login to an app) to relink anything new"
          ;;
      esac
    '';
  in {
    home.packages = [ stateBackupScript ];

    home.activation.linkSessionState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SESSION_DIR="$HOME/.config/vayori/session"
      PATHS=(${pathsBashArray})

      for p in "''${PATHS[@]}"; do
        TARGET="$HOME/$p"
        LINK_DEST="$SESSION_DIR/$p"

        if [ -L "$TARGET" ]; then
          continue
        fi

        run mkdir -p "$(dirname "$LINK_DEST")" "$(dirname "$TARGET")"

        if [ -e "$TARGET" ]; then
          if [ -e "$LINK_DEST" ]; then
            echo "vayori-session: both $TARGET and $LINK_DEST already exist - leaving $TARGET as-is, resolve by hand"
            continue
          fi
          run mv "$TARGET" "$LINK_DEST"
        else
          run mkdir -p "$LINK_DEST"
        fi

        run ln -s "$LINK_DEST" "$TARGET"
      done
    '';
  };
}
