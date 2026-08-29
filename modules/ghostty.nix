{ ... }: {
  programs.ghostty = {
    enable = true;
    # Installation is handled outside home-manager (Homebrew cask on
    # Darwin, nix package on Linux — see nix-dendrites/modules/ghostty.nix).
    package = null;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}
