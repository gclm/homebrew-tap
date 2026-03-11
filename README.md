# gclm/homebrew-tap

Personal Homebrew tap maintained by `gclm`.

## Setup

```bash
brew tap gclm/tap
```

## Formulae

### `cli-proxy-api-plus`

OpenAI-compatible proxy with third-party provider support.

```bash
brew install gclm/tap/cli-proxy-api-plus
brew services start gclm/tap/cli-proxy-api-plus
```

Management UI: `http://127.0.0.1:8917/management.html`

Generated files:
- Config: `$(brew --prefix)/etc/cliproxyapi-plus/config.yaml`
- Metadata: `$(brew --prefix)/var/lib/cliproxyapi-plus/install-info`

Upstream: [router-for-me/CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus)

---

### `codex`

Rust-first coding agent with multi-agent support and Anthropic API.

```bash
brew install gclm/tap/codex
```

Upstream: [stellarlinkco/codex](https://github.com/stellarlinkco/codex)

## Updating

Formulas are auto-updated every 6 hours via CI. To update locally:

```bash
bash scripts/upgrade-local.sh
```

To manually trigger CI:

```bash
gh workflow run update-formulas.yml
```
