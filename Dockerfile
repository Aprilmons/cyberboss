FROM node:22-slim

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# All state and Claude sessions live under /data (Railway Volume)
ENV HOME=/data
ENV CYBERBOSS_STATE_DIR=/data/cyberboss
ENV CYBERBOSS_WORKSPACE_ROOT=/data/workspace

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "/app/bin/cyberboss.js", "start"]
