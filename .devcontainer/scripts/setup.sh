#!/usr/bin/env bash
set -euo pipefail

bash "$(dirname "$0")/setup-shell.sh" &
SHELL_PID=$!
bash "$(dirname "$0")/setup-ai-tools.sh"
wait $SHELL_PID || { echo "Shell setup failed"; exit 1; }
