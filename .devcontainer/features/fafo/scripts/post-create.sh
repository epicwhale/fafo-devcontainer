#!/usr/bin/env bash
set -euo pipefail

FAFO_DATA="/fafo-data"

# --- Volume ownership (mounted as root by Docker) ---
sudo chown -R "$(id -u):$(id -g)" "$FAFO_DATA"

# --- Subdirectories inside the volume ---
mkdir -p \
  "$FAFO_DATA/claude" \
  "$FAFO_DATA/gemini" \
  "$FAFO_DATA/codex" \
  "$FAFO_DATA/agents" \
  "$FAFO_DATA/opencode-data" \
  "$FAFO_DATA/opencode-config" \
  "$FAFO_DATA/npm-cache" \
  "$FAFO_DATA/claude-share"

# --- Symlinks from expected paths into the volume ---
# Note: $HOME/.local/bin is NOT symlinked — claude installs there at image
# build time as a real directory, and symlinking would shadow the binary.
#
# Some of these target dirs (.claude, .local/share/claude, .npm) are created
# at image build time by the claude/npm installers running as the remote user.
# link_into_volume() migrates their contents into the volume (non-destructively,
# preserving any existing volume state) before replacing with the symlink.
link_into_volume() {
    local source="$1"  # path inside /fafo-data
    local target="$2"  # $HOME path that should become a symlink

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        return  # already correct
    fi

    if [ -d "$target" ] && [ ! -L "$target" ]; then
        # Drop any broken symlinks from prior runs, then merge into the volume
        find "$target" -xtype l -delete 2>/dev/null || true
        mkdir -p "$source"
        cp -an "$target"/. "$source"/ 2>/dev/null || true
        rm -rf "$target"
    fi

    ln -sfn "$source" "$target"
}

mkdir -p "$HOME/.local" "$HOME/.local/share" "$HOME/.config"

link_into_volume "$FAFO_DATA/claude"           "$HOME/.claude"
link_into_volume "$FAFO_DATA/gemini"           "$HOME/.gemini"
link_into_volume "$FAFO_DATA/codex"            "$HOME/.codex"
link_into_volume "$FAFO_DATA/agents"           "$HOME/.agents"
link_into_volume "$FAFO_DATA/npm-cache"        "$HOME/.npm"
link_into_volume "$FAFO_DATA/claude-share"     "$HOME/.local/share/claude"
link_into_volume "$FAFO_DATA/opencode-data"    "$HOME/.local/share/opencode"
link_into_volume "$FAFO_DATA/opencode-config"  "$HOME/.config/opencode"

# --- Install/update AI agent skills (best-effort — failures don't block container startup) ---

echo "=== Setting up AI agent skills ==="

# --- Superpowers for Claude Code ---
if ! claude plugin marketplace list 2>/dev/null | grep -q "claude-plugins-official"; then
  echo "Adding Claude plugins marketplace..."
  claude plugin marketplace add anthropics/claude-plugins-official || echo "⚠ Claude marketplace add failed (non-fatal)"
fi
if claude plugin list 2>/dev/null | grep -q "superpowers"; then
  echo "Updating superpowers for Claude..."
  claude plugin update superpowers@claude-plugins-official || echo "⚠ Claude superpowers update failed (non-fatal)"
else
  echo "Installing superpowers for Claude..."
  claude plugin install superpowers@claude-plugins-official || echo "⚠ Claude superpowers install failed (non-fatal)"
fi

# --- Superpowers for Gemini CLI ---
if [ -d "$HOME/.gemini/extensions/superpowers" ]; then
  echo "Updating superpowers for Gemini..."
  gemini extensions update superpowers || echo "⚠ Gemini superpowers update failed (non-fatal)"
else
  echo "Installing superpowers for Gemini..."
  gemini extensions install https://github.com/obra/superpowers --auto-update --consent || echo "⚠ Gemini superpowers install failed (non-fatal)"
fi

# --- Superpowers for Codex ---
if [ -d "$HOME/.codex/superpowers/.git" ]; then
  echo "Updating superpowers for Codex..."
  git -C "$HOME/.codex/superpowers" pull || echo "⚠ Codex superpowers update failed (non-fatal)"
else
  echo "Installing superpowers for Codex..."
  if git clone https://github.com/obra/superpowers.git "$HOME/.codex/superpowers"; then
    mkdir -p "$HOME/.agents/skills"
    ln -sfn "$HOME/.codex/superpowers/skills" "$HOME/.agents/skills/superpowers"
  else
    echo "⚠ Codex superpowers install failed (non-fatal)"
  fi
fi
# Enable multi-agent for subagent skills (dispatching-parallel-agents, subagent-driven-development)
if ! grep -q 'multi_agent' "$HOME/.codex/config.toml" 2>/dev/null; then
  printf '\n[features]\nmulti_agent = true\n' >> "$HOME/.codex/config.toml"
fi

# --- Superpowers for OpenCode ---
# --global installs to user config; --force handles both install and update
echo "Installing/updating superpowers for OpenCode..."
opencode plugin "superpowers@git+https://github.com/obra/superpowers.git" --global --force || echo "⚠ OpenCode superpowers install failed (non-fatal)"
