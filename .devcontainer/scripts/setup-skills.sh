#!/usr/bin/env bash
set -euo pipefail

echo "=== Setting up AI agent skills ==="

# --- Superpowers for Claude Code ---
if claude plugin list 2>/dev/null | grep -q "superpowers"; then
  echo "Updating superpowers for Claude..."
  claude plugin update superpowers@claude-plugins-official
else
  echo "Installing superpowers for Claude..."
  claude plugin install superpowers@claude-plugins-official
fi

# --- Superpowers for Gemini CLI ---
if [ -d "$HOME/.gemini/extensions/superpowers" ]; then
  echo "Updating superpowers for Gemini..."
  gemini extensions update superpowers
else
  echo "Installing superpowers for Gemini..."
  gemini extensions install https://github.com/obra/superpowers --auto-update --consent
fi

# --- Superpowers for Codex ---
if [ -d "$HOME/.codex/superpowers/.git" ]; then
  echo "Updating superpowers for Codex..."
  git -C "$HOME/.codex/superpowers" pull
else
  echo "Installing superpowers for Codex..."
  git clone https://github.com/obra/superpowers.git "$HOME/.codex/superpowers"
  mkdir -p "$HOME/.agents/skills"
  ln -sfn "$HOME/.codex/superpowers/skills" "$HOME/.agents/skills/superpowers"
fi
# Enable multi-agent for subagent skills (dispatching-parallel-agents, subagent-driven-development)
if ! grep -q 'multi_agent' "$HOME/.codex/config.toml" 2>/dev/null; then
  printf '\n[features]\nmulti_agent = true\n' >> "$HOME/.codex/config.toml"
fi

# --- Superpowers for OpenCode ---
# --global installs to user config; --force handles both install and update
echo "Installing/updating superpowers for OpenCode..."
opencode plugin "superpowers@git+https://github.com/obra/superpowers.git" --global --force
