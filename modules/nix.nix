{ pkgs, ... }: {
  home.packages = with pkgs; [
    deadnix
    nh
    nil
    nixd
    nixfmt
    statix
  ];
}
