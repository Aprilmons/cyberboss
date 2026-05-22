#!/bin/sh
set -e

# Create required directories
mkdir -p "$CYBERBOSS_STATE_DIR/accounts"
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

exec "$@"
