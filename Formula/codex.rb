# typed: false
# frozen_string_literal: true

class Codex < Formula
  desc "Rust-first coding agent with multi-agent support and Anthropic API"
  homepage "https://github.com/stellarlinkco/codex"
  version "1.3.0"
  license "AGPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/stellarlinkco/codex/releases/download/v1.3.0/codex-aarch64-apple-darwin.tar.gz"
      sha256 "bd2a356a147ed0e2057998b3bae605888f1451fde1e529b7d337a673548c0ee2"
    else
      url "https://github.com/stellarlinkco/codex/releases/download/v1.3.0/codex-x86_64-apple-darwin.tar.gz"
      sha256 "8c2abdd00dd2b32c8b2f1b3836f695d272deb3e51a4da45f01ecc0acb3495bd4"
    end
  end

  def install
    if Hardware::CPU.arm?
      bin.install "codex-aarch64-apple-darwin" => "codex"
    else
      bin.install "codex-x86_64-apple-darwin" => "codex"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codex --version")
  end
end
