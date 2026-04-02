mkdir -p ~/Applications
mkdir -p ~/Developer/{playground,projects,git-clones,experiments,sandboxes,ai}

# Installing uv
curl -LsSf https://astral.sh/uv/install.sh | sh

sudo mkdir -p /opt/zerobrew
cd /opt/zerobrew
sudo chmod 777 .
# Installing zerobrew
curl -fsSL https://raw.githubusercontent.com/i-nick/zerobrew/refs/heads/main/install.sh | bash
export ZEROBREW_DIR=$HOME/.local
$ZEROBREW_DIR/bin/zb init
source $HOME/.zshenv
zb install ffmpeg jq yt-dlp hf
zb install cask:ghostty cask:visual-studio-code cask:brave-browser cask:httpie-desktop cask:zed
# Installing rustup
curl https://sh.rustup.rs -sSf | sh -s -- -y
# Installing bun.sh
curl -fsSL https://bun.sh/install | bash
# Open iCloud sign-in
open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane"
