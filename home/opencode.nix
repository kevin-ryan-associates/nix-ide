# opencode — coding agent. Installed from the PREBUILT upstream release
# binary (hash-verified `fetchurl` from GitHub Releases), NOT compiled from
# source.
#
# Why prebuilt: opencode is a Bun-compiled binary. Building it from source
# (Bun/Vite toolchain) is unreliable under virtualized CPUs (Parallels, UTM,
# VMware, some CI runners): Bun's CPU feature detection mismatches the
# hypervisor's virtual CPU and the resulting binary dies with SIGSEGV on the
# smoke test (`opencode --version`). Upstream CI builds on bare metal, so the
# published binaries sidestep the whole class of failure. Variant choices,
# made for the same portability reason:
#
#   - x86_64 (both platforms): the "-baseline" builds — no AVX2-era
#     instruction-set assumptions. The embedded Bun runtime does CPU feature
#     detection at RUNTIME too, so baseline keeps opencode working inside
#     VMs even though it was compiled on upstream's hardware.
#   - Linux: the glibc builds + `autoPatchelfHook`. The musl builds looked
#     attractive ("static") but are dynamically linked against musl AND a
#     musl-linked libstdc++/libgcc_s that nixpkgs has no clean package for;
#     the glibc builds need only glibc itself (libc/libpthread/libdl/libm),
#     which `autoPatchelfHook` wires from stdenv automatically (interpreter
#     from `$NIX_CC/nix-support/dynamic-linker`, libc rpath from
#     `orig-libc`). Verified via `readelf -d` on the v1.18.4 assets.
#   - aarch64: upstream publishes no "-baseline" arm variant (arm has no
#     AVX-style feature lottery) — the standard builds are the only ones.
#
# Every asset contains a single `opencode` binary at the archive root
# (verified). The darwin assets are .zip, the linux assets .tar.gz.
#
# To bump: edit `version`, then re-prefetch all four assets:
#   for a in opencode-linux-x64-baseline.tar.gz opencode-linux-arm64.tar.gz \
#            opencode-darwin-x64-baseline.zip opencode-darwin-arm64.zip; do
#     nix store prefetch-file --json \
#       "https://github.com/anomalyco/opencode/releases/download/v<NEW>/$a" | jq -r .hash
#   done
#
# Config tree: `~/dotfiles/opencode/.config/opencode/` ported minus runtime
# drag-in (node_modules, package.json, package-lock.json, .gitignore — see
# the dotfiles AGENTS.md for the directory-symlink note). 10 files kept:
#   opencode.jsonc, tui.json, themes/tokyonight-moon.json,
#   agents/sdd-01-product.md, agents/sdd-02-discover.md,
#   skills/sdd/SKILL.md, skills/sdd-discovery-authoring/*.md,
#   skills/sdd-product-authoring/*.md
# These deploy via `home.file.".config/opencode".source` — same directory
# shape the Stow package deployed, but as plain symlinks (Nix store → home).

{ lib, pkgs, ... }:

let
  version = "1.18.4";

  # Per-system release asset + sha256 of the ARCHIVE (fetchurl semantics).
  assets = {
    x86_64-linux = {
      name = "opencode-linux-x64-baseline.tar.gz";
      hash = "sha256-TYfkFGB7d/75QCVgIeQvu/N7jGKwbO12tp4mxdy/urw=";
    };
    aarch64-linux = {
      name = "opencode-linux-arm64.tar.gz";
      hash = "sha256-66h++6OXbVM6JMygMW+O83W1+OeXwKlcJe6RlwC3ujU=";
    };
    x86_64-darwin = {
      name = "opencode-darwin-x64-baseline.zip";
      hash = "sha256-gKIOIKG5nL6eVE+fRQ2be9dY7Sx2xPTF0oufdK7KMi4=";
    };
    aarch64-darwin = {
      name = "opencode-darwin-arm64.zip";
      hash = "sha256-BPuIG2MrMjxxLf2m3LvG/Oc2OU8HunYXblLWZlkl1OY=";
    };
  };

  system = pkgs.stdenv.hostPlatform.system;
  asset = assets.${system} or (throw "opencode: no prebuilt binary for system ${system}");

  opencode-bin = pkgs.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${asset.name}";
      inherit (asset) hash;
    };

    # The archive holds a lone binary; stdenv's auto-unpack of a single
    # plain file is ambiguous, so extract explicitly in installPhase.
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    # Ship the binary bit-identical to upstream — stripping risks corrupting
    # the embedded Bun bundle.
    dontStrip = true;

    # .zip extraction on darwin; glibc ELF interpreter/rpath fixup on linux.
    nativeBuildInputs =
      lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.unzip ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
    buildInputs =
      lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      ${if pkgs.stdenv.hostPlatform.isDarwin then ''
        unzip -p "$src" opencode > "$out/bin/opencode"
      '' else ''
        tar -xzOf "$src" opencode > "$out/bin/opencode"
      ''}
      chmod 755 "$out/bin/opencode"
      runHook postInstall
    '';

    meta.mainProgram = "opencode";
  };
in
{
  home.packages = [ opencode-bin ];

  home.file.".config/opencode".source = ../files/opencode;
}
