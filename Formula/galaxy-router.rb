# typed: false
# frozen_string_literal: true

class GalaxyRouter < Formula
  desc "AI 协议互转代理网关"
  homepage "https://github.com/gclm/galaxy-router"
  version "0.0.2"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/gclm/galaxy-router/releases/download/v#{version}/galaxy-router-darwin-arm64.zip"
      sha256 "101e73759b8645c38dd8c9199166813aa0b4f7152c72f2f53d8ec8b9c2163ac9"
    else
      url "https://github.com/gclm/galaxy-router/releases/download/v#{version}/galaxy-router-darwin-x86_64.zip"
      sha256 "45aadb6edee810672bdb4603d5e8755b0a17ff28a7031d001bf1878f6e5ccead"
    end
  end

  def install
    bin.install "galaxy-router"
  end

  def post_install
    (var/"lib/galaxy-router").mkpath
    (var/"log/galaxy-router").mkpath

    config_dir = etc/"galaxy-router"
    config_dir.mkpath
    config_path = config_dir/"config.toml"

    unless config_path.exist?
      config_path.write <<~TOML
        [server]
        host = "127.0.0.1"
        port = 29088

        [database]
        path = "#{var}/lib/galaxy-router/galaxy.db"

        [logging]
        level = "info"
        format = "compact"
        file = true
        file_path = "#{var}/log/galaxy-router/galaxy.log"

        [auth]
        jwt_secret = ""
        token_expiry_hours = 24

        [pricing]
        cache_path = "#{var}/lib/galaxy-router/pricing_cache.json"
        refresh_interval_hours = 24
        providers = ["openai", "anthropic", "deepseek", "google", "zhipuai", "minimax", "xai", "moonshot", "xiaomi", "stepfun"]
      TOML
    end
  end

  service do
    run [opt_bin/"galaxy-router", "--config", etc/"galaxy-router/config.toml"]
    keep_alive true
    working_dir var/"lib/galaxy-router"
    log_path var/"log/galaxy-router/output.log"
    error_log_path var/"log/galaxy-router/error.log"
  end

  def caveats
    <<~EOS
      Config file: #{etc}/galaxy-router/config.toml
      Data directory: #{var}/lib/galaxy-router

      Start the service:
        brew services start gclm/tap/galaxy-router
    EOS
  end

  test do
    assert_match "galaxy-router", shell_output("#{bin}/galaxy-router --help", 0)
  end
end
