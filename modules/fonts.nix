{ pkgs, ... }: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs.ioskeley-mono; [
    normal-NF
    normal-NL-NF
    normal
    condensed
    normal-term
    condensed-NF
    semiCondensed
    normal-term-NF
    condensed-term
  ];
}
