{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (config) user host modules;
  inherit (modules) dev;
  inherit (host) darwin;
  cfg = config.modules.dev.extra;
in {
  options.modules.dev.extra = { enable = mkBoolOpt dev.enable-all; };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; optionals (!darwin) [ valgrind ];

    home-manager.users.${user.name} = {
      home.packages = with pkgs; [
        bash-language-server
        cmake-language-server
        gnuplot
        go
        html-tidy
        lessc
        mdformat
        mono
        pandoc
        sbcl
        roswell
        pueue
      ];
    };
  };
}
