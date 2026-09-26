{ pkgs, lib, ... }:
let
  widgetsToggle = pkgs.writeShellApplication {
    name = "vayume-widgets";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.systemd
    ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/vayume-hidden-widgets"

      list() { dms ipc call desktopWidget list 2>/dev/null || true; }

      hidden_now() {
        [ -s "$state" ] || return 1
        local current id
        current=$(list)
        while IFS= read -r id; do
          if [ "$id" = pet ]; then
            systemctl --user is-active --quiet vayume-pet || return 0
          elif grep -q "^$id .*\[disabled\]$" <<<"$current"; then
            return 0
          fi
        done <"$state"
        return 1
      }

      hide() {
        : >"$state"
        list | while IFS= read -r line; do
          case "$line" in
          *"[enabled]")
            id=''${line%% *}
            dms ipc call desktopWidget disable "$id" >/dev/null
            echo "$id" >>"$state"
            ;;
          esac
        done
        if systemctl --user is-active --quiet vayume-pet; then
          systemctl --user stop vayume-pet
          echo pet >>"$state"
        fi
        echo "Desktop widgets hidden"
      }

      show() {
        if [ -f "$state" ]; then
          while IFS= read -r id; do
            if [ "$id" = pet ]; then
              systemctl --user start vayume-pet
            else
              dms ipc call desktopWidget enable "$id" >/dev/null
            fi
          done <"$state"
          rm -f "$state"
        fi
        echo "Desktop widgets shown"
      }

      case "''${1:-toggle}" in
      hide) hidden_now || hide ;;
      show) show ;;
      toggle) if hidden_now; then show; else hide; fi ;;
      status) if hidden_now; then echo hidden; else echo shown; fi ;;
      *)
        echo "usage: vayume widgets [toggle|show|hide|status]" >&2
        exit 2
        ;;
      esac
    '';
  };
in
{
  vayume.commands.widgets = {
    command = lib.getExe widgetsToggle;
    description = "Hide or show every desktop widget and the desktop pet";
    usage = "[toggle|show|hide|status]";
    panel = {
      label = "Show or hide desktop widgets";
      icon = "visibility_off";
      args = [ "toggle" ];
      page = "appearance";
      group = "Desktop";
    };
  };
}
