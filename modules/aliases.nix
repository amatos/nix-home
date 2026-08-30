{ ... }:
let
  commonAliases = {
    # SSH variants
    sshk = "ssh -o StrictHostKeyChecking=no";
    sshv = "ssh -vvv";
    sshp = "ssh -o PreferredAuthentications=password";
    ssht = "ssh -o ConnectTimeout=5";
    sshx = "ssh -X";
    sshnone = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";

    # Git history viewers
    git-log = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    git-author = "echo '👤 Commit Author History:' && git log --pretty=format:'%h%x09%an%x09%ad%x09%s'";

    # nix-darwin aliases
    build-darwin = "build-nix";
    switch-darwin = "switch-nix";
  };
in
{
  programs.bash.shellAliases = commonAliases;

  programs.zsh.shellAliases = commonAliases;

  programs.fish.shellAliases = commonAliases;

  programs.bash.initExtra = ''
    build-home() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager build --flake .#darwin ;;
        Linux) home-manager build --flake .#nixos ;;
      esac
      popd
    }

    switch-home() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager switch --flake .#darwin ;;
        Linux) home-manager switch --flake .#nixos ;;
      esac
      popd
    }

    build-nix() {
      pushd "$HOME/Projects/nix-dendrites" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild build --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild build --flake .#$(hostname) ;;
      esac
      popd
    }

    switch-nix() {
      pushd "$HOME/Projects/nix-dendrites" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild switch --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild switch --flake .#$(hostname) ;;
      esac
      popd
    }

    nfu() {
      pushd "$HOME/Projects/nix-dendrites" || return
      flake-update-branch
      cd "$HOME/Projects/nix-home" || return
      flake-update-branch
      popd
    }

    flake-update-branch() {
      local ORIGINAL_BRANCH BRANCH
      ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
      BRANCH=$(date +%Y-%m-%d-%H-%M-%S)

      if ! git checkout -b "$BRANCH"; then
        echo "Failed to create/checkout branch $BRANCH"
        return 1
      fi

      nix flake update

      if ! git diff --quiet -- flake.lock; then
        git add flake.lock
        git commit -m "Update flake.lock"

        if ! git checkout main; then
          echo "Failed to checkout main"
          return 1
        fi

        if ! git merge "$BRANCH"; then
          echo "Merge of $BRANCH into main failed"
          return 1
        fi

        git branch -d "$BRANCH"
        git push origin main
      else
        echo "flake.lock unchanged; nothing to commit or merge"
        git checkout "$ORIGINAL_BRANCH"
        git branch -d "$BRANCH"
        return 0
      fi

      git checkout "$ORIGINAL_BRANCH"
    }
  '';

  programs.zsh.initContent = ''
    build-home() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager build --flake .#darwin ;;
        Linux) home-manager build --flake .#nixos ;;
      esac
      popd
    }

    switch-home() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager switch --flake .#darwin ;;
        Linux) home-manager switch --flake .#nixos ;;
      esac
      popd
    }

    build-nix() {
      pushd "$HOME/Projects/nix-dendrites" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild build --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild build --flake .#$(hostname) ;;
      esac
      popd
    }

    switch-nix() {
      pushd "$HOME/Projects/nix-dendrites" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild switch --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild switch --flake .#$(hostname) ;;
      esac
      popd
    }

    nfu() {
      pushd "$HOME/Projects/nix-dendrites" || return
      flake-update-branch
      cd "$HOME/Projects/nix-home" || return
      flake-update-branch
      popd
    }

    flake-update-branch() {
      local ORIGINAL_BRANCH BRANCH
      ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
      BRANCH=$(date +%Y-%m-%d-%H-%M-%S)

      if ! git checkout -b "$BRANCH"; then
        echo "Failed to create/checkout branch $BRANCH"
        return 1
      fi

      nix flake update

      if ! git diff --quiet -- flake.lock; then
        git add flake.lock
        git commit -m "Update flake.lock"

        if ! git checkout main; then
          echo "Failed to checkout main"
          return 1
        fi

        if ! git merge "$BRANCH"; then
          echo "Merge of $BRANCH into main failed"
          return 1
        fi

        git branch -d "$BRANCH"
        git push origin main
      else
        echo "flake.lock unchanged; nothing to commit or merge"
        git checkout "$ORIGINAL_BRANCH"
        git branch -d "$BRANCH"
        return 0
      fi

      git checkout "$ORIGINAL_BRANCH"
    }
  '';

  programs.fish.functions.build-home = ''
    pushd $HOME/Projects/nix-home
    switch (uname -s)
      case Darwin
        home-manager build --flake .#darwin
      case Linux
        home-manager build --flake .#nixos
    end
    popd
  '';

  programs.fish.functions.switch-home = ''
    pushd $HOME/Projects/nix-home
    switch (uname -s)
      case Darwin
        home-manager switch --flake .#darwin
      case Linux
        home-manager switch --flake .#nixos
    end
    popd
  '';

  programs.fish.functions.build-nix = ''
    pushd $HOME/Projects/nix-dendrites
    switch (uname -s)
      case Darwin
        darwin-rebuild build --flake .#$(hostname)
      case Linux
        nixos-rebuild build --flake .#$(hostname)
    end
    popd
  '';

  programs.fish.functions.switch-nix = ''
    pushd $HOME/Projects/nix-dendrites
    switch (uname -s)
      case Darwin
        sudo darwin-rebuild switch --flake .#$(hostname)
      case Linux
        sudo nixos-rebuild switch --flake .#$(hostname)
    end
    popd
  '';

  programs.fish.functions.nfu = ''
    pushd $HOME/Projects/nix-dendrites
    flake-update-branch
    cd $HOME/Projects/nix-home
    flake-update-branch
    popd
  '';

  programs.fish.functions.flake-update-branch = ''
    set -l ORIGINAL_BRANCH (git rev-parse --abbrev-ref HEAD)
    set -l BRANCH (date +%Y-%m-%d-%H-%M-%S)

    if not git checkout -b $BRANCH
        echo "Failed to create/checkout branch $BRANCH"
        return 1
    end

    nix flake update

    if not git diff --quiet -- flake.lock
        git add flake.lock
        git commit -m "Update flake.lock"

        if not git checkout main
            echo "Failed to checkout main"
            return 1
        end

        if not git merge $BRANCH
            echo "Merge of $BRANCH into main failed"
            return 1
        end

        git branch -d $BRANCH
        git push origin main
    else
        echo "flake.lock unchanged; nothing to commit or merge"
        git checkout $ORIGINAL_BRANCH
        git branch -d $BRANCH
        return 0
    end

    git checkout $ORIGINAL_BRANCH
  '';
}
