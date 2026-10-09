# typed: false
# frozen_string_literal: true

class WeftDevice < Formula
  desc "Weft 私有化 Mesh VPN 设备端（EasyTier 内核）"
  homepage "https://weft.gclmit.club"
  version "0.4.1"
  license "MIT"

  livecheck do
    skip "私有部署：版本随生产控制台 releases 上架节奏，不自动检测"
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://weft.gclmit.club/downloads/weft-device-darwin-arm64-#{version}.tar.gz"
      sha256 "dc0e095e84a121a7e56f50df05b0d0c65f0a17b88bf88587df4e0a0dab4a9acc"
    else
      url "https://weft.gclmit.club/downloads/weft-device-darwin-amd64-#{version}.tar.gz"
      sha256 "b21507511cd09e519dc5ad9d45e2c4a9801a3e718fbb31b82d78f2d6abd0ee10"
    end
  end

  def install
    bin.install "weft-device"
  end

  service do
    run [opt_bin/"weft-device", "up", "--console", "https://weft.gclmit.club"]
    run_type :immediate
    keep_alive true
    working_dir var/"lib/weft-device"
    log_path var/"log/weft-device.log"
    error_log_path var/"log/weft-device.log"
  end

  def caveats
    <<~EOS
      首次使用（TUN 需 root 运行）：

        sudo brew services start gclm/tap/weft-device

      服务日志含网页授权链接（浏览器打开并批准即入网）：
        sudo tail -f $(brew --prefix)/var/log/weft-device.log

      查看入网状态：weft-device status
      升级：brew upgrade weft-device（重启服务式，不走 --auto-upgrade）
    EOS
  end

  test do
    assert_match "weft-device", shell_output("#{bin}/weft-device --version", 0)
  end
end
