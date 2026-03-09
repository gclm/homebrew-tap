# gclm/homebrew-tap

Personal Homebrew tap for packages maintained or curated by `gclm`.

This repository is intended to host multiple custom formulae over time.
Formulae should live under `Formula/`.

## Tap Usage

```bash
brew tap gclm/tap
```

Install a formula from this tap:

```bash
brew install gclm/tap/<formula>
```

## Included Formulae

### `cliproxyapi-plus`

Installs `CLIProxyAPIPlus` with a local-first default configuration for management on:

- `http://127.0.0.1:8917/management.html`

Install:

```bash
brew install gclm/tap/cliproxyapi-plus
```

Start as a background service:

```bash
brew services start gclm/tap/cliproxyapi-plus
```

Generated files after install:

- Config: `$(brew --prefix)/etc/cliproxyapi-plus/config.yaml`
- Install metadata: `$(brew --prefix)/var/lib/cliproxyapi-plus/install-info`

The formula generates a management token on first install and shows it in `brew` caveats.

## Maintenance

This tap tracks upstream releases where needed, but keeps formula-specific bootstrap logic local to this repository.

For `cliproxyapi-plus`:

- upstream binary version and checksums come from `router-for-me/CLIProxyAPIPlus` releases
- local config bootstrap, caveats, and service behavior are maintained in this repository

## Automation

`.github/workflows/update-cliproxyapi-plus.yml` checks for upstream updates and only commits when the formula file actually changes.

## Conventions

- Put reusable formula logic in the formula itself unless it becomes shared across multiple packages
- Keep automation scripts minimal and targeted
- Avoid regenerating whole formula files when only a few upstream fields change
