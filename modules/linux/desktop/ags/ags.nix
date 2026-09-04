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
  cfg = modules.desktop.ags;
  ags-pkgs = inputs.ags.packages.${pkgs.system};
in
{
  options.modules.desktop.ags = {
    enable = mkBoolOpt modules.desktop.hyprland.enable;
  };

  config = mkMerge [
    (mkIf modules.desktop.quickshell.enable {
      modules.desktop.ags.enable = mkForce false;
    })
    (mkIf cfg.enable {
      nix.registry.ags.flake = inputs.ags;

      home-manager.users.${user.name} =
        { pkgs, ... }:
        {
          imports = [ inputs.ags.homeManagerModules.default ];

          home.packages =
            (with pkgs; [ sass ])
            ++ (with ags-pkgs; [
              io
              notifd
              tray
            ]);

          programs.ags = {
            enable = true;
            configDir = null;
            package = ags-pkgs.agsFull;
            extraPackages = (
              with ags-pkgs;
              [
                battery
                cava
                hyprland
                io
                mpris
                notifd
                tray
                wireplumber
              ]
            );
          };

          systemd.user.services.ags = {
            Unit = {
              Description = "AGS status bar for Wayland";
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              Type = "simple";
              ExecCondition = ''${pkgs.bash}/bin/sh -c '[ -n "$WAYLAND_DISPLAY" ]' '';
              WorkingDirectory = "${user.home}/.config/ags2";
              ExecStart = "${pkgs.bash}/bin/bash ./dev";
            };
          };
        };
    })
  ];
}
