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
  inherit (config) user host modules;
  cfg = modules.desktop.niri;
  pwd = "${host.config-dir}/modules/linux/desktop/niri";
  # Fork adding wp_alpha_modifier_v1, which also fades blur behind a surface
  # (used by hyprshell's notification fade). Based on the release in nixpkgs,
  # so its cargo dependencies are unchanged.
  niri = pkgs.niri.overrideAttrs { src = inputs.niri-src; };
in
{
  options.modules.desktop.niri = {
    enable = mkBoolOpt modules.desktop.enable;
    extraConf = mkOpt types.str "";
  };

  config = mkIf cfg.enable {
    programs.niri.enable = true;
    programs.niri.package = niri;
    # programs.niri enables gnome-keyring by default, which also swaps the
    # ssh-agent socket for gcr-ssh-agent; keep the existing setup.
    services.gnome.gnome-keyring.enable = mkOverride 999 false;

    environment.systemPackages = with pkgs; [
      awww
      hypridle
      hyprlock
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

        systemd.user.services.niri-awww = {
          Unit = {
            Description = "Wallpaper daemon for niri";
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "niri-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.awww}/bin/awww-daemon";
            Restart = "always";
            RestartSec = 5;
          };
        };

        systemd.user.services.niri-wallpapers = {
          Unit = {
            Description = "Per-workspace wallpapers for niri";
            PartOf = [ "graphical-session.target" ];
            BindsTo = [ "niri-awww.service" ];
            After = [ "niri-awww.service" ];
          };
          Install = {
            WantedBy = [ "niri-session.target" ];
          };
          Service = {
            Type = "simple";
            Environment = [
              "PATH=${
                makeBinPath (
                  with pkgs;
                  [
                    awww
                    bash
                    coreutils
                    findutils
                    jq
                  ]
                  ++ [ niri ]
                )
              }"
            ];
            ExecStart = "%h/bin/niri-workspace-wallpapers.sh";
            Restart = "always";
            RestartSec = 5;
          };
        };
      };
  };
}
