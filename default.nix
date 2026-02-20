# {
#   pkgs ? import <nixpkgs> { },
# }:
# pkgs.callPackage ./derivation.nix { }
let
  nixpkgs = fetchTarball "https://github.com/NixOs/nixpkgs/tarball/bce5fe2bb998488d8e7e7856315f90496723793c";
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };
in
{
  ps1-builder = pkgs.callPackage ./derivation.nix { zig = pkgs.zig; };
}
