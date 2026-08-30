{ ... }:
let
  ezaAliases = {
    l = "eza";
    ll = "eza -l";
    la = "eza -la";
    lt = "eza -lT";
    ltt = "eza -lT --level=2";
    tree = "eza -T --all --level=3";
    ls = "eza -abghlUm";
    big = "eza -lSh";
  };
in
{
  programs.eza.enable = true;
  programs.zsh.shellAliases = ezaAliases;
  programs.bash.shellAliases = ezaAliases;
  programs.fish.shellAliases = ezaAliases;
}
