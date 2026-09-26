#!/usr/bin/env bash
# Quick checks for WSL2 Pixegami install (stdout only).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok() { printf '  OK   %s\n' "$1"; }
warn() { printf '  WARN %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; }

echo "=== WSL environment ==="
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
	ok "WSL distro: ${WSL_DISTRO_NAME}"
else
	fail "Not running in WSL (use install_profile.sh on native Ubuntu)"
fi

echo "=== Shell (Linux) ==="
login_shell="$(getent passwd "$(whoami)" | cut -d: -f7)"
if [[ "$login_shell" == *zsh ]]; then
	ok "Login shell: $login_shell"
else
	warn "Login shell is $login_shell (expected zsh after install_profile_wsl.sh)"
fi

if [[ -f "${HOME}/.zshrc" ]] && grep -q 'ZSH_THEME="pixegami-agnoster"' "${HOME}/.zshrc"; then
	ok "pixegami-agnoster in ~/.zshrc"
else
	warn "Missing or wrong ZSH_THEME in ~/.zshrc"
fi

if [[ -f "${HOME}/.oh-my-zsh/themes/pixegami-agnoster.zsh-theme" ]]; then
	ok "Theme file installed"
else
	warn "Theme file missing"
fi

echo "=== Windows Terminal / Cursor (host) ==="
win_user="${WIN_USER:-}"
if [[ -z "$win_user" ]] && command -v whoami.exe >/dev/null 2>&1; then
	win_user="$(whoami.exe | tr -d '\r\n')"
fi

if [[ -z "$win_user" ]]; then
	warn "Could not detect Windows user (set WIN_USER)"
else
	wt="/mnt/c/Users/${win_user}/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
	wsl_frag="/mnt/c/Users/${win_user}/AppData/Local/Microsoft/Windows Terminal/Fragments/Microsoft.WSL/{d6c95319-5a40-5c47-b65e-bec40e033979}.json"
	cursor="/mnt/c/Users/${win_user}/AppData/Roaming/Cursor/User/settings.json"

	if [[ -f "$wt" ]] && grep -q Pixegami "$wt"; then
		ok "Windows Terminal settings mention Pixegami"
	else
		warn "Windows Terminal not patched (run ./wsl_apply_windows_terminal.sh)"
	fi

	if [[ -f "$wsl_frag" ]] && grep -q Pixegami "$wsl_frag"; then
		ok "Microsoft.WSL fragment uses Pixegami"
	else
		warn "WSL fragment not patched or not found"
	fi

	if [[ -f "$cursor" ]] && grep -q 'terminal.background' "$cursor"; then
		ok "Cursor terminal colors configured"
	else
		warn "Cursor terminal colors not set (optional; set APPLY_CURSOR=1 when applying)"
	fi
fi

echo "=== dconf (native Ubuntu only) ==="
if command -v dconf >/dev/null 2>&1; then
	ok "dconf present (native GNOME path; not used on WSL)"
else
	ok "No dconf (expected on WSL — colors come from Windows Terminal / Cursor)"
fi

echo ""
echo "Repo: ${REPO_ROOT}"
