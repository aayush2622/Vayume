steam_root="$HOME/.local/share/Steam"
library="${HEROIC_SIDELOAD_LIBRARY:-$HOME/.config/heroic/sideload_apps/library.json}"
launchers="$GAMES_DIR/.launchers"

mkdir -p "$launchers" "$(dirname "$library")"
[ -s "$library" ] && jq -e . "$library" >/dev/null 2>&1 || printf '{"games":[]}' >"$library"

if pgrep -x heroic >/dev/null 2>&1; then
  echo "games-sync: Heroic is running, it would overwrite the library on exit - retrying on the next Steam change or login"
  exit 0
fi

steamapps=("$steam_root/steamapps")
if [ -f "$steam_root/steamapps/libraryfolders.vdf" ]; then
  while IFS= read -r dir; do
    steamapps+=("$dir/steamapps")
  done < <(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"/\1/p' "$steam_root/steamapps/libraryfolders.vdf")
fi

entries=$(mktemp)
trap 'rm -f "$entries"' EXIT
count=0
while IFS= read -r dir; do
  for manifest in "$dir"/appmanifest_*.acf; do
    [ -f "$manifest" ] || continue
    appid=${manifest##*appmanifest_}
    appid=${appid%.acf}
    name=$(sed -n 's/^[[:space:]]*"name"[[:space:]]*"\(.*\)"/\1/p' "$manifest" | head -1)
    case "$name" in
      "" | Proton* | "Steam Linux Runtime"* | "Steamworks Common Redistributables"*) continue ;;
    esac
    script="$launchers/steam-$appid.sh"
    printf '#!/bin/sh\nexec steam steam://rungameid/%s\n' "$appid" >"$script"
    chmod +x "$script"
    art="https://cdn.cloudflare.steamstatic.com/steam/apps/$appid"
    jq -cn --arg id "steam-$appid" --arg title "$name" --arg exe "$script" --arg art "$art" \
      '{runner: "sideload", app_name: $id, title: $title, is_installed: true, canRunOffline: true,
        install: {executable: $exe, platform: "linux"},
        art_cover: ($art + "/library_600x900.jpg"), art_square: ($art + "/header.jpg")}' >>"$entries"
    count=$((count + 1))
  done
done < <(printf '%s\n' "${steamapps[@]}" | awk '!seen[$0]++')

tmp="$library.tmp"
jq --slurpfile steam "$entries" \
  '.games = ([.games[] | select(.app_name | startswith("steam-") | not)] + $steam)' \
  "$library" >"$tmp"
mv -f "$tmp" "$library"
echo "Heroic: $count installed Steam games linked ($library)"
