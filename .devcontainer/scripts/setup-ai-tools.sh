#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Install AI CLIs (claude + npm in parallel) ---
if [ ! -x "$HOME/.local/bin/claude" ]; then
    curl -fsSL https://claude.ai/install.sh | bash &
    CLAUDE_PID=$!
else
    echo "Claude Code already installed, skipping."
    CLAUDE_PID=
fi
npm install -g @google/gemini-cli@preview @openai/codex opencode-ai
[ -n "${CLAUDE_PID:-}" ] && { wait $CLAUDE_PID || { echo "Claude Code install failed"; exit 1; }; }

# --- Install/update AI agent skills ---
bash "$SCRIPT_DIR/setup-skills.sh"
