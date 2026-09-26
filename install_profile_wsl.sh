#!/usr/bin/env bash
# WSL2 profile setup: same shell config as install_profile.sh, without GNOME dconf.
set -euxo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "install_profile_wsl.sh is for WSL2 only. On native Ubuntu, use ./install_profile.sh instead."
	exit 1
fi

clone_plugin() {
	local url="$1"
	local dest="$2"
	if [[ -d "${dest}/.git" ]]; then
		return 0
	fi
	mkdir -p "$(dirname "$dest")"
	git clone "$url" "$dest"
}

clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" \
	"${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
clone_plugin "https://github.com/zsh-users/zsh-autosuggestions" \
	"${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

cp "${REPO_ROOT}/configs/.zshrc" "${HOME}/.zshrc"
cp "${REPO_ROOT}/configs/pixegami-agnoster.zsh-theme" \
	"${HOME}/.oh-my-zsh/themes/pixegami-agnoster.zsh-theme"

chsh -s "$(command -v zsh)"

echo "Shell profile installed. Run ./wsl_apply_windows_terminal.sh for Ubuntu WSL colors/font in Windows Terminal."
