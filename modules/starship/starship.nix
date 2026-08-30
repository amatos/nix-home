{ ... }:
let
  baseSettings = builtins.fromTOML (builtins.readFile ./starship.toml);
in
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = baseSettings;
  };
}
