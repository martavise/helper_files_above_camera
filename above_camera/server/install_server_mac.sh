#!/bin/bash
set -e

echo "Starting MediaMTX installation on macOS..."

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update and install ffmpeg
echo "Installing ffmpeg..."
brew update
brew install ffmpeg

# Detect architecture
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    MEDIAMTX_ARCH="amd64"
elif [ "$ARCH" = "arm64" ]; then
    MEDIAMTX_ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

MEDIAMTX_VERSION="v1.16.1"

echo "Downloading MediaMTX for macOS ($MEDIAMTX_ARCH)..."

curl -LO "https://github.com/bluenviron/mediamtx/releases/download/${MEDIAMTX_VERSION}/mediamtx_${MEDIAMTX_VERSION}_darwin_${MEDIAMTX_ARCH}.tar.gz"

tar -xzf "mediamtx_${MEDIAMTX_VERSION}_darwin_${MEDIAMTX_ARCH}.tar.gz"

# Install binary and config
echo "Installing MediaMTX..."

sudo mv mediamtx /usr/local/bin/
sudo mkdir -p /usr/local/etc
sudo cp mediamtx.yml /usr/local/etc/mediamtx.yml

rm "mediamtx_${MEDIAMTX_VERSION}_darwin_${MEDIAMTX_ARCH}.tar.gz"

# Create launchd service
echo "Creating launchd service..."

PLIST_PATH="$HOME/Library/LaunchAgents/com.mediamtx.plist"

cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mediamtx</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/mediamtx</string>
        <string>/usr/local/etc/mediamtx.yml</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/mediamtx.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/mediamtx.err</string>
</dict>
</plist>
EOF

# Load service
echo "Starting MediaMTX service..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "✅ Installation complete!"
echo "Logs:"
echo "  stdout: /tmp/mediamtx.log"
echo "  stderr: /tmp/mediamtx.err"