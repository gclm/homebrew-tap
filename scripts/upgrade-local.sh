#!/usr/bin/env bash
# Pull latest tap formulas and upgrade installed services.
set -euo pipefail

# Sync local tap to Homebrew's tap directory if it's a local tap
sync_local_tap() {
  local tap_dir
  tap_dir=$(brew --repository gclm/tap 2>/dev/null) || return 0

  local tap_origin
  tap_origin=$(git -C "$tap_dir" remote get-url origin 2>/dev/null) || return 0

  # Check if origin points to a local directory (not a git URL)
  if [[ -d "$tap_origin" && ! "$tap_origin" =~ ^https?:// && ! "$tap_origin" =~ ^git@ ]]; then
    echo "==> Syncing local tap from $tap_origin..."
    git -C "$tap_dir" fetch origin --quiet 2>/dev/null || true
    git -C "$tap_dir" reset --hard origin/main --quiet 2>/dev/null || \
      git -C "$tap_dir" reset --hard origin/master --quiet 2>/dev/null || true
  fi
}

echo "==> Updating tap..."
sync_local_tap
brew update

formulas=(cli-proxy-api-plus codex octopus)

for formula in "${formulas[@]}"; do
  if brew list --formula "gclm/tap/$formula" &>/dev/null; then
    if brew outdated "gclm/tap/$formula" 2>/dev/null | grep -q .; then
      echo "==> Upgrading $formula..."
      brew upgrade "gclm/tap/$formula"
      if brew services list | grep -q "^$formula"; then
        echo "==> Restarting $formula service..."
        brew services restart "gclm/tap/$formula"
      fi
    else
      echo "==> $formula is up to date"
    fi
  fi
done

echo "==> Done"
