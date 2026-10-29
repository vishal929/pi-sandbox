#!/bin/bash
set -euo pipefail

# get script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ROOT_DIR=$(dirname "$SCRIPT_DIR")
SESSIONS_DIR="$ROOT_DIR/sessions"
PROXY_FILE="$ROOT_DIR/podman-compose.proxy.yml"
LOCKFILE="/tmp/pi-proxy.lock"

sanitize() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/^-*//;s/-*$//'; }

list_sessions() {
  local found=0
  for d in "$SESSIONS_DIR"/*/; do
    [[ -d "$d" ]] || continue
    found=1
    echo "  $(basename "$d")"
  done
  [[ "$found" -eq 1 ]] || echo "  (none)"
}

usage() {
  cat <<EOF
Usage:
  pi-destroy [--name] <name>   # destroy a named session created with pi-start --name <name>
  pi-destroy -h|--help

Examples:
  pi-destroy --name myproject
  pi-destroy myproject
EOF
}

NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name|-n)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --name requires a value."
        usage
        exit 1
      fi
      if [[ -n "$NAME" ]]; then
        echo "Error: only one instance name can be given."
        usage
        exit 1
      fi
      NAME="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0;;
    --) shift; while [[ $# -gt 0 ]]; do
          if [[ -n "$NAME" ]]; then
            echo "Error: only one instance name can be given."
            usage
            exit 1
          fi
          NAME="$1"
          shift
        done; break;;
    -*) echo "Unknown option: $1"; usage; exit 1;;
    *)
      if [[ -n "$NAME" ]]; then
        echo "Error: only one instance name can be given."
        usage
        exit 1
      fi
      NAME="$1"
      shift
      ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Error: no instance name given."
  usage
  exit 1
fi

INSTANCE=$(sanitize "$NAME")
if [[ -z "$INSTANCE" ]]; then
  echo "Invalid instance name '$NAME': it must contain at least one letter or number."
  echo "Nothing to destroy. Saved sessions (pi-list):"
  list_sessions
  exit 0
fi

COMPOSE_FILE="$ROOT_DIR/podman-compose.${INSTANCE}.generated.yml"
PROJECT="pi-${INSTANCE}"
AGENT_CONTAINER="pi-agent-${INSTANCE}"
AGENT_VOLUME="pi-volume-${INSTANCE}"

# Consider the instance present if any of its artifacts still exist. This makes
# the command useful for cleaning up partially-started or partially-removed sessions.
FOUND=0
[[ -d "$SESSIONS_DIR/$INSTANCE" ]] && FOUND=1
[[ -f "$COMPOSE_FILE" ]] && FOUND=1
podman container exists "$AGENT_CONTAINER" >/dev/null 2>&1 && FOUND=1
podman volume inspect "$AGENT_VOLUME" >/dev/null 2>&1 && FOUND=1

if [[ "$FOUND" -eq 0 ]]; then
  # A bad/unknown name is not an exceptional condition: report it and move on.
  echo "No pi instance named '$NAME' was found. Nothing to destroy."
  echo "Saved sessions (pi-list):"
  list_sessions
  exit 0
fi

echo "Destroying pi instance '$INSTANCE'..."

# Prefer compose so containers and volumes are removed as a unit. If the
# generated file is missing (or compose fails), fall back to explicit cleanup.
if [[ -f "$COMPOSE_FILE" ]]; then
  podman compose -p "$PROJECT" -f "$COMPOSE_FILE" down -v >/dev/null 2>&1 || true
fi

if podman container exists "$AGENT_CONTAINER" >/dev/null 2>&1; then
  podman rm -f "$AGENT_CONTAINER" >/dev/null 2>&1 || true
fi

if podman volume inspect "$AGENT_VOLUME" >/dev/null 2>&1; then
  podman volume rm "$AGENT_VOLUME" >/dev/null 2>&1 || true
fi

rm -f "$COMPOSE_FILE"
rm -rf "$SESSIONS_DIR/$INSTANCE"

# Stop the shared proxy if this was the last agent, matching pi-start's cleanup.
( flock -x 200
  remaining=$(podman ps --format '{{.Names}}' 2>/dev/null | grep -c '^pi-agent-' || true)
  if [[ "${remaining:-0}" -eq 0 ]]; then
    if [[ "$(podman inspect -f '{{.State.Running}}' pi-proxy 2>/dev/null || echo false)" == "true" ]]; then
      echo "Last agent removed, stopping shared pi-proxy..."
      podman compose -p pi-proxy -f "$PROXY_FILE" down 2>/dev/null || true
    fi
  else
    echo "(${remaining} agent(s) still running, proxy left up)"
  fi
) 200>"$LOCKFILE"

echo "Destroyed pi instance '$INSTANCE'."
