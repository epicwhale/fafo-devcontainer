FAFO Stack — a copy-pasteable `.devcontainer/` package that provides an opinionated dev environment: shell ergonomics, AI coding CLIs with persistent state, and dev tools. No language runtimes, VS Code extensions, or forwarded ports — those are project-specific.

## Repo structure

```
.devcontainer/
  devcontainer.json        # Main config — references fafo feature + project-specific features
  docker-compose.yml       # Single devcontainer service (add more services per-project)
  features/
    fafo/
      devcontainer-feature.json  # Feature metadata, dependsOn, options, mounts, lifecycle hooks
      install.sh                 # Build-time: AI CLI installs + shell config (cached Docker layer)
      scripts/
        post-create.sh           # Runtime: volume setup + symlinks + skills installation
        starship.toml            # Starship prompt config
```

## Build and test

Requires Docker and the `devcontainer` CLI (`npm install -g @devcontainers/cli`).

```sh
# Build and start
devcontainer up

# Verify tools are working
devcontainer exec zsh -c 'zsh --version && claude --version && gemini --version && codex --version && node --version && gh --version && docker --version'

# Interactive shell
devcontainer exec zsh
```

## Conventions

- **Compose-based** even with a single service — makes adding services trivial.
- **No project-specific opinions** in the base. Runtimes, extensions, ports, and services are added per-project.
- **Custom devcontainer feature** (`features/fafo/`) encapsulates all FAFO opinions — shell ergonomics, AI CLIs, volume management. Shell tool features are auto-installed via `dependsOn` (upstream-maintained). AI CLI installs are cached as a Docker layer.
- **Named Docker volume** (`fafo-data`) persists AI tool config/state across container rebuilds via symlinks from `$HOME` dirs.

## References
- refer to updated [devcontainer feature development specifications](https://containers.dev/implementors/features/)
- [devcontainer CLI docs](https://code.visualstudio.com/docs/remote/devcontainerjson-reference)