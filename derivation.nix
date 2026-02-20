{ stdenv, zig }:
stdenv.mkDerivation rec {
  name = "ps1-builder-${version}";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ ];
  buildInputs = [
    zig
  ];

  zigout = "zig-out";
  zigcache = "zig-cache";

  buildPhase = ''
    mkdir -p $zigcache $zigout
    export ZIG_GLOBAL_CACHE_DIR=$zigcache
    zig build -p $zigout -Doptimize=ReleaseFast --cache-dir $zigcache
  '';

  installPhase = ''
    mkdir -p $out
    cp -r zig-out/* $out
  '';
}
