# Pi-Sandbox
Environment Sandbox for running the Pi Agent Harness. You need some container runtime like podman or docker and you need a compose implementation, like docker-compose or podman-compose. 

## Rootless
For my setup, I am running this image with a rootless podman setup.
This will ensure that the process does not have priviledged access on the host. 

## File Access
The agent only has access to modify the volumes which are mounted by the user in the configuration. 

In addition, for the pi-permission-system extension, the configuration is mounted as read-only, so the container process cannot modify it, even as root. 

## Network Access
We use an application-level guard and an http proxy to prevent unwanted network requests made by the pi harness. 

The pi-permission-system will be setup to inspect outgoing requests to make sure they are following the https standard and are not fishy. 

The squid forward http proxy will forward all requests from the pi agent after checking against the allowlist specified in the squid configuration. See [proxy/README.md](./proxy/README.md) 

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
The install will also symlink the commands `pi-start` -> `./bin/pi-start.sh` and `pi-uninstall` -> `./bin/pi-uninstall.sh`.

calling `pi-uninstall` will cleanup the installation folder and symlinks

## pi-start Usage
this script provides options to build and run the pi harness stack I have defined. After the podman-compose operation completes, the process automatically attaches to the pi-sandbox and you can interact with the pi agent CLI.

This uses the podman-compose.template.yml to generate a podman-compose.generated.yml that will hold the final definition to be deployed.

### arguments
Host directory locations can be passed as argument to be mounted in the pi-agent container under the /home/workspace location. 

i.e ```pi-start "PATH/TO/Dir1" "PATH/TO/DIR2" ...```

These directories are **NOT** mounted as read-only, so the agent can modify them. Ensure that pi-permission-system configuration is provided in the specific directories that you mount so that the pi-agent obeys permissions you might require. See [extensions/pi-permission-system/README.md](./extensions/pi-permission-system/README.md).

## kill-compose.sh
This will tear down the pi harness stack based on the compose file **podman-compose.generate.yml**, which is the output of the run-compose.sh script.
