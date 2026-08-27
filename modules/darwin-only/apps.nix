{ pkgs, lib, ... }: {
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    pkgs.orion-browser
    pkgs.betterdisplay
    pkgs.syncthing-macos
  ];
}
