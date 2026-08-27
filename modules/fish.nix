{ pkgs, config, ... }: {
  programs.fish.enable = true;
  programs.fish.plugins = [
    { name = "bass"; src = pkgs.fishPlugins.bass.src; }
  ];
  programs.fish.interactiveShellInit = ''
    op completion fish | source
    if test -f ${config.xdg.configHome}/op/plugins.sh
      bass source ${config.xdg.configHome}/op/plugins.sh
    end
  '';
}
