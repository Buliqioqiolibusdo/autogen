#!/usr/bin/env bash
# Idempotent Cloud Agent setup for the AutoGen monorepo.
#
# The base image already provides Python 3.12, Node 22 (via nvm), git, git-lfs,
# yarn and curl. This script adds the two missing tools (uv, rsync), fetches the
# Git LFS assets, syncs the Python `uv` workspace, and builds the AutoGen Studio
# frontend so the Studio GUI can be served from the Python package.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Make Node/npm/yarn (installed via nvm in the base image) available to this
# non-interactive shell without mutating any shell profile.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
fi

# --- System package: rsync (required by the Studio frontend build step) ---
if ! command -v rsync >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends rsync
fi

# --- uv: Python package/venv manager used by the workspace (python/README.md) ---
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
# Expose uv on the system PATH for future (non-login) shells without editing
# shell profiles.
sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv
sudo ln -sf "$HOME/.local/bin/uvx" /usr/local/bin/uvx

# --- Git LFS assets (icons/images used by the Studio frontend build and docs) ---
git lfs install --local
git lfs pull

# --- Python workspace: create/refresh the .venv with all optional extras ---
cd "$REPO_ROOT/python"
uv sync --all-extras

# --- AutoGen Studio frontend: build the Gatsby app into autogenstudio/web/ui ---
cd "$REPO_ROOT/python/packages/autogen-studio/frontend"
yarn install --frozen-lockfile
yarn build

echo "AutoGen environment setup complete."
