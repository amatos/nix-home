{ config, ... }: {
  programs.bash = {
    enable = true;
    package = null;
    initExtra = ''
      [ -f ${config.xdg.configHome}/op/plugins.sh ] && source ${config.xdg.configHome}/op/plugins.sh
    '';
    # History — negative = truly unlimited per bash(1):
    # "Numeric values less than zero result in every command being saved on the history list (no limit)."
    historySize = -1;
    historyFileSize = -1;
    historyFile = "${config.home.homeDirectory}/.local/share/bash/history";
    historyControl = [
      "erasedups"
      "ignoreboth"
    ];
    historyIgnore = [
      "exit"
      "ls"
      "bg"
      "fg"
      "history"
      "clear"
    ];

    # Source the shared shell-function library — the same env.zsh + aliases.zsh
    # that zsh ingests via programs.zsh.initContent (see zsh.nix). env.zsh is
    # bash-clean; aliases.zsh guards its zsh-only bits behind `[ -n "$ZSH_VERSION" ]`.
    # Simple aliases come separately from aliases.nix (programs.bash.shellAliases).
    bashrcExtra = ''
      # Cargo
      [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    ''
    + builtins.readFile ./env.zsh
    + builtins.readFile ./aliases.zsh;

    profileExtra = ''
      # Cargo
      [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    '';
  };
}
