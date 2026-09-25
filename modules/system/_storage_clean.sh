assume_yes=0
args=()
for a in "$@"; do
  if [ "$a" = "--yes" ]; then
    assume_yes=1
  else
    args+=("$a")
  fi
done
sub=${args[0]:-}

confirm() {
  local reply
  if [ "$assume_yes" = 1 ]; then
    return 0
  fi
  if [ ! -t 0 ]; then
    echo "vayume clean: not a terminal - pass --yes to run without asking" >&2
    exit 1
  fi
  read -r -p "$1 [y/N] " reply
  case "$reply" in
    y | Y) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
}

case "$sub" in
  caches)
    total=0
    targets=()
    for rel in "${caches[@]}"; do
      s=$(size "$HOME/$rel")
      if [ "$s" -gt 0 ]; then
        printf '  %9s  ~/%s\n' "$(hr "$s")" "$rel"
        total=$((total + s))
        targets+=("$HOME/$rel")
      fi
    done
    if [ "${#targets[@]}" -eq 0 ]; then
      echo "No regenerable caches to remove."
      exit 0
    fi
    confirm "Delete these caches ($(hr "$total"))? They are rebuilt on demand."
    rm -rf -- "${targets[@]}"
    echo "Freed $(hr "$total")."
    ;;
  trash)
    days=${args[1]:-30}
    case "$days" in
      '' | *[!0-9]*)
        echo "vayume clean trash: days must be a number" >&2
        exit 2
        ;;
    esac
    before=$(size "$HOME/.local/share/Trash")
    echo "Trash holds $(hr "$before"); this removes everything trashed more than $days days ago."
    trash-empty --dry-run "$days" 2>/dev/null | head -8 || true
    confirm "Permanently delete those items?"
    trash-empty -f "$days"
    after=$(size "$HOME/.local/share/Trash")
    echo "Freed $(hr $((before - after)))."
    ;;
  artifacts)
    listing=$(find_artifacts | sized_list)
    if [ -z "$listing" ]; then
      echo "No build artifacts found in: ${project_roots[*]}"
      exit 0
    fi
    total=0
    targets=()
    while IFS=$'\t' read -r s p; do
      printf '  %9s  %s\n' "$(hr "$s")" "${p/#$HOME/\~}"
      total=$((total + s))
      targets+=("$p")
    done <<<"$listing"
    confirm "Delete these ${#targets[@]} folders ($(hr "$total"))? They are recreated by the next build or install."
    rm -rf -- "${targets[@]}"
    echo "Freed $(hr "$total")."
    ;;
  *)
    echo "usage: vayume clean <caches|trash [days]|artifacts> [--yes]" >&2
    exit 2
    ;;
esac
