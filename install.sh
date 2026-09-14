#!/usr/bin/env bash
# Lite v1 offline installer. No downloads, sudo, automatic server reload, or telemetry.
set -Eeuo pipefail
umask 077
kit_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
kit_home=${HOME:?HOME is not set}
kit_state="$kit_home/.local/state/vim-tmux-kit"
kit_mode=${1:---install}
kit_visual_files=(
  mime/packages/verilog-workbench.xml
  icons/hicolor/scalable/mimetypes/text-x-verilog.svg
  icons/hicolor/scalable/mimetypes/text-x-verilog-header.svg
  icons/hicolor/scalable/mimetypes/text-x-systemverilog.svg
  icons/hicolor/scalable/mimetypes/text-x-systemverilog-header.svg
  icons/hicolor/scalable/mimetypes/text-x-svsrc.svg
  icons/hicolor/scalable/mimetypes/text-x-svhdr.svg
)
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
write_hdl_visuals() {
  local root=$1
  mkdir -p "$root/mime/packages" "$root/icons/hicolor/scalable/mimetypes"
  cat >"$root/mime/packages/verilog-workbench.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="text/x-verilog-header">
    <comment>Verilog header</comment>
    <comment xml:lang="zh_CN">Verilog 头文件</comment>
    <sub-class-of type="text/x-verilog"/>
    <glob pattern="*.vh" weight="90"/>
  </mime-type>
</mime-info>
EOF
  cat >"$root/icons/hicolor/scalable/mimetypes/text-x-verilog.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect x="15" y="15" width="98" height="98" rx="20" fill="#1769d2"/>
  <rect x="22" y="22" width="84" height="84" rx="15" fill="#0d47a1" stroke="#67e8f9" stroke-width="4"/>
  <g stroke="#67e8f9" stroke-width="5" stroke-linecap="round">
    <path d="M4 35h11M4 54h11M4 74h11M4 93h11M113 35h11M113 54h11M113 74h11M113 93h11"/>
    <path d="M35 4v11M54 4v11M74 4v11M93 4v11M35 113v11M54 113v11M74 113v11M93 113v11"/>
  </g>
  <path d="M36 39l27 53 29-53" fill="none" stroke="#ffffff" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="92" cy="92" r="7" fill="#fbbf24"/>
</svg>
EOF
  cat >"$root/icons/hicolor/scalable/mimetypes/text-x-verilog-header.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect x="15" y="15" width="98" height="98" rx="20" fill="#1769d2"/>
  <rect x="22" y="22" width="84" height="84" rx="15" fill="#0d47a1" stroke="#67e8f9" stroke-width="4"/>
  <g stroke="#67e8f9" stroke-width="5" stroke-linecap="round">
    <path d="M4 35h11M4 54h11M4 74h11M4 93h11M113 35h11M113 54h11M113 74h11M113 93h11"/>
    <path d="M35 4v11M54 4v11M74 4v11M93 4v11M35 113v11M54 113v11M74 113v11M93 113v11"/>
  </g>
  <path d="M37 35l26 48 28-48" fill="none" stroke="#ffffff" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="64" y="104" text-anchor="middle" fill="#fbbf24" font-family="sans-serif" font-size="22" font-weight="800">H</text>
</svg>
EOF
  cat >"$root/icons/hicolor/scalable/mimetypes/text-x-systemverilog.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect x="15" y="15" width="98" height="98" rx="20" fill="#7c3aed"/>
  <rect x="22" y="22" width="84" height="84" rx="15" fill="#4c1d95" stroke="#c4b5fd" stroke-width="4"/>
  <g stroke="#c4b5fd" stroke-width="5" stroke-linecap="round">
    <path d="M4 35h11M4 54h11M4 74h11M4 93h11M113 35h11M113 54h11M113 74h11M113 93h11"/>
    <path d="M35 4v11M54 4v11M74 4v11M93 4v11M35 113v11M54 113v11M74 113v11M93 113v11"/>
  </g>
  <text x="64" y="78" text-anchor="middle" fill="#ffffff" font-family="sans-serif" font-size="43" font-weight="800">SV</text>
  <circle cx="94" cy="94" r="7" fill="#fbbf24"/>
</svg>
EOF
  cat >"$root/icons/hicolor/scalable/mimetypes/text-x-systemverilog-header.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect x="15" y="15" width="98" height="98" rx="20" fill="#7c3aed"/>
  <rect x="22" y="22" width="84" height="84" rx="15" fill="#4c1d95" stroke="#c4b5fd" stroke-width="4"/>
  <g stroke="#c4b5fd" stroke-width="5" stroke-linecap="round">
    <path d="M4 35h11M4 54h11M4 74h11M4 93h11M113 35h11M113 54h11M113 74h11M113 93h11"/>
    <path d="M35 4v11M54 4v11M74 4v11M93 4v11M35 113v11M54 113v11M74 113v11M93 113v11"/>
  </g>
  <text x="64" y="69" text-anchor="middle" fill="#ffffff" font-family="sans-serif" font-size="38" font-weight="800">SV</text>
  <text x="64" y="94" text-anchor="middle" fill="#fbbf24" font-family="sans-serif" font-size="21" font-weight="800">H</text>
</svg>
EOF
  cp "$root/icons/hicolor/scalable/mimetypes/text-x-systemverilog.svg" "$root/icons/hicolor/scalable/mimetypes/text-x-svsrc.svg"
  cp "$root/icons/hicolor/scalable/mimetypes/text-x-systemverilog-header.svg" "$root/icons/hicolor/scalable/mimetypes/text-x-svhdr.svg"
}
refresh_hdl_visuals() {
  if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database "$kit_home/.local/share/mime"
  else
    printf 'NOTE: update-mime-database is missing; .vh type registration is pending.\n'
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$kit_home/.local/share/icons/hicolor" >/dev/null
  else
    printf 'NOTE: gtk-update-icon-cache is missing; reopen the desktop session if icons remain cached.\n'
  fi
}
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
  local backup=$1 name rel target saved
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
  if [[ -f "$backup/VISUALS" ]]; then
    for rel in "${kit_visual_files[@]}"; do
      target="$kit_home/.local/share/$rel"
      saved="$backup/visuals/$rel"
      mkdir -p "$(dirname "$target")"
      if [[ -e "$saved" || -L "$saved" ]]; then
        rm -f -- "$target"
        cp -a -- "$saved" "$target"
      elif [[ -f "$saved.absent" ]]; then
        rm -f -- "$target"
      else
        die "Incomplete visual backup: $rel"
      fi
    done
    refresh_hdl_visuals
  fi
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
write_hdl_visuals "$kit_tmp/visuals"
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
kit_same=1
cmp -s "$kit_dir/vimrc" "$kit_home/.vimrc" || kit_same=0
cmp -s "$kit_dir/tmux.conf" "$kit_home/.tmux.conf" || kit_same=0
for rel in "${kit_visual_files[@]}"; do
  cmp -s "$kit_tmp/visuals/$rel" "$kit_home/.local/share/$rel" || kit_same=0
done
if [[ $kit_same == 1 ]]; then
  printf 'Already installed; no changes.\n'; exit 0
fi
mkdir -p "$kit_state"
kit_backup=$(mktemp -d "$kit_state/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")
for name in vimrc tmux.conf; do
  if [[ -e "$kit_home/.$name" || -L "$kit_home/.$name" ]]; then cp -a -- "$kit_home/.$name" "$kit_backup/$name"; else touch "$kit_backup/$name.absent"; fi
done
touch "$kit_backup/VISUALS"
for rel in "${kit_visual_files[@]}"; do
  target="$kit_home/.local/share/$rel"
  saved="$kit_backup/visuals/$rel"
  mkdir -p "$(dirname "$saved")"
  if [[ -e "$target" || -L "$target" ]]; then
    cp -a -- "$target" "$saved"
  else
    touch "$saved.absent"
  fi
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
for rel in "${kit_visual_files[@]}"; do
  install -D -m 0644 "$kit_tmp/visuals/$rel" "$kit_home/.local/share/$rel"
done
refresh_hdl_visuals
kit_committing=0
printf 'Installed. Backup: %s\n' "$kit_backup"
printf '%s\n' 'Open a new Vim. In live tmux: tmux source-file ~/.tmux.conf' 'Existing tmux panes retain their old TERM; test colors in a newly created pane.'
printf '%s\n' 'HDL file icons installed. Refresh or reopen the file-manager window.'
