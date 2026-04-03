#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Starship prompt ---
mkdir -p "$HOME/.config"
cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"

# --- Zoxide ---
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# --- AI aliases ---
cat >> "$HOME/.zshrc" <<'EOF'
alias cy="claude --dangerously-skip-permissions"
alias csy="claude --dangerously-skip-permissions --model sonnet"
alias gy="gemini --yolo"
alias xy="codex --yolo"
EOF
