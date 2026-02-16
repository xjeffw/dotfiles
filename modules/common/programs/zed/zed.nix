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
    ;
  inherit (host) darwin;
  cfg = modules.programs.zed;
  pwd = "${host.config-dir}/modules/common/programs/zed";
in
{
  options = {
    modules.programs.zed = {
      enable = mkBoolOpt true;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} =
      { config, pkgs, ... }:
      let
        _link = config.lib.file.mkOutOfStoreSymlink;
      in
      {
        home.packages = with pkgs; [
          (if darwin then zed-editor else zed-editor-fhs)
        ];
      };
  };
}
