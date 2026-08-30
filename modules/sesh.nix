{ pkgs, lib, ... }:
{
  # sesh — smart tmux session manager (https://github.com/joshmedeski/sesh).
  # Lives next to tmux.nix; the tmux picker keybind (`prefix + g`) is defined
  # there. This module owns the binary, its config, the non-tmux shell launcher
  # (`Alt-s`), and shell completion. Backed by the always-on fzf + zoxide
  # (home/shared/shell/tools.nix).
  home.packages = [ pkgs.sesh ];

  # Declarative config. nixpkgs has no `programs.sesh` HM module, so write the
  # TOML directly; xdg.configFile lands at ~/.config/sesh/sesh.toml on both Linux
  # and macOS. preview-only default_session keeps session creation non-intrusive.
  xdg.configFile."sesh/sesh.toml".text = ''
    blacklist = ["scratch"]

    [default_session]
    preview_command = "eza --all --git --icons --color=always {}"

    [[session]]
    name = "config 🛠️"
    path = "~/.config"

    [[session]]
    name = "home 🏠"
    path = "~"

    # Add machine-specific project sessions here, e.g.:
    # [[session]]
    # name = "the-one-nix ❄️"
    # path = "~/projects/personal/gitlab/frankper/the-one-nix"
    # startup_command = "nvim"
  '';

  # ── zsh: completion + the `Alt-s` non-tmux launcher ────────────────────────
  # Appended after zsh.nix's initContent (so compinit has already run) — the
  # `lines`-typed option merges the two blocks.
  programs.zsh.initContent = lib.mkAfter ''
    # sesh completion (nixpkgs ships none — generate at init)
    source <(sesh completion zsh)

    # Alt-s: open the sesh picker from a bare shell prompt (no tmux needed)
    function sesh-sessions() {
      local session
      session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
      [[ -z "$session" ]] && { zle reset-prompt 2>/dev/null; return; }
      sesh connect "$session"
      zle reset-prompt 2>/dev/null
    }
    zle -N sesh-sessions
    bindkey -M emacs '\es' sesh-sessions
    bindkey -M vicmd '\es' sesh-sessions
    bindkey -M viins '\es' sesh-sessions
  '';

  # ── completion for the other configured shells (no-op when disabled) ───────
  programs.bash.initExtra = lib.mkAfter ''
    command -v sesh >/dev/null && source <(sesh completion bash)
  '';
  programs.fish.interactiveShellInit = lib.mkAfter ''
    sesh completion fish | source
  '';
}
