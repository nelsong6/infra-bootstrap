# Microsoft's azure-mcp image — Alpine/musl-based, multi-stage source for
# the co-located stdio binary at /mcp-server/server-binary.
FROM mcr.microsoft.com/azure-sdk/azure-mcp AS azmcp-src

# Alpine base so the musl-linked azmcp binary loads natively (we tried
# Debian + side-loaded musl earlier; the right answer is matching libcs).
FROM node:20-alpine

ARG TARGETARCH=amd64
ARG KUBECTL_VERSION=v1.31.0
ARG TOFU_VERSION=1.9.0

RUN apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        git \
        github-cli \
        gnupg \
        icu-libs \
        jq \
        less \
        py3-pip \
        python3 \
        unzip \
        vim

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

# mcp-github stdio variant — same nine tools as the (now-retired) HTTP
# server, no JWT layer (we trust the in-container caller).
COPY mcp-servers/github /opt/mcp-github
RUN pip install --no-cache-dir --break-system-packages /opt/mcp-github

# Co-located azure-mcp binary. Upstream image's WORKDIR is /mcp-server;
# entrypoint pattern is `./server-binary server start`. We mirror that
# against the extracted /opt/azure-mcp tree so callers only pass transport
# flags. Binary is ~142MB self-contained .NET single-file publish.
COPY --from=azmcp-src /mcp-server /opt/azure-mcp
RUN printf '#!/bin/sh\ncd /opt/azure-mcp\nexec ./server-binary server start "$@"\n' > /usr/local/bin/azmcp \
    && chmod +x /usr/local/bin/azmcp

# Default MCP wiring for the in-container agent. Lives in /workspace so
# Claude Code picks it up as project-scope config; also kept at
# /opt/claude-container/mcp.json for users who mount their own /workspace.
COPY claude-container/mcp.json /opt/claude-container/mcp.json
RUN mkdir -p /workspace && cp /opt/claude-container/mcp.json /workspace/.mcp.json

WORKDIR /workspace

CMD ["bash"]
