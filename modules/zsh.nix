{ config, ... }: {
  programs.zsh.enable = true;
  programs.zsh.package = null;
  programs.zsh.initContent = ''
    [ -f ${config.xdg.configHome}/op/plugins.sh ] && source ${config.xdg.configHome}/op/plugins.sh
  '';
}
