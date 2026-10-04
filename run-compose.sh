#!/bin/bash
set -euo pipefail

# get script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# location where the user is
INVOCATION_DIR="$PWD"

# Path to template and generated file
TEMPLATE="$SCRIPT_DIR/podman-compose.template.yml"
COMPOSE_FILE="$SCRIPT_DIR/podman-compose.generated.yml"

# Build the volumes string
# Arguments passed: /path/to/host1 /path/to/host2 ...

# bake in permission system files to the volume lines
VOL_LINES="      - $SCRIPT_DIR/extensions/pi-permission-system/pi-permissions.jsonc:/home/node/.pi/agent/extensions/pi-permission-system/pi-permissions.jsonc:ro
"
# mount the skill files, so if pi wants to customize them, we can commit them back
VOL_LINES="${VOL_LINES}      - $SCRIPT_DIR/skills:/home/node/.pi/agent/skills:Z
"
for path in "$@"; do
    # Ensure absolute path
    abs_path=$(realpath "$path")
    # Get the base directory name
    dir_name=$(basename "$abs_path")
    VOL_LINES="${VOL_LINES}      - ${abs_path}:/home/workspace/${dir_name}:Z
"
done

# Use envsubst to create the actual compose file
export DYNAMIC_VOLUMES="${VOL_LINES}"
envsubst < "$TEMPLATE" > "$COMPOSE_FILE"

echo "Launching with extra volumes..."
podman compose -f "$COMPOSE_FILE" up -d

# trap the kill operation so the stack 
# is immediately torn down on disconnect
trap "podman compose -f $COMPOSE_FILE down -v" EXIT INT TERM

echo "Container is running. Attaching to pi-agent..."
podman attach pi-agent
