{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.my;
let
  inherit (config) user host;
  inherit (host) darwin;
  cfg = config.modules.dev;
in
{
  options.modules.dev = {
    enable = mkBoolOpt true;
    enable-all = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = optionals (!darwin) [ inputs.nil-server.overlays.nil ];

    home-manager.users.${user.name} = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      home.packages =
        with pkgs;
        [
          babashka
          bun
          direnv
          editorconfig-checker
          editorconfig-core-c
          gnumake
          nil
          ninja
          nix-init
          nixfmt
          nodePackages.stylelint
          nodePackages.prettier
          nodejs_latest
          rbenv
          shellcheck
          shfmt
        ]
        ++ (with pkgs.pkgs-latest; [
          claude-code
          codex
          gemini-cli
        ])
        ++ optionals (!darwin) [ gcc ]
        ++ optionals (host.gui) [ python3Packages.grip ]
        ++ optionals (!host.minimal) [
          cmake
          nixd
          openai
          reg
          regctl
          skopeo
          subversion
        ]; # ++ optionals (pkgs.system != "aarch64-linux" && !host.minimal)
      # [ semgrep ];
    };
  };
}
