#!/usr/bin/env bash
set -euo pipefail

# Installs:
# - Docker + docker compose (plugin)
# - Ghostty (terminal)
# - Catppuccin theme for Ghostty (default: mocha)
# - Yazi (terminal file manager)
# - Zellij (terminal multiplexer)
# - fish (shell)
# - z (via zoxide: smarter cd)
#
# Target: Debian 11/12/13 with sudo available.

REPO_ZELLIJ="zellij-org/zellij"
ZELLIJ_API_URL="https://api.github.com/repos/${REPO_ZELLIJ}/releases/latest"

TARGET_USER="${SUDO_USER:-$USER}"

log() { printf '\n[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }

ensure_local_bin_in_path() {
  local BIN_DIR="$HOME/.local/bin"
  mkdir -p "$BIN_DIR"

  case ":$PATH:" in
  *":$BIN_DIR:"*)
    log "✔ $BIN_DIR already in PATH."
    ;;
  *)
    log "➜ Adding $BIN_DIR to PATH (current session + shell config)."
    export PATH="$BIN_DIR:$PATH"

    local files=("$HOME/.profile" "$HOME/.bashrc")
    for f in "${files[@]}"; do
      if [ -f "$f" ]; then
        if ! grep -Fq '.local/bin' "$f"; then
          {
            echo ""
            echo "# Added by dev-tools installer on $(date)"
            echo 'export PATH="$HOME/.local/bin:$PATH"'
          } >>"$f"
          log "✔ Added PATH line to $f"
        fi
      fi
    done

    if [ ! -f "$HOME/.profile" ]; then
      {
        echo "# Created by dev-tools installer on $(date)"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
      } >>"$HOME/.profile"
      log "✔ Created $HOME/.profile with PATH update"
    fi
    ;;
  esac
}

install_prereqs() {
  log "Installing prerequisites (curl, ca-certificates, gnupg, lsb-release)..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
}

ensure_griffo_repo() {
  # Community repo providing Ghostty, Yazi, zoxide, etc.
  if [ ! -f /etc/apt/sources.list.d/debian.griffo.io.list ]; then
    log "Adding debian.griffo.io repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -sS \
      https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc |
      sudo gpg --dearmor --yes \
        -o /etc/apt/keyrings/debian.griffo.io.gpg

    echo "deb [signed-by=/etc/apt/keyrings/debian.griffo.io.gpg] https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" |
      sudo tee /etc/apt/sources.list.d/debian.griffo.io.list >/dev/null

    sudo apt-get update
  else
    log "debian.griffo.io repository already configured."
  fi
}

install_docker() {
  log "Installing Docker Engine + docker compose plugin from official Docker repo..."

  sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc || true

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt-get update
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  if getent group docker >/dev/null 2>&1; then
    sudo usermod -aG docker "$TARGET_USER" || true
  fi

  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    if ! command -v docker-compose >/dev/null 2>&1; then
      for cand in /usr/libexec/docker/cli-plugins/docker-compose \
        /usr/lib/docker/cli-plugins/docker-compose; do
        if [ -x "$cand" ]; then
          sudo ln -sf "$cand" /usr/local/bin/docker-compose || true
          log "✔ Created docker-compose shim at /usr/local/bin/docker-compose"
          break
        fi
      done
    fi
  fi

  log "✔ Docker installed. You may need to log out/in for group changes to apply."
}

install_ghostty() {
  log "Installing Ghostty..."
  ensure_griffo_repo
  sudo apt-get install -y ghostty
  log "✔ Ghostty installed. Version:"
  ghostty --version || true
}

install_catppuccin_ghostty_theme() {
  log "Installing Catppuccin theme for Ghostty..."

  local GHOSTTY_CONFIG_DIR
  GHOSTTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
  mkdir -p "${GHOSTTY_CONFIG_DIR}/themes"

  # Change this env var before running to use another flavor: latte/frappe/macchiato/mocha
  local FLAVOR THEME_FILE THEME_URL
  FLAVOR="${GHOSTTY_CATPPUCCIN_FLAVOR:-mocha}"
  THEME_FILE="catppuccin-${FLAVOR}.conf"
  THEME_URL="https://raw.githubusercontent.com/catppuccin/ghostty/main/themes/${THEME_FILE}"

  log "Downloading Catppuccin (${FLAVOR}) theme from:"
  log "  ${THEME_URL}"

  if ! curl -fsSL "$THEME_URL" -o "${GHOSTTY_CONFIG_DIR}/themes/${THEME_FILE}"; then
    log "ERROR: Failed to download Catppuccin Ghostty theme (${FLAVOR})."
    return 1
  fi

  local CONFIG_FILE
  CONFIG_FILE="${GHOSTTY_CONFIG_DIR}/config"
  if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
  fi

  # If a theme line exists, replace it; otherwise append a new theme line
  if grep -q '^theme *= ' "$CONFIG_FILE"; then
    sed -i -E 's/^theme *=.*/theme = catppuccin-'"$FLAVOR"'.conf/' "$CONFIG_FILE"
  else
    {
      echo ""
      echo "# Theme set by dev-tools installer on $(date)"
      echo "theme = catppuccin-${FLAVOR}.conf"
    } >>"$CONFIG_FILE"
  fi

  log "✔ Catppuccin (${FLAVOR}) installed for Ghostty."
  log "   Theme file: ${GHOSTTY_CONFIG_DIR}/themes/${THEME_FILE}"
  log "   Config:     ${CONFIG_FILE}"
}

install_yazi() {
  log "Installing Yazi terminal file manager..."
  ensure_griffo_repo
  sudo apt-get install -y yazi
  log "✔ Yazi installed. Version:"
  yazi --version || true
}

install_zellij() {
  log "Installing latest Zellij release (GitHub binary to ~/.local/bin)..."

  ensure_local_bin_in_path

  local json tag_name asset_url tmp_dir
  json="$(curl -fsSL "$ZELLIJ_API_URL")" || {
    log "ERROR: Failed to query Zellij GitHub API."
    return 1
  }

  tag_name="$(printf '%s\n' "$json" | grep -m1 '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  if [ -z "$tag_name" ]; then
    log "ERROR: Could not determine Zellij latest tag."
    return 1
  fi
  log "Latest Zellij tag: $tag_name"

  asset_url="$(printf '%s\n' "$json" |
    grep -Eo 'https://[^"]+zellij-x86_64-unknown-linux-musl\.tar\.gz' |
    head -n1 || true)"

  if [ -z "$asset_url" ]; then
    log "ERROR: Could not find zellij-x86_64-unknown-linux-musl.tar.gz asset."
    return 1
  fi

  log "Downloading: $asset_url"
  tmp_dir="$(mktemp -d)"
  curl -fsSL "$asset_url" -o "$tmp_dir/zellij.tar.gz"

  tar -xzf "$tmp_dir/zellij.tar.gz" -C "$tmp_dir"
  install -m 0755 "$tmp_dir/zellij" "$HOME/.local/bin/zellij"
  rm -rf "$tmp_dir"

  log "✔ Zellij installed at $HOME/.local/bin/zellij. Version:"
  "$HOME/.local/bin/zellij" --version || true
}

install_fish() {
  log "Installing fish shell from Debian repository..."
  sudo apt-get install -y fish
  log "✔ fish installed. Version:"
  fish --version || true
}

install_z() {
  log "Installing z (via zoxide)..."
  ensure_griffo_repo

  sudo apt-get install -y zoxide

  log "✔ zoxide installed. Setting up 'z' integration for bash and fish (if present)."

  # Bash integration
  local BASHRC="$HOME/.bashrc"
  if [ -f "$BASHRC" ]; then
    if ! grep -Fq 'zoxide init bash' "$BASHRC"; then
      {
        echo ""
        echo "# z (zoxide) init added by dev-tools installer"
        echo 'eval "$(zoxide init bash --cmd z)"'
      } >>"$BASHRC"
      log "✔ Added zoxide init for bash in $BASHRC (use 'z' command)."
    else
      log "ℹ zoxide init for bash already present in $BASHRC"
    fi
  fi

  # Fish integration
  local FISH_CFG="$HOME/.config/fish/config.fish"
  mkdir -p "$(dirname "$FISH_CFG")"
  if ! grep -Fq 'zoxide init fish' "$FISH_CFG" 2>/dev/null; then
    {
      echo ""
      echo "# z (zoxide) init added by dev-tools installer"
      echo 'zoxide init fish --cmd z | source'
    } >>"$FISH_CFG"
    log "✔ Added zoxide init for fish in $FISH_CFG (use 'z' command)."
  else
    log "ℹ zoxide init for fish already present in $FISH_CFG"
  fi

  log "✔ z configured. Open a new shell to start using 'z'."
}

main() {
  log "Starting dev tools installer:"
  log "Docker, docker compose, Ghostty (+ Catppuccin), Yazi, Zellij, fish, z (zoxide)."

  ensure_local_bin_in_path
  install_prereqs
  install_docker
  install_ghostty
  install_catppuccin_ghostty_theme
  install_yazi
  install_zellij
  install_fish
  install_z

  log "All done! Summary (paths as seen *now*):"
  log "- Docker:        $(command -v docker || echo 'not found')"
  log "- docker compose: try 'docker compose version'"
  log "- Ghostty:       $(command -v ghostty || echo 'not found')"
  log "- Yazi:          $(command -v yazi || echo 'not found')"
  log "- Zellij:        $(command -v zellij || echo 'not found')"
  log "- fish:          $(command -v fish || echo 'not found')"
  log "- z (zoxide):    $(command -v zoxide || echo 'not found')"
  log ""
  log "Catppuccin theme is set in ~/.config/ghostty/config."
  log "Tip: log out and back in so Docker group membership and PATH/shell config changes fully apply."
}

main "$@"
