class Clipper < Formula
  desc "Share macOS clipboard with tmux and other local and remote apps"
  homepage "https://wincent.com/products/clipper"
  url "https://github.com/wincent/clipper/archive/refs/tags/2.0.0.tar.gz"
  sha256 "9c9fa0b198d11513777d40c88e2529b2f2f84d7045a500be5946976a5cdcfe83"
  license "BSD-2-Clause"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "eb860fc6db9dbad5c62e2501ec592f25f4d1adad41e28557ecf85467c9bd1373"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "d029ac8ca30a76a9e4825071d1f082a9b1f1d922846f8c6b131381e065b8245c"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "cbcfb891555f7d4da43b749781f5e3b28ff1cd693c446f91d4300bbe49f52e7d"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "a114dd1e41872b63ca5ced700ee503aa4eb87f0add568e3dc1ad9e10cca9459b"
    sha256 cellar: :any_skip_relocation, sonoma:         "6804f1f1044b14f798fe8acb3222658f87bb37a53f7114585f6d38ce9dcdfe84"
    sha256 cellar: :any_skip_relocation, ventura:        "861c78501ae9ef8bd85c6305b4c5c9dbd62810a07b6b30e3020d953c4b55ee9f"
    sha256 cellar: :any_skip_relocation, monterey:       "c38aa99876034b161cf484ef0d28e62bd01ff20f51322d9aab883733167d8dca"
    sha256 cellar: :any_skip_relocation, big_sur:        "3322412e9d0979650ad863bf42ba473c4eaabf06f48ef6d1053cf3fbc89dfc8a"
    sha256 cellar: :any_skip_relocation, catalina:       "6e16549f9930f652364f727cf42ea04608d92f172e7916c85900c3b6feb98df0"
    sha256 cellar: :any_skip_relocation, mojave:         "2216327dbb3a341f14db9d2da767749d00e460917bcf1098665948e24eeb2e8b"
    sha256 cellar: :any_skip_relocation, high_sierra:    "a2230d8cb54b244b82ea5f5c47cebabe2f63a6b9dc1b98d47cd4a0fcd4eb743f"
  end

  depends_on "go" => :build
  depends_on :macos

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "clipper.go"
  end

  service do
    run opt_bin/"clipper"
    environment_variables LANG: "en_US.UTF-8"
    keep_alive true
    working_dir HOMEBREW_PREFIX
  end

  test do
    test_data = "a simple string! to test clipper, with söme spéciål characters!! 🐎\n".freeze

    cmd = [opt_bin/"clipper", "-a", testpath/"clipper.sock", "-l", testpath/"clipper.log"].freeze
    ohai cmd.join " "

    require "open3"
    Open3.popen3({ "LANG" => "en_US.UTF-8" }, *cmd) do |_, _, _, clipper|
      sleep 0.5 # Give it a moment to launch and create its socket.
      begin
        sock = UNIXSocket.new testpath/"clipper.sock"
        assert_equal test_data.bytesize, sock.sendmsg(test_data)
        sock.close
        sleep 0.5
        assert_equal test_data, `LANG=en_US.UTF-8 pbpaste`
      ensure
        Process.kill "TERM", clipper.pid
      end
    end
  end
end
