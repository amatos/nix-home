{ config, ... }: {
  programs.bash.enable = true;
  programs.bash.package = null;
  programs.bash.initExtra = ''
    [ -f ${config.xdg.configHome}/op/plugins.sh ] && source ${config.xdg.configHome}/op/plugins.sh
  '';
}
