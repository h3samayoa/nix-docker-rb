{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.loader.grub.enable = true;

  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "mbhv";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.your_username = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
  };

  # add support for macbook wifi adaptors
  boot.kernelModules = [ 
    "kvm-intel" 
    "wl"
  ];
  virtualisation.libvirtd.enable = true;

  # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
  nixpkgs.config.allowUnfree = true;

  # packages that will be available globally on the system
  environment.systemPackages = with pkgs; [
    vim
    git
    tailscale
    curl
    gh
  ];
}