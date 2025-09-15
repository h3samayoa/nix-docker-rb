{ config, pkgs, ... }:

{
  # Import the base module that provides the logic for building an ISO image.
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix>
  ];

  # Set the system architecture for the live environment.
  nixpkgs.localSystem.system = "x86_64-linux";

  # --- Hardware Support for Intel MacBook Pro ---
  # This is the most critical part for a smooth installation.
  # We enable non-free packages to get the Broadcom firmware.
  nixpkgs.config.allowUnfree = true;

  # Add necessary firmware and tools to the live environment.
  environment.systemPackages = with pkgs; [
    # Essential firmware for MacBook Wi-Fi and Bluetooth.
    broadcom-bt-firmware

    # Useful tools for the installation process.
    git
    vim
    gparted
    wget
    curl # Added for downloading scripts
    gh   # Added GitHub CLI
  ];

  # Copy the target system's configuration into the installer.
  # This makes it available at /etc/nixos/configuration.nix in the live environment,
  # so the `nixos-install` command knows what system to build and install.
  environment.etc."nixos/configuration.nix".source = ../../hv/configuration.nix;
}