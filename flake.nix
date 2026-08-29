{
  description = "Home Manager configuration for alberth";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets = {
      url = "github:amatos/nix-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-secrets, ... }:
    let
      configs = {
        darwin = "aarch64-darwin";
        nixos = "x86_64-linux";
      };
    in {
      homeConfigurations = builtins.mapAttrs (_: system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit nix-secrets; };
          modules = [ ./home.nix ];
        }
      ) configs;
    };
}
