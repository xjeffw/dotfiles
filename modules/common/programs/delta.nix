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
  inherit (config) user modules;
  cfg = modules.programs.delta;
in
{
  options.modules.programs.delta = {
    enable = mkBoolOpt (modules.desktop.enable && modules.dev.enable-all);
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = [ inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta ];
    };
  };
}
