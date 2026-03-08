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

cat > "$formula" <<EOF
# typed: false
# frozen_string_literal: true

class CliproxyapiPlus < Formula
  desc "CLIProxyAPI Plus distribution for Homebrew"
  homepage "https://github.com/router-for-me/CLIProxyAPIPlus"
  version "$version"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/$tag/$arm_asset"
      sha256 "$arm_sha"
    else
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/$tag/$intel_asset"
      sha256 "$intel_sha"
    end
  end

  def install
    bin.install "cli-proxy-api-plus"

    config_dir = etc/"cliproxyapi-plus"
    config_dir.mkpath
    config_path = config_dir/"config.yaml"
    config_path.write(buildpath/"config.example.yaml".read) unless config_path.exist?

    (var/"lib/cliproxyapi-plus").mkpath
    (var/"log/cliproxyapi-plus").mkpath
  end

  service do
    run [opt_bin/"cli-proxy-api-plus", "-config", etc/"cliproxyapi-plus/config.yaml"]
    keep_alive true
    working_dir var/"lib/cliproxyapi-plus"
    log_path var/"log/cliproxyapi-plus/output.log"
    error_log_path var/"log/cliproxyapi-plus/error.log"
  end

  def caveats
    <<~EOS
      Config file: #{etc}/cliproxyapi-plus/config.yaml
      Auth directory: ~/.cli-proxy-api

      Edit the config file before starting the service:
        #{ENV.fetch("EDITOR", "vi")} #{etc}/cliproxyapi-plus/config.yaml

      Start the service:
        brew services start gclm/tap/cliproxyapi-plus
    EOS
  end

  test do
    assert_match "CLIProxyAPI Version", shell_output("#{bin}/cli-proxy-api-plus --help")
  end
end
EOF

echo "Updated $formula to $version"
