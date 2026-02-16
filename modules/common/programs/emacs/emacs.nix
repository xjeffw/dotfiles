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
  inherit (config)
    user
    host
    modules
    theme
    ;
  inherit (host) darwin;
  inherit (pkgs) fetchpatch;
  cfg = modules.programs.emacs;
  pwd = "${host.config-dir}/modules/common/programs/emacs";

  emacsPkgs = (
    epkgs: with epkgs; [
      vterm
      all-the-icons
      treesit-grammars.with-all-grammars
      mu4e
      mu4e-alert
    ]
  );
  patches-url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30";
  emacs-base =
    optimizePkg
      {
        enable = host.optimize;
        level = 4;
        native = true;
      }
      (
        if darwin then
          pkgs.emacs30.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              # Fix OS window role so that yabai can pick up emacs
              # (fetchpatch {
              #   url = "${patches-url}/fix-window-role.patch";
              #   sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
              # })
              # Enable rounded window with no decoration
              (fetchpatch {
                url = "${patches-url}/round-undecorated-frame.patch";
                sha256 = "sha256-uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
              })
            ];
            configureFlags = (old.configureFlags or [ ]) ++ [ "LDFLAGS=-headerpad_max_install_names" ];
          })
        else if modules.desktop.enable then
          # pkgs.emacs30-pgtk # from nixpkgs
          pkgs.emacs-git-pgtk # from emacs-overlay
        else
          pkgs.emacs30-nox
      );
in
{
  options = {
    modules.programs.emacs = {
      enable = mkBoolOpt true;
      service.enable = mkBoolOpt cfg.enable;
      service.install = mkBoolOpt cfg.service.enable;
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.emacs-overlay.overlay
      (final: prev: { ripgrep = prev.ripgrep.override { withPCRE2 = true; }; })
      (final: prev: {
        ## note:
        ## emacsWithPackages [ mu4e ] -> mu.mu4e -> emacs -> emacsWithPackages ...
        ## build mu with original emacs package to avoid the infinite recursion
        mu = prev.mu.override { emacs = prev.emacs; };
        emacs = (prev.emacsPackagesFor emacs-base).emacsWithPackages emacsPkgs;
      })
    ];

    environment.systemPackages = with pkgs; [
      emacs
      xsel
      xclip
    ];

    home-manager.users.${user.name} =
      { config, pkgs, ... }:
      let
        link = config.lib.file.mkOutOfStoreSymlink;
      in
      {
        home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

        home.sessionVariables = {
          EMACSDIR = "${config.xdg.configHome}/emacs";
          DOOMDIR = "${config.xdg.configHome}/doom";
          EDITOR = "emacsclient -t -a emacs";
          VISUAL = "emacsclient -t -a emacs";
          LSP_USE_PLISTS = "true";
        };

        home.packages = with pkgs; [
          ripgrep
          sqlite
          editorconfig-core-c
          emacs-lsp-booster
          mu
          isync
          gnutls
          graphviz
          (aspellWithDicts (
            dicts: with dicts; [
              en
              en-computers
              en-science
            ]
          ))
        ];

        xdg.configFile = {
          "doom/".source = link "${pwd}/doom.d";
          "emacs.elpaca/".source = link "${pwd}/elpaca.d";

          "config-nix.el".text = ''
            (setq --window-opacity ${toString theme.windowOpacity})
          '';
        };
      };
  };
}
