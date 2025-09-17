{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "rb example shell";

  packages = with pkgs; [
    docker
    just
  ];

  shellHook = ''
    export PS1='\[\033[1;32m\][nix-shell]\[\033[0m\] \[\033[1;34m\]\W\[\033[0m\] \$ '
  '';
}
