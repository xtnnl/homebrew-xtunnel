class Xtunnel < Formula
  desc "Lightweight ngrok alternative tunnel utility"
  homepage "https://xtunnel.ru"
  version "4.3.1"
  # xtunnel CLI is a proprietary commercial product; no SPDX identifier applies.
  # `:cannot_represent` is Homebrew's documented value for licenses that can't be
  # expressed in SPDX terms (commercial / EULA-only); avoids `brew audit --strict`
  # warning about a missing `license` field that would otherwise flag the formula.
  license :cannot_represent

  on_macos do
    if Hardware::CPU.arm?
      url "https://dl.xtunnel.ru/v4.3.1/xtunnel-v4.3.1-osx-arm64.tar.gz"
      sha256 "d374cecc9d13ab5c42714199f5ecbe00885b27bc502fda7b18417595e9fe988d"
    else
      url "https://dl.xtunnel.ru/v4.3.1/xtunnel-v4.3.1-osx-x64.tar.gz"
      sha256 "ec1a5da2ea7f9a9818cda00e28e18bec3051a551f82b02c82b8f444d014bd32e"
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
      url "https://dl.xtunnel.ru/v4.3.1/xtunnel-v4.3.1-linux-x64.tar.gz"
      sha256 "45beb7e97ac9a0b96840e70c047400e8bf6662fffc2a5e378b0526ff9c5cd584"
    elsif Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      # ARM64 / aarch64 — Raspberry Pi 4+, AWS Graviton, Linux on Apple Silicon, etc.
      url "https://dl.xtunnel.ru/v4.3.1/xtunnel-v4.3.1-linux-arm64.tar.gz"
      sha256 "f32d932913b013575addab0be6e650c849db979b3a6ddff3836e1611ea95b10e"
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
