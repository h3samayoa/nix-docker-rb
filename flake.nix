{
  description = "NixOS configuration for my hypervisor (mbhv)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # https://zerforschen.plus/posts/why-i-do-not-use-flake-utils/
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in 
    {

      nixosConfigurations.mbhv = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { }; 
        modules = [
          ../hv/configuration.nix
        ];
      };

      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./iso/iso.nix ];
      };

      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
      });
    };
}