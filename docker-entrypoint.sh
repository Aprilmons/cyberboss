#!/bin/sh
set -e

# If running as root: fix /data permissions then drop to cyberboss user
if [ "$(id -u)" = "0" ]; then
  mkdir -p /data
  chown -R cyberboss:cyberboss /data
  exec gosu cyberboss "$0" "$@"
fi

# Create required directories
mkdir -p "$CYBERBOSS_STATE_DIR/accounts"

# Clear stale session state so cyberboss starts a fresh Claude Code session
rm -f "$CYBERBOSS_STATE_DIR/sessions.json"
mkdir -p "$CYBERBOSS_WORKSPACE_ROOT"
mkdir -p "$HOME/.claude"

# Initialize workspace .mcp.json if not present
if [ ! -f "$CYBERBOSS_WORKSPACE_ROOT/.mcp.json" ]; then
  cat > "$CYBERBOSS_WORKSPACE_ROOT/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "ombre-brain": {
      "type": "http",
      "url": "https://solbrain-production.up.railway.app/mcp"
    }
  }
}
EOF
fi

# Write WeChat account files from env vars if provided
if [ -n "$CYBERBOSS_WEIXIN_ACCOUNT_JSON" ]; then
  printf '%s' "$CYBERBOSS_WEIXIN_ACCOUNT_JSON" > "$CYBERBOSS_STATE_DIR/accounts/c8bb026e0796-im.bot.json"
fi
if [ -n "$CYBERBOSS_WEIXIN_CONTEXT_TOKENS_JSON" ]; then
  printf '%s' "$CYBERBOSS_WEIXIN_CONTEXT_TOKENS_JSON" > "$CYBERBOSS_STATE_DIR/accounts/c8bb026e0796-im.bot.context-tokens.json"
fi

# Copy weixin-instructions.md from template if not already customized
if [ ! -f "$CYBERBOSS_STATE_DIR/weixin-instructions.md" ]; then
  cp /app/templates/weixin-instructions.md "$CYBERBOSS_STATE_DIR/weixin-instructions.md"
fi

# Wake up ombre-brain MCP server before starting (Railway services sleep when idle)
echo "[entrypoint] warming up ombre-brain..."
curl -s --max-time 60 -X POST https://solbrain-production.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"warmup","version":"1.0"}},"id":0}' \
  > /dev/null 2>&1 || true
echo "[entrypoint] ombre-brain warmup done"

exec "$@"
