#!/bin/bash
set -euo pipefail

# get script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ROOT_DIR=$(dirname "$SCRIPT_DIR")

TEMPLATE="$ROOT_DIR/podman-compose.agent.template.yml"
PROXY_FILE="$ROOT_DIR/podman-compose.proxy.yml"
SESSIONS_DIR="$ROOT_DIR/sessions"
LOCKFILE="/tmp/pi-proxy.lock"

sanitize() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/^-*//;s/-*$//'; }
session_exists() { [[ -f "$SESSIONS_DIR/$1/mounts.txt" ]]; }

usage() {
  echo "Usage:"
  echo "  pi-start [--name <name>] <DIR...>  # ephemeral if --name omitted (cleaned up on exit)"
  echo "  pi-start --name <name> <DIR...>    # create/update named persistent session"
  echo "  pi-start --name <name>             # restart saved named session"
  echo "  pi-list                            # list saved sessions"
}

NAME=""
DIRS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name|-n) [[ $# -ge 2 ]] || { echo "--name requires a value"; usage; exit 1; }; NAME="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    --) shift; while [[ $# -gt 0 ]]; do DIRS+=("$1"); shift; done; break;;
    -*) echo "Unknown option: $1"; usage; exit 1;;
    *) DIRS+=("$1"); shift;;
  esac
done

PERSISTENT=0
INSTANCE=""

if [[ -n "$NAME" ]]; then
  INSTANCE=$(sanitize "$NAME")
  if [[ -z "$INSTANCE" ]]; then echo "Invalid session name: $NAME"; exit 1; fi
  PERSISTENT=1
  if [[ ${#DIRS[@]} -gt 0 ]]; then
    # create/update named session
    mkdir -p "$SESSIONS_DIR/$INSTANCE"
    : > "$SESSIONS_DIR/$INSTANCE/mounts.txt"
    for path in "${DIRS[@]}"; do
      realpath "$path" >> "$SESSIONS_DIR/$INSTANCE/mounts.txt"
    done
  elif session_exists "$INSTANCE"; then
    # restart saved session (no dirs given)
    mapfile -t DIRS < "$SESSIONS_DIR/$INSTANCE/mounts.txt"
  else
    echo "No saved session named '$NAME'."
    echo "Create it with: pi-start --name \"$NAME\" <DIR...>"
    echo ""
    echo "Saved sessions (pi-list):"
    ls -1 "$SESSIONS_DIR" 2>/dev/null || echo "  (none)"
    exit 1
  fi
else
  # ephemeral: no --name given
  if [[ ${#DIRS[@]} -eq 0 ]]; then usage; exit 1; fi
  RAND=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | cut -c1-4 || echo $RANDOM)
  INSTANCE="i$(date +%s)-$$-${RAND}"
  INSTANCE=$(sanitize "$INSTANCE")
  PERSISTENT=0
fi

COMPOSE_FILE="$ROOT_DIR/podman-compose.${INSTANCE}.generated.yml"
PROJECT="pi-${INSTANCE}"
AGENT_CONTAINER="pi-agent-${INSTANCE}"

# Shared network for agents -> shared proxy DNS (http://pi-proxy:3128)
podman network exists pi-shared-net || podman network create pi-shared-net

# Start shared proxy once (lock so two concurrent pi-starts don't race).
( flock -x 200
  if [[ "$(podman inspect -f '{{.State.Running}}' pi-proxy 2>/dev/null || echo false)" != "true" ]]; then
    echo "Starting shared pi-proxy..."
    podman compose -p pi-proxy -f "$PROXY_FILE" up -d
  fi
) 200>"$LOCKFILE"

# Build the volumes string from saved or supplied mounts
VOL_LINES="      - $ROOT_DIR/extensions/pi-permission-system/pi-permissions.jsonc:/home/node/.pi/agent/extensions/pi-permission-system/pi-permissions.jsonc:ro
"
VOL_LINES="${VOL_LINES}      - $ROOT_DIR/skills:/home/node/.pi/agent/skills:Z
"
VOL_LINES="${VOL_LINES}      - $ROOT_DIR/system/APPEND_SYSTEM.md:/home/node/.pi/agent/APPEND_SYSTEM.md:ro
"
VOL_LINES="${VOL_LINES}      - $ROOT_DIR/extensions/subagent:/home/node/.pi/agent/extensions/subagent:ro
"
VOL_LINES="${VOL_LINES}      - $ROOT_DIR/extensions/subagent/agents:/home/node/.pi/agent/agents:ro
"

for path in "${DIRS[@]}"; do
    abs_path=$(realpath "$path")
    dir_name=$(basename "$abs_path")
    VOL_LINES="${VOL_LINES}      - ${abs_path}:/home/workspace/${dir_name}:Z
"
done

export INSTANCE DYNAMIC_VOLUMES="${VOL_LINES}"
awk '{gsub(/\$\{INSTANCE\}/, ENVIRON["INSTANCE"]); gsub(/\$\{DYNAMIC_VOLUMES\}/, ENVIRON["DYNAMIC_VOLUMES"]); print}' "$TEMPLATE" > "$COMPOSE_FILE"

echo "Launching ${AGENT_CONTAINER}..."
podman compose -p "$PROJECT" -f "$COMPOSE_FILE" up -d

# On session end: ephemeral => full cleanup (down -v + rm compose).
# Named/persistent => stop only, keep volume + compose + mounts.txt for restart.
cleanup() {
  if [[ "$PERSISTENT" -eq 1 ]]; then
    podman compose -p "$PROJECT" -f "$COMPOSE_FILE" stop 2>/dev/null || true
    echo "Stopped ${AGENT_CONTAINER} (session '$INSTANCE' saved, restart with: pi-start --name \"$INSTANCE\")"
  else
    podman compose -p "$PROJECT" -f "$COMPOSE_FILE" down -v 2>/dev/null || true
    rm -f "$COMPOSE_FILE"
    echo "cleaned up ${AGENT_CONTAINER}"
  fi
  ( flock -x 200
    remaining=$(podman ps --format '{{.Names}}' 2>/dev/null | grep -c '^pi-agent-' || true)
    if [[ "$remaining" -eq 0 ]]; then
      echo "Last agent exited, stopping shared pi-proxy..."
      podman compose -p pi-proxy -f "$PROXY_FILE" down 2>/dev/null || true
    else
      echo "(${remaining} agent(s) still running, proxy left up)"
    fi
  ) 200>"$LOCKFILE"
}
trap cleanup EXIT INT TERM

echo "Container is running. Attaching to ${AGENT_CONTAINER}..."
podman attach "$AGENT_CONTAINER"
