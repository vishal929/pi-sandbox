#!/bin/bash

# remove the symlinks for pi-start, and pi-uninstall
rm ~/.local/bin/pi-start
rm ~/.local/bin/pi-uninstall
rm ~/.local/bin/pi-add-domain

# nukes the install dir
rm -rf ~/.local/share/pi-sandbox

# delete the volumes from podman
podman volume rm \
    "pi-sandbox_pi-volume" \
    "pi-sandbox_squid-cache" \
    "pi-sandbox_squid-logs"

echo "Successfully uninstalled pi-sandbox"
