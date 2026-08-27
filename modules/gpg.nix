{ pkgs, ... }: {
  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = pkgs.fetchurl {
          url = "https://keys.openpgp.org/vks/v1/by-fingerprint/5FC8FE1141FA769594E91E48F41BDBF6171A3BB4";
          hash = "sha256-BdHZRXJw27vnOXetqj+wANTYf7L58yRTgAiz6dKBD64=";
        };
        trust = "ultimate";
      }
    ];
  };
}
