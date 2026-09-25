full=0
if [ "${1:-}" = "--full" ]; then
  full=1
fi

row() { printf '  %-40s %9s   %s\n' "$1" "$(hr "$2")" "$3"; }

echo "Filesystem"
df -h --output=source,size,used,avail,pcent / | tail -n 1 \
  | awk '{ printf "  %s: %s used of %s, %s free (%s)\n", $1, $3, $2, $4, $5 }'

echo
echo "Regenerable caches (vayume clean caches)"
cache_total=0
for rel in "${caches[@]}"; do
  s=$(size "$HOME/$rel")
  if [ "$s" -gt 0 ]; then
    row "$(tilde "$HOME/$rel")" "$s" ""
    cache_total=$((cache_total + s))
  fi
done
row "total" "$cache_total" ""

echo
echo "Other caches (managed by their apps, not touched)"
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
done | sort -rn | head -5 | while IFS=$'\t' read -r s d; do
  row "$(tilde "$d")" "$s" ""
done

echo
echo "Your data (nothing here is deleted without asking)"
row "Trash" "$(size "$HOME/.local/share/Trash")" "vayume clean trash [days]"
{ find "$HOME/Downloads" -maxdepth 2 -type f -size +200M -printf '%s\t%p\n' 2>/dev/null || true; } | sort -rn | head -5 \
  | while IFS=$'\t' read -r s p; do
    row "${p/#$HOME/\~}" "$s" "large download"
  done

echo
echo "System (vayume gc)"
row "Coredumps" "$(size /var/lib/systemd/coredump)" "older than 7 days are removed"
journalctl --disk-usage 2>/dev/null | sed 's/^/  /' || true
generations=$(find /nix/var/nix/profiles -maxdepth 1 -name 'system-*-link' 2>/dev/null | wc -l)
echo "  System generations: $generations (gc keeps the newest ${keep_generations})"

if [ "$full" = 1 ]; then
  echo
  echo "Project build artifacts (vayume clean artifacts)"
  find_artifacts | sized_list | head -12 | while IFS=$'\t' read -r s p; do
    row "${p/#$HOME/\~}" "$s" ""
  done
  echo
  echo "Nix garbage that gc would delete"
  dead=$(nix-store --gc --print-dead 2>/dev/null | xargs -r du -scb 2>/dev/null | tail -n 1 | cut -f1)
  row "unreferenced store paths" "${dead:-0}" ""
else
  echo
  echo "Run with --full to also scan project folders and count Nix garbage (slower)."
fi
