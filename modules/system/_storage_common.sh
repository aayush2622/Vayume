tilde() { printf '%s' "${1/#$HOME/\~}"; }

hr() { numfmt --to=iec --suffix=B "$1"; }

size() {
  if [ -e "$1" ]; then
    du -sxbD "$1" 2>/dev/null | cut -f1
  else
    echo 0
  fi
}

find_artifacts() {
  local root dir parent name
  for root in "${project_roots[@]}"; do
    [ -d "$root" ] || continue
    while IFS= read -r -d '' dir; do
      parent=$(dirname "$dir")
      name=$(basename "$dir")
      case "$name" in
        node_modules) [ -f "$parent/package.json" ] || continue ;;
        target) [ -f "$parent/Cargo.toml" ] || continue ;;
        build | .dart_tool) [ -f "$parent/pubspec.yaml" ] || continue ;;
      esac
      printf '%s\0' "$dir"
    done < <(find "$root" -maxdepth 6 -type d \( -name node_modules -o -name target -o -name .venv -o -name .dart_tool -o -name build \) -prune -print0 2>/dev/null)
  done
}

cache_manifest="$HOME/.config/vayume/cache/.links"
if [ -f "$cache_manifest" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] && caches+=("$rel")
  done <"$cache_manifest"
fi
mapfile -t caches < <(printf '%s\n' "${caches[@]}" | awk '!seen[$0]++')

wipe() {
  if [ -L "$1" ]; then
    find "$1/" -mindepth 1 -delete
  else
    rm -rf -- "$1"
  fi
}

sized_list() {
  local path
  while IFS= read -r -d '' path; do
    printf '%s\t%s\n' "$(size "$path")" "$path"
  done | sort -rn
}
