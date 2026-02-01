{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  inherit (lib.my) mkBoolOpt optimize;
  inherit (config) user host modules;
  inherit (user) home;
  inherit (host) config-dir darwin;
  pwd = "${config-dir}/modules/common";
in
{
  options = {
    modules.guix.enable = mkBoolOpt false;
  };

  config = {
    nixpkgs.config.permittedInsecurePackages = [
      "nodejs-10.24.1"
      "nodejs-12.22.12"
      "python-2.7.18.6"
    ];

    environment.systemPackages = with pkgs; [
      cachix
      home-manager
    ];

    home-manager.users.${user.name} =
      { config, pkgs, ... }:
      let
        link = config.lib.file.mkOutOfStoreSymlink;
      in
      {
        home.sessionPath = [
          "${home}/bin.local"
          "${home}/bin"
          "${home}/.cargo/bin"
          "${home}/.npm-global/bin"
        ];

        home.file."bin/".source = link "${config-dir}/bin";
        home.file.".tmux.conf".source = ./tmux.conf;
        xdg.configFile."htop/htoprc".source = link "${pwd}/htoprc";
        xdg.configFile."bat/config".source = link "${pwd}/bat.config";

        programs.htop.enable = true;
        programs.htop.package = optimize config pkgs.htop;
        programs.gpg.enable = true;

        programs.imv.enable = !darwin;
        # programs.pqiv.enable = !darwin;

        home.packages =
          with pkgs;
          let
            core = [
              (optimize config fd)
              (optimize config lsd)
              curl
              entr
              expect
              gnugrep
              gnused
              inetutils
              jq
              procs
              tmux
              w3m
              wget
            ];
            tools = [
              autossh
              babashka
              bat
              glow
              gpg-tui
              graphicsmagick
              graphicsmagick-imagemagick-compat
              jc
              ncdu
              nushell
              pass
              python3Packages.markdownify
              ripgrep
              speedtest-rs
              tree
              yt-dlp
            ];
            compression = [
              p7zip
              unrar
              unzip
              xz
              zip
            ];
            nix-tools = [
              comma
              rippkgs
            ];
            fetch = [
              fastfetch
              inxi
              neofetch
              screenfetch
            ];
            media = [
              greg
              mediainfo
            ];
            games = [ nethack ];
            ai = [
              aichat
              aider-chat
              mods
              tgpt
            ];
            matrix = [
              cmatrix
              tmatrix
              unimatrix
            ];
            extra = [
              asciinema
              asciinema-agg
              termtosvg
              timg
            ];
            sounds = [
              sound-theme-freedesktop
              pantheon.elementary-sound-theme
            ];
            guix-pkgs = optionals (modules.guix.enable) [ guix ];
          in
          core
          ++ tools
          ++ compression
          ++ nix-tools
          ++ fetch
          ++ media
          ++ games
          ++ ai
          ++ matrix
          ++ extra
          ++ sounds
          ++ guix-pkgs;
      };
  };
}
