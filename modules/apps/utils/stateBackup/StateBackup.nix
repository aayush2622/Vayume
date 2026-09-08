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

    stateBackupScript = pkgs.writeShellScriptBin "vayume-app-state" ''
      set -euo pipefail

      SESSION_DIR="$HOME/.config/vayume/session"

      usage() {
        echo "usage: vayume-app-state backup <output-file>" >&2
        echo "       vayume-app-state restore <input-file>" >&2
        echo "" >&2
        echo "Every app's real login/session state (Zen Browser profile, Vesktop," >&2
        echo "VS Code/Zed accounts, rbw session, Bitwarden desktop, Free Claude" >&2
        echo "Code's .env, ...) lives at" >&2
        echo "~/.config/vayume/session - always that same fixed path, regardless" >&2
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

    # Runs *before* Home Manager links its own files: a stale symlink left by a
    # previous project name (…/<oldname>/session/<p>) would otherwise make HM's
    # linkGeneration die with `mkdir: File exists` / `ln: No such file or
    # directory`. This entry repairs those links first, and if the project was
    # renamed it moves the whole old session dir across in one shot - recovered
    # from the links themselves, so there's no list of old names to maintain.
    home.activation.linkSessionState =
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        SESSION_DIR="$HOME/.config/vayume/session"
        PATHS=(${pathsBashArray})

        # One-shot migration after a rename: the managed links still point into
        # the old session dir. Derive it from a link's target and move it over,
        # but only while we have no state of our own yet.
        if [ ! -d "$SESSION_DIR" ] || [ -z "$(ls -A "$SESSION_DIR" 2>/dev/null || true)" ]; then
          for p in "''${PATHS[@]}"; do
            link="$HOME/$p"
            if [ ! -L "$link" ]; then continue; fi
            tgt="$(readlink "$link")"
            oldDir=""
            case "$tgt" in
              */"$p") oldDir="''${tgt%/"$p"}" ;;
            esac
            if [ -n "$oldDir" ] && [ "$oldDir" != "$SESSION_DIR" ] && [ -d "$oldDir" ]; then
              echo "vayume-session: project renamed - moving session state $oldDir -> $SESSION_DIR"
              run mkdir -p "$(dirname "$SESSION_DIR")"
              rmdir "$SESSION_DIR" 2>/dev/null || true
              run mv "$oldDir" "$SESSION_DIR"
              rmdir "$(dirname "$oldDir")" 2>/dev/null || true
              break
            fi
          done
        fi

        for p in "''${PATHS[@]}"; do
          TARGET="$HOME/$p"
          LINK_DEST="$SESSION_DIR/$p"

          # Already pointing where it should - nothing to do.
          if [ "$(readlink "$TARGET" 2>/dev/null || true)" = "$LINK_DEST" ]; then
            continue
          fi

          run mkdir -p "$(dirname "$LINK_DEST")" "$(dirname "$TARGET")"

          if [ -L "$TARGET" ]; then
            # Wrong or dangling link (typically a leftover from a previous name).
            # Pull real data along if the link still resolves outside SESSION_DIR
            # and we don't already hold state for this app; otherwise start fresh.
            resolved="$(readlink -f "$TARGET" 2>/dev/null || true)"
            case "$resolved" in
              "$SESSION_DIR"|"$SESSION_DIR"/*) resolved="" ;;
            esac
            if [ ! -e "$LINK_DEST" ] && [ -n "$resolved" ] && [ -e "$resolved" ]; then
              run mv "$resolved" "$LINK_DEST"
            fi
            if [ ! -e "$LINK_DEST" ]; then
              echo "vayume-session: $TARGET pointed at missing $(readlink "$TARGET") - creating fresh $LINK_DEST"
              run mkdir -p "$LINK_DEST"
            fi
            run ln -sfn "$LINK_DEST" "$TARGET"
            continue
          fi

          if [ -e "$TARGET" ]; then
            if [ -e "$LINK_DEST" ]; then
              echo "vayume-session: both $TARGET and $LINK_DEST already exist - leaving $TARGET as-is, resolve by hand"
              continue
            fi
            run mv "$TARGET" "$LINK_DEST"
          else
            run mkdir -p "$LINK_DEST"
          fi

          run ln -sfn "$LINK_DEST" "$TARGET"
        done
      '';
  };
}
