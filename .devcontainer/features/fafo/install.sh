#!/usr/bin/env bash
set -e

# Shell tools (zsh, oh-my-zsh, fd, rg, fzf, eza, starship, zsh-plugins, node)
# are auto-installed by dependsOn — nothing to do here for those.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Shell config (on top of what dependsOn features provide) ---

# zoxide: system binary, install directly to /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | \
    sh -s -- --bin-dir /usr/local/bin

# Starship config: owned by the remote user
install -o "$_REMOTE_USER" -g "$_REMOTE_USER" -m 755 -d "$_REMOTE_USER_HOME/.config"
install -o "$_REMOTE_USER" -g "$_REMOTE_USER" -m 644 \
    "$SCRIPT_DIR/scripts/starship.toml" "$_REMOTE_USER_HOME/.config/starship.toml"

# .zshrc: starship init, AI aliases, CLAUDE_CONFIG_DIR (idempotent)
if ! grep -q '# fafo-config' "$_REMOTE_USER_HOME/.zshrc" 2>/dev/null; then
    cat >> "$_REMOTE_USER_HOME/.zshrc" <<'ZSHRC'
# fafo-config
eval "$(starship init zsh)"
export CLAUDE_CONFIG_DIR="$HOME/.claude"
alias cy="claude --dangerously-skip-permissions"
alias csy="claude --dangerously-skip-permissions --model sonnet"
alias gy="gemini --yolo"
alias xy="codex --yolo"
ZSHRC
fi

# --- AI coding CLIs ---
# All installs run as the remote user so ownership is correct from the start
# and self-update works at runtime. Claude lands in $HOME/.local/bin/; npm
# globals go into nvm's tree (group-writable by `nvm` group).

if [ "$INSTALLCLAUDE" = "true" ]; then
    su "$_REMOTE_USER" -c "curl -fsSL https://claude.ai/install.sh | bash" &
    CLAUDE_PID=$!
fi

NPM_PKGS=""
[ "$INSTALLGEMINI" = "true" ]   && NPM_PKGS="$NPM_PKGS @google/gemini-cli@preview"
[ "$INSTALLCODEX" = "true" ]    && NPM_PKGS="$NPM_PKGS @openai/codex"
[ "$INSTALLOPENCODE" = "true" ] && NPM_PKGS="$NPM_PKGS opencode-ai"
if [ -n "$NPM_PKGS" ]; then
    # `su` resets PATH, and nvm isn't sourced in non-interactive user shells
    # at build time. Pass npm's bin dir through explicitly.
    NPM_BIN_DIR="$(dirname "$(command -v npm)")"
    su "$_REMOTE_USER" -c "PATH=$NPM_BIN_DIR:\$PATH npm install -g $NPM_PKGS"
fi

[ -n "${CLAUDE_PID:-}" ] && wait "$CLAUDE_PID"

# --- Bake runtime script into image ---
mkdir -p /usr/local/share/fafo
cp "$SCRIPT_DIR/scripts/post-create.sh" /usr/local/share/fafo/
chmod +x /usr/local/share/fafo/post-create.sh
