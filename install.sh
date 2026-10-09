#!/bin/bash
set -euo pipefail

# just copies the repo to a /usr/local/share location
# adjusts PATH so that we can call "pi-start" and "pi-stop"

# get script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

mkdir -p ~/.local/share/pi-sandbox 
mkdir -p ~/.local/bin

cp -r "$SCRIPT_DIR/system" "$SCRIPT_DIR/bin" "$SCRIPT_DIR/credentials" "$SCRIPT_DIR/extensions" "$SCRIPT_DIR/proxy" "$SCRIPT_DIR/scripts" "$SCRIPT_DIR/skills" "$SCRIPT_DIR/podman-compose.template.yml" ~/.local/share/pi-sandbox

# create symlinks for the scripts to expose
chmod +x ~/.local/share/pi-sandbox/bin/pi-start.sh
chmod +x ~/.local/share/pi-sandbox/bin/pi-uninstall.sh
chmod +x ~/.local/share/pi-sandbox/bin/pi-add-domain.sh
ln -sf ~/.local/share/pi-sandbox/bin/pi-start.sh ~/.local/bin/pi-start
ln -sf ~/.local/share/pi-sandbox/bin/pi-uninstall.sh ~/.local/bin/pi-uninstall
ln -sf ~/.local/share/pi-sandbox/bin/pi-add-domain.sh ~/.local/bin/pi-add-domain

echo "Successfully copied over pi-sandbox. Ensure you have podman/docker + podman-compose/docker-compose installed. Invoke the tool with pi-start and kill the stack with pi-stop." 
echo "If you need to add additional domains to the allowlist, use the pi-add-domain command"
