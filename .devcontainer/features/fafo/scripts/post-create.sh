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

# --- Codex plugin for Claude Code (provides /codex:rescue, /codex:review etc) ---
if ! claude plugin marketplace list 2>/dev/null | grep -q "openai-codex"; then
  echo "Adding Codex plugin marketplace..."
  claude plugin marketplace add openai/codex-plugin-cc || echo "⚠ Codex marketplace add failed (non-fatal)"
fi
if claude plugin list 2>/dev/null | grep -q "codex@openai-codex"; then
  echo "Updating codex plugin for Claude..."
  claude plugin update codex@openai-codex || echo "⚠ Codex plugin update failed (non-fatal)"
else
  echo "Installing codex plugin for Claude..."
  claude plugin install codex@openai-codex || echo "⚠ Codex plugin install failed (non-fatal)"
fi

# --- DeepWiki MCP for Claude (free, no-auth, public-repo wiki + Q&A) ---
# Skip if already present so a user-initiated `claude mcp remove deepwiki` sticks
# across rebuilds — the user config lives in the persisted fafo-data volume.
if ! claude mcp get deepwiki >/dev/null 2>&1; then
  echo "Adding DeepWiki MCP server to Claude..."
  claude mcp add -s user -t http deepwiki https://mcp.deepwiki.com/mcp \
    || echo "⚠ Claude deepwiki MCP add failed (non-fatal)"
fi

# --- Antigravity (gemini-cli's successor) has no superpowers plugin. Clean up
#     the now-orphan gemini-cli extension if a persisted volume still has it. ---
rm -rf "$HOME/.gemini/extensions/superpowers"

# --- Superpowers for Codex (official curated plugin) ---
# Migrate away from the previous git-clone install if a persisted volume
# still has it around. Safe on fresh installs.
rm -rf "$HOME/.codex/superpowers"
rm -f "$HOME/.agents/skills/superpowers"

# Codex auto-syncs the openai/plugins repo to ~/.codex/.tmp/plugins on any
# invocation. Trigger that sync explicitly so `codex plugin add` can resolve
# `superpowers@openai-curated` at build time.
codex plugin marketplace list >/dev/null 2>&1 || true

# `codex plugin add` is idempotent — re-running upgrades to the curated version.
echo "Installing/updating superpowers for Codex..."
codex plugin add superpowers@openai-curated || echo "⚠ Codex superpowers install failed (non-fatal)"
# Enable multi-agent for subagent skills (dispatching-parallel-agents, subagent-driven-development)
if ! grep -q 'multi_agent' "$HOME/.codex/config.toml" 2>/dev/null; then
  printf '\n[features]\nmulti_agent = true\n' >> "$HOME/.codex/config.toml"
fi
# Bypass bwrap sandbox on Ubuntu 24.04 hosts where AppArmor blocks unprivileged
# user namespaces (kernel.apparmor_restrict_unprivileged_userns=1). Codex falls
# back to the Landlock LSM, which doesn't need userns. Symptom without this:
# `bwrap --dev-bind / / --tmpfs /tmp echo ok` fails with "No permissions to
# create new namespace", and `codex exec` / `/codex:rescue` hang or fail silently.
if ! grep -q 'use_legacy_landlock' "$HOME/.codex/config.toml" 2>/dev/null; then
  if grep -q '^\[features\]' "$HOME/.codex/config.toml" 2>/dev/null; then
    # multi_agent block above already added [features] header — append under it
    sed -i '/^\[features\]/a use_legacy_landlock = true' "$HOME/.codex/config.toml"
  else
    printf '\n[features]\nuse_legacy_landlock = true\n' >> "$HOME/.codex/config.toml"
  fi
fi
# Enable Codex memories so context (preferences, conventions, pitfalls) carries
# across threads. Not available in EEA/UK/CH at launch. Required team rules still
# belong in AGENTS.md — memories are a local recall layer, not the source of truth.
# https://developers.openai.com/codex/memories
if ! grep -q '^memories = ' "$HOME/.codex/config.toml" 2>/dev/null; then
  if grep -q '^\[features\]' "$HOME/.codex/config.toml" 2>/dev/null; then
    sed -i '/^\[features\]/a memories = true' "$HOME/.codex/config.toml"
  else
    printf '\n[features]\nmemories = true\n' >> "$HOME/.codex/config.toml"
  fi
fi

# --- DeepWiki MCP for Codex (free, no-auth, public-repo wiki + Q&A) ---
# Skip if already present so a user-initiated `codex mcp remove deepwiki` sticks
# across rebuilds — the global config lives in the persisted fafo-data volume.
if ! codex mcp get deepwiki >/dev/null 2>&1; then
  echo "Adding DeepWiki MCP server to Codex..."
  codex mcp add deepwiki --url https://mcp.deepwiki.com/mcp \
    || echo "⚠ Codex deepwiki MCP add failed (non-fatal)"
fi

# --- Superpowers for OpenCode ---
# --global installs to user config; --force handles both install and update
echo "Installing/updating superpowers for OpenCode..."
opencode plugin "superpowers@git+https://github.com/obra/superpowers.git" --global --force || echo "⚠ OpenCode superpowers install failed (non-fatal)"
