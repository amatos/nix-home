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
}
