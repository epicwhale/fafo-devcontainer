Modernized devcontainer setup with Claude, Codex, Gemini, and opencode that's ready to run in YOLO mode. Pre-configured with [obra/superpowers](https://github.com/obra/superpowers) and sane defaults that persists logins, configs, and conversation history across container rebuilds. Just drop the `.devcontainer/` folder into any repo and you're good to go.

## Why

I found myself fighting with a swamp of configuration and long-build times every time I wanted to spin up a devcontainer for agentic coding: installing CLIs, configuring shell, setting up volumes for persistent state (like logins, conversation history, ...), and so on. It was inertia I didn't like.

## What's in the box

- **Coding CLIs** — Claude Code, Gemini CLI, OpenAI Codex, opencode — pre-installed with yolo-mode aliases
- **Superpowers** — [obra/superpowers](https://github.com/obra/superpowers) skills auto-installed for all four AI CLIs
- **Persistent state** — named docker volume keeps your logins, configs, and conversation history across container rebuilds
- **Shell** — zsh + starship + (fd, ripgrep, fzf, eza, zoxide)


## YOLO Aliases

| Alias | What it runs |
|-------|-------------|
| `cy`  | `claude --dangerously-skip-permissions` |
| `csy` | `claude --dangerously-skip-permissions --model sonnet` |
| `gy`  | `gemini --yolo` |
| `xy`  | `codex --yolo` |

## Quickstart

1. Copy `.devcontainer/` into your repo (or clone this one)
2. Open in VS Code → **Dev Containers: Reopen in Container**
3. Start coding freely: type `cy`, `xy`, `gy`, or `opencode`

Using devcontainer cli? `devcontainer up` then `devcontainer exec zsh`.
