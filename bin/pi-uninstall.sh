#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
INSTALL_DIR=$(dirname "$SCRIPT_DIR") # ~/.local/share/pi-sandbox when installed
PROXY_FILE="$INSTALL_DIR/podman-compose.proxy.yml"

echo "Stopping all pi-agent instances..."
for f in "$INSTALL_DIR"/podman-compose.*.generated.yml; do
  [ -f "$f" ] || continue
  name=$(basename "$f" | sed 's/^podman-compose\.//;s/\.generated\.yml$//')
  echo " -> down pi-${name}"
  podman compose -p "pi-${name}" -f "$f" down -v 2>/dev/null || true
done
# fallback for containers without a generated file (e.g. trap was skipped)
for c in $(podman ps -a --format '{{.Names}}' 2>/dev/null | grep -E '^pi-agent-' || true); do
  podman rm -f "$c" 2>/dev/null || true
done

echo "Stopping shared pi-proxy..."
if [ -f "$PROXY_FILE" ]; then
  podman compose -p pi-proxy -f "$PROXY_FILE" down 2>/dev/null || true
fi
# legacy single-instance stack, if present
if [ -f "$INSTALL_DIR/podman-compose.generated.yml" ]; then
  podman compose -f "$INSTALL_DIR/podman-compose.generated.yml" down 2>/dev/null || true
fi
podman rm -f pi-proxy 2>/dev/null || true

echo "Removing volumes and shared network..."
# per-instance agent volumes + shared squid volumes + legacy volumes
podman volume ls --format '{{.Name}}' 2>/dev/null | grep -E '(pi-volume|squid-(cache|logs))' | xargs -r podman volume rm 2>/dev/null || true
podman network rm pi-shared-net 2>/dev/null || true

# remove the symlinks for pi-start, pi-uninstall, pi-add-domain, pi-list
rm -f ~/.local/bin/pi-start
rm -f ~/.local/bin/pi-uninstall
rm -f ~/.local/bin/pi-add-domain
rm -f ~/.local/bin/pi-list

# nukes the install dir (this is what clears the saved allowlist)
rm -rf ~/.local/share/pi-sandbox

echo "Successfully uninstalled pi-sandbox"
