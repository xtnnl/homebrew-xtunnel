class Xtunnel < Formula
  desc "Lightweight ngrok alternative tunnel utility"
  homepage "https://xtunnel.ru"
  version "4.3.0"
  revision 1
  # xtunnel CLI is a proprietary commercial product; no SPDX identifier applies.
  # `:cannot_represent` is Homebrew's documented value for licenses that can't be
  # expressed in SPDX terms (commercial / EULA-only); avoids `brew audit --strict`
  # warning about a missing `license` field that would otherwise flag the formula.
  license :cannot_represent

  on_macos do
    if Hardware::CPU.arm?
      url "https://dl.xtunnel.ru/v4.3.0/certfix1/xtunnel-v4.3.0-osx-arm64.tar.gz"
      sha256 "ef4962193b81074c2be63447b8df160ebdef64e5a09622184fd2143da014872b"
    else
      url "https://dl.xtunnel.ru/v4.3.0/certfix1/xtunnel-v4.3.0-osx-x64.tar.gz"
      sha256 "1456c326169412f87c6b81717d444702000d63f0220f89ca9f08195fd271d3c2"
    end
  end

  # #733: Linuxbrew support — addresses customer dead-end «formula requires at
  # least a URL» on Linux. Explicit if/elsif/else rather than nested on_intel/on_arm
  # so unsupported architectures (32-bit ARM, anything Tier-3 like RISC-V) fail
  # with a clear `odie` instead of silently producing a formula with no URL.
  #
  # Covers Homebrew's officially-supported 64-bit Linux archs: x86_64 + aarch64.
  # 32-bit ARM (`linux-arm` tarball) and musl variants (`linux-musl-*`) intentionally
  # not covered — Homebrew on Linux doesn't officially support them; those remain
  # available via manual tarball install from dl.xtunnel.ru.
  on_linux do
    if Hardware::CPU.intel?
      url "https://dl.xtunnel.ru/v4.3.0/certfix1/xtunnel-v4.3.0-linux-x64.tar.gz"
      sha256 "178197170477d141d19a8f187d20e349becea568d4ab9f55b0217cf770cf0304"
    elsif Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      # ARM64 / aarch64 — Raspberry Pi 4+, AWS Graviton, Linux on Apple Silicon, etc.
      url "https://dl.xtunnel.ru/v4.3.0/certfix1/xtunnel-v4.3.0-linux-arm64.tar.gz"
      sha256 "de8649e32c82fd6accabe77e40c5af38bcc4aff3fc9995f15a032e0735dfdfe4"
    else
      odie "xtunnel Homebrew formula supports Linux x86_64 and arm64 only. " \
           "Use manual tarball install from https://dl.xtunnel.ru/v#{version}/ for this architecture."
    end
  end

  def install
    bin.install "xtunnel"
    # Every supported archive includes the public certificate promised by the installation docs.
    odie "Publisher certificate missing from xtunnel archive" unless File.file?("xtunnel-cert.cer")
    prefix.install "xtunnel-cert.cer"
  end

  def caveats
    return unless OS.mac?

    <<~EOS
      Сертификат xtunnel.dev находится в #{opt_prefix}/xtunnel-cert.cer.
      Он подтверждает издателя Windows-версии. macOS-версия имеет отдельную
      подпись; импорт этого сертификата не заменяет проверку приложения macOS.
    EOS
  end

  test do
    # Stronger than mere `exist?` — proves the binary launches AND reports the
    # right version. Catches a class of bottle / arch / runtime breakage that a
    # pure `:exist?` check would miss (downloaded tarball was for the wrong arch,
    # binary segfaults at startup, etc.).
    #
    # It is `xtunnel version`, NOT `--version`: the CLI has a `version` command and
    # rejects an unknown `--version` option with exit 255 and no output. This block
    # asked for `--version` and therefore failed for every release it ever ran on —
    # `brew test` was red, not green, all the way back. Fixed while cutting v2.8.1.
    assert_path_exists prefix/"xtunnel-cert.cer"
    assert_match version.to_s, shell_output("#{bin}/xtunnel version")
  end
end
