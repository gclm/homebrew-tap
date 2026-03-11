#!/usr/bin/env bash
# Update a Homebrew formula to the latest GitHub release.
#
# Usage:
#   update-formula.sh --repo REPO --formula PATH \
#                     --arm-asset PATTERN --intel-asset PATTERN
#
# PATTERN may contain {version} and {tag} placeholders, e.g.
#   "MyApp_{version}_darwin_arm64.tar.gz"
#   "codex-aarch64-apple-darwin.tar.gz"  (no placeholder needed)
set -euo pipefail

usage() {
  echo "Usage: $0 --repo REPO --formula PATH --arm-asset PATTERN --intel-asset PATTERN" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)        repo="$2";          shift 2 ;;
    --formula)     formula="$2";       shift 2 ;;
    --arm-asset)   arm_pattern="$2";   shift 2 ;;
    --intel-asset) intel_pattern="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "${repo:-}" || -z "${formula:-}" || -z "${arm_pattern:-}" || -z "${intel_pattern:-}" ]] && usage

release_json="$(gh api "repos/${repo}/releases/latest")"
tag="$(jq -r '.tag_name' <<<"$release_json")"
version="${tag#v}"

arm_asset="${arm_pattern//\{version\}/$version}"
arm_asset="${arm_asset//\{tag\}/$tag}"
intel_asset="${intel_pattern//\{version\}/$version}"
intel_asset="${intel_asset//\{tag\}/$tag}"

arm_sha="$(jq -r --arg name "$arm_asset" '.assets[] | select(.name == $name) | .digest' <<<"$release_json" | sed 's/^sha256://')"
intel_sha="$(jq -r --arg name "$intel_asset" '.assets[] | select(.name == $name) | .digest' <<<"$release_json" | sed 's/^sha256://')"

if [[ -z "$arm_sha" || -z "$intel_sha" ]]; then
  echo "Failed to resolve release assets for tag $tag (arm: $arm_asset, intel: $intel_asset)" >&2
  exit 1
fi

export FORMULA_PATH="$formula"
export REPO="$repo"
export VERSION="$version"
export TAG="$tag"
export ARM_ASSET="$arm_asset"
export INTEL_ASSET="$intel_asset"
export ARM_SHA="$arm_sha"
export INTEL_SHA="$intel_sha"

python3 - <<'EOF'
import re, os, sys

formula   = os.environ['FORMULA_PATH']
repo      = os.environ['REPO']
tag       = os.environ['TAG']
version   = os.environ['VERSION']
arm_asset   = os.environ['ARM_ASSET']
intel_asset = os.environ['INTEL_ASSET']
arm_sha     = os.environ['ARM_SHA']
intel_sha   = os.environ['INTEL_SHA']

content = open(formula).read()
base    = f'https://github.com/{repo}/releases/download'

def url_pat(asset):
    # replace version/tag occurrences in asset name with a wildcard
    escaped = re.escape(asset).replace(re.escape(version), r'[^"]+').replace(re.escape(tag.lstrip('v')), r'[^"]+').replace(re.escape(tag), r'[^"]+') if version else re.escape(asset)
    return rf'url "{re.escape(base)}/[^/]+/{escaped}"'

replacements = [
    (r'version "[^"]+"',                        f'version "{version}"'),
    (url_pat(arm_asset),                          f'url "{base}/{tag}/{arm_asset}"'),
    (r'(sha256 "[0-9a-f]{64}")(\n\s+else)',      rf'sha256 "{arm_sha}"\2'),
    (url_pat(intel_asset),                        f'url "{base}/{tag}/{intel_asset}"'),
    (r'(sha256 "[0-9a-f]{64}")(\n\s+end\n\s+end)', rf'sha256 "{intel_sha}"\2'),
]

# version replacement is optional (some formulas derive version from URL)
required = replacements[1:]

for pat, _repl in required:
    if not re.search(pat, content):
        sys.exit(f'Formula update pattern mismatch: required pattern not found: {pat}')

updated = content
for pat, repl in replacements:
    updated = re.sub(pat, repl, updated, count=1)

if updated == content:
    print('no')
else:
    open(formula, 'w').write(updated)
    print('yes')
EOF
