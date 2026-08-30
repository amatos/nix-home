{ pkgs, ... }:
{
  # programs.mise.enable installs the package + sets up shell integration.
  # Deliberately NO globalConfig: home-manager would otherwise deploy
  # ~/.config/mise/config.toml as a read-only nix-store symlink, and mise
  # writes BOTH settings and the [tools] section into that one file — so
  # `mise use -g <tool>` fails with "Read-only file system". Leaving config
  # unmanaged lets mise own a writable config.toml that survives rebuilds.
  # (The previously-set idiomatic_version_file_enable_tools = [] was a no-op:
  # it already matches mise's default.)
  programs.mise = {
    enable = true;
    # `programs.mise.package` supports `nullable = true` and every shell
    # activation hook (`mise activate zsh`/bash/fish/nu) is already gated on
    # `cfg.package != null` — so a bare `package = null` would work, but it
    # would also silently drop HM-managed shell activation entirely on
    # darwin. nixpkgs' mise build already had a known darwin-sandbox test
    # quirk (see overlays/sandbox-test-flakes.nix), and on the currently-live
    # cctools-binutils-darwin regression its Rust build is squarely in the
    # same risk class as starship/wezterm — so shim `package` to the
    # Homebrew-installed binary (`mise` in
    # modules/darwin/homebrew/default.nix's `brews`) the same way as
    # home/shared/prompt/starship.nix, which keeps shell activation working
    # (`cfg.package != null` stays true) instead of losing it.
    package =
      if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.runCommand "mise-homebrew-shim" { meta.mainProgram = "mise"; } ''
          mkdir -p $out/bin
          ln -s /opt/homebrew/bin/mise $out/bin/mise
        ''
      else
        pkgs.mise;
    # zsh/fish integration are plain runtime `eval "$(mise activate ...)"` /
    # `... | source` strings — safe with the shim above, since the actual
    # binary only needs to exist at shell-startup time, on the real
    # filesystem. bash/nushell integration are different: upstream's module
    # pre-generates their config via a build-time `pkgs.runCommand` that
    # actually EXECUTES `${cfg.package}/bin/mise` inside the Nix sandbox
    # (`mise completion bash` / `mise activate nu`) — which fails, since the
    # shim's `/opt/homebrew/bin/mise` symlink target doesn't exist inside a
    # sandboxed build (confirmed on a real brutus rebuild: "mise-homebrew-shim
    # /bin/mise: No such file or directory"). Disable both on darwin; zsh is
    # this repo's primary shell there.
    enableBashIntegration = !pkgs.stdenv.hostPlatform.isDarwin;
    enableNushellIntegration = !pkgs.stdenv.hostPlatform.isDarwin;
  };
}
