FROM node:22-slim

# Install runtime utilities used by the entrypoint.
RUN apt-get update \
  && apt-get install -y --no-install-recommends gosu curl python3 \
  && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI and MCP servers.
RUN npm install -g @anthropic-ai/claude-code @iflow-mcp/cc-zhipu-web-search

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Claude Code refuses --dangerously-skip-permissions as root, so run as non-root.
# Home is /data so passwd entry matches HOME env var (gosu reads passwd).
RUN useradd -u 1001 -d /data cyberboss

# All state and Claude sessions live under /data (Railway Volume).
ENV HOME=/data
ENV CYBERBOSS_RUNTIME=claudecode
ENV CYBERBOSS_STATE_DIR=/data/cyberboss
ENV CYBERBOSS_WORKSPACE_ROOT=/data/workspace

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "/app/bin/cyberboss.js", "start"]
