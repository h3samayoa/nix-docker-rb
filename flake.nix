{
  description = "nix docker rb";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./iso.nix ];
      };

      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
      });
    };
}