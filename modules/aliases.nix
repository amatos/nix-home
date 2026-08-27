{ ... }: {
  programs.bash.initExtra = ''
    home-build() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager build --flake .#darwin ;;
        Linux) home-manager build --flake .#nixos ;;
      esac
      popd
    }

    home-switch() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager switch --flake .#darwin ;;
        Linux) home-manager switch --flake .#nixos ;;
      esac
      popd
    }

    nix-build() {
      pushd "$HOME/Projects/nix-dendritic" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild build --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild build --flake .#$(hostname) ;;
      esac
      popd
    }

    nix-switch() {
      pushd "$HOME/Projects/nix-dendritic" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild switch --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild switch --flake .#$(hostname) ;;
      esac
      popd
    }
  '';

  programs.zsh.initContent = ''
    home-build() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager build --flake .#darwin ;;
        Linux) home-manager build --flake .#nixos ;;
      esac
      popd
    }

    home-switch() {
      pushd "$HOME/Projects/nix-home" || return
      case "$(uname -s)" in
        Darwin) home-manager switch --flake .#darwin ;;
        Linux) home-manager switch --flake .#nixos ;;
      esac
      popd
    }

    nix-build() {
      pushd "$HOME/Projects/nix-dendritic" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild build --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild build --flake .#$(hostname) ;;
      esac
      popd
    }

    nix-switch() {
      pushd "$HOME/Projects/nix-dendritic" || return
      case "$(uname -s)" in
        Darwin) sudo darwin-rebuild switch --flake .#$(hostname) ;;
        Linux) sudo nixos-rebuild switch --flake .#$(hostname) ;;
      esac
      popd
    }
  '';

  programs.fish.functions.home-build = ''
    pushd $HOME/Projects/nix-home
    switch (uname -s)
      case Darwin
        home-manager build --flake .#darwin
      case Linux
        home-manager build --flake .#nixos
    end
    popd
  '';

  programs.fish.functions.home-switch = ''
    pushd $HOME/Projects/nix-home
    switch (uname -s)
      case Darwin
        home-manager switch --flake .#darwin
      case Linux
        home-manager switch --flake .#nixos
    end
    popd
  '';

  programs.fish.functions.nix-build = ''
    pushd $HOME/Projects/nix-dendritic
    switch (uname -s)
      case Darwin
        darwin-rebuild build --flake .#$(hostname)
      case Linux
        nixos-rebuild build --flake .#$(hostname)
    end
    popd
  '';

  programs.fish.functions.nix-switch = ''
    pushd $HOME/Projects/nix-dendritic
    switch (uname -s)
      case Darwin
        sudo darwin-rebuild switch --flake .#$(hostname)
      case Linux
        sudo nixos-rebuild switch --flake .#$(hostname)
    end
    popd
  '';

}
