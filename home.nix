{ pkgs, lib, config, ... }: {
  home.username = "alberth";
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${config.home.username}"
    else "/home/${config.home.username}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    package = null;
    settings.user = {
      name = "Alberth Matos";
      email = "alberth@matos.cc";
    };
  };

  programs.gpg = {
    enable = true;
    package = null;
    publicKeys = [
      {
        source = pkgs.fetchurl {
          url = "https://keys.openpgp.org/vks/v1/by-fingerprint/5FC8FE1141FA769594E91E48F41BDBF6171A3BB4";
          hash = "sha256-BdHZRXJw27vnOXetqj+wANTYf7L58yRTgAiz6dKBD64=";
        };
        trust = "ultimate";
      }
    ];
  };

  programs.zsh.enable = true;
  programs.zsh.package = null;
  programs.bash.enable = true;
  programs.bash.package = null;
  programs.fish.enable = true;
  programs.man.generateCaches = false;

  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      search_mode = "fuzzy";
      sync_address = "https://api.atuin.sh";
      sync_frequency = "5m";
      filter_mode = "global";
      style = "compact";
      ai.enabled = false;
    };
  };

  home.packages = [ pkgs._1password-cli ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.orion-browser
      pkgs.betterdisplay
      pkgs.syncthing-macos
      pkgs.tailscale-gui
    ];

  programs.zsh.initContent = ''
    [ -f ${config.xdg.configHome}/op/plugins.sh ] && source ${config.xdg.configHome}/op/plugins.sh
  '';
  programs.bash.initExtra = ''
    [ -f ${config.xdg.configHome}/op/plugins.sh ] && source ${config.xdg.configHome}/op/plugins.sh
  '';

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
