{ inputs, nixpkgsConfig, ... }: {
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
}
