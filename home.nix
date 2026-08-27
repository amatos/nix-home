{ ... }:
let
  loadModules = dir:
    let entries = builtins.readDir dir;
    in builtins.concatMap (name:
      let path = dir + "/${name}"; in
      if entries.${name} == "directory" then loadModules path
      else if entries.${name} == "regular" && builtins.match ".*\\.nix" name != null then [ path ]
      else []
    ) (builtins.attrNames entries);
in {
  imports = loadModules ./modules;
}
