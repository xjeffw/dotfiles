{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.my;
let
  inherit (config) user host modules;
  cfg = modules.desktop.niri;
  pwd = "${host.config-dir}/modules/linux/desktop/niri";
in
{
  options.modules.desktop.niri = {
    enable = mkBoolOpt modules.desktop.enable;
    extraConf = mkOpt types.str "";
  };

  config = mkIf cfg.enable {
    programs.niri.enable = true;
    # programs.niri enables gnome-keyring by default, which also swaps the
    # ssh-agent socket for gcr-ssh-agent; keep the existing setup.
    services.gnome.gnome-keyring.enable = mkOverride 999 false;

    environment.systemPackages = with pkgs; [
      hypridle
      hyprlock
      swaybg
      xwayland-satellite
    ];

    home-manager.users.${user.name} =
      { config, pkgs, ... }:
      let
        link = path: config.lib.file.mkOutOfStoreSymlink "${pwd}/${path}";
      in
      {
        xdg.configFile."niri/config.kdl".source = link "config.kdl";
        xdg.configFile."niri/hypridle.conf".source = link "hypridle.conf";
        xdg.configFile."niri/extra.kdl".text = cfg.extraConf;

        # started by spawn-sh-at-startup in config.kdl
        systemd.user.targets.niri-session = {
          Unit = {
            Description = "Niri compositor session";
            BindsTo = [ "graphical-session.target" ];
          };
        };

        systemd.user.services.avizo.Install.WantedBy = mkIf modules.desktop.avizo.enable [
          "niri-session.target"
        ];

        systemd.user.services.lxqt-policykit-agent.Install.WantedBy = mkIf modules.desktop.enable [
          "niri-session.target"
        ];

        systemd.user.services.niri-hypridle = {
          Unit = {
            Description = "Idle manager for niri compositor";
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "niri-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.hypridle}/bin/hypridle -c ${config.xdg.configHome}/niri/hypridle.conf";
            Restart = "always";
            RestartSec = 60;
            SyslogLevel = "debug";
          };
        };

        systemd.user.services.niri-swaybg = {
          Unit = {
            Description = "Wallpaper service for niri";
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "niri-session.target" ];
          };
          Service = {
            Type = "simple";
            # same wallpapers as hyprpaper.conf
            ExecStart = concatStringsSep " " [
              "${pkgs.swaybg}/bin/swaybg"
              "-o HDMI-A-1 -m fill -i %h/.config/hypr/wallpapers/code-monitor-closeup.png"
              "-o '*' -m fill -i %h/.config/hypr/wallpapers/wall2.png"
            ];
            Restart = "always";
            RestartSec = 5;
          };
        };
      };
  };
}
