#!/bin/bash
set -euo pipefail

# get script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# path to proxy configuration (bind-mounted into pi-proxy,
# so edits persist across proxy restarts until uninstall wipes the install dir)
PROXY_FILE="$SCRIPT_DIR/../proxy/allowlist.txt"

for arg in "$@"; do
    if grep -qxF "$arg" "$PROXY_FILE" 2>/dev/null; then
        echo "$arg already allowlisted, skipping"
    else
        echo "Adding $arg to trusted domain list"
        echo "$arg" >> "$PROXY_FILE"
    fi
done

# If the shared proxy is running, reload it now.
# If not, the saved file will be picked up on next pi-start.
if podman container exists pi-proxy 2>/dev/null && \
   [[ "$(podman inspect -f '{{.State.Running}}' pi-proxy 2>/dev/null || echo false)" == "true" ]]; then
    echo "Reloading the squid proxy configuration for the changed allowlist..."
    podman exec pi-proxy squid -k reconfigure
    echo "Successfully added additional trusted domains to the list"
else
    echo "Proxy not running. Domains saved and will apply on next pi-start."
fi
