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
  desc "OpenAI-compatible proxy with third-party provider support"
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
    config_path.write(minimal_config_template) unless config_path.exist?

    (var/"lib/cliproxyapi-plus").mkpath
    (var/"log/cliproxyapi-plus").mkpath

    wrapper = libexec/"brew-service-wrapper"
    wrapper.write(service_wrapper_script)
    wrapper.chmod 0755
  end

  service do
    run [opt_libexec/"brew-service-wrapper"]
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

  private

  def minimal_config_template
    <<~YAML
      host: '127.0.0.1'
      port: 8917

      remote-management:
        allow-remote: false
        secret-key: '__AUTO_GENERATE__'
        disable-control-panel: false
        panel-github-repository: 'https://github.com/router-for-me/Cli-Proxy-API-Management-Center'

      auth-dir: '~/.cli-proxy-api'

      api-keys:
        - 'local-dev-api-key'
    YAML
  end

  def service_wrapper_script
    <<~SH
      #!/bin/bash
      set -euo pipefail

      CONFIG_PATH="#{etc}/cliproxyapi-plus/config.yaml"
      STATE_DIR="#{var}/lib/cliproxyapi-plus"
      TOKEN_FILE="\$STATE_DIR/management-token"

      mkdir -p "\$STATE_DIR"

      read_secret_key() {
        awk '
          /^remote-management:[[:space:]]*$/ { in_rm=1; next }
          in_rm && /^[^[:space:]]/ { in_rm=0 }
          in_rm && /^[[:space:]]*secret-key:/ {
            sub(/^[[:space:]]*secret-key:[[:space:]]*/, "", \$0)
            gsub(/^["\047]|["\047]$/, "", \$0)
            print \$0
            exit
          }
        ' "\$CONFIG_PATH"
      }

      write_secret_key() {
        awk -v token="\$1" '
          BEGIN { replaced=0 }
          /^remote-management:[[:space:]]*$/ { in_rm=1; print; next }
          in_rm && /^[^[:space:]]/ { in_rm=0 }
          in_rm && /^[[:space:]]*secret-key:/ {
            print "  secret-key: \047" token "\047"
            replaced=1
            next
          }
          { print }
          END {
            if (!replaced) exit 42
          }
        ' "\$CONFIG_PATH" > "\$CONFIG_PATH.tmp"
        mv "\$CONFIG_PATH.tmp" "\$CONFIG_PATH"
      }

      read_port() {
        awk '
          /^port:[[:space:]]*[0-9]+[[:space:]]*$/ {
            sub(/^port:[[:space:]]*/, "", \$0)
            sub(/[[:space:]]*$/, "", \$0)
            print \$0
            found=1
            exit
          }
          END {
            if (!found) print "8917"
          }
        ' "\$CONFIG_PATH"
      }

      secret="\$(read_secret_key)"
      token=""
      if [ -z "\$secret" ] || [ "\$secret" = "__AUTO_GENERATE__" ]; then
        token="\$(openssl rand -hex 16)"
        write_secret_key "\$token"
        umask 077
        printf '%s\n' "\$token" > "\$TOKEN_FILE"
        echo "[cliproxyapi-plus] Generated management token and stored it at \$TOKEN_FILE"
      elif [ -f "\$TOKEN_FILE" ]; then
        token="\$(cat "\$TOKEN_FILE")"
      fi

      port="\$(read_port)"
      echo "[cliproxyapi-plus] Management UI: http://127.0.0.1:\${port}/management.html"
      if [ -n "\$token" ]; then
        echo "[cliproxyapi-plus] Management token: \$token"
      else
        echo "[cliproxyapi-plus] Management token is configured but plaintext is unavailable"
      fi

      exec "#{opt_bin}/cli-proxy-api-plus" -config "\$CONFIG_PATH"
    SH
  end
end
EOF

echo "Updated $formula to $version"
