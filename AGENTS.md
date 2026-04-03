FAFO Stack — a copy-pasteable `.devcontainer/` package that provides an opinionated dev environment: shell ergonomics, AI coding CLIs with persistent state, and dev tools. No language runtimes, VS Code extensions, or forwarded ports — those are project-specific.

## Repo structure

```
.devcontainer/
  devcontainer.json        # Main config — features, mounts, AI CLI installs, shell setup
  docker-compose.yml       # Single devcontainer service (add more services per-project)
  scripts/
    ...
```

## Build and test

Requires Docker and the `devcontainer` CLI (`npm install -g @devcontainers/cli`).

```sh
# Build and start
devcontainer up

# Verify tools are working
devcontainer exec zsh -c 'claude --version && gemini --version && codex --version && node --version && gh --version && docker --version'

# Interactive shell
devcontainer exec zsh
```

## Conventions

- **Compose-based** even with a single service — makes adding services trivial.
- **No project-specific opinions** in the base. Runtimes, extensions, ports, and services are added per-project.
- **Named Docker volumes** persist AI tool config/state across container rebuilds (claude, gemini, codex, agents, opencode).