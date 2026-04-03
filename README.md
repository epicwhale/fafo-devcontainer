# FAFO Devcontainer

Opinionated 0-to-1 devcontainer for yolo agentic coding with Claude, Codex, Gemini, and opencode ready to run in yolo mode, with obra/skills pre-instaled. Pre-configured volume to persist logins, configs, and conversation history across container rebuilds. Just drop the `.devcontainer/` folder into any repo and you're good to go.

## Why

I've found myself repeating the same devcontainer setup process - install the CLIs, configure shell, lose all your logins when the container rebuilds, do it again. 

## What's in the box

- **Coding CLIs** — Claude Code, Gemini CLI, OpenAI Codex, opencode — pre-installed with yolo-mode aliases
- **Persistent state** — a named Docker volume keeps your logins, configs, and conversation history across container rebuilds
- **Shell** — zsh + oh-my-zsh + starship prompt + fd, ripgrep, fzf, eza, zoxide
- **Dev tools** — GitHub CLI, Docker-outside-of-Docker
- **Superpowers** — [obra/superpowers](https://github.com/obra/superpowers) skills auto-installed for all four AI CLIs

## Yolo aliases

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
