{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
  };
}
