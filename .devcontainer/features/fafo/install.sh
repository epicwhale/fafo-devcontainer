#!/usr/bin/env bash
set -e

# Shell tools (zsh, oh-my-zsh, fd, rg, fzf, eza, starship, zsh-plugins, node)
# are auto-installed by dependsOn — nothing to do here for those.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Shell config (on top of what dependsOn features provide) ---

# Install zoxide (installer puts it in ~/.local/bin/ which is /root/.local/bin/ during build)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
cp /root/.local/bin/zoxide /usr/local/bin/zoxide

# Copy starship.toml
mkdir -p "$_REMOTE_USER_HOME/.config"
cp "$SCRIPT_DIR/scripts/starship.toml" "$_REMOTE_USER_HOME/.config/starship.toml"

# Configure .zshrc: starship init, AI aliases, CLAUDE_CONFIG_DIR
cat >> "$_REMOTE_USER_HOME/.zshrc" <<'ZSHRC'
eval "$(starship init zsh)"
export CLAUDE_CONFIG_DIR="$HOME/.claude"
alias cy="claude --dangerously-skip-permissions"
alias csy="claude --dangerously-skip-permissions --model sonnet"
alias gy="gemini --yolo"
alias xy="codex --yolo"
ZSHRC

# --- AI coding CLIs ---

if [ "$INSTALLCLAUDE" = "true" ]; then
    curl -fsSL https://claude.ai/install.sh | bash &
    CLAUDE_PID=$!
fi

NPM_PKGS=""
[ "$INSTALLGEMINI" = "true" ]   && NPM_PKGS="$NPM_PKGS @google/gemini-cli@preview"
[ "$INSTALLCODEX" = "true" ]    && NPM_PKGS="$NPM_PKGS @openai/codex"
[ "$INSTALLOPENCODE" = "true" ] && NPM_PKGS="$NPM_PKGS opencode-ai"
[ -n "$NPM_PKGS" ] && npm install -g $NPM_PKGS

[ -n "${CLAUDE_PID:-}" ] && wait "$CLAUDE_PID"

# Claude installer puts binary in /root/.local/bin/ (runs as root during build).
# Copy to /usr/local/bin/ so it's accessible to the runtime user.
if [ "$INSTALLCLAUDE" = "true" ] && [ -L /root/.local/bin/claude ]; then
    cp -L /root/.local/bin/claude /usr/local/bin/claude
fi

# --- Bake runtime script into image ---
mkdir -p /usr/local/share/fafo
cp "$SCRIPT_DIR/scripts/post-create.sh" /usr/local/share/fafo/
chmod +x /usr/local/share/fafo/post-create.sh
