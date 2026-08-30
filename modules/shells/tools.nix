{
  config,
  lib,
  options,
  ...
}:
{
  # ── fzf ───────────────────────────────────────────────────────────────────
  # programs.fzf handles installation + shell keybindings + completion.
  # Replaces the bare 'fzf' entry in packages.nix.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    # Note: home-manager's programs.fzf has no enableNushellIntegration option
    # at this nixpkgs revision (Bash/Fish/Zsh only). Wire fzf into nu manually
    # in shell/nushell.nix if/when needed — `fzf` binary is still on PATH.
  }
  // lib.optionalAttrs (options.programs.fzf ? historyWidget) {
    # Newer home-manager warns that fzf and atuin both bind Ctrl-R (atuin,
    # sourced after fzf, wins at runtime). Make that ownership explicit: an
    # empty command disables fzf's Ctrl-R history widget wherever atuin is
    # enabled (Ctrl-T / Alt-C are separate widgets and keep working).
    # Guarded on option existence — the stable release-26.05 HM pin has no
    # historyWidget option and no warning; drop the guard once every
    # consumer is on an HM that ships it.
    historyWidget.command = lib.mkIf config.programs.atuin.enable "";
  };

  # ── television ──────────────────────────────────────────────────────────
  # Fuzzy finder TUI — files, git repos, env vars, etc. programs.television
  # installs the binary + shell completion (sources completion.{zsh,bash,fish,nu};
  # it does NOT rebind Ctrl-T, so no clash with programs.fzf above). Replaces the
  # bare `home.packages = [ pkgs.television ]`.
  programs.television = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  # ── zoxide ────────────────────────────────────────────────────────────────
  # programs.zoxide handles installation + 'eval "$(zoxide init zsh)"'.
  # Replaces the manual eval in env.zsh and the workstation-only package.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };
}
