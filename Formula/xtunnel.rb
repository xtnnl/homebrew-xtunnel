class Xtunnel < Formula
  desc "Lightweight ngrok alternative tunnel utility"
  homepage "https://xtunnel.ru"
  version "2.7.0"
  # xtunnel CLI is a proprietary commercial product; no SPDX identifier applies.
  # `:cannot_represent` is Homebrew's documented value for licenses that can't be
  # expressed in SPDX terms (commercial / EULA-only); avoids `brew audit --strict`
  # warning about a missing `license` field that would otherwise flag the formula.
  license :cannot_represent

  on_macos do
    if Hardware::CPU.arm?
      url "https://dl.xtunnel.ru/v2.7.0/xtunnel-v2.7.0-osx-arm64.tar.gz"
      sha256 "2e81f4cd0ab251de38236f06b9000beddbccbc568284c65fad600eb5ac5a9f8b"
    else
      url "https://dl.xtunnel.ru/v2.7.0/xtunnel-v2.7.0-osx-x64.tar.gz"
      sha256 "f4aaa997d886cc4d6aefbc458e711373caa6449c55c443368c92398d45fb7aae"
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
      url "https://dl.xtunnel.ru/v2.7.0/xtunnel-v2.7.0-linux-x64.tar.gz"
      sha256 "ea59efb4657e23af77fe3cd2d6a8ac839930edd88ec2f870a249276a0bb47665"
    elsif Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      # ARM64 / aarch64 — Raspberry Pi 4+, AWS Graviton, Linux on Apple Silicon, etc.
      url "https://dl.xtunnel.ru/v2.7.0/xtunnel-v2.7.0-linux-arm64.tar.gz"
      sha256 "624e3a981c2e5834bea4170e1e963e76e0fbe0dd428135b30b90011c0b18911e"
    else
      odie "xtunnel Homebrew formula supports Linux x86_64 and arm64 only. " \
           "Use manual tarball install from https://dl.xtunnel.ru/v#{version}/ for this architecture."
    end
  end

  def install
    bin.install "xtunnel"
    # The developer certificate ships only on macOS bundles (Linux tarballs don't
    # include it — Linux uses standard CA validation, no keychain step needed).
    prefix.install "xtunnel-cert.cer" if File.exist?("xtunnel-cert.cer")
  end

  def caveats
    # The developer-cert instructions only make sense on macOS; on Linux there's
    # no keychain to trust, no Gatekeeper warning to dismiss. Skip them entirely.
    return unless OS.mac?

    cert_installed = quiet_system("security", "find-certificate", "-c", "xtunnel.dev")

    if cert_installed
      "✅ Сертификат xtunnel.dev уже установлен. Никаких дополнительных действий не требуется."
    else
      <<~EOS
        🔐 Установка сертификата (рекомендуется):
        Чтобы macOS доверяла утилите и не показывала предупреждений при запуске, установите сертификат разработчика.

        Выполните команду:
          sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain #{opt_prefix}/xtunnel-cert.cer
      EOS
    end
  end

  test do
    # Stronger than mere `exist?` — proves the binary launches AND reports the
    # right version. Catches a class of bottle / arch / runtime breakage that a
    # pure `:exist?` check would miss (downloaded tarball was for the wrong arch,
    # binary segfaults at startup, etc.).
    assert_match version.to_s, shell_output("#{bin}/xtunnel --version")
  end
end
