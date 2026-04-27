#!/usr/bin/env bash
set -eo pipefail

install_release_app() {
  local release_api="https://api.github.com/repos/i-nick/new-mac-setup/releases/tags/v0.1"
  local app_install_dir="$HOME/Applications"
  local release_tmp
  local release_json
  local zip_url
  local zip_path
  local extract_dir
  local app_path
  local app_name
  local target_app

  mkdir -p "$app_install_dir"

  release_tmp="$(mktemp -d)"
  trap "rm -rf '$release_tmp'" EXIT

  release_json="$release_tmp/release.json"
  zip_path="$release_tmp/app.zip"
  extract_dir="$release_tmp/extracted"

  echo "Downloading setup app from GitHub release v0.1..."
  curl -fsSL "$release_api" -o "$release_json"

  zip_url="$(
    tr ',' '\n' < "$release_json" |
      awk -F'"' '
        /"browser_download_url":/ {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^https?:.*\.zip$/) {
              print $i
              exit
            }
          }
        }
      '
  )"

  if [ -z "$zip_url" ]; then
    echo "No .zip asset found in GitHub release v0.1." >&2
    exit 1
  fi

  curl -fL "$zip_url" -o "$zip_path"
  mkdir -p "$extract_dir"
  ditto -x -k "$zip_path" "$extract_dir"

  app_path="$(find "$extract_dir" -maxdepth 4 -name "*.app" -type d -print -quit)"
  if [ -z "$app_path" ]; then
    echo "No .app bundle found in release zip." >&2
    exit 1
  fi

  app_name="$(basename "$app_path")"
  target_app="$app_install_dir/$app_name"

  if [ -e "$target_app" ]; then
    rm -rf "$target_app"
  fi

  ditto "$app_path" "$target_app"
  xattr -cr "$target_app"

  echo "Installed $app_name to $target_app."

  rm -rf "$release_tmp"
  trap - EXIT
}

setup_workspace_volume() {
  local workspace_volume="/Volumes/Workspace"
  local workspace_name="Workspace"
  local llms_link="$HOME/.llms"
  local apfs_container
  local existing_link_target

  if diskutil info "$workspace_volume" >/dev/null 2>&1; then
    echo "Using existing Workspace volume at $workspace_volume."
  else
    if [ -e "$workspace_volume" ]; then
      echo "$workspace_volume exists but is not a mounted disk volume. Move it before rerunning setup." >&2
      exit 1
    fi

    apfs_container="$(
      diskutil info / | awk -F': *' '/APFS Container Reference/ { print $2; exit }'
    )"

    if [ -z "$apfs_container" ]; then
      echo "Unable to find the root APFS container for Workspace volume creation." >&2
      exit 1
    fi

    echo "Creating APFS volume Workspace in $apfs_container..."
    sudo diskutil apfs addVolume "$apfs_container" APFS "$workspace_name"

    if ! diskutil info "$workspace_volume" >/dev/null 2>&1; then
      echo "Workspace volume was created, but $workspace_volume is not available." >&2
      exit 1
    fi
  fi

  mkdir -p "$workspace_volume"/{llms,projects,playground,repos,servers,agents,experiments,sandboxes,ai,tools,datasets,scratch,archives}

  if [ -L "$llms_link" ]; then
    existing_link_target="$(readlink "$llms_link")"
    if [ "$existing_link_target" != "$workspace_volume/llms" ]; then
      ln -sfn "$workspace_volume/llms" "$llms_link"
    fi
  elif [ -e "$llms_link" ]; then
    echo "$llms_link already exists and is not a symlink. Move it before rerunning setup." >&2
    exit 1
  else
    ln -s "$workspace_volume/llms" "$llms_link"
  fi
}

install_release_app
setup_workspace_volume

# Installing uv
curl -LsSf https://astral.sh/uv/install.sh | sh

sudo mkdir -p /opt/zerobrew
cd /opt/zerobrew
sudo chmod 777 .
# Installing zerobrew
curl -fsSL https://raw.githubusercontent.com/i-nick/zerobrew/refs/heads/main/install.sh | bash
export ZEROBREW_DIR="$HOME/.local"
"$ZEROBREW_DIR/bin/zb" init
"$ZEROBREW_DIR/bin/zb" install ffmpeg hf jq llama.cpp mactop python@3.12 python@3.14 xcodegen yt-dlp
"$ZEROBREW_DIR/bin/zb" install cask:claude cask:claude-code cask:codex cask:codex-app cask:ghostty cask:visual-studio-code cask:brave-browser cask:httpie-desktop
# Installing rustup
curl https://sh.rustup.rs -sSf | sh -s -- -y
# Installing bun.sh
curl -fsSL https://bun.sh/install | bash
# Open iCloud sign-in
open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane"
