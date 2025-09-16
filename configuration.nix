{ config, pkgs, ... }:

{
  imports = [
    # Scans hardware and suggests a configuration. Not strictly necessary but good practice.
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  # --- Bootloader ---
  # GRUB is the standard bootloader.
  boot.loader.grub.enable = true;
  # IMPORTANT: During installation, you MUST verify this is the correct device!
  # It will likely be something like /dev/nvme0n1 or /dev/sda.
  boot.loader.grub.device = "/dev/sda";

  # --- Networking ---
  networking.hostName = "mbhv"; # Set the hostname.
  networking.networkmanager.enable = true; # Use NetworkManager for easy Wi-Fi.

  # --- Timezone and Locale ---
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- User Accounts ---
  users.users.your_username = {
    isNormalUser = true;
    description = "Your Name";
    # Add user to the 'wheel' group to allow sudo access.
    # Add user to 'libvirtd' to manage VMs without sudo.
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
  };
  # Set a password for your user after installation with `passwd your_username`.

  # --- Hypervisor Pre-configuration ---
  # Prepare the system for virtualization from the very first boot.
  boot.kernelModules = [ "kvm-intel" ];
  virtualisation.libvirtd.enable = true;

  # --- Allow unfree packages for firmware, codecs, etc. ---
  nixpkgs.config.allowUnfree = true;

  # --- System Packages ---
  # Add any packages you want available globally on the hypervisor.
  environment.systemPackages = with pkgs; [
    vim
    git
    tailscale # For your future VM manager access.
    curl      # For downloading the GitHub Actions runner
    gh        # GitHub CLI for runner setup and management
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions,
  # are taken. It's perfectly fine and recommended to leave this commented out
  # initially. The `nixos-generate-config` tool will set it for you.
  # system.stateVersion = "23.11";
}