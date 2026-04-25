FROM node:20-bookworm-slim

ARG TARGETARCH=amd64
ARG KUBECTL_VERSION=v1.31.0
ARG TOFU_VERSION=1.9.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        less \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        vim \
    && install -m 0755 -d /etc/apt/keyrings \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
        -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${TARGETARCH}.zip" \
        -o /tmp/tofu.zip \
    && unzip -q /tmp/tofu.zip tofu -d /usr/local/bin \
    && chmod +x /usr/local/bin/tofu \
    && rm /tmp/tofu.zip

RUN npm install -g @anthropic-ai/claude-code

COPY claude-container/platform-mcp /opt/platform-mcp
RUN pip install --no-cache-dir --break-system-packages /opt/platform-mcp

# mcp-github stdio variant — same nine tools as the HTTP server at
# github.mcp.romaine.life, no JWT layer (we trust the in-container caller).
COPY mcp-servers/github /opt/mcp-github
RUN pip install --no-cache-dir --break-system-packages /opt/mcp-github

# azure-mcp will be re-added once we confirm the upstream image's actual
# binary path — `mcr.microsoft.com/azure-sdk/azure-mcp` doesn't expose
# `/app`, contrary to the assumption from the previous session's k8s
# deployment yaml. Tracked separately; the github + platform MCP servers
# below are sufficient to start.

# Default MCP wiring for the in-container agent. Lives in /workspace so
# Claude Code picks it up as project-scope config; also kept at
# /opt/claude-container/mcp.json for users who mount their own /workspace.
COPY claude-container/mcp.json /opt/claude-container/mcp.json
RUN mkdir -p /workspace && cp /opt/claude-container/mcp.json /workspace/.mcp.json

WORKDIR /workspace

CMD ["bash"]
