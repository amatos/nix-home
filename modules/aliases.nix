{ ... }: {
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
      nix flake update && git add flake.lock && git commit -m "Update flake.lock" && git push
      cd "$HOME/Projects/nix-home" || return
      nix flake update && git add flake.lock && git commit -m "Update flake.lock" && git push
      popd
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
      nix flake update && git add flake.lock && git commit -m "Update flake.lock" && git push
      cd "$HOME/Projects/nix-home" || return
      nix flake update && git add flake.lock && git commit -m "Update flake.lock" && git push
      popd
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
    nix flake update && git add flake.lock && git commit -m "Update flake.lock" && git push
    cd $HOME/Projects/nix-home
    nix flake update && git add flake.lock && git commit -m "Update flake.lock" && git push
    popd
  '';
}
