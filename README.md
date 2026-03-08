# homebrew-tap

Homebrew tap for packages maintained by gclm.

## Install

```bash
brew tap gclm/tap
brew install gclm/tap/cliproxyapi-plus
```

## Run as a service

```bash
brew services start gclm/tap/cliproxyapi-plus
```

Default config path:

```text
$(brew --prefix)/etc/cliproxyapi-plus/config.yaml
```

The formula seeds that file from upstream `config.example.yaml` on first install and preserves local edits on upgrade.

## Update policy

`CLIProxyAPIPlus` is tracked from upstream GitHub releases. The GitHub Actions workflow in `.github/workflows/update-cliproxyapi-plus.yml` refreshes the formula every 6 hours and pushes a commit when the version or checksums change.

## Existing formulas

This tap already contains `ghp.rb` at repository root for compatibility. New formulas should go under `Formula/`.
