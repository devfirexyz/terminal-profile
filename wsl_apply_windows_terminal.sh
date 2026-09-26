#!/usr/bin/env bash
# Apply Pixegami colors + Powerline font on Windows (Terminal, WSL profile, optional Cursor).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_win_user() {
	if [[ -n "${WIN_USER:-}" ]]; then
		printf '%s' "$WIN_USER"
		return 0
	fi
	if command -v whoami.exe >/dev/null 2>&1; then
		whoami.exe | tr -d '\r\n'
		return 0
	fi
	echo "Set WIN_USER to your Windows login name (e.g. WIN_USER=Admin $0)." >&2
	return 1
}

WIN_USER="$(detect_win_user)"
WT_STATE="/mnt/c/Users/${WIN_USER}/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
WT_SETTINGS="${WT_STATE}/settings.json"
WSL_FRAGMENT="/mnt/c/Users/${WIN_USER}/AppData/Local/Microsoft/Windows Terminal/Fragments/Microsoft.WSL/{d6c95319-5a40-5c47-b65e-bec40e033979}.json"
CURSOR_SETTINGS="/mnt/c/Users/${WIN_USER}/AppData/Roaming/Cursor/User/settings.json"
FONT_SRC="${REPO_ROOT}/fonts/RobotoMono"
UBUNTU_PROFILE_GUID="{d6c95319-5a40-5c47-b65e-bec40e033979}"
APPLY_CURSOR="${APPLY_CURSOR:-1}"

PIXEGAMI_SCHEME='{
  "name": "Pixegami",
  "background": "#0C1C25",
  "foreground": "#86FFAF",
  "black": "#152535",
  "red": "#FF3C3C",
  "green": "#49FF6D",
  "yellow": "#FFBC51",
  "blue": "#3DB6F9",
  "purple": "#8E44AD",
  "cyan": "#16A085",
  "white": "#BDC3C7",
  "brightBlack": "#26384B",
  "brightRed": "#FF3C4C",
  "brightGreen": "#93FF91",
  "brightYellow": "#FFD057",
  "brightBlue": "#5BD7FF",
  "brightPurple": "#9B59B6",
  "brightCyan": "#205C57",
  "brightWhite": "#FFFFFF"
}'

if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "This script is intended for WSL2 (WSL_DISTRO_NAME is unset)." >&2
	exit 1
fi

PS_EXE="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
PS_SCRIPT="${REPO_ROOT}/install_windows_fonts.ps1"
if [[ ! -x "$PS_EXE" && ! -f "$PS_EXE" ]]; then
	echo "Windows PowerShell not found at $PS_EXE" >&2
	exit 1
fi
"$PS_EXE" -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$PS_SCRIPT")" "$(wslpath -w "$FONT_SRC")"

export WT_SETTINGS WSL_FRAGMENT CURSOR_SETTINGS UBUNTU_PROFILE_GUID APPLY_CURSOR
export PIXEGAMI_SCHEME

python3 - <<'PY'
import json
import os
from pathlib import Path

ubuntu_guid = os.environ["UBUNTU_PROFILE_GUID"]
pixegami = json.loads(os.environ["PIXEGAMI_SCHEME"])
font = {"face": "Roboto Mono for Powerline", "size": 14}
apply_cursor = os.environ.get("APPLY_CURSOR", "1") == "1"

terminal_colors = {
    "terminal.background": "#0C1C25",
    "terminal.foreground": "#86FFAF",
    "terminal.ansiBlack": "#152535",
    "terminal.ansiRed": "#FF3C3C",
    "terminal.ansiGreen": "#49FF6D",
    "terminal.ansiYellow": "#FFBC51",
    "terminal.ansiBlue": "#3DB6F9",
    "terminal.ansiMagenta": "#8E44AD",
    "terminal.ansiCyan": "#16A085",
    "terminal.ansiWhite": "#BDC3C7",
    "terminal.ansiBrightBlack": "#26384B",
    "terminal.ansiBrightRed": "#FF3C4C",
    "terminal.ansiBrightGreen": "#93FF91",
    "terminal.ansiBrightYellow": "#FFD057",
    "terminal.ansiBrightBlue": "#5BD7FF",
    "terminal.ansiBrightMagenta": "#9B59B6",
    "terminal.ansiBrightCyan": "#205C57",
    "terminal.ansiBrightWhite": "#FFFFFF",
}


def upsert_scheme(schemes):
    out = [s for s in (schemes or []) if s.get("name") != "Pixegami"]
    out.append(pixegami)
    return out


def patch_ubuntu_profile(profiles):
    for p in profiles:
        if p.get("guid") == ubuntu_guid or p.get("updates") == ubuntu_guid:
            p["colorScheme"] = "Pixegami"
            p["font"] = dict(font)
    return profiles


wt_settings = Path(os.environ["WT_SETTINGS"])
if wt_settings.is_file():
    data = json.loads(wt_settings.read_text(encoding="utf-8"))
    data["schemes"] = upsert_scheme(data.get("schemes"))
    plist = data.setdefault("profiles", {}).setdefault("list", [])
    patch_ubuntu_profile(plist)
    data["defaultProfile"] = ubuntu_guid
    wt_settings.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    print(f"Patched Windows Terminal settings: {wt_settings}")
else:
    print(f"Skip: Windows Terminal settings not found at {wt_settings}")

wsl_fragment = Path(os.environ["WSL_FRAGMENT"])
if wsl_fragment.is_file():
    frag = json.loads(wsl_fragment.read_text(encoding="utf-8"))
    frag["schemes"] = upsert_scheme(frag.get("schemes"))
    for p in frag.get("profiles", []):
        if p.get("guid") == ubuntu_guid:
            p["colorScheme"] = "Pixegami"
            p["font"] = dict(font)
    wsl_fragment.write_text(json.dumps(frag, indent=2) + "\n", encoding="utf-8")
    print(f"Patched WSL terminal fragment: {wsl_fragment}")
else:
    print(f"Skip: WSL fragment not found at {wsl_fragment}")

if apply_cursor:
    cursor_settings = Path(os.environ["CURSOR_SETTINGS"])
    cursor_settings.parent.mkdir(parents=True, exist_ok=True)
    if cursor_settings.is_file():
        try:
            cursor = json.loads(cursor_settings.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError:
            cursor = {}
    else:
        cursor = {}

    cursor["terminal.integrated.fontFamily"] = (
        "'Roboto Mono for Powerline', 'Ubuntu Mono', Consolas, monospace"
    )
    cursor["terminal.integrated.fontSize"] = 14
    cc = cursor.setdefault("workbench.colorCustomizations", {})
    cc.update(terminal_colors)
    cursor_settings.write_text(json.dumps(cursor, indent=4) + "\n", encoding="utf-8")
    print(f"Patched Cursor terminal settings: {cursor_settings}")
else:
    print("Skip: Cursor settings (APPLY_CURSOR=0)")
PY

echo ""
echo "Done. Fully quit Windows Terminal and Cursor, then reopen."
echo "Open a new terminal tab so zsh, colors, and font reload."
