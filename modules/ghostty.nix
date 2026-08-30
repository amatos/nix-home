{ ... }: {
  programs.ghostty = {
    enable = true;
    # Installation is handled outside home-manager (Homebrew cask on
    # Darwin, nix package on Linux — see nix-dendrites/modules/ghostty.nix).
    package = null;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = {
      # Patched Nerd Font family — explicit to avoid the fontconfig
      # "monospace" alias indirection on Linux (which falls back to DejaVu
      # without a `defaultFonts.monospace` override) and Core Text's
      # Menlo default on darwin (which ships no Nerd Font glyphs).
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;
      # bell-features = "no-system,no-audio,no-attention,no-title,no-border";
      mouse-scroll-multiplier = 3;
      # ghostty has no "unlimited" mode (planned upstream); bytes, not lines.
      # 100 MB ≈ ~500k–1M lines depending on content.
      scrollback-limit = 100000000;
    };
  };
}
