{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "nixos-hypervisor";

  packages = with pkgs; [
    nixos-generators
    nixos-rebuild

    qemu
    gptfdisk
    util-linux

    openssh
    curl
    jq
    tree
    htop

    nixpkgs-fmt
    statix
    deadnix

    podman
    docker
    gemini-cli
  ];

  shellHook = ''
    export PS1='\[\033[1;32m\][nix-shell]\[\033[0m\] \[\033[1;34m\]\W\[\033[0m\] \$ '
  '';
}
