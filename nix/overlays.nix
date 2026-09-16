{ inputs, nixpkgsConfig, ... }: {
  claude-code = final: prev:
    let
      platform = final.stdenv.hostPlatform.node;
      src = inputs."claude-code-src-${platform.platform}-${platform.arch}";
    in {
      # Keep nixpkgs-latest's runtime dependencies, patching, wrapper, and version check.
      claude-code = final.pkgs-latest.claude-code.overrideAttrs (old: {
        inherit src;
        version = (builtins.fromJSON (builtins.readFile "${src}/package.json")).version;
        dontUnpack = false;
        installPhase = builtins.replaceStrings
          [ "unzstd -q $src -o $out/bin/claude" ]
          [ "install -m755 claude $out/bin/claude" ]
          old.installPhase;
      });
    };
  fastStdenv = final: prev: {
    final.stdenv = prev.fastStdenv.mkDerivation { name = "env"; };
  };
  pkgs-stable = final: prev: {
    pkgs-stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv) system;
      config = nixpkgsConfig;
    };
  };
  pkgs-2311 = final: prev: {
    pkgs-2311 = import inputs.nixpkgs-2311 {
      inherit (prev.stdenv) system;
      config = nixpkgsConfig;
    };
  };
  pkgs-x86 = final: prev:
    prev.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
      pkgs-x86 = import inputs.nixpkgs {
        system = "x86_64-darwin";
        config = nixpkgsConfig;
      };
    };
  pkgs-latest = final: prev: {
    pkgs-latest = import inputs.nixpkgs-latest {
      inherit (prev.stdenv) system;
      config = nixpkgsConfig;
    };
  };
}
