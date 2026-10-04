# PI Permissions System

The [Pi Permission System](https://github.com/MasuRii/pi-permission-system#readme) extension is installed to provide another layer of security around tool calls

# Global permission file
The global permission file here *pi-permissions.jsonc* is copied over to the pi-sandbox container on podman compose to the location `~/.pi/agent/extensions/pi-permission-system`.

The permission file is set to be read only on podman-compose, so the agent cannot modify it.

# project level permissions files
Folders that you mount to the pi-sandbox as workspaces should have project level permissions defined: *pi-permission.jsonc* within a project directory.

These project-level permissions should go into the `.pi/agent/pi-permissions.jsonc` location within the project workspace. 

For better security, ensure the permission file is set to be readonly for users of the container, so it cannot be modified by pi.


