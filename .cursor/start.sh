#!/usr/bin/env bash
# Per-boot setup for the AutoGen monorepo.
#
# Cursor performs a fresh git checkout on every boot, which leaves Git LFS-tracked
# files (icons/images) as small pointer stubs. The one-time `install` step is not
# re-run when an agent boots from a prebuilt environment build, so LFS content must
# be restored here on each boot. Without it, rebuilding the AutoGen Studio frontend
# or the docs fails on the placeholder images.
#
# This is best-effort: a transient LFS/network failure logs a warning but does not
# block the environment from starting.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

git lfs install --local >/dev/null 2>&1 || true
if git lfs pull; then
  echo "Git LFS assets restored."
else
  echo "WARNING: 'git lfs pull' failed; LFS-tracked binary assets remain as pointers." >&2
fi
