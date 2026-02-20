{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/bce5fe2bb998488d8e7e7856315f90496723793c";
    flake-utils.url = "github:numtide/flake-utils";

    zig2nix = {
      url = "github:Cloudef/zig2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      zig2nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        zig-env = zig2nix.outputs.zig-env.${system} {
          zig = zig2nix.outputs.packages.${system}.zig-0_15_2;
        };
      in
      rec {
        packages.default = zig-env.package rec {
          src = zig-env.pkgs.lib.cleanSource ./.;

          zigBuildFlags = [ "-Doptimize=ReleaseFast" ];
        };

        apps.build = zig-env.app [ ] "zig build \"$@\"";

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
