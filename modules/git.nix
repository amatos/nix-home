{ config, ... }: {
  programs.git = {
    enable = true;
    package = null;
    signing = {
      key = "5FC8FE1141FA769594E91E48F41BDBF6171A3BB4";
      signByDefault = true;
    };
    lfs.enable = true;
    settings.user = {
      name = "Alberth Matos";
      email = "alberth@matos.cc";
      core = {
        editor = "nvim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab"; # Highlight whitespace issues
      };
      init = {
        defaultBranch = "main";
        templateDir = "${config.home.homeDirectory}/.config/git/template/repo";
      };
      commit = {
        gpgSign = true;
        template = "${config.home.homeDirectory}/.config/git/gitmessage";
      };
      tag.gpgSign = true;
      push.autoSetupRemote = true;
      maintenance.auto = true;
      maintenance.strategy = "incremental";
      # Fetch behavior
      fetch = {
        prune = true; # Auto-remove deleted remote branches
        pruneTags = true; # Auto-remove deleted remote tags
      };
      diff = {
        algorithm = "histogram"; # Better diff algorithm than default
        colorMoved = "default"; # Highlight moved lines in different color
        mnemonicPrefix = true; # Use i/w/c/o instead of a/b in diffs
      };
      color.ui = "auto";
    };
    ignores = [
      "*.swp"

      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon[]"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdiskre"

      # Linux
      "*~"
      ".fuse_hidden*"
      ".directory"
      ".Trash-*"
      ".nfs*"
      "nohup.out"

      # Windows
      "Thumbs.db"
      "Thumbs.db:encryptable"
      "ehthumbs.db"
      "ehthumbs_vista.db"
      "*.stackdump"
      "[Dd]esktop.ini"
      "$RECYCLE.BIN/"
      "*.cab"
      "*.msi"
      "*.msix"
      "*.msm"
      "*.msp"
      "*.lnk"

      # mise (https://mise.jdx.dev/configuration.html)
      ".mise.*.local.toml"
      ".mise.local.toml"
      "mise.*.local.toml"
      "mise.local.toml"
      ".mise/*.local.toml"
      "mise/*.local.toml"

      # VSCode
      ".vscode/*"
      "!.vscode/settings.json"
      "!.vscode/tasks.json"
      "!.vscode/launch.json"
      "!.vscode/extensions.json"
      "!.vscode/*.code-snippets"
      "!*.code-workspace"
      "*.vsix"

      "**/.claude/settings.local.json"
    ];

    attributes = [
      "* text=auto" # Automatically normalize line endings

      "*.png  binary"
      "*.jpg  binary"
      "*.jpeg binary"
      "*.bmp  binary"
    ];
  };

  xdg.configFile."git/gitmessage".text = ''
    [Type](Scope): <Short summary in imperative mood, max 50 chars>

    # ─── Type of change ───
    # feat: A new feature for the user.
    # fix: A bug fix.
    # docs: Documentation-only changes.
    # style: Formatting, missing semicolons, etc. (no production code changes).
    # refactor: Production code changes that neither fix a bug nor add a feature.
    # test: Adding missing tests or correcting existing tests.
    # chore: Updating build tasks, package manager configs, etc.

    # ─── Why is this change required? ───
    # - Explain the context or problem being solved.
    # - Do not explain "how" (the code shows how).

    # ─── What was changed? ───
    # - Bullet points summarizing the structural shifts.
    # - Keep lines wrapped under 72 characters.

    # ─── References / Trackers ───
    # Resolve: #JIRA-123
    # See also: #456
  '';

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "zed";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      pager = "bat";
      aliases = {
        co = "pr checkout";
      };
      color_labels = "enabled";
      accessible_colors = "disabled";
      accessible_prompter = "disabled";
      spinner = "enabled";
    };
  };
}
