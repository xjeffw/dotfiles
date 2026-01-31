{
  description = "Personal system config (nixos, nix-darwin)";

  inputs = {
    ### System
    # nixpkgs.url = "github:NixOS/nixpkgs/c5ae371f1a6a7fd27823";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-2311.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nixpkgs-latest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    # nixos-apple-silicon.url =
    #   "github:marcin-serwin/nixos-apple-silicon/push-nwvktpxoswts";
    # nixos-apple-silicon.inputs.rust-overlay.follows = "rust-overlay";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ### Nix helpers
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    ### Additional sources
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    ags.url = "github:jeffwkm/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    ags.inputs.astal.follows = "astal";
    astal.url = "github:jeffwkm/astal";
    astal.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nil-server.url = "github:oxalica/nil";
    nil-server.inputs.nixpkgs.follows = "nixpkgs";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    # hyprland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }@inputs:
    let
      # extend lib with custom functions under lib.my
      lib = inputs.nixpkgs.lib.extend (final: prev: {
        my = import ./lib {
          inherit inputs;
          # - make nixpkgs.lib available within ./lib
          # - provide for references between files in ./lib
          lib = final;
        };
      });

      nixpkgsConfig = { allowUnfree = true; };

      overlays = import ./nix/overlays.nix { inherit inputs nixpkgsConfig; };

      mapHosts' = dir: system:
        lib.my.mapHosts dir {
          inherit system nixpkgsConfig self;
          overlays = lib.attrValues overlays;
        };
    in {
      inherit inputs lib;

      nixosConfigurations = (mapHosts' ./hosts/nixos "x86_64-linux")
        // (mapHosts' ./hosts/asahi "aarch64-linux");

      darwinConfigurations = mapHosts' ./hosts/darwin "aarch64-darwin";

      # define default home-manager configuration to support nixd completion
      homeConfigurations.default =
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit lib;
          pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
          modules = [
            ({ lib, config, ... }: {
              options =
                (import ./hosts/options.nix { inherit lib config; }).options;
              config = {
                home.username = "${config.user.name}";
                home.homeDirectory = "${config.user.home}";
                home.stateVersion = "24.05";
              };
            })
          ];
        };
    };
}
