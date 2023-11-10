{
  description = "pintos";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
  };

  outputs = { self, nixpkgs, utils, rust-overlay }:
    utils.lib.eachDefaultSystem (system: with import nixpkgs
      {
        overlays = [ (import rust-overlay) ];
        inherit system;
      }; {
      devShells =
        let
          rust = rust-bin.nightly.latest.minimal.override {
            extensions = [
              "clippy"
              "llvm-tools-preview"
              "rustfmt"
              "rust-src"
              "rust-std"
            ];
            targets = [ "i686-unknown-linux-gnu" ];
          };
          # Adapted from: https://github.com/oxalica/rust-overlay/blob/master/docs/cross_compilation.md
          i686-cc = (import nixpkgs {
            crossSystem = "i686-linux";
            inherit system;
          }).stdenv.cc;
        in
        {
          default = mkShell {
            depsBuildBuild = [ i686-cc rust ];
            nativeBuildInputs = [ rust-analyzer ];

            CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_LINKER = "${i686-cc.targetPrefix}cc";
            CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_RUNNER = "${qemu}/bin/qemu-i386";
          };
        };
    });
}
