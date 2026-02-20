{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/bce5fe2bb998488d8e7e7856315f90496723793c";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.zig
          ];
          packages = [
            pkgs.zls
          ];
        };
      }
    );
}
