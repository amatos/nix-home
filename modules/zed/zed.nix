{ config, ... }:
{
  # Symlink straight to the file in the repo (instead of copying it into the
  # nix store) so Zed's settings GUI can write to it directly. Changes show
  # up as a normal git diff in nix-home to review/commit.
  xdg.configFile."zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Projects/nix-home/modules/zed/settings.json";
}
