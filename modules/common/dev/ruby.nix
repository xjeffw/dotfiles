{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (config) user modules;
  inherit (modules) dev;
  rubyPackages = (ps:
    with ps; [
      curses
      ffi
      gio2
      glib2
      gtk3
      native-package-installer
      pango
      pkg-config
      rake
    ]);
  rubyCustom = pkgs.pkgs-stable.ruby_3_3.withPackages rubyPackages;
  cfg = config.modules.dev.ruby;
in {
  options.modules.dev.ruby.enable = mkBoolOpt dev.enable-all;

  config = mkIf cfg.enable {
    environment.systemPackages = if cfg.enable then
      with pkgs; [
        (optimize config rubyCustom)
        ruby_3_3.devdoc
        rubocop
        rufo
        ruby-lsp
        solargraph
      ]
    else
      with pkgs; [ ruby ];
    home-manager.users.${user.name} = { };
  };
}
