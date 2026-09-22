# typed: false
# frozen_string_literal: true

class WeftDevice < Formula
  desc "Weft 私有化 Mesh VPN 设备端（EasyTier 内核）"
  homepage "https://weft.gclmit.club"
  version "0.3.6"
  license "MIT"

  livecheck do
    skip "私有部署：版本随生产控制台 releases 上架节奏，不自动检测"
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://weft.gclmit.club/downloads/weft-device-darwin-arm64-#{version}.tar.gz"
      sha256 "12eb4252b66e63a4aac47b5cbf9697d37c72a082b3ba4bd8494b6e4aa63d22e5"
    else
      url "https://weft.gclmit.club/downloads/weft-device-darwin-amd64-#{version}.tar.gz"
      sha256 "f8d370f4276cfc6049cd22a2c141f830687e708e891c5359bf4edc1c1c4cf1e9"
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
