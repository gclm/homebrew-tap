# typed: false
# frozen_string_literal: true

class CliproxyapiPlus < Formula
  desc "OpenAI-compatible proxy with third-party provider support"
  homepage "https://github.com/router-for-me/CLIProxyAPIPlus"
  version "6.8.49-0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.8.49-0/CLIProxyAPIPlus_6.8.49-0_darwin_arm64.tar.gz"
      sha256 "8204333d08d99a8245290536383d4938a3a9cd119f222b00225bd4c64695a516"
    else
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.8.49-0/CLIProxyAPIPlus_6.8.49-0_darwin_amd64.tar.gz"
      sha256 "6f16f3c445fe0133f182419b4b2f855c6c08f4f4a671073237c4469c9713bd5a"
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
      TOKEN_FILE="$STATE_DIR/management-token"

      mkdir -p "$STATE_DIR"

      read_secret_key() {
        ruby -e '
          path = ARGV[0]
          inside = false
          value = ""
          File.readlines(path).each do |line|
            if line =~ /^remote-management:\s*$/
              inside = true
              next
            end
            if inside && line =~ /^\S/
              inside = false
            end
            next unless inside
            if line =~ /^\s*secret-key:\s*(.*)$/
              raw = Regexp.last_match(1).strip
              value = raw.gsub(/\A["\047]|["\047]\z/, "")
              break
            end
          end
          puts value
        ' "$CONFIG_PATH"
      }

      write_secret_key() {
        ruby -e '
          path = ARGV[0]
          token = ARGV[1]
          inside = false
          replaced = false
          lines = File.readlines(path).map do |line|
            if line =~ /^remote-management:\s*$/
              inside = true
              line
            elsif inside && line =~ /^\S/
              inside = false
              line
            elsif inside && line =~ /^(\s*secret-key:)/
              replaced = true
              "\#{$1} \047\#{token}\047\n"
            else
              line
            end
          end
          abort("secret-key not found in \#{path}") unless replaced
          File.write(path, lines.join)
        ' "$CONFIG_PATH" "$1"
      }

      read_port() {
        ruby -e '
          path = ARGV[0]
          port = "8917"
          File.readlines(path).each do |line|
            if line =~ /^port:\s*([0-9]+)\s*$/
              port = Regexp.last_match(1)
              break
            end
          end
          puts port
        ' "$CONFIG_PATH"
      }

      secret="$(read_secret_key)"
      token=""
      if [ -z "$secret" ] || [ "$secret" = "__AUTO_GENERATE__" ]; then
        token="$(openssl rand -hex 16)"
        write_secret_key "$token"
        umask 077
        printf '%s\n' "$token" > "$TOKEN_FILE"
        echo "[cliproxyapi-plus] Generated management token and stored it at $TOKEN_FILE"
      elif [ -f "$TOKEN_FILE" ]; then
        token="$(cat "$TOKEN_FILE")"
      fi

      port="$(read_port)"
      echo "[cliproxyapi-plus] Management UI: http://127.0.0.1:${port}/management.html"
      if [ -n "$token" ]; then
        echo "[cliproxyapi-plus] Management token: $token"
      else
        echo "[cliproxyapi-plus] Management token is configured but plaintext is unavailable"
      fi

      exec "#{opt_bin}/cli-proxy-api-plus" -config "$CONFIG_PATH"
    SH
  end
end
