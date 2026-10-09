FROM node:trixie-slim

# Install system dependencies, git, and python utilities often required by Pi agents
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    python3 \
    python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Add the node user to the sudo group and allow passwordless sudo
RUN usermod -aG sudo node \
    && echo "node ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/node 

USER node
WORKDIR /home/node
ENV HOME=/home/node

# Install the Pi coding agent

# renovate: datasource=npm depName=@earendil-works/pi-coding-agent
ARG PI_VERSION=1.1.0

RUN sudo chown -R node /usr/local/
RUN npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}"

RUN export PATH="/home/node/.pi/agent/bin:$PATH"
ENV PATH="/home/node/.pi/agent/bin:${PATH}"

# install the pi permissions system extension
RUN npm config set allow-scripts=pi-permission-system --location=user
RUN pi install npm:pi-permission-system --approve

LABEL org.opencontainers.image.title="Pi Agent Sandbox" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com" \
      org.opencontainers.image.licenses="MIT"

# start bash, so that the user starts pi in a given location
CMD ["/bin/bash"]