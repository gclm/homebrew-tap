# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Ghp < Formula
  desc "Github Proxy | Github 代理"
  homepage "https://blog.gclmit.club"
  url "https://github.com/gclm/ghp/releases/download/v1.0.3-rc3/ghp_1.0.3-rc3_darwin_amd64.tar.gz"
  sha256 "58f078b7b6a0725d33c85b819968605d123c619dde057a11f1f312d0e21d68ac"
  license "https://raw.githubusercontent.com/gclm/ghp/master/LICENSE"

  # depends_on "cmake" => :build
  def install
    bin.install "ghp"
  end

end
