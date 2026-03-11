#!/usr/bin/env bash
# Pull latest tap formulas and upgrade installed services.
set -euo pipefail

echo "==> Updating tap..."
brew update

formulas=(cli-proxy-api-plus codex)

for formula in "${formulas[@]}"; do
  if brew list --formula "gclm/tap/$formula" &>/dev/null; then
    if ! brew outdated "gclm/tap/$formula" 2>/dev/null | grep -q .; then
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
