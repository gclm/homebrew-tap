# typed: false
# frozen_string_literal: true

require "securerandom"

class CliProxyApi < Formula
  desc "OpenAI-compatible proxy with third-party provider support"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  version "6.9.45"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v6.9.45/CLIProxyAPI_6.9.45_darwin_arm64.tar.gz"
      sha256 "6e4c6dd407a54894e60bfac845e3acb1f68949403caf202179e40f60886557d7"
    else
      url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v6.9.45/CLIProxyAPI_6.9.45_darwin_amd64.tar.gz"
      sha256 "7056d833515182b3f5a32f0b845129d56d95b5e5b381d004fdbd0c5789b9c4d6"
    end
  end

  def install
    bin.install "cli-proxy-api"
  end

  def post_install
    config_dir = etc/"cli-proxy-api"
    config_dir.mkpath
    config_path = config_dir/"config.yaml"

    state_dir = var/"lib/cli-proxy-api"
    state_dir.mkpath
    info_path = state_dir/"install-info"

    (var/"log/cli-proxy-api").mkpath

    unless config_path.exist?
      token = existing_management_token(info_path) || SecureRandom.hex(16)
      rendered = minimal_config_template.gsub("__MANAGEMENT_TOKEN__", token)
      config_path.write(rendered)
      info_path.write(install_info(port: configured_port_from(rendered), token: token))
    end
  end

  service do
    run [opt_bin/"cli-proxy-api", "-config", etc/"cli-proxy-api/config.yaml"]
    keep_alive true
    working_dir var/"lib/cli-proxy-api"
    log_path var/"log/cli-proxy-api/output.log"
    error_log_path var/"log/cli-proxy-api/error.log"
  end

  def caveats
    config_path = etc/"cli-proxy-api/config.yaml"
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
    output << "  brew services start gclm/tap/cli-proxy-api"
    output << ""
    output << "If you update the config manually, restart the service:"
    output << "  brew services restart gclm/tap/cli-proxy-api"

    output.join("\n")
  end

  test do
    assert_match "CLIProxyAPI Version", shell_output("#{bin}/cli-proxy-api --help")
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
    info_path = var/"lib/cli-proxy-api/install-info"
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
