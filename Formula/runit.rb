class Runit < Formula
  desc "Collection of tools for managing UNIX services"
  homepage "http://smarden.org/runit"
  url "http://smarden.org/runit/runit-2.1.2.tar.gz"
  sha256 "6fd0160cb0cf1207de4e66754b6d39750cff14bb0aa66ab49490992c0c47ba18"

  livecheck do
    url "http://smarden.org/runit/install.html"
    regex(/href=.*?runit[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "c3de3e4ad3452a4aec3dee1aacd399c795564290dcd13afb4f52430af6d12b9e"
    sha256 cellar: :any_skip_relocation, big_sur:       "3d22eb4db4e411604950ffc708beb131f4a380af75025148f507e323633f4e5c"
    sha256 cellar: :any_skip_relocation, catalina:      "c6e5b49ab3601824db1969967c5ba4a0d35fa65841cfa2ec1d50fcca968fcf05"
    sha256 cellar: :any_skip_relocation, mojave:        "3c684c031305f98a2d24e904b6fc3301a71f0089e84e814028bad8ab05658cae"
    sha256 cellar: :any_skip_relocation, high_sierra:   "a66fbfb0258db267c5a3a3d7790fe4b5224478e7ecc1377a9a877118d5e27be5"
  end

  def install
    # Runit untars to 'admin/runit-VERSION'
    cd "runit-#{version}" do
      # Per the installation doc on macOS, we need to make a couple changes.
      system "echo 'cc -Xlinker -x' >src/conf-ld"
      inreplace "src/Makefile", / -static/, ""

      inreplace "src/sv.c", "char *varservice =\"/service/\";", "char *varservice =\"#{var}/service/\";"
      system "package/compile"

      # The commands are compiled and copied into the 'command' directory and
      # names added to package/commands. Read the file for the commands and
      # install them in homebrew.
      rcmds = File.read("package/commands")

      rcmds.split("\n").each do |r|
        bin.install("command/#{r.chomp}")
        man8.install("man/#{r.chomp}.8")
      end

      (var + "service").mkpath
    end
  end

  def caveats
    <<~EOS
      This formula does not install runit as a replacement for init.
      The service directory is #{var}/service instead of /service.

      A system service that runs runsvdir with the default service directory is
      provided. Alternatively you can run runsvdir manually:

           runsvdir -P #{var}/service

      Depending on the services managed by runit, this may need to start as root.
    EOS
  end

  service do
    run [opt_bin/"runsvdir", "-P", var/"service"]
    keep_alive true
    log_path var/"log/runit.log"
    error_log_path var/"log/runit.log"
    environment_variables PATH: "/usr/bin:/bin:/usr/sbin:/sbin:#{opt_bin}"
  end

  test do
    assert_match "usage: #{bin}/runsvdir [-P] dir", shell_output("#{bin}/runsvdir 2>&1", 1)
  end
end
