{ config, lib, ... }:
with lib;
with lib.my;
let
  inherit (config) user host modules;
  cfg = config.modules.desktop.mako;
  pwd = "${host.config-dir}/modules/linux/desktop";
in
{
  options.modules.desktop.mako = {
    enable = mkBoolOpt modules.desktop.sway.enable;
  };

  config = mkMerge [
    (mkIf modules.desktop.quickshell.enable {
      modules.desktop.mako.enable = mkForce false;
    })
    (mkIf cfg.enable {
      home-manager.users.${user.name} =
        { config, pkgs, ... }:
        {
          home.packages = [ pkgs.mako ];

          xdg.configFile."mako/config".source = config.lib.file.mkOutOfStoreSymlink "${pwd}/_mako.config";

          systemd.user.services.mako = {
            Unit = {
              Description = "Mako notification daemon";
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              Type = "dbus";
              BusName = "org.freedesktop.Notifications";
              ExecCondition = ''${pkgs.bash}/bin/sh -c '[ -n "$WAYLAND_DISPLAY" ]' '';
              ExecStart = "${pkgs.mako}/bin/mako";
              ExecReload = "${pkgs.mako}/bin/makoctl reload";
            };
          };
        };
    })
  ];
}
