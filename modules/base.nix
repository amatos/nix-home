{ pkgs, config, ... }: {
  home.username = "alberth";
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${config.home.username}"
    else "/home/${config.home.username}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.man.generateCaches = false;
}
