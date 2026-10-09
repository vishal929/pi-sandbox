#!/bin/bash
set -euo pipefail

# remove the symlinks for pi-start, and pi-uninstall
rm ~/.local/bin/pi-start
rm ~/.local/bin/pi-uninstall
rm ~/.local/bin/pi-add-domain

# remove images associated with the install
podman image rm pi-sandbox
podman image rm squid

# nukes the install dir
rm -rf ~/.local/share/pi-sandbox

echo "Successfully uninstalled pi-sandbox"
