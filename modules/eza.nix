{ ... }:
let
  ezaAliases = {
    l = "eza";
    ll = "eza -l --icons";
    la = "eza -la --icons";
    lt = "eza -lT --icons";
    ltt = "eza -lT --level=2 --icons";
    tree = "eza -T --all --level=3 --icons";
    ls = "eza -abghlUm --icons";
    big = "eza -lSh --icons";
  };
in
{
  programs.eza.enable = true;
  programs.zsh.shellAliases = ezaAliases;
  programs.bash.shellAliases = ezaAliases;
  programs.fish.shellAliases = ezaAliases;
}
