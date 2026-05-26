#!/usr/bin/env bash
set -e

# Shell tools (zsh, oh-my-zsh, fd, rg, fzf, eza, starship, zsh-plugins, node)
# are auto-installed by dependsOn — nothing to do here for those.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# tmux: terminal multiplexer (Ubuntu 24.04 ships 3.4, one release behind upstream — fine for daily use)
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tmux
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- Shell config (on top of what dependsOn features provide) ---

# zoxide: system binary, install directly to /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | \
    sh -s -- --bin-dir /usr/local/bin

# lazygit: system binary, install latest GitHub release to /usr/local/bin
LAZYGIT_MIN_VERSION=0.61.1
LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -Po '"tag_name": "v\K[^"]*')
case "$(uname -m)" in
    x86_64)  LAZYGIT_ARCH="x86_64" ;;
    aarch64) LAZYGIT_ARCH="arm64"  ;;
    *) echo "lazygit: unsupported arch $(uname -m)" >&2; exit 1 ;;
esac
curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin lazygit
LAZYGIT_INSTALLED=$(lazygit --version | grep -Po 'version=\K[0-9.]+')
if [ "$(printf '%s\n%s\n' "$LAZYGIT_MIN_VERSION" "$LAZYGIT_INSTALLED" | sort -V | head -1)" != "$LAZYGIT_MIN_VERSION" ]; then
    echo "lazygit: installed $LAZYGIT_INSTALLED is below required $LAZYGIT_MIN_VERSION" >&2
    exit 1
fi

# lazydocker: system binary, install latest GitHub release to /usr/local/bin
LAZYDOCKER_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" \
    | grep -Po '"tag_name": "v\K[^"]*')
case "$(uname -m)" in
    x86_64)  LAZYDOCKER_ARCH="x86_64" ;;
    aarch64) LAZYDOCKER_ARCH="arm64"  ;;
    *) echo "lazydocker: unsupported arch $(uname -m)" >&2; exit 1 ;;
esac
curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_${LAZYDOCKER_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin lazydocker

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
alias ay="agy --dangerously-skip-permissions"
alias xy="codex --yolo"
alias lzg="lazygit"
alias lzd="lazydocker"
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

if [ "$INSTALLOPENCODE" = "true" ]; then
    # --no-modify-path: we expose the binary system-wide via a /usr/local/bin
    # symlink below, so the installer doesn't need to edit .zshrc.
    su "$_REMOTE_USER" -c "curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path" &
    OPENCODE_PID=$!
fi

if [ "$INSTALLANTIGRAVITY" = "true" ]; then
    # Antigravity CLI (successor to gemini-cli — reads same ~/.gemini state).
    # Binary `agy` lands in $HOME/.local/bin (same dir as claude).
    su "$_REMOTE_USER" -c "curl -fsSL https://antigravity.google/cli/install.sh | bash" &
    ANTIGRAVITY_PID=$!
fi

if [ "$INSTALLCODEX" = "true" ] || [ "$INSTALLSKILLS" = "true" ]; then
    # `su` resets PATH, and nvm isn't sourced in non-interactive user shells
    # at build time. Pass npm's bin dir through explicitly.
    NPM_BIN_DIR="$(dirname "$(command -v npm)")"
fi

if [ "$INSTALLCODEX" = "true" ]; then
    su "$_REMOTE_USER" -c "PATH=$NPM_BIN_DIR:\$PATH npm install -g @openai/codex"
fi

if [ "$INSTALLSKILLS" = "true" ]; then
    su "$_REMOTE_USER" -c "PATH=$NPM_BIN_DIR:\$PATH npm install -g skills"
fi

[ -n "${CLAUDE_PID:-}" ]       && wait "$CLAUDE_PID"
[ -n "${OPENCODE_PID:-}" ]     && wait "$OPENCODE_PID"
[ -n "${ANTIGRAVITY_PID:-}" ]  && wait "$ANTIGRAVITY_PID"

# opencode installs to $HOME/.opencode/bin (not on default PATH). Expose it
# system-wide so post-create.sh and other non-interactive scripts can find it.
if [ "$INSTALLOPENCODE" = "true" ]; then
    ln -sfn "$_REMOTE_USER_HOME/.opencode/bin/opencode" /usr/local/bin/opencode
fi

# --- Bake runtime script into image ---
mkdir -p /usr/local/share/fafo
cp "$SCRIPT_DIR/scripts/post-create.sh" /usr/local/share/fafo/
chmod +x /usr/local/share/fafo/post-create.sh
