# Pi-Sandbox
Environment Sandbox for running the Pi Agent Harness. You need some container runtime like podman or docker and you need a compose implementation, like docker-compose or podman-compose. 

## Rootless
For my setup, I am running this image with a rootless podman setup.
This will ensure that the process does not have priviledged access on the host. 

## File Access
The agent only has access to modify the volumes which are mounted by the user in the configuration. 

In addition, for the pi-permission-system extension, the configuration is mounted as read-only, so the container process cannot modify it, even as root. 

## Network Access
The squid forward http proxy will forward all requests from the pi agent after checking against the allowlist specified in the squid configuration. See [proxy/README.md](./proxy/README.md) 

The agent will know to inform the user when a domain it tried to access is rejected based on the allowlist (see system/APPEND_SYSTEM.md). The agent will prompt the user to run `pi-add-domain [Domain1] [Domain2] ...` in order to whitelist the domains.

## Internet Tool
We use the [ketch-cli](https://github.com/1broseidon/ketch) for internet exploration for use by the agent and is installed via npm in the dockerfile. A skill is written called `websearch` which leverages the ketch-cli.

## Dockerfile setup
We rely on the debian trixy slim node image as a base and install other dependencies the agent might need.
The entrypoint is the Pi harness CLI itself

## Current dependencies installed in the image
1) [@earendil-works/pi-coding-agent](https://github.com/earendil-works/pi)
2) [npm:pi-permission-system](https://github.com/MasuRii/pi-permission-system)
    - Extension for configured access to commands,tools, and files
2) sudo
3) git
4) curl
5) jq
6) python3 + pip

## credential setup
the credentials/credentials.env file includes exports for API Keys to use with pi harness.

Look at the credentials.env.example accordingly. These env variables are loaded into the process via podman run flags and not included at image build time. 

Since credentials.env is set to be ignored by git, on clone, modify the credentials.env.example to include your API keys and then rename the file to credentials.env. 

## installation
Run `install.sh` which copies necessary folders to the user install location ~/.local/share/pi-sandbox.
The install will also symlink the commands 
- `pi-start` -> `./bin/pi-start.sh`
    - this starts a new `pi-agent` instance and automatically attaches to it
    - each invocation gets a unique instance (`pi-agent-<id>`) with its own mounts and state volume, so you can run multiple instances at once
    - the shared `pi-proxy` starts automatically with the first agent and stops automatically when the last agent exits
    - when the session ends, that agent instance is auto-cleaned (`down -v` + generated compose file removed); the proxy is kept only while other agents are still running
- `pi-uninstall` -> `./bin/pi-uninstall.sh`
    - this stops all running `pi-agent` instances and the shared `pi-proxy`, removes per-instance/state volumes and the shared network, then removes symlinks and destroys the install location (this is the only thing that clears the saved allowlist)
- `pi-add-domain` -> `./bin/pi-add-domain.sh`
    - this appends to the allowlist and reloads squid so pi can access more domains seamlessly
    - saved to `proxy/allowlist.txt` (bind-mounted into the proxy), so it persists across proxy restarts; if the proxy isn't running it is saved and applied on the next `pi-start`
- `pi-list` -> `./bin/pi-list.sh`
    - lists saved (named/persistent) sessions with `running`/`stopped` status and their mounts
- `pi-destroy` -> `./bin/pi-destroy.sh`
    - destroys a named session created with `pi-start --name`: stops/removes its container, deletes its state volume, generated compose file, and saved mounts
    - unknown or invalid names are reported without failing, so it is safe to run idempotently

## pi-start Usage
Run one `pi-agent` per terminal. After the compose operation completes, the process automatically attaches to that agent and you can interact with the pi agent CLI.

This uses `podman-compose.agent.template.yml` to generate a per-instance `podman-compose.<id>.generated.yml`, plus a singleton `podman-compose.proxy.yml` for the shared `pi-proxy` (both talk over the shared `pi-shared-net`, agents reach the proxy at `http://pi-proxy:3128`).

### arguments
Host directory locations can be passed as argument to be mounted in the pi-agent container under the /home/workspace location.

i.e ```pi-start [--name "SESSION"] "PATH/TO/Dir1" "PATH/TO/DIR2" ...```

`--name` (short: `-n`) is optional. Without it the instance is ephemeral. With it the instance is a named persistent session.

These directories are **NOT** mounted as read-only, so the agent can modify them. Ensure that pi-permission-system configuration is provided in the specific directories that you mount so that the pi-agent obeys permissions you might require. See [extensions/pi-permission-system/README.md](./extensions/pi-permission-system/README.md).

### concurrent instances
```bash
# terminal 1
pi-start ./app1
# terminal 2
pi-start ./app2
```
Each gets its own container (`pi-agent-<id>`), compose project (`pi-<id>`), and state volume (`pi-volume-<id>`). Exiting a session cleans up only that instance. The shared `pi-proxy` stays up while any agent is running and spins down when the last one stops.

### named instances (persistent sessions)
Use the optional `--name` flag:

```bash
pi-start --name myproject ./app1 ./app2   # create (or update mounts for) session "myproject"
pi-start --name myproject                 # restart saved session "myproject" (reuses mounts + state volume)
pi-list                                   # list saved sessions with running/stopped status
pi-destroy --name myproject               # destroy the named session (container, volume, saved mounts)
```

* Named sessions persist on exit (`stop`, not `down -v`): the compose file, `sessions/<name>/mounts.txt`, and `pi-volume-<name>` are kept, so restarting with `pi-start --name "<name>"` restores mounts and agent state.
* Without `--name` (`pi-start ./app1`) the instance is ephemeral: fully cleaned (`down -v`) on exit and never shown in `pi-list` after it stops.
* Updating mounts: `pi-start --name myproject ./newdir` overwrites the saved mounts and regenerates the compose file.
* Destroying a named session permanently removes its state volume and saved mounts. `pi-destroy` accepts either `--name <name>` or the name as a positional argument, and reports unknown/invalid names without failing.

## pi-add-domain Usage

```pi-add-domain ".google.com" ".quarkus.io" ... ```

Input a list of strings of domains to add to the allowlist.
These will be added and the forward proxy will be dynamically reloaded so that pi will immediately be able to access those domains. If the proxy isn't running, domains are still saved to `proxy/allowlist.txt` and applied on the next `pi-start`. Saved domains persist until `pi-uninstall`.
