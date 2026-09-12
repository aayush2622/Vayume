#!/usr/bin/env bash
# Vayume bootstrap - stand up a new host from this flake without hand-editing Nix.
#
# It does the three things a fresh machine needs (see docs/getting-started.md):
#   1. host dir   - modules/hosts/<host>/ (copied + renamed from Diablo if new)
#   2. _hardware.nix - from `nixos-generate-config` (or an existing file you point at)
#   3. _user.nix     - built interactively: users, groups, sudo, password hash,
#                      extra packages, per-user secrets, avatar
# then offers to run `sudo nixos-rebuild switch --flake path:.#<host>`.
#
# Usage:  ./install.sh [--host NAME] [--system SYS] [--hardware-file PATH]
#                      [--skip-hardware] [--no-rebuild] [--yes] [--dry-run]
#
# Nothing is overwritten without asking; replaced files are kept as <file>.bak.

set -euo pipefail

# ---------------------------------------------------------------- ui helpers ---
bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; grn=$'\e[32m'; ylw=$'\e[33m'; rst=$'\e[0m'
# all UI chatter goes to stderr; stdout is reserved for captured values
# (ask answers, generated Nix) so `x=$(fn)` never picks up a log line
say()  { printf '%s\n' "${bold}::${rst} $*" >&2; }
info() { printf '%s\n' "   $*" >&2; }
warn() { printf '%s\n' "${ylw}!!${rst} $*" >&2; }
die()  { printf '%s\n' "${red}xx${rst} $*" >&2; exit 1; }

# read from the terminal even when stdin is the script (curl | bash),
# but fall back to stdin when there's no usable controlling tty (pipes, CI)
TTY_OK=0; if (exec </dev/tty) 2>/dev/null; then TTY_OK=1; fi
_read() { if (( TTY_OK )); then IFS= read -r "$@" </dev/tty; else IFS= read -r "$@"; fi; }

ASSUME_YES=0
ask() { # ask "prompt" "default" -> echo answer
  local prompt=$1 default=${2:-} reply
  if (( ASSUME_YES )) && [[ -n $default ]]; then printf '%s\n' "$default"; return; fi
  if [[ -n $default ]]; then printf '%s' "${bold}?${rst} $prompt ${dim}[$default]${rst} " >&2
  else printf '%s' "${bold}?${rst} $prompt " >&2; fi
  _read reply || true
  printf '%s\n' "${reply:-$default}"
}
confirm() { # confirm "prompt" [Y|N default] -> return 0/1
  local prompt=$1 default=${2:-N} reply
  if (( ASSUME_YES )); then [[ $default == Y ]]; return; fi
  local hint='[y/N]'; [[ $default == Y ]] && hint='[Y/n]'
  printf '%s' "${bold}?${rst} $prompt $hint " >&2
  _read reply || true
  reply=${reply:-$default}
  [[ $reply == [yY]* ]]
}
ask_secret() { # ask_secret "prompt" -> echo value (no echo to screen)
  local prompt=$1 reply
  printf '%s' "${bold}?${rst} $prompt " >&2
  if (( TTY_OK )); then IFS= read -rs reply </dev/tty; else IFS= read -rs reply; fi
  printf '\n' >&2
  printf '%s\n' "$reply"
}

# escape an arbitrary string for a Nix "double-quoted" literal
# (backslash, quote, and the ${ interpolation opener - a lone $ is literal in Nix)
nix_str() { printf '%s' "${1-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\${/\\${/g'; }

DRY_RUN=0
run() { if (( DRY_RUN )); then info "${dim}would run:${rst} $*"; else "$@"; fi; }
write_file() { # write_file PATH  (content on stdin); backs up an existing file
  local path=$1 tmp
  tmp=$(mktemp); cat >"$tmp"
  if (( DRY_RUN )); then
    info "${dim}would write $path:${rst}"; sed 's/^/     | /' "$tmp"; rm -f "$tmp"; return
  fi
  if [[ -e $path ]] && ! cmp -s "$tmp" "$path"; then
    cp -p "$path" "$path.bak"; info "kept previous ${path##*/} as ${path##*/}.bak"
  fi
  mkdir -p "$(dirname "$path")"; mv "$tmp" "$path"
  say "wrote ${path#"$REPO/"}"
}

# ---------------------------------------------------------------- args ---------
HOST=""; SYSTEM=""; HARDWARE_FILE=""; SKIP_HW=0; DO_REBUILD=-1
while (( $# )); do
  case $1 in
    --host)          HOST=${2:?}; shift 2;;
    --system)        SYSTEM=${2:?}; shift 2;;
    --hardware-file) HARDWARE_FILE=${2:?}; shift 2;;
    --skip-hardware) SKIP_HW=1; shift;;
    --no-rebuild)    DO_REBUILD=0; shift;;
    --rebuild)       DO_REBUILD=1; shift;;
    --yes|-y)        ASSUME_YES=1; shift;;
    --dry-run)       DRY_RUN=1; shift;;
    -h|--help)       sed -n '2,20p' "$0"; exit 0;;
    *) die "unknown option: $1 (see --help)";;
  esac
done

# ---------------------------------------------------------------- preconditions
REPO=$(cd "$(dirname "$0")" && pwd)
cd "$REPO"
[[ -f flake.nix && -d modules/hosts/Diablo ]] || die "run this from the Vayume repo root"
[[ $EUID -ne 0 ]] || die "run as your normal user, not root - the script sudo's the few steps that need it"
command -v nix >/dev/null || die "nix not found - this bootstrap targets a NixOS machine"

MKPASSWD=(mkpasswd)
command -v mkpasswd >/dev/null || MKPASSWD=(nix run --extra-experimental-features 'nix-command flakes' nixpkgs#mkpasswd --)

IS_GIT=0; git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 && IS_GIT=1

# ---------------------------------------------------------------- host + system
detect_host() {
  local h; h=$(hostnamectl --static 2>/dev/null || true)
  [[ -z $h || $h == localhost ]] && h=$(cat /proc/sys/kernel/hostname 2>/dev/null || true)
  [[ -z $h || $h == localhost ]] && h=nixos
  printf '%s\n' "$h"
}
detect_system() {
  local s; s=$(nix eval --impure --raw --expr builtins.currentSystem 2>/dev/null || true)
  if [[ -z $s ]]; then case $(uname -m) in
    x86_64|amd64) s=x86_64-linux;; aarch64|arm64) s=aarch64-linux;; *) s=x86_64-linux;;
  esac; fi
  printf '%s\n' "$s"
}

[[ -n $HOST   ]] || HOST=$(ask "Hostname" "$(detect_host)")
[[ $HOST =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] || die "invalid hostname: $HOST"
[[ -n $SYSTEM ]] || SYSTEM=$(ask "System (Nix platform)" "$(detect_system)")
[[ $SYSTEM == *-linux ]] || warn "system '$SYSTEM' doesn't look like a NixOS platform - continuing anyway"

HOSTDIR="modules/hosts/$HOST"
say "Host ${bold}$HOST${rst}  ·  system ${bold}$SYSTEM${rst}  ·  $HOSTDIR"

# ---------------------------------------------------------------- host dir -----
if [[ $HOST != Diablo && ! -d $HOSTDIR ]]; then
  info "creating $HOSTDIR from the Diablo template"
  run cp -r modules/hosts/Diablo "$HOSTDIR"
  # drop the template's personal files; keep tracked scaffolding
  run rm -f "$HOSTDIR/_hardware.nix" "$HOSTDIR/_user.nix" "$HOSTDIR/me.jpg"
  # rename Diablo -> $HOST inside the tracked .nix / .example files
  if (( DRY_RUN )); then
    info "would rename Diablo -> $HOST in $HOSTDIR/{Host.nix,Vm.nix,*.example}"
  else
    while IFS= read -r -d '' f; do sed -i "s/Diablo/$HOST/g" "$f"; done \
      < <(find "$HOSTDIR" -maxdepth 1 -type f \( -name '*.nix' -o -name '*.nix.example' \) -print0)
    info "renamed Diablo -> $HOST in $HOSTDIR/{Host.nix,Vm.nix,*.example}"
  fi
elif [[ -d $HOSTDIR ]]; then
  info "$HOSTDIR already exists - filling in what's missing, not touching Host.nix"
else
  info "using the existing Diablo host dir in place"
fi
(( DRY_RUN )) || [[ -f $HOSTDIR/Host.nix ]] || die "$HOSTDIR/Host.nix missing - unexpected"

# keep networking.hostName in sync with the chosen name
if (( ! DRY_RUN )) && grep -q 'networking\.hostName' "$HOSTDIR/Host.nix"; then
  sed -i "s/\(networking\.hostName *= *\"\)[^\"]*\"/\1$HOST\"/" "$HOSTDIR/Host.nix"
fi

# ---------------------------------------------------------------- _hardware.nix
HW="$HOSTDIR/_hardware.nix"
gen_hardware() {
  if [[ -n $HARDWARE_FILE ]]; then
    [[ -f $HARDWARE_FILE ]] || die "--hardware-file $HARDWARE_FILE not found"
    info "using $HARDWARE_FILE"; cat "$HARDWARE_FILE"
  elif [[ -f /etc/nixos/hardware-configuration.nix ]] && \
       confirm "Use the existing /etc/nixos/hardware-configuration.nix?" Y; then
    cat /etc/nixos/hardware-configuration.nix
  elif command -v nixos-generate-config >/dev/null; then
    info "running: sudo nixos-generate-config --show-hardware-config"
    sudo nixos-generate-config --show-hardware-config
  else
    die "nixos-generate-config not found - pass --hardware-file PATH or --skip-hardware"
  fi
}
if (( SKIP_HW )); then
  info "skipping _hardware.nix (--skip-hardware)"
elif [[ -f $HW ]] && ! confirm "$HW exists - regenerate it?" N; then
  info "keeping existing $HW"
else
  hw_content=$(gen_hardware)
  # pin the platform to the chosen system
  hw_content=$(printf '%s\n' "$hw_content" | sed -E \
    "s#(nixpkgs\.hostPlatform *= *(lib\.mkDefault +)?)\"[^\"]*\"#\1\"$SYSTEM\"#")
  if ! grep -q 'nixpkgs\.hostPlatform' <<<"$hw_content"; then
    hw_content=$(printf '%s\n' "$hw_content" | sed -E \
      "s#^\}[[:space:]]*\$#  nixpkgs.hostPlatform = lib.mkDefault \"$SYSTEM\";\n}#")
  fi
  printf '%s\n' "$hw_content" | write_file "$HW"
  grep -qE 'REPLACE|CHANGE|nodev' "$HW" 2>/dev/null && \
    warn "check $HW - it may still have placeholders or need the dGPU block removed"
fi

# ---------------------------------------------------------------- _user.nix ----
USR="$HOSTDIR/_user.nix"
build_user_block() {
  local uname fullname groups extra_groups g hash pw pw2
  local -a group_list pkg_list
  local pkgs_in pkg avatar avatar_ref wk rbw

  uname=$(ask "  username")
  [[ $uname =~ ^[a-z_][a-z0-9_-]*$ ]] || { warn "invalid username, skipping"; return 1; }

  fullname=$(ask "  full name" "$(tr '[:lower:]' '[:upper:]' <<<"${uname:0:1}")${uname:1}")

  group_list=(networkmanager video input)
  confirm "  sudo access (add to 'wheel')?" Y && group_list+=(wheel)
  extra_groups=$(ask "  extra groups (space-separated, blank for none)" "")
  for g in $extra_groups; do [[ $g =~ ^[a-zA-Z0-9_-]+$ ]] && group_list+=("$g"); done
  # dedupe, preserve order
  groups=$(printf '%s\n' "${group_list[@]}" | awk '!seen[$0]++' | sed 's/.*/"&"/' | paste -sd' ' -)

  hash=""
  if confirm "  set a password now (else first login is 'changeme')?" Y; then
    while :; do
      pw=$(ask_secret "  password:"); pw2=$(ask_secret "  confirm :")
      [[ $pw == "$pw2" && -n $pw ]] && break
      warn "  didn't match (or empty) - try again"
    done
    hash=$(printf '%s' "$pw" | "${MKPASSWD[@]}" -m sha-512 -s) || die "mkpasswd failed"
  fi

  avatar_ref=""
  avatar=$(ask "  avatar image path (blank to skip)" "")
  if [[ -n $avatar ]]; then
    if [[ -f $avatar ]]; then
      run cp "$avatar" "$HOSTDIR/${uname}-avatar${avatar##*.}"
      avatar_ref="./${uname}-avatar${avatar##*.}"
    else warn "  $avatar not found - skipping avatar"; fi
  fi

  pkg_list=()
  pkgs_in=$(ask "  extra packages (nixpkgs attrs, space-separated, blank for none)" "")
  for pkg in $pkgs_in; do
    if [[ $pkg =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then pkg_list+=("$pkg")
    else warn "  ignoring odd package name: $pkg"; fi
  done

  wk=""; rbw=""
  if confirm "  set any secrets (WakaTime key / rbw email)?" N; then
    wk=$(ask "    WAKATIME_API_KEY (blank to skip)" "")
    rbw=$(ask "    RBW_EMAIL (blank to skip)" "")
  fi

  # ---- emit ----
  printf '    %s = {\n' "$uname"
  printf '      fullName = "%s";\n' "$(nix_str "$fullname")"
  printf '      extraGroups = [ %s ];\n' "$groups"
  [[ -n $hash ]]       && printf '      hashedPassword = "%s";\n' "$(nix_str "$hash")"
  [[ -n $avatar_ref ]] && printf '      avatar = %s;\n' "$avatar_ref"
  if (( ${#pkg_list[@]} )); then
    printf '      extraPackages = with pkgs; [ %s ];\n' "${pkg_list[*]}"
  fi
  if [[ -n $wk || -n $rbw ]]; then
    printf '      secrets = {\n'
    [[ -n $wk  ]] && printf '        WAKATIME_API_KEY = "%s";\n' "$(nix_str "$wk")"
    [[ -n $rbw ]] && printf '        RBW_EMAIL = "%s";\n' "$(nix_str "$rbw")"
    printf '      };\n'
  fi
  printf '    };\n'
}

if [[ -f $USR ]] && ! confirm "$USR exists - rebuild it?" N; then
  info "keeping existing $USR"
else
  say "Users for $HOST - add at least one."
  users_nix=""
  while :; do
    if block=$(build_user_block); then users_nix+="$block"$'\n'; fi
    confirm "Add another user?" N || break
  done
  [[ -n $users_nix ]] || die "no users defined - _user.nix needs at least one"
  { printf '{ pkgs, ... }:\n{\n  vayume.users = {\n%s  };\n}\n' "$users_nix"; } | write_file "$USR"
fi

# ---------------------------------------------------------------- wrap up ------
if (( IS_GIT && ! DRY_RUN )) && [[ -d $HOSTDIR && $HOST != Diablo ]]; then
  git -C "$REPO" add "$HOSTDIR/Host.nix" "$HOSTDIR/Vm.nix" "$HOSTDIR"/*.nix.example 2>/dev/null || true
  info "staged the tracked files in $HOSTDIR (_hardware.nix / _user.nix stay gitignored)"
fi

echo
say "Done. ${bold}$HOSTDIR${rst} now has:"
for f in Host.nix _hardware.nix _user.nix; do
  if [[ -f $HOSTDIR/$f ]]; then info "${grn}✓${rst} $f"; else info "${ylw}–${rst} $f (skipped)"; fi
done
echo
REBUILD_CMD=(sudo nixos-rebuild switch --flake "path:.#$HOST")
info "review the files, then:  ${bold}${REBUILD_CMD[*]}${rst}"
info "${dim}(path:.# is required - a bare .# hides the gitignored files)${rst}"

if (( DO_REBUILD == 1 )) || { (( DO_REBUILD == -1 )) && ! (( DRY_RUN )) && confirm $'\n'"Run it now?" N; }; then
  exec "${REBUILD_CMD[@]}"
fi
