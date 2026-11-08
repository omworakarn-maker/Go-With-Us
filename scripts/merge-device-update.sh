#!/bin/bash
set -eu
source_repo="$(cd "$(dirname "$0")/.." && pwd)"
target_repo="${1:-/Users/worakan/Desktop/Go-With-Us}"
if [ "$source_repo" = "$(cd "$target_repo" && pwd)" ]; then
  echo "This is already the updated repository; review git status before pushing."
  exit 0
fi
if [ "$(git -C "$target_repo" branch --show-current)" != "main" ]; then
  echo "Switch the target repository to main before merging."
  exit 1
fi
if [ -n "$(git -C "$target_repo" status --porcelain --untracked-files=no)" ]; then
  echo "The target has uncommitted changes. Commit or stash them before merging."
  exit 1
fi
git -C "$target_repo" fetch "$source_repo" main
git -C "$target_repo" merge --no-ff --no-edit FETCH_HEAD
echo "Merged locally. Review the changes before running git push origin main."
echo "Backend deployment also requires npm run db:deploy before the new server starts."
