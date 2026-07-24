# herdr — agent multiplexer from https://herdr.dev/
# Installed from the PREBUILT upstream release binary (hash-verified
# `fetchurl` from GitHub Releases), NOT compiled from source — same
# provisioning story as opencode (see home/opencode.nix): prebuilt binaries
# are the portable default for VMs/CI, and herdr upstream publishes exactly
# four bare binaries, one per supported system.
#
# No patchelf needed anywhere (verified on the v0.7.5 assets):
#   - linux: FULLY STATIC (`file` reports "static-pie linked" /
#     "statically linked" for both arches).
#   - macOS: links only system frameworks (Carbon, CoreFoundation,
#     Foundation, libSystem, libobjc, libiconv — verified via `otool -L`).
#
# To bump: edit `version`, then re-prefetch all four assets:
#   for a in herdr-linux-x86_64 herdr-linux-aarch64 \
#            herdr-macos-x86_64 herdr-macos-aarch64; do
#     nix store prefetch-file --json \
#       "https://github.com/ogulcancelik/herdr/releases/download/v<NEW>/$a" | jq -r .hash
#   done
#
# Config: `~/dotfiles/herdr/.config/herdr/config.toml` shipped verbatim via
# `home.file` (no HM module exists for herdr).

{ pkgs, ... }:

let
  version = "0.7.5";

  # Per-system release asset + sha256 of the bare binary.
  assets = {
    x86_64-linux = {
      name = "herdr-linux-x86_64";
      hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
    };
    aarch64-linux = {
      name = "herdr-linux-aarch64";
      hash = "sha256-MudjoUmaa2lLHXCOTwYrdDvh2p80/PpNIS1ttv4JqLk=";
    };
    x86_64-darwin = {
      name = "herdr-macos-x86_64";
      hash = "sha256-P+UMSmPcgQIwaxMiF4Yo3bNlXNOuVteE8JQVNAjWnmI=";
    };
    aarch64-darwin = {
      name = "herdr-macos-aarch64";
      hash = "sha256-NzUFRrABJVWUO5Lq+WJmXeTiZDlbrrRCJ7gBXo/1sNY=";
    };
  };

  system = pkgs.stdenv.hostPlatform.system;
  asset = assets.${system} or (throw "herdr: no prebuilt binary for system ${system}");

  herdr-bin = pkgs.stdenv.mkDerivation {
    pname = "herdr";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/${asset.name}";
      inherit (asset) hash;
    };

    # Bare binary, no archive to unpack.
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    # Ship the binary bit-identical to upstream.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 "$src" "$out/bin/herdr"
      runHook postInstall
    '';

    meta.mainProgram = "herdr";
  };
in
{
  home.packages = [ herdr-bin ];

  home.file.".config/herdr".source = ../files/herdr;
}
