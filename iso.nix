{ config, pkgs, ... }:

{
  # import iso module from nixpkgs
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix>
  ];

  # nixpkgs.localSystem.system = "x86_64-linux";

  # put our configuration.nix file in /etc/nixos/configuration.nix
  environment.etc."nixos/configuration.nix".source = ./configuration.nix;
}