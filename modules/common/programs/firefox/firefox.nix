{ config, lib, ... }:
with lib;
let
  inherit (lib.my) mkBoolOpt mkOpt;
  inherit (config) user host modules;
  cfg = config.modules.programs.firefox;
  pwd = "${host.config-dir}/modules/common/programs/firefox";
in {
  options.modules.programs.firefox = with types; {
    enable = mkBoolOpt modules.desktop.enable;
    default = mkBoolOpt true;
    profilePath = mkOpt (nullOr str) null;
    theme = mkOpt (nullOr str) null;
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = { config, pkgs, ... }:
      let link = config.lib.file.mkOutOfStoreSymlink;
      in {
        programs.firefox = {
          enable = true;
          configPath = "${config.xdg.configHome}/mozilla/firefox";
          profiles.default = mkIf (cfg.profilePath != null) {
            id = 0;
            name = "default";
            path = cfg.profilePath;
            isDefault = true;
            settings = {
              toolkit.legacyUserProfileCustomizations.stylesheets = true;
              layers.acceleration.force-enabled = true;
              gfx.webrender.all = true;
              svg.context-properties.content.enabled = true;
            };
          };
        };

        home.file = mkIf (cfg.profilePath != null && cfg.theme != null) {
          ".mozilla/firefox/${cfg.profilePath}/chrome".source =
            link "${pwd}/${cfg.theme}/chrome";
        };

        home.sessionVariables = mkIf cfg.default {
          BROWSER = "${pkgs.firefox}/bin/firefox";
          DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
        };
      };
  };
}
