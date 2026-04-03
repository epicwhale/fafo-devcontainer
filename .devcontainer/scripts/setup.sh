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
  "$AI_DIR/opencode-config" \
  "$AI_DIR/bin" \
  "$AI_DIR/npm-cache" \
  "$AI_DIR/claude-share"

# --- Symlinks from expected paths into the volume ---
ln -sfn "$AI_DIR/claude"         "$HOME/.claude"
ln -sfn "$AI_DIR/gemini"         "$HOME/.gemini"
ln -sfn "$AI_DIR/codex"          "$HOME/.codex"
ln -sfn "$AI_DIR/agents"         "$HOME/.agents"

mkdir -p "$HOME/.local" "$HOME/.local/share" "$HOME/.config"
ln -sfn "$AI_DIR/bin"             "$HOME/.local/bin"
ln -sfn "$AI_DIR/npm-cache"       "$HOME/.npm"
ln -sfn "$AI_DIR/claude-share"    "$HOME/.local/share/claude"
ln -sfn "$AI_DIR/opencode-data"   "$HOME/.local/share/opencode"
ln -sfn "$AI_DIR/opencode-config" "$HOME/.config/opencode"

# --- Run tool installers in parallel ---
bash "$SCRIPT_DIR/setup-shell.sh" &
SHELL_PID=$!
bash "$SCRIPT_DIR/setup-ai-tools.sh"
wait $SHELL_PID || { echo "Shell setup failed"; exit 1; }
