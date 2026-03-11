# typed: false
# frozen_string_literal: true

class Codex < Formula
  desc "Rust-first coding agent with multi-agent support and Anthropic API"
  homepage "https://github.com/stellarlinkco/codex"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/stellarlinkco/codex/releases/download/v1.2.6/codex-aarch64-apple-darwin.tar.gz"
      sha256 "18efd5721820844c300c6783759bc11144277a03a1eea769db7606ef6f490673"
    else
      url "https://github.com/stellarlinkco/codex/releases/download/v1.2.6/codex-x86_64-apple-darwin.tar.gz"
      sha256 "7d7aec5d7812d442fccc67fd5280fd109c92467dbc83aa4c59b7ea88601b06a0"
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
