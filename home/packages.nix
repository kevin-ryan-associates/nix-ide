# Binaries the user invokes that aren't enrolled in their own `programs.*`
# HM module. The split (module vs raw package) mirrors the dotfiles repo:
#
#   - In their own HM module: fzf, zoxide, starship, git, lazygit, lazydocker,
#     bat (Phase 4), htop (Phase 4), btop (Phase 4)…).
#   - Raw packages here: eza, fd, delta, gh, glab (only needed for the binary;
#     configs come from the tools' HM modules or `home.file`).
#
# `delta` is the nixpkgs upstream name for what Homebrew calls `git-delta`.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    eza
    fd
    delta
    gh
    glab
    tree
    jq
    yq
    # Kubernetes tooling — no per-tool config to port (dotfiles has none).
    # nixpkgs `helm` is some unrelated tool; the kubernetes Helm 3 binary is
    # `kubernetes-helm` (provides the `helm` command, just like brew's
    # `helm` formula did in the dotfiles repo).
    kubectl
    kubernetes-helm
    k9s
    # Additional CLI tools — no per-tool config to port.
    glow       # markdown renderer
    bandwhich  # per-process bandwidth TUI (needs sudo on macOS for capture)
    dust       # du + tree, Rust
    # lazygit, lazydocker come from their HM programs.* modules.
    # btop is shipped in home/btop.nix via home.packages.
    # htop is shipped in home/htop.nix via programs.htop (module adds the binary).
    # herdr is shipped in home/herdr.nix via the vendored upstream flake.
    # opencode is shipped in home/opencode.nix via the vendored upstream flake.
    # hunk is shipped in home/hunk.nix via the vendored upstream flake.
    # neovim/nodejs/ripgrep/cmake are in home/nvim.nix.
  ];
}