#!/usr/bin/env bash
set -euo pipefail

# Install or update Neovim to the latest release on Debian/Ubuntu
# 1. Try .deb package
# 2. If .deb fails (e.g. glibc too old), fall back to AppImage
#    - Try running AppImage directly
#    - If FUSE is not available, extract it and use the extracted binary
# Also ensures $HOME/.local/bin (e.g. /home/thomas/.local/bin) is in PATH.

REPO="neovim/neovim"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
ARCH="amd64"

ensure_local_bin_in_path() {
  BIN_DIR="${HOME}/.local/bin"

  # Create directory if needed
  mkdir -p "$BIN_DIR"

  case ":$PATH:" in
    *":${BIN_DIR}:"*)
      echo "✔ ${BIN_DIR} already in PATH."
      ;;
    *)
      echo "➜ ${BIN_DIR} is not in PATH. Adding it."

      # Export for current session
      export PATH="${BIN_DIR}:${PATH}"

      # Persist for future shells (bash/sh via ~/.profile)
      PROFILE_FILE="${HOME}/.profile"

      if ! grep -Fq '${HOME}/.local/bin' "$PROFILE_FILE" 2>/dev/null; then
        {
          echo ""
          echo "# Added by Neovim installer on $(date)"
          echo 'export PATH="$HOME/.local/bin:$PATH"'
        } >> "$PROFILE_FILE"
        echo "✔ Added export line to ${PROFILE_FILE}"
      else
        echo "ℹ PATH line for ~/.local/bin already present in ${PROFILE_FILE}"
      fi

      # Also add to ~/.bashrc if it exists and doesn't already contain it
      if [ -f "${HOME}/.bashrc" ] && ! grep -Fq '${HOME}/.local/bin' "${HOME}/.bashrc"; then
        {
          echo ""
          echo "# Ensure ~/.local/bin is in PATH (added by Neovim installer)"
          echo 'export PATH="$HOME/.local/bin:$PATH"'
        } >> "${HOME}/.bashrc"
        echo "✔ Added export line to ${HOME}/.bashrc"
      fi

      ;;
  esac
}

echo "Fetching latest Neovim release info from GitHub…"

json="$(curl -fsSL "$API_URL")" || {
  echo "Error: failed to query GitHub API." >&2
  exit 1
}

tag_name="$(printf '%s\n' "$json" | grep -m1 '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"

if [ -z "$tag_name" ]; then
  echo "Error: could not determine latest tag_name from GitHub API." >&2
  exit 1
fi

echo "Latest tag is: $tag_name"

# Try .deb first
deb_url="$(printf '%s\n' "$json" \
  | grep -Eo 'https://[^"]+nvim-linux64\.deb' \
  | head -n1 || true)"

deb_installed=0

if [ -n "${deb_url:-}" ]; then
  echo "Found Debian package asset:"
  echo "  $deb_url"

  tmp_deb="/tmp/nvim-${tag_name}-${ARCH}.deb"
  echo "Downloading Neovim .deb to ${tmp_deb}…"

  if curl -fL "$deb_url" -o "$tmp_deb"; then
    echo "Installing Neovim from .deb (requires sudo)…"
    if sudo dpkg -i "$tmp_deb" || sudo apt-get -f install -y; then
      deb_installed=1
      echo "Cleaning up .deb…"
      rm -f "$tmp_deb"
    else
      echo "Warning: .deb installation failed (possibly glibc version issue)."
      echo "Falling back to AppImage builds for older glibc…"
      rm -f "$tmp_deb" || true
    fi
  else
    echo "Warning: failed to download .deb. Falling back to AppImage…" >&2
  fi
else
  echo "No nvim-linux64.deb asset found in latest release. Falling back to AppImage…" >&2
fi

if [ "$deb_installed" -eq 1 ]; then
  ensure_local_bin_in_path
  echo
  echo "Neovim ${tag_name} installed from .deb!"
  echo "Version check:"
  nvim --version | head -n3 || true
  exit 0
fi

echo
echo "=== AppImage fallback (for older glibc) ==="

# Find AppImage asset
appimage_url="$(printf '%s\n' "$json" \
  | grep -Eo 'https://[^"]+nvim-linux-x86_64\.appimage' \
  | head -n1 || true)"

if [ -z "${appimage_url:-}" ]; then
  echo "Error: could not find nvim-linux-x86_64.appimage asset in latest release." >&2
  echo "Check the release assets here:"
  echo "  https://github.com/${REPO}/releases/tag/${tag_name}"
  exit 1
fi

echo "Found AppImage asset:"
echo "  $appimage_url"

BIN_DIR="${HOME}/.local/bin"
ensure_local_bin_in_path

APPIMAGE_PATH="${BIN_DIR}/nvim.appimage"

echo "Downloading AppImage to ${APPIMAGE_PATH}…"
curl -fL "$appimage_url" -o "$APPIMAGE_PATH"

chmod u+x "$APPIMAGE_PATH"

echo "Trying to run AppImage directly…"
if "$APPIMAGE_PATH" --version >/dev/null 2>&1; then
  ln -sf "$APPIMAGE_PATH" "${BIN_DIR}/nvim"
  echo
  echo "Neovim AppImage installed as:"
  echo "  ${BIN_DIR}/nvim"
  echo
  echo "Version check:"
  "${BIN_DIR}/nvim" --version | head -n3 || true
  exit 0
fi

echo
echo "AppImage could not be run directly (likely no FUSE)."
echo "Extracting AppImage…"

WORKDIR="$(mktemp -d)"
cp "$APPIMAGE_PATH" "${WORKDIR}/nvim.appimage"

(
  cd "$WORKDIR"
  ./nvim.appimage --appimage-extract >/dev/null 2>&1
)

NEOVIM_APPIMAGE_DIR="${HOME}/.local/neovim-appimage"
mkdir -p "$NEOVIM_APPIMAGE_DIR"

# Replace any previous extracted tree
rm -rf "${NEOVIM_APPIMAGE_DIR}/squashfs-root"
mv "${WORKDIR}/squashfs-root" "${NEOVIM_APPIMAGE_DIR}/squashfs-root"

rm -rf "$WORKDIR"

ln -sf "${NEOVIM_APPIMAGE_DIR}/squashfs-root/usr/bin/nvim" "${BIN_DIR}/nvim"

echo
echo "Neovim extracted from AppImage."
echo "Installed binary symlinked as:"
echo "  ${BIN_DIR}/nvim"
echo
echo "Version check:"
"${BIN_DIR}/nvim" --version | head -n3 || true
