#!/bin/sh
set -e

# If running as root: fix /data permissions then drop to cyberboss user
if [ "$(id -u)" = "0" ]; then
  mkdir -p /data
  chown -R cyberboss:cyberboss /data
  exec gosu cyberboss "$0" "$@"
fi

# Ensure HOME is /data even if gosu reset it from passwd
export HOME=/data
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

# Create required directories
mkdir -p "$CYBERBOSS_STATE_DIR/accounts"

# Clear stale session state so cyberboss starts a fresh Codex session
rm -f "$CYBERBOSS_STATE_DIR/sessions.json"
mkdir -p "$CYBERBOSS_WORKSPACE_ROOT"
mkdir -p "$CODEX_HOME"

# Configure Codex MCP servers (rebuilt every start so env var toggles take effect)
if [ "$CYBERBOSS_CODEX_SKIP_EXTERNAL_MCP" = "true" ] || [ "$CYBERBOSS_CLAUDE_SKIP_BRAIN_MCP" = "true" ]; then
  codex mcp remove ombre-brain >/dev/null 2>&1 || true
  codex mcp remove zhipu-web-search >/dev/null 2>&1 || true
  codex mcp remove co-reading >/dev/null 2>&1 || true
else
  export CO_READING_MCP_TOKEN="${CO_READING_MCP_TOKEN:-3a337e64a3763374fee04c06305402e1}"
  codex mcp add ombre-brain --url https://solbrain-production.up.railway.app/mcp >/dev/null
  codex mcp add zhipu-web-search --env "BIGMODEL_API_KEY=${ZHIPU_API_KEY:-}" -- cc-zhipu-web-search >/dev/null
  codex mcp add co-reading --url https://co-reading-mcp-production.up.railway.app/mcp --bearer-token-env-var CO_READING_MCP_TOKEN >/dev/null
fi

# Write WeChat account files from env vars if provided
if [ -n "$CYBERBOSS_WEIXIN_ACCOUNT_JSON" ]; then
  ACCOUNT_ID=$(printf '%s' "$CYBERBOSS_WEIXIN_ACCOUNT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['accountId'])" 2>/dev/null || echo "account")
  printf '%s' "$CYBERBOSS_WEIXIN_ACCOUNT_JSON" > "$CYBERBOSS_STATE_DIR/accounts/${ACCOUNT_ID}.json"
  if [ -n "$CYBERBOSS_WEIXIN_CONTEXT_TOKENS_JSON" ]; then
    printf '%s' "$CYBERBOSS_WEIXIN_CONTEXT_TOKENS_JSON" > "$CYBERBOSS_STATE_DIR/accounts/${ACCOUNT_ID}.context-tokens.json"
  fi
fi

# Always sync weixin-instructions.md from template on startup
cp /app/templates/weixin-instructions.md "$CYBERBOSS_STATE_DIR/weixin-instructions.md"

# Wake up ombre-brain MCP server before starting (Railway services sleep when idle)
echo "[entrypoint] warming up ombre-brain..."
curl -s --max-time 60 -X POST https://solbrain-production.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"warmup","version":"1.0"}},"id":0}' \
  > /dev/null 2>&1 || true
echo "[entrypoint] ombre-brain warmup done"

exec "$@"
