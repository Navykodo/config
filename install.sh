#!/usr/bin/env bash
# Lite v1 offline installer. No downloads, sudo, automatic server reload, or telemetry.
set -Eeuo pipefail
umask 077
kit_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
kit_home=${HOME:?HOME is not set}
kit_state="$kit_home/.local/state/vim-tmux-kit"
kit_mode=${1:---install}
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
version_check() {
  command -v vim >/dev/null || die 'Vim is missing (requires 9.1+)'
  vim -Nu NONE -i NONE -n -es -c 'if v:version < 901 || !has("popupwin") | cquit 2 | endif' -c 'qa!' || die 'Requires Vim 9.1+ with popupwin'
  command -v tmux >/dev/null || die 'tmux is missing (requires 3.3+)'
  local ver major minor
  ver=$(tmux -V); ver=${ver#tmux }; major=${ver%%.*}; minor=${ver#*.}; minor=${minor%%[!0-9]*}
  [[ $major =~ ^[0-9]+$ && $minor =~ ^[0-9]+$ ]] || die 'Unknown tmux version'
  (( major > 3 || (major == 3 && minor >= 3) )) || die 'Requires tmux >=3.3'
  infocmp tmux-256color >/dev/null 2>&1 || die 'tmux-256color terminfo missing; install it before deployment'
}
restore() {
  local backup=$1 name
  [[ -d "$backup" && -f "$backup/COMPLETE" ]] || die 'Not a complete kit backup'
  for name in vimrc tmux.conf; do
    [[ ! -d "$kit_home/.$name" ]] || die "Target is a directory: .$name"
    [[ -e "$backup/$name" || -L "$backup/$name" || -f "$backup/$name.absent" ]] || die "Incomplete backup: $name"
  done
  for name in vimrc tmux.conf; do
    if [[ -e "$backup/$name" || -L "$backup/$name" ]]; then
      rm -f -- "$kit_home/.$name"
      cp -a -- "$backup/$name" "$kit_home/.$name"
    elif [[ -f "$backup/$name.absent" ]]; then
      rm -f -- "$kit_home/.$name"
    else
      die "Incomplete backup for $name"
    fi
  done
}
case "$kit_mode" in
  --help|-h)
    printf '%s\n' 'bash install.sh [--check|--install|--rollback BACKUP_DIR]' 'Default: offline install. Existing configs are backed up including symlinks.' 'Rollback overwrites current configs; save later edits first. Never kills or reloads a live tmux server.'; exit 0 ;;
  --rollback)
    [[ $# == 2 ]] || die 'Specify exact backup directory'
    [[ $2 == "$kit_state"/backup-* ]] || die 'Backup must belong to this user kit state directory'
    restore "$2"
    printf 'Restored %s. Restart Vim; reload tmux manually.\n' "$2"; exit 0 ;;
  --check|--install) ;;
  *) die 'Unknown option; use --help' ;;
esac
[[ $# -le 1 ]] || die 'Unexpected arguments'
[[ "$kit_home" == /* && "$kit_home" != / && -d "$kit_home" && -w "$kit_home" ]] || die 'HOME must be a writable, non-root absolute directory'
for file in vimrc tmux.conf DEPLOY.md install.sh; do [[ -f "$kit_dir/$file" ]] || die "Missing $file"; done
version_check
for name in vimrc tmux.conf; do [[ ! -d "$kit_home/.$name" ]] || die "Target is a directory: .$name"; done
kit_tmp=$(mktemp -d "${TMPDIR:-/tmp}/vim-tmux-kit.XXXXXXXX")
trap 'if [[ -S "$kit_tmp/tmux.sock" ]]; then tmux -S "$kit_tmp/tmux.sock" kill-server >/dev/null 2>&1 || true; fi; rm -rf -- "$kit_tmp"' EXIT
mkdir "$kit_tmp/home"
# Validate without touching the real HOME, viminfo, or undo directories.
HOME="$kit_tmp/home" vim -Nu "$kit_dir/vimrc" -i NONE -n -es -V1"$kit_tmp/vim.log" -c 'call KitSelfCheck()' -c 'qa!' || { tail -30 "$kit_tmp/vim.log"; die 'Vim validation failed'; }
# An isolated server parses the config. Socket restrictions are reported plainly.
kit_socket="$kit_tmp/tmux.sock"
if ! tmux -S "$kit_socket" -f /dev/null new-session -d -s kit-check 'sleep 30' 2>"$kit_tmp/tmux.log"; then
  cat "$kit_tmp/tmux.log"; die 'Isolated tmux validation failed (socket permissions or config)'
fi
if ! tmux -S "$kit_socket" source-file "$kit_dir/tmux.conf" 2>>"$kit_tmp/tmux.log"; then
  cat "$kit_tmp/tmux.log"; die 'tmux configuration failed to load'
fi
kit_errors=$(tmux -S "$kit_socket" show-messages 2>/dev/null || true)
tmux -S "$kit_socket" kill-server
if [[ -s "$kit_tmp/tmux.log" || $kit_errors == *"unknown command"* || $kit_errors == *"invalid"* ]]; then
  cat "$kit_tmp/tmux.log"; printf '%s\n' "$kit_errors"; die 'tmux config diagnostics require inspection'
fi
printf 'Vim/tmux checks passed.\n'
if [[ -z "$(command -v xclip || command -v wl-copy || command -v pbcopy || true)" && ! -x "$kit_home/.local/bin/xclip" ]]; then
  printf 'NOTE: no desktop clipboard tool found; clipboard may require terminal OSC52 support.\n'
fi
[[ $kit_mode == --check ]] && exit 0
if cmp -s "$kit_dir/vimrc" "$kit_home/.vimrc" && cmp -s "$kit_dir/tmux.conf" "$kit_home/.tmux.conf"; then
  printf 'Already installed; no changes.\n'; exit 0
fi
mkdir -p "$kit_state"
kit_backup=$(mktemp -d "$kit_state/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")
for name in vimrc tmux.conf; do
  if [[ -e "$kit_home/.$name" || -L "$kit_home/.$name" ]]; then cp -a -- "$kit_home/.$name" "$kit_backup/$name"; else touch "$kit_backup/$name.absent"; fi
done
touch "$kit_backup/COMPLETE"
kit_committing=1
on_error() {
  local rc=$?
  trap - ERR
  if [[ ${kit_committing:-0} == 1 ]]; then restore "$kit_backup"; fi
  printf 'Installation failed; restored backup: %s\n' "$kit_backup" >&2
  exit "$rc"
}
trap on_error ERR
trap 'false' HUP INT TERM
for name in vimrc tmux.conf; do
  kit_stage=$(mktemp "$kit_home/.kit-${name}.XXXXXX")
  install -m 0644 "$kit_dir/$name" "$kit_stage"
  mv -f -- "$kit_stage" "$kit_home/.$name"
done
kit_committing=0
printf 'Installed. Backup: %s\n' "$kit_backup"
printf '%s\n' 'Open a new Vim. In live tmux: tmux source-file ~/.tmux.conf' 'Existing tmux panes retain their old TERM; test colors in a newly created pane.'
