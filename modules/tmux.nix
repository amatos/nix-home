{ pkgs, ... }:
{
  # Some terminals on macOS (Ghostty, iTerm, Terminal.app, …) launch tmux
  # without `XDG_CONFIG_HOME` set, so the HM-managed config at
  # `~/.config/tmux/tmux.conf` is invisible and tmux falls back to the
  # legacy `~/.tmux.conf` (which doesn't exist) — leaving an unconfigured
  # session.  Drop a thin redirect at the legacy path that source-files
  # the XDG one.  Harmless on Linux (the file is read once and immediately
  # forwards to the real config).
  home.file.".tmux.conf".text = ''
    # HM redirect — see home/shared/terminal/tmux.nix
    source-file ~/.config/tmux/tmux.conf
  '';

  # sesh — smart tmux session manager: the binary, config, shell launcher, and
  # completion live in ./sesh.nix. The `prefix + g` picker keybind is below.

  programs.tmux = {
    enable = true;
    prefix = "C-z";
    mouse = true;
    baseIndex = 1;
    historyLimit = 200000;
    keyMode = "vi";
    terminal = "tmux-256color";
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      battery
      prefix-highlight
      online-status
      sidebar
      copycat
      open
      yank
      resurrect
      logging
    ];

    # NOTE: The following plugins are NOT in nixpkgs and would need TPM if wanted:
    #   - samoshkin/tmux-plugin-sysstat
    #   - MunifTanjim/tmux-suspend
    #   - xamut/tmux-network-bandwidth
    #   - xamut/tmux-weather

    extraConfig = ''
      # ==========================
      # ===  General settings  ===
      # ==========================
      set -g buffer-limit 20
      # Truecolor when the outer TERM is the SSH-normalized xterm-256color
      # (its terminfo doesn't declare RGB on its own).
      set -sa terminal-features ",xterm-256color:RGB"
      set -g display-time 1500
      set -g remain-on-exit off
      set -g repeat-time 300
      setw -g allow-rename off
      setw -g automatic-rename off
      setw -g aggressive-resize on

      # Sync parent terminal title with current tmux window
      set -g set-titles on
      set -g set-titles-string "#I:#W"

      # Pane index starts at 1
      setw -g pane-base-index 1

      # ==========================
      # ===   Key bindings     ===
      # ==========================
      unbind "\$" # rename-session
      unbind ,    # rename-window
      unbind %    # split-window -h
      unbind '"'  # split-window
      unbind \}   # swap-pane -D
      unbind \{   # swap-pane -U
      unbind [    # paste-buffer
      unbind ]
      unbind "'"  # select-window
      unbind n    # next-window
      unbind p    # previous-window
      unbind l    # last-window
      unbind M-n  # next window with alert
      unbind M-p  # next window with alert
      unbind o    # focus thru panes
      unbind &    # kill-window
      unbind "#"  # list-buffer
      unbind =    # choose-buffer
      unbind z    # zoom-pane
      unbind M-Up
      unbind M-Down
      unbind M-Right
      unbind M-Left

      # Reload config
      bind C-r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      # sesh — smart session manager: fuzzy session picker in a popup (C-z g).
      # 'g' = "go to session" ('t'/'T' are taken by the sidebar plugin).
      bind g display-popup -E -w 80% -h 70% \
        "sesh connect \"$(sesh list --icons | fzf --ansi --no-sort --prompt '⚡  ')\""

      # New window retaining cwd
      bind c new-window -c "#{pane_current_path}"

      # Prompt to rename window right after creation — guarded by session_attached
      # so detached/scripted builds (tmuxp, libtmux, `tmux new-window` on a
      # detached session) don't fire command-prompt with no client (which errors
      # on stderr and libtmux 0.58 turns into a fatal exception).
      set-hook -g after-new-window 'if -F "#{session_attached}" "command-prompt -I \"#{window_name}\" \"rename-window '%%'\""'

      # Rename session and window
      bind r command-prompt -I "#{window_name}" "rename-window '%%'"
      bind R command-prompt -I "#{session_name}" "rename-session '%%'"

      # Split panes
      bind | split-window -h -c "#{pane_current_path}"
      bind _ split-window -v -c "#{pane_current_path}"

      # Select pane and windows
      bind -r C-[ previous-window
      bind -r C-] next-window
      bind -r [ select-pane -t :.-
      bind -r ] select-pane -t :.+
      bind -r Tab last-window
      bind -r C-o swap-pane -D

      # Zoom pane
      bind + resize-pane -Z

      # Link window
      bind L command-prompt -p "Link window from (session:window): " "link-window -s %% -a"

      # Swap panes back and forth with 1st pane
      bind \\ if '[ #{pane_index} -eq 1 ]' \
           'swap-pane -s "!"' \
           'select-pane -t:.1 ; swap-pane -d -t 1 -s "!"'

      # Kill pane/window/session shortcuts
      bind x kill-pane
      bind X kill-window
      bind C-x confirm-before -p "kill other windows? (y/n)" "kill-window -a"
      bind Q confirm-before -p "kill-session #S? (y/n)" kill-session

      # Merge session with another one
      bind C-u command-prompt -p "Session to merge with: " \
         "run-shell 'yes | head -n #{session_windows} | xargs -I {} -n 1 tmux movew -t %%'"

      # Detach from session
      bind d detach
      bind D if -F '#{session_many_attached}' \
          'confirm-before -p "Detach other clients? (y/n)" "detach -a"' \
          'display "Session has only 1 client attached"'

      # Toggle status bar
      bind C-s if -F '#{s/off//:status}' 'set status off' 'set status on'

      # ==================================================
      # === Window monitoring for activity and silence ===
      # ==================================================
      bind m setw monitor-activity \; display-message 'Monitor window activity [#{?monitor-activity,ON,OFF}]'
      bind M if -F '#{monitor-silence}' \
          'setw monitor-silence 0 ; display-message "Monitor window silence [OFF]"' \
          'command-prompt -p "Monitor silence: interval (s)" "setw monitor-silence %%"'

      set -g visual-activity on

      # ================================================
      # ===     Copy mode, scroll and clipboard      ===
      # ================================================
      set -g @copy_use_osc52_fallback on

      bind p paste-buffer
      bind C-p choose-buffer

      # Trigger copy mode
      bind -n M-Up copy-mode

      # Scroll up/down in copy mode
      bind -T copy-mode-vi M-Up       send-keys -X scroll-up
      bind -T copy-mode-vi M-Down     send-keys -X scroll-down
      bind -T copy-mode-vi M-PageUp   send-keys -X halfpage-up
      bind -T copy-mode-vi M-PageDown send-keys -X halfpage-down
      bind -T copy-mode-vi PageDown   send-keys -X page-down
      bind -T copy-mode-vi PageUp     send-keys -X page-up

      # Reduce scroll speed (2 rows per tick instead of 5)
      bind -T copy-mode-vi WheelUpPane   select-pane \; send-keys -X -N 2 scroll-up
      bind -T copy-mode-vi WheelDownPane select-pane \; send-keys -X -N 2 scroll-down

      # macOS: wrap shell in reattach-to-user-namespace if available
      if -b "command -v reattach-to-user-namespace > /dev/null 2>&1" \
          "run 'tmux set -g default-command \"exec $(tmux show -gv default-shell) 2>/dev/null & reattach-to-user-namespace -l $(tmux show -gv default-shell)\"'"

      # =====================================
      # ===           Theme               ===
      # =====================================
      color_orange="colour166"
      color_purple="colour134"
      color_green="colour076"
      color_blue="colour39"
      color_yellow="colour220"
      color_red="colour160"
      color_black="colour232"
      color_white="white"

      color_dark="$color_black"
      color_light="$color_white"
      color_session_text="$color_blue"
      color_status_text="colour245"
      color_main="$color_orange"
      color_secondary="$color_purple"
      color_level_ok="$color_green"
      color_level_warn="$color_yellow"
      color_level_stress="$color_red"
      color_window_off_indicator="colour088"
      color_window_off_status_bg="colour238"
      color_window_off_status_current_bg="colour254"

      # =====================================
      # ===    Appearance and status bar  ===
      # =====================================
      set -g mode-style "fg=default,bg=$color_main"
      set -g message-style "fg=$color_main,bg=$color_dark"
      set -g status-style "fg=$color_status_text,bg=$color_dark"

      set -g window-status-separator ""
      separator_powerline_left=""
      separator_powerline_right=""

      setw -g window-status-format " #I:#W "
      setw -g window-status-current-style "fg=$color_light,bold,bg=$color_main"
      setw -g window-status-current-format "#[fg=$color_dark,bg=$color_main]$separator_powerline_right#[default] #I:#W# #[fg=$color_main,bg=$color_dark]$separator_powerline_right#[default]"
      setw -g window-status-activity-style "fg=$color_main"
      setw -g pane-active-border-style "fg=$color_main"

      set -g status on
      set -g status-interval 5
      set -g status-position top
      set -g status-justify left
      set -g status-right-length 100

      wg_session="#[fg=$color_session_text] #S #[default]"
      wg_battery="#{battery_status_fg} #{battery_icon} #{battery_percentage}"
      wg_date="#[fg=$color_secondary]%h %d %H:%M#[default]"
      wg_user_host="#[fg=$color_secondary]#(whoami)#[default]@#H"
      wg_is_zoomed="#[fg=$color_dark,bg=$color_secondary]#{?window_zoomed_flag,[Z],}#[default]"
      wg_is_keys_off="#[fg=$color_light,bg=$color_window_off_indicator]#([ $(tmux show-option -qv key-table) = 'off' ] && echo 'OFF')#[default]"

      set -g status-left " $wg_session"
      set -g status-right "#{prefix_highlight} $wg_is_keys_off $wg_is_zoomed $wg_battery | $wg_user_host | $wg_date | #{online_status}"

      # tmux-online-status icons
      set -g @online_icon "#[fg=$color_level_ok]●#[default]"
      set -g @offline_icon "#[fg=$color_level_stress]●#[default]"

      # tmux-battery colors
      set -g @batt_color_full_charge "#[fg=$color_level_ok]"
      set -g @batt_color_high_charge "#[fg=$color_level_ok]"
      set -g @batt_color_medium_charge "#[fg=$color_level_warn]"
      set -g @batt_color_low_charge "#[fg=$color_level_stress]"

      # tmux-prefix-highlight colors
      set -g @prefix_highlight_output_prefix '['
      set -g @prefix_highlight_output_suffix ']'
      set -g @prefix_highlight_fg "$color_dark"
      set -g @prefix_highlight_bg "$color_secondary"
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr "fg=$color_dark,bg=$color_secondary"

      # =====================================
      # ===        Renew environment      ===
      # =====================================
      set -g update-environment \
        "DISPLAY\
        SSH_ASKPASS\
        SSH_AUTH_SOCK\
        SSH_AGENT_PID\
        SSH_CONNECTION\
        SSH_TTY\
        WINDOWID\
        XAUTHORITY"

      # ============================
      # ===    Plugin settings   ===
      # ============================
      set -g @logging-path "$HOME/tmux_logging"

      set -g @sidebar-tree 't'
      set -g @sidebar-tree-focus 'T'
      set -g @sidebar-tree-command 'tree -C'
      set -g @sidebar-tree-position 'left'
      set -g @sidebar-tree-width '60'

      set -g @open-S 'https://www.google.com/search?q='

      set -g @resurrect-save 'SS'
      set -g @resurrect-restore 'RR'
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'

      # ==============================================
      # ===   Nesting local and remote sessions   ===
      # ==============================================
      # F10: disable local prefix — pass all input to inner/remote session
      bind -T root F10 \
          set prefix None \;\
          set key-table off \;\
          set status-style "fg=$color_status_text,bg=$color_window_off_status_bg" \;\
          set window-status-current-format "#[fg=$color_window_off_status_bg,bg=$color_window_off_status_current_bg]$separator_powerline_right#[default] #I:#W# #[fg=$color_window_off_status_current_bg,bg=$color_window_off_status_bg]$separator_powerline_right#[default]" \;\
          set window-status-current-style "fg=$color_dark,bold,bg=$color_window_off_status_current_bg" \;\
          if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
          refresh-client -S \;\

      # F9: restore local prefix
      bind -T off F9 \
        set -u prefix \;\
        set -u key-table \;\
        set -u status-style \;\
        set -u window-status-current-style \;\
        set -u window-status-current-format \;\
        refresh-client -S
    '';
  };
}
