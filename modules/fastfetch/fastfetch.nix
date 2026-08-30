{ pkgs, ... }:
let
  # Wrapper that shadows `fastfetch` on PATH.  Calls the real binary, then
  # post-processes the output to resize section banners to the widest data
  # row — fastfetch itself has no built-in way to do this since banner
  # strings are static in the config.  See fastfetch-wrapper.py for the
  # algorithm.  Falls through to printing partial output if fastfetch exits
  # non-zero, so the user sees something even when fastfetch crashes mid-run.
  fastfetchWrapper = pkgs.writeShellApplication {
    name = "fastfetch";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      export FASTFETCH_BIN="${pkgs.fastfetch}/bin/fastfetch"
      exec ${pkgs.python3}/bin/python3 ${./fastfetch-wrapper.py} "$@"
    '';
  };
in
{
  home.packages = [ fastfetchWrapper ];
  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch-config.jsonc;
}
