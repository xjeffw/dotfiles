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
  cfg = modules.desktop.quickshell;
  hyprshell = inputs.hyprshell.packages.${pkgs.stdenv.hostPlatform.system}.hyprshell;
  waylandDesktopEnabled = modules.desktop.hyprland.enable || modules.desktop.sway.enable;
in
{
  options.modules.desktop.quickshell.enable = mkBoolOpt true;

  config = mkIf (cfg.enable && waylandDesktopEnabled) {
    home-manager.users.${user.name} = {
      home.packages = [ hyprshell ];

      systemd.user.services.quickshell = {
        Unit = {
          Description = "HyprShell desktop shell for Wayland";
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy =
          optionals modules.desktop.hyprland.enable [ "hyprland-session.target" ]
          ++ optionals modules.desktop.sway.enable [ "sway-session.target" ];
        Service = {
          Type = "simple";
          ExecCondition = ''${pkgs.bash}/bin/sh -c '[ -n "$WAYLAND_DISPLAY" ]' '';
          ExecStart = "${hyprshell}/bin/hyprshell";
        };
      };
    };
  };
}
