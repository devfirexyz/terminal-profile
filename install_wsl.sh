#!/usr/bin/env bash
# Full Pixegami install for WSL2 (Linux shell + Windows Terminal / Cursor appearance).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "This script is for WSL2 only."
	echo "On native Ubuntu with GNOME Terminal, use:"
	echo "  ./install_powerline.sh && ./install_terminal.sh && ./install_profile.sh"
	exit 1
fi

"${REPO_ROOT}/install_powerline.sh"
"${REPO_ROOT}/install_terminal.sh"
"${REPO_ROOT}/install_profile_wsl.sh"
"${REPO_ROOT}/wsl_apply_windows_terminal.sh"

cat <<'EOF'

WSL install finished.

Next steps on Windows:
  1. If a font preview opens, click Install for "Roboto Mono for Powerline".
  2. Fully quit Cursor and Windows Terminal, then reopen.
  3. Open a new terminal tab and confirm zsh + Pixegami colors.

If the font is still missing, sign out of Windows once, or run:
  ./wsl_apply_windows_terminal.sh

EOF
