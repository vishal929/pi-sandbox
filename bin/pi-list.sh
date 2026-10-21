#!/bin/bash
set -euo pipefail

# Lists persistent (named) sessions saved under sessions/<name>/mounts.txt,
# plus any ephemeral running agents without a saved session.

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ROOT_DIR=$(dirname "$SCRIPT_DIR")
SESSIONS_DIR="$ROOT_DIR/sessions"

is_running() {
  [[ "$(podman inspect -f '{{.State.Running}}' "pi-agent-$1" 2>/dev/null || echo false)" == "true" ]]
}

printf "%-20s %-10s %s\n" "NAME" "STATUS" "MOUNTS"
printf "%-20s %-10s %s\n" "----" "------" "------"

if [[ -d "$SESSIONS_DIR" ]]; then
  for d in "$SESSIONS_DIR"/*/; do
    [[ -d "$d" ]] || continue
    name=$(basename "$d")
    status="stopped"
    is_running "$name" && status="running"
    mounts=$(paste -sd',' "$d/mounts.txt" 2>/dev/null || echo "-")
    printf "%-20s %-10s %s\n" "$name" "$status" "$mounts"
  done
fi

# Ephemeral agents (auto-ids like i<ts>-<pid>-xxxx) with no saved session
for c in $(podman ps --format '{{.Names}}' 2>/dev/null | grep -E '^pi-agent-' || true); do
  name=${c#pi-agent-}
  [[ -d "$SESSIONS_DIR/$name" ]] && continue
  printf "%-20s %-10s %s\n" "$name" "running" "(ephemeral)"
done
