# FAFO Stack

An opinionated devcontainer starter for spinning up a fully loaded dev environment with zero project-specific opinions. Clone, reopen in container, start coding.

## Quickstart

1. Clone this repo (or copy `.devcontainer/` into an existing project)
2. Open in VS Code
3. `Dev Containers: Reopen in Container`
4. Wait for build
5. Start coding — shell, AI CLIs, and dev tools are ready

## What's included

**Shell:** zsh + oh-my-zsh + starship prompt + fzf, fd, ripgrep, eza, zoxide

**AI coding CLIs** (with persistent named volumes for config/state):
- Claude Code (`cy` = yolo mode, `csy` = sonnet yolo)
- Gemini CLI (`gy` = yolo mode)
- OpenAI Codex (`xy` = yolo mode)
- opencode

**Dev tools:** GitHub CLI, Docker-outside-of-Docker

**Node.js** (LTS) with npm, pnpm, yarn — installed as AI CLI runtime infrastructure, not as a project runtime opinion.

## Aliases

| Alias | Command |
|-------|---------|
| `cy`  | `claude --dangerously-skip-permissions` |
| `csy` | `claude --dangerously-skip-permissions --model sonnet` |
| `gy`  | `gemini --yolo` |
| `xy`  | `codex --yolo` |

## Testing changes

Use the `devcontainer` CLI to build and verify without VS Code:

```sh
# Build and start the container
devcontainer up

# Run commands inside it
devcontainer exec zsh -c 'claude --version && gemini --version'

# Run a full verification
devcontainer exec zsh -c '
  fd --version && rg --version && fzf --version && eza --version && zoxide --version &&
  node --version && npm --version && pnpm --version &&
  claude --version && gemini --version && codex --version &&
  gh --version && docker --version
'
```

## Customizing for a project

Add project-specific config to `.devcontainer/devcontainer.json`:

- **Runtimes:** Add features like `ghcr.io/devcontainers-extra/features/uv:1`
- **Ports:** Add `forwardPorts` and `portsAttributes`
- **Extensions:** Add `customizations.vscode.extensions`
- **Services:** Add services to `docker-compose.yml` (Redis, Postgres, etc.)
- **postCreateCommand:** Add project setup commands (`uv sync`, `npm install`, etc.)

## Workspace mount convention

The compose file mounts `../../` to `/workspaces`, assuming a `-space/main` folder structure. For repos opened directly, change the volume mount in `docker-compose.yml` to `..:/workspaces:cached`.
