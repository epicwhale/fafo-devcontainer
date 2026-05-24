Modernized devcontainer setup with Claude, Codex, Antigravity, and opencode that's ready to run in YOLO mode. Pre-configured with [obra/superpowers](https://github.com/obra/superpowers) and sane defaults that persists logins, configs, and conversation history across container rebuilds. Just drop the `.devcontainer/` folder into any repo and you're good to go.

## Why

I found myself fighting with a swamp of configuration and long-build times every time I wanted to spin up a devcontainer for agentic coding: installing CLIs, configuring shell, setting up volumes for persistent state (like logins, conversation history, ...), and so on. It was inertia I didn't like.

## What's in the box

- **Coding CLIs** — Claude Code, Google Antigravity (`agy`, gemini-cli's successor), OpenAI Codex, opencode — pre-installed with yolo-mode aliases
- **Superpowers** — [obra/superpowers](https://github.com/obra/superpowers) skills auto-installed for Claude, Codex, and opencode (Antigravity has no superpowers plugin yet)
- **`skills` CLI** — [vercel-labs/skills](https://github.com/vercel-labs/skills) package manager for agent skills — `skills add <pkg>` works across Claude, Codex, opencode, and more
- **DeepWiki MCP** — pre-wired for Claude and Codex for instant Q&A on any public GitHub repo
- **Persistent state** — named docker volume keeps your logins, configs, and conversation history across container rebuilds
- **Shell** — zsh + starship + (fd, ripgrep, fzf, eza, zoxide) + lazygit (`lzg`) + lazydocker (`lzd`)


## YOLO Aliases

| Alias | What it runs |
|-------|-------------|
| `cy`  | `claude --dangerously-skip-permissions` |
| `csy` | `claude --dangerously-skip-permissions --model sonnet` |
| `ay`  | `agy --dangerously-skip-permissions` |
| `xy`  | `codex --yolo` |

## Quickstart

1. Copy `.devcontainer/` into your repo root (also works to update an existing FAFO scaffold to the latest — re-running replaces `.devcontainer/`, so back up any local edits first):

   ```bash
   rm -rf _fafo-tmp .devcontainer && \
   git clone --depth 1 https://github.com/epicwhale/fafo-devcontainer.git _fafo-tmp && \
   mv _fafo-tmp/.devcontainer . && rm -rf _fafo-tmp
   ```

2. Open in VS Code → **Dev Containers: Reopen in Container**
3. Start coding freely: type `cy`, `xy`, `ay`, or `opencode`

Using devcontainer cli? `devcontainer up` then `devcontainer exec zsh`.
