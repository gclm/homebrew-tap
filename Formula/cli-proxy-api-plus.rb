# typed: false
# frozen_string_literal: true

require "securerandom"

class CliProxyApiPlus < Formula
  desc "OpenAI-compatible proxy with third-party provider support"
  homepage "https://github.com/router-for-me/CLIProxyAPIPlus"
  version "6.9.10-1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.9.10-1/CLIProxyAPIPlus_6.9.10-1_darwin_arm64.tar.gz"
      sha256 "c6af9831d047165a1fb5acded24f3d6ce6b4f5e161c28ef907bb035afadc960a"
    else
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.9.10-1/CLIProxyAPIPlus_6.9.10-1_darwin_amd64.tar.gz"
      sha256 "64e235196e644ff629d1d55e49271dd4afb68842fba8327835659d450c024edd"
    end
  end

  def install
    bin.install "cli-proxy-api-plus"
  end

  def post_install
    config_dir = etc/"cliproxyapi-plus"
    config_dir.mkpath
    config_path = config_dir/"config.yaml"

    state_dir = var/"lib/cliproxyapi-plus"
    state_dir.mkpath
    info_path = state_dir/"install-info"

    (var/"log/cliproxyapi-plus").mkpath

    unless config_path.exist?
      token = existing_management_token(info_path) || SecureRandom.hex(16)
      rendered = minimal_config_template.gsub("__MANAGEMENT_TOKEN__", token)
      config_path.write(rendered)
      info_path.write(install_info(port: configured_port_from(rendered), token: token))
    end
  end

  service do
    run [opt_bin/"cli-proxy-api-plus", "-config", etc/"cliproxyapi-plus/config.yaml"]
    keep_alive true
    working_dir var/"lib/cliproxyapi-plus"
    log_path var/"log/cliproxyapi-plus/output.log"
    error_log_path var/"log/cliproxyapi-plus/error.log"
  end

  def caveats
    config_path = etc/"cliproxyapi-plus/config.yaml"
    info = read_install_info
    port = configured_port_from(config_path.exist? ? config_path.read : minimal_config_template)
    management_url = "http://127.0.0.1:#{port}/management.html"

    output = []
    output << "Config file: #{config_path}"
    output << "Auth directory: ~/.cli-proxy-api"
    output << "Management URL: #{management_url}"

    management_token = info["management_token"]
    token_message =
      if management_token.present?
        "Management token: #{management_token}"
      else
        "Management token: preserved from existing config (not re-generated)"
      end
    output << token_message

    output << ""
    output << "Start the service:"
    output << "  brew services start gclm/tap/cli-proxy-api-plus"
    output << ""
    output << "If you update the config manually, restart the service:"
    output << "  brew services restart gclm/tap/cli-proxy-api-plus"

    output.join("\n")
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
        secret-key: '__MANAGEMENT_TOKEN__'
        disable-control-panel: false
        panel-github-repository: 'https://github.com/router-for-me/Cli-Proxy-API-Management-Center'

      auth-dir: '~/.cli-proxy-api'

      api-keys:
        - 'local-dev-api-key'
    YAML
  end

  def install_info(port:, token:)
    <<~TEXT
      management_url=http://127.0.0.1:#{port}/management.html
      management_token=#{token}
    TEXT
  end

  def read_install_info
    info_path = var/"lib/cliproxyapi-plus/install-info"
    parse_install_info(info_path)
  end

  def existing_management_token(info_path)
    token = parse_install_info(info_path)["management_token"]
    return nil if token.to_s.empty?

    token
  end

  def parse_install_info(info_path)
    return {} unless info_path.exist?

    info_path.each_line.with_object({}) do |line, acc|
      key, value = line.strip.split("=", 2)
      acc[key] = value if key && value
    end
  end

  def configured_port_from(content)
    match = content.match(/^port:\s*(\d+)\s*$/)
    match ? match[1] : "8917"
  end
end
