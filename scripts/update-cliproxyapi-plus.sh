#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
formula="$repo_root/Formula/cliproxyapi-plus.rb"
release_json="$(gh api repos/router-for-me/CLIProxyAPIPlus/releases/latest)"
tag="$(jq -r '.tag_name' <<<"$release_json")"
version="${tag#v}"
arm_asset="CLIProxyAPIPlus_${version}_darwin_arm64.tar.gz"
intel_asset="CLIProxyAPIPlus_${version}_darwin_amd64.tar.gz"
arm_sha="$(jq -r --arg name "$arm_asset" '.assets[] | select(.name == $name) | .digest' <<<"$release_json" | sed 's/^sha256://')"
intel_sha="$(jq -r --arg name "$intel_asset" '.assets[] | select(.name == $name) | .digest' <<<"$release_json" | sed 's/^sha256://')"

if [[ -z "$arm_sha" || -z "$intel_sha" ]]; then
  echo "Failed to resolve release assets for tag $tag" >&2
  exit 1
fi

export FORMULA_PATH="$formula"
export VERSION="$version"
export TAG="$tag"
export ARM_ASSET="$arm_asset"
export INTEL_ASSET="$intel_asset"
export ARM_SHA="$arm_sha"
export INTEL_SHA="$intel_sha"

changed="$(
ruby <<'RUBY'
formula = ENV.fetch("FORMULA_PATH")
content = File.read(formula)
matched = 0

replacements = [
  [/version ".*?"/, %(version "#{ENV.fetch("VERSION")}")],
  [
    /url "https:\/\/github\.com\/router-for-me\/CLIProxyAPIPlus\/releases\/download\/v[^"]+\/CLIProxyAPIPlus_[^"]+_darwin_arm64\.tar\.gz"/,
    %(url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/#{ENV.fetch("TAG")}/#{ENV.fetch("ARM_ASSET")}")
  ],
  [
    /sha256 "[0-9a-f]{64}"\n\s+else/,
    %(sha256 "#{ENV.fetch("ARM_SHA")}"\n    else)
  ],
  [
    /url "https:\/\/github\.com\/router-for-me\/CLIProxyAPIPlus\/releases\/download\/v[^"]+\/CLIProxyAPIPlus_[^"]+_darwin_amd64\.tar\.gz"/,
    %(url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/#{ENV.fetch("TAG")}/#{ENV.fetch("INTEL_ASSET")}")
  ],
  [
    /sha256 "[0-9a-f]{64}"\n\s+end\n\s+end/,
    %(sha256 "#{ENV.fetch("INTEL_SHA")}"\n    end\n  end)
  ]
]

updated = replacements.reduce(content) do |memo, (pattern, replacement)|
  next memo unless memo.match?(pattern)

  matched += 1
  memo.sub(pattern, replacement)
end

raise "Formula update pattern mismatch" unless matched == replacements.length

if updated == content
  puts "no"
  exit 0
end

File.write(formula, updated)
puts "yes"
RUBY
)"

if [[ "$changed" == "yes" ]]; then
  echo "Updated $formula to $version"
else
  echo "No formula changes detected"
fi
