{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Symlink straight to the file in the repo (instead of copying it into the
  # nix store) so Zed's settings GUI can write to it directly. Changes show
  # up as a normal git diff in nix-home to review/commit.
  xdg.configFile."zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-home/modules/zed/settings.json";

  programs.zed-editor = {
    enable = true;

    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.zed-editor;

    extensions = [
      # Languages & frameworks
      #
      # go/rust/python/css/javascript/typescript/yaml are deliberately absent:
      # those extension IDs no longer exist in Zed's registry (404 from
      # api.zed.dev) because the languages were folded into Zed core — see
      # https://zed.dev/docs/languages ("*" = built-in). Zed's client doesn't
      # check the HTTP status before gunzipping the response, so requesting a
      # dead ID surfaces as "Invalid gzip header" in Zed.log rather than a
      # clear 404, and the extension is silently skipped on every activation.
      "nix"
      "toml"
      "dockerfile"
      "terraform"
      "helm"
      "ruby"
      "html"
      "lua"

      # Added for VSCode parity
      "java-eclipse-jdtls" # Java LSP via Eclipse JDTLS (matches vscjava.vscode-java-pack)
      "just" # Justfile syntax + LSP
      "make" # Makefile syntax
      "git-firefly" # Git-blob syntax highlighting (Zed has built-in inline blame)
      "material-icon-theme" # VSCode-style file-type icons (see icon_theme below)
      "typst" # Typst language (matches vscode myriad-dreamin.tinymist)
      "mermaid" # Mermaid diagram syntax (repo authors diagrams under readme/diagrams/)
      "sql" # SQL language support
      "env" # .env / dotenv file support
      "marksman" # Markdown LSP — cross-file refs over Zed's built-in markdown

      # Color schemes / themes
      "dracula"
      "vscode-dark"
      "vscode-light"
    ];

    userSettings = lib.mkForce {
      # ── Identity / look ──────────────────────────────────────────────
      theme = {
        mode = "system";
        light = "Dracula Light (Alucard";
        dark = "Dracula Solid";
      };
      icon_theme = {
        mode = "system";
        light = "Colored Zed Icons Theme Light";
        dark = "Colored Zed Icons Theme Dark";
      };
      vim_mode = false;
      base_keymap = "Zed";
      ui_font_size = 16;
      buffer_font_size = 15;
      buffer_font_family = ".ZedMono";

      # ── Chrome ───────────────────────────────────────────────────────
      tabs = {
        file_icons = true;
        git_status = true;
      };
      scrollbar = {
        show = "auto";
      };
      indent_guides = {
        enabled = true;
      };

      # ── Editor behaviour ─────────────────────────────────────────────
      tab_size = 2;
      soft_wrap = "editor_width";
      show_whitespaces = "selection";
      preferred_line_length = 100;
      remove_trailing_whitespace_on_save = true;
      ensure_final_newline_on_save = true;
      autosave = {
        after_delay = {
          milliseconds = 1000;
        };
      };
      auto_indent = "syntax_aware";
      format_on_save = "on";
      confirm_quit = false;

      # ── Git ──────────────────────────────────────────────────────────
      git = {
        inline_blame = {
          enabled = true;
        };
      };

      # ── Terminal ─────────────────────────────────────────────────────
      terminal = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 13;
        copy_on_select = true;
        shell = {
          program = "fish";
        };
      };

      # ── Telemetry ────────────────────────────────────────────────────
      telemetry = {
        metrics = true;
        diagnostics = true;
      };

      # ── LSP: nil (Nix) ───────────────────────────────────────────────
      # The Zed "Nix" extension ships both `nil` and `nixd` and defaults to
      # `nixd`. Select `nil` (installed via home/shared/editor/neovim.nix,
      # on PATH) and disable `nixd` so the extension stops demanding it.
      languages = {
        Nix = {
          language_servers = [
            "nil"
            "!nixd"
          ];
        };
      };

      # Pin nil's flake handling so it stops popping "Some flake inputs are
      # not available — fetch them now?". autoArchive = false keeps nil from
      # running `nix flake archive` in the background; flip both to true if
      # you want full cross-input evaluation/completion (heavier on a flake
      # this size).
      lsp = {
        nil = {
          # Absolute store path so the cask Zed on macOS (no Nix PATH) finds
          # nil; on Linux this is just deterministic. Same nil as neovim.nix.
          binary = {
            path = "${pkgs.nil}/bin/nil";
          };
          initialization_options = {
            nix = {
              flake = {
                autoArchive = false;
                autoEvalInputs = false;
              };
            };
          };
        };
      };
    };
  };
}
