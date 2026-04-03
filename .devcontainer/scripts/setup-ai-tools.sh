#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_DIR="$HOME/.ai-agents-data"

# --- Volume ownership (mounted as root by Docker) ---
sudo chown -R vscode:vscode "$AI_DIR"

# --- Subdirectories inside the single volume ---
mkdir -p \
  "$AI_DIR/claude" \
  "$AI_DIR/gemini" \
  "$AI_DIR/codex" \
  "$AI_DIR/agents" \
  "$AI_DIR/opencode-data" \
  "$AI_DIR/opencode-config"

# --- Symlinks from expected paths into the volume ---
ln -sfn "$AI_DIR/claude"         "$HOME/.claude"
ln -sfn "$AI_DIR/gemini"         "$HOME/.gemini"
ln -sfn "$AI_DIR/codex"          "$HOME/.codex"
ln -sfn "$AI_DIR/agents"         "$HOME/.agents"

mkdir -p "$HOME/.local/share" "$HOME/.config"
ln -sfn "$AI_DIR/opencode-data"   "$HOME/.local/share/opencode"
ln -sfn "$AI_DIR/opencode-config" "$HOME/.config/opencode"

# --- Install AI CLIs (claude + npm in parallel) ---
curl -fsSL https://claude.ai/install.sh | bash &
CLAUDE_PID=$!
npm install -g @google/gemini-cli@preview @openai/codex opencode-ai
wait $CLAUDE_PID || { echo "Claude Code install failed"; exit 1; }

# --- Install/update AI agent skills ---
bash "$SCRIPT_DIR/setup-skills.sh"
