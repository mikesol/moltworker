FROM docker.io/cloudflare/sandbox:0.7.0

# Install Node.js 22 (required by OpenClaw), rclone (R2 persistence),
# GitHub CLI, Chromium, and a practical toolkit for coding/automation.
# The base image has Node 20, we need to replace it with Node 22.
ENV NODE_VERSION=22.13.1
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
         amd64) NODE_ARCH="x64" ;; \
         arm64) NODE_ARCH="arm64" ;; \
         *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
       esac \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         xz-utils \
         ca-certificates \
         curl \
         gnupg \
         git \
         ripgrep \
         jq \
         less \
         unzip \
         zip \
         file \
         procps \
         sqlite3 \
         python3 \
         python3-pip \
         python3-venv \
         rclone \
         ffmpeg \
         imagemagick \
         software-properties-common \
    && add-apt-repository -y ppa:xtradeb/apps \
    && apt-get update \
    && apt-get install -y --no-install-recommends chromium \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && curl -fsSLk https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && node --version \
    && npm --version \
    && gh --version \
    && git --version \
    && rg --version \
    && jq --version \
    && ffmpeg -version | head -n1 \
    && convert --version | head -n1 \
    && chromium --version \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN npm install -g pnpm

# Install OpenClaw (formerly clawdbot/moltbot)
# Pin to specific version for reproducible builds
RUN npm install -g openclaw@2026.3.2 \
    && openclaw --version

# Create OpenClaw directories
# Legacy .clawdbot paths are kept for R2 backup migration
RUN mkdir -p /root/.openclaw \
    && mkdir -p /root/clawd \
    && mkdir -p /root/clawd/skills

# Copy startup script
# Build cache bust: 2026-03-05-v31-tooling-pack
COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh

# Copy custom skills
COPY skills/ /root/clawd/skills/

# Set working directory
WORKDIR /root/clawd

# Expose the gateway port
EXPOSE 18789
