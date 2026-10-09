#!/bin/bash
set -euo pipefail

# get script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# location where the user is
INVOCATION_DIR="$PWD"

# path to proxy configuration
PROXY_FILE="$SCRIPT_DIR/../proxy/allowlist.txt"

for arg in "$@"; do
    echo "Adding $arg to trusted domain list"
    echo "$arg" >> $PROXY_FILE
done

echo "Reloading the squid proxy configuration for the changed allowlist..."

podman compose -f "$SCRIPT_DIR/../podman-compose.generated.yml" exec pi-proxy squid -k reconfigure

echo "Successfully added additional trusted domains to the list"
