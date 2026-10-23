quick=0
full=0
top=15
while [ "$#" -gt 0 ]; do
  case "$1" in
    --quick) quick=1 ;;
    --full) full=1 ;;
    --top)
      top=${2:?--top needs a number}
      shift
      ;;
    *)
      echo "usage: vayume disk [--quick] [--full] [--top N]" >&2
      exit 2
      ;;
  esac
  shift
done
case "$top" in
  '' | *[!0-9]*)
    echo "vayume disk: --top needs a number" >&2
    exit 2
    ;;
esac

fit() {
  local text=$1 width=44
  if [ "${#text}" -gt "$width" ]; then
    local head=$(((width - 1) / 2)) tail=$((width - 1 - (width - 1) / 2))
    text="${text:0:head}…${text: -tail}"
  fi
  printf '%s' "$text"
}

row() { printf '  %-44s %9s   %s\n' "$(fit "$1")" "$(hr "$2")" "$3"; }

pct() {
  awk -v a="$1" -v b="$2" 'BEGIN { if (b > 0) printf "%4.1f%%", 100 * a / b; else printf "     " }'
}

pct_base=0

prow() { printf '  %-44s %9s %6s  %s\n' "$(fit "$1")" "$(hr "$2")" "$(pct "$2" "$pct_base")" "${3:-}"; }

srow() { printf '    %-42s %9s %6s  %s\n' "$(fit "$1")" "$(hr "$2")" "$(pct "$2" "$pct_base")" "${3:-}"; }

total_row() { printf '  %-44s %9s %6s\n' "$1" "$(hr "$2")" "$(pct "$2" "$pct_base")"; }

children() {
  {
    find "$1" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
      | xargs -0 -r -P 4 -n 1 du -sxB1 2>/dev/null \
      | sort -rn
  } || true
}

sum_col() { awk -F'\t' '{ s += $1 } END { print s + 0 }'; }

read -r fs_source fs_size used_bytes avail_bytes fs_pct < <(
  df -B1 --output=source,size,used,avail,pcent / | tail -n 1
)

echo "Filesystem"
printf '  %s: %s used of %s, %s free (%s)\n' "$fs_source" "$(hr "$used_bytes")" "$(hr "$fs_size")" "$(hr "$avail_bytes")" "$fs_pct"
echo "  Sizes below are allocated file sizes, before the disk's own compression, so they add up to more than the used space."

grand=0

if [ "$quick" = 0 ]; then
  store_total=$(size /nix/store)
  home_total=$(size "$HOME")
  home_children=$(children "$HOME")

  rest_total=0
  rest_children=""
  while IFS= read -r -d '' d; do
    case "$d" in
      /nix | /home | /proc | /sys | /dev | /run | /tmp) continue ;;
    esac
    s=$(size "$d")
    [ "$s" -gt 0 ] || continue
    rest_total=$((rest_total + s))
    rest_children+="$s"$'\t'"$d"$'\n'
  done < <(find / -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  counted=$((store_total + home_total + rest_total))
  pct_base=$counted

  echo
  echo "Where all the space goes (percent of the total counted here)"

  prow "Nix store (/nix/store)" "$store_total"

  nix_tmp=$(mktemp -d)
  trap 'rm -rf "$nix_tmp"' EXIT
  nix path-info --all -s 2>/dev/null | awk -F'\t' '{ gsub(/ +$/, "", $1); print $1 "\t" $2 }' >"$nix_tmp/sizes" || true
  sum_paths() { awk -F'\t' 'NR == FNR { sz[$1] = $2; next } ($1 in sz) { s += sz[$1] } END { print s + 0 }' "$nix_tmp/sizes" -; }

  nix-store --gc --print-live 2>/dev/null >"$nix_tmp/live" || true
  roots=(/run/current-system)
  for r in /nix/var/nix/profiles/per-user/"$USER"/* "$HOME"/.local/state/nix/profiles/*; do
    [ -e "$r" ] && roots+=("$r")
  done
  nix-store -qR "${roots[@]}" 2>/dev/null | sort -u >"$nix_tmp/current" || true

  all_nar=$(awk -F'\t' '{ s += $2 } END { print s + 0 }' "$nix_tmp/sizes")
  live_nar=$(sum_paths <"$nix_tmp/live")
  current_nar=$(sum_paths <"$nix_tmp/current")
  srow "In use: current system and your profiles" "$current_nar" "(package sizes)"
  srow "Kept by old generations and other roots" "$((live_nar - current_nar))" "(vayume gc)"
  srow "Unreferenced garbage" "$((all_nar - live_nar))" "(vayume gc)"
  printf '      (the three lines are the packages'"'"' own sizes, before hard-linking, so they\n'
  printf '       add up to a little more than the %s the store takes)\n' "$(hr "$store_total")"

  prow "Home ($(tilde "$HOME"))" "$home_total"
  home_listed=0
  home_hidden=0
  while IFS=$'\t' read -r s p; do
    [ -n "$p" ] || continue
    home_listed=$((home_listed + 1))
    if [ "$home_listed" -gt "$top" ]; then
      home_hidden=$((home_hidden + s))
      continue
    fi
    srow "$(tilde "$p")" "$s"
    if [ "$s" -gt 1073741824 ] && [ -d "$p" ] && [ ! -L "$p" ]; then
      {
        children "$p" | head -n 5 | while IFS=$'\t' read -r cs cp; do
          printf '        %-40s %9s\n' "$(fit "${cp#"$p"/}")" "$(hr "$cs")"
          if [ "$cs" -gt 1073741824 ] && [ -d "$cp" ] && [ ! -L "$cp" ]; then
            {
              children "$cp" | head -n 5 | while IFS=$'\t' read -r ds dp; do
                printf '            %-36s %9s\n' "$(fit "${dp#"$cp"/}")" "$(hr "$ds")"
              done
            } || true
          fi
        done
      } || true
    fi
  done <<<"$home_children"
  [ "$home_listed" -le "$top" ] || srow "$((home_listed - top)) more entries (use --top N)" "$home_hidden"

  prow "System files (the rest of /)" "$rest_total"
  {
    sort -rn <<<"$rest_children" | head -n "$top" | while IFS=$'\t' read -r s p; do
      [ -n "$p" ] || continue
      srow "$p" "$s"
      if [ "$s" -gt 536870912 ] && [ -d "$p" ]; then
        {
          children "$p" | head -n 4 | while IFS=$'\t' read -r cs cp; do
            printf '        %-40s %9s\n' "$(fit "${cp#"$p"/}")" "$(hr "$cs")"
          done
        } || true
      fi
    done
  } || true

  echo "  ────────────────────────────────────────────────────────────────────"
  total_row "Total counted (before compression)" "$counted"
  if [ "$counted" -ge "$used_bytes" ]; then
    printf '  %-44s %9s\n' "Used on the disk (df)" "$(hr "$used_bytes")"
    printf '  %-44s %9s\n' "Saved by compression and shared data" "$(hr $((counted - used_bytes)))"
  else
    printf '  %-44s %9s\n' "Used on the disk (df)" "$(hr "$used_bytes")"
    printf '  %-44s %9s\n' "Not counted (metadata, other users, unreadable)" "$(hr $((used_bytes - counted)))"
  fi
fi

echo
echo "Regenerable caches (vayume clean caches)"
cache_total=0
cache_listed=0
cache_hidden=0
while IFS=$'\t' read -r s d; do
  cache_total=$((cache_total + s))
  cache_listed=$((cache_listed + 1))
  if [ "$cache_listed" -le "$top" ]; then
    row "$(tilde "$d")" "$s" ""
  else
    cache_hidden=$((cache_hidden + s))
  fi
done < <(
  for rel in "${caches[@]}"; do
    s=$(size "$HOME/$rel")
    if [ "$s" -gt 0 ]; then
      printf '%s\t%s\n' "$s" "$HOME/$rel"
    fi
  done | sort -rn
)
[ "$cache_listed" -le "$top" ] || row "$((cache_listed - top)) smaller caches" "$cache_hidden" "use --top N to list them"
row "total" "$cache_total" ""
grand=$((grand + cache_total))

echo
echo "Other caches (managed by their apps, not touched)"
other_total=0
other_listed=0
other_hidden=0
while IFS=$'\t' read -r s d; do
  other_total=$((other_total + s))
  other_listed=$((other_listed + 1))
  if [ "$other_listed" -le "$top" ]; then
    row "$(tilde "$d")" "$s" ""
  else
    other_hidden=$((other_hidden + s))
  fi
done < <(
  for d in "$HOME"/.cache/*; do
    [ -e "$d" ] || continue
    known=0
    for rel in "${caches[@]}"; do
      if [ "$d" = "$HOME/$rel" ]; then
        known=1
      fi
    done
    if [ "$known" = 0 ]; then
      printf '%s\t%s\n' "$(size "$d")" "$d"
    fi
  done | sort -rn
)
[ "$other_listed" -le "$top" ] || row "$((other_listed - top)) smaller caches" "$other_hidden" "use --top N to list them"
row "total" "$other_total" ""
grand=$((grand + other_total))

echo
echo "Your data (nothing here is deleted without asking)"
data_total=0
trash_size=$(size "$HOME/.local/share/Trash")
row "Trash" "$trash_size" "vayume clean trash [days]"
data_total=$((data_total + trash_size))
downloads_size=$(size "$HOME/Downloads")
row "Downloads (all of it)" "$downloads_size" ""
data_total=$((data_total + downloads_size))
echo "  Largest downloads (these are inside the line above):"
{
  find "$HOME/Downloads" -maxdepth 2 -type f -size +100M -printf '%b\t%p\n' 2>/dev/null | sort -rn | head -n "$top" \
    | while IFS=$'\t' read -r blocks p; do
      printf '    %-42s %9s\n' "$(fit "${p/#$HOME/\~}")" "$(hr $((blocks * 512)))"
    done
} || true
row "total" "$data_total" ""
grand=$((grand + data_total))

echo
echo "System (vayume gc)"
sys_total=0
coredumps=$(size /var/lib/systemd/coredump)
row "Coredumps" "$coredumps" "older than 7 days are removed"
sys_total=$((sys_total + coredumps))
journal=$(size /var/log/journal)
row "Journal" "$journal" "capped at 500 MB"
sys_total=$((sys_total + journal))
generations=$(find /nix/var/nix/profiles -maxdepth 1 -name 'system-*-link' 2>/dev/null | wc -l)
echo "  System generations: $generations (gc keeps the newest ${keep_generations})"
row "total" "$sys_total" ""
grand=$((grand + sys_total))

echo
echo "All the sections above"
row "Regenerable caches" "$cache_total" ""
row "Other caches" "$other_total" ""
row "Your data" "$data_total" ""
row "System (coredumps, journal)" "$sys_total" ""
echo "  ────────────────────────────────────────────────────────────────────"
row "Total of the sections above" "$grand" ""
echo "  (these are parts of the home and system lines in the breakdown, not extra space)"

if [ "$quick" = 0 ] && [ "$full" = 0 ]; then
  echo
  echo "Run with --full to also scan project folders for build output and list what keeps the Nix store alive."
fi
if [ "$quick" = 1 ]; then
  echo
  echo "Quick mode skipped the full breakdown of the store, home and the rest of the disk (about a minute)."
fi

if [ "$full" = 1 ]; then
  echo
  echo "Project build artifacts (vayume clean artifacts)"
  artifacts_total=0
  artifacts_listed=0
  artifacts_hidden=0
  while IFS=$'\t' read -r s p; do
    artifacts_total=$((artifacts_total + s))
    artifacts_listed=$((artifacts_listed + 1))
    if [ "$artifacts_listed" -le "$top" ]; then
      row "${p/#$HOME/\~}" "$s" ""
    else
      artifacts_hidden=$((artifacts_hidden + s))
    fi
  done < <(find_artifacts | sized_list)
  [ "$artifacts_listed" -le "$top" ] || row "$((artifacts_listed - top)) smaller folders" "$artifacts_hidden" "use --top N to list them"
  row "total" "$artifacts_total" ""

  echo
  echo "What keeps Nix store paths alive (closure sizes overlap, so they do not add up)"
  roots_tmp=$(mktemp)
  nix-store --gc --print-roots 2>/dev/null | grep -v '^{' | awk -F' -> ' '{ gsub(/"/, "", $1); print $1 "\t" $2 }' >"$roots_tmp" || true
  cut -f2 "$roots_tmp" | sort -u | xargs -r nix path-info -S 2>/dev/null \
    | awk -F'\t' '{ gsub(/ +$/, "", $1); print $1 "\t" $2 }' >"${roots_tmp}.sizes" || true
  {
    awk -F'\t' 'NR == FNR { sz[$1] = $2; next } ($2 in sz) { print sz[$2] "\t" $1 }' "${roots_tmp}.sizes" "$roots_tmp" | sort -rn | head -n "$top" \
      | while IFS=$'\t' read -r s p; do
        row "${p/#$HOME/\~}" "$s" ""
      done
  } || true
  rm -f "$roots_tmp" "${roots_tmp}.sizes"
fi
