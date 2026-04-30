# gclm/homebrew-tap

Personal Homebrew tap maintained by `gclm`.

## Setup

```bash
brew tap gclm/tap
```

## Formulae

### `cli-proxy-api`

OpenAI-compatible proxy with third-party provider support.

```bash
brew install gclm/tap/cli-proxy-api
brew services start gclm/tap/cli-proxy-api
```

Management UI: `http://127.0.0.1:8917/management.html`

Generated files:
- Config: `$(brew --prefix)/etc/cli-proxy-api/config.yaml`
- Metadata: `$(brew --prefix)/var/lib/cli-proxy-api/install-info`

Upstream: [router-for-me/CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI)

---

### `octopus`

```bash
brew install gclm/tap/octopus
```

Upstream: [gclm/octopus](https://github.com/gclm/octopus)

---

### `securefox`

```bash
brew install gclm/tap/securefox
```

Upstream: [gclm/securefox](https://github.com/gclm/securefox)

## Updating

Formulas are auto-updated every 6 hours via CI. To update locally:

```bash
bash scripts/upgrade-local.sh
```

To manually trigger CI:

```bash
gh workflow run update-formulas.yml
```
