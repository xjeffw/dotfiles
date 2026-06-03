{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let inherit (config) user host modules;
in {
  options.modules.desktop.gammastep = { enable = mkBoolOpt false; };

  config = mkIf modules.desktop.enable {
    nixpkgs.overlays = [
      (final: prev: {
        wl-clipboard-x11 = prev.stdenv.mkDerivation rec {
          pname = "wl-clipboard-x11";
          version = "5";

          src = prev.fetchFromGitHub {
            owner = "brunelli";
            repo = "wl-clipboard-x11";
            rev = "v${version}";
            sha256 = "1y7jv7rps0sdzmm859wn2l8q4pg2x35smcrm7mbfxn5vrga0bslb";
          };

          dontBuild = true;
          dontConfigure = true;
          propagatedBuildInputs = [ prev.wl-clipboard ];
          makeFlags = [ "PREFIX=$(out)" ];
        };

        xsel = final.wl-clipboard-x11;
        xclip = final.wl-clipboard-x11;
      })
    ];

    environment.systemPackages = with pkgs; [ xsel xclip ];

    environment.sessionVariables = {
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland-egl";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      ECORE_EVAS_ENGINE = "wayland-egl";
      ELM_ENGINE = "wayland_egl";
      SDL_VIDEODRIVER = "wayland";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };

    home-manager.users.${user.name} = { config, pkgs, ... }: {
      services.gammastep = mkIf modules.desktop.gammastep.enable {
        enable = true;
        provider = "manual";
        latitude = 39.02588;
        longitude = -77.15228;
        temperature.day = 6250; # 5800 6000 6200
        temperature.night = 6000; # 4800 5000 5200
      };

      systemd.user.services.lxqt-policykit-agent = {
        Unit = {
          Description = "polkit agent from lxqt";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
        };
      };

      home.packages = with pkgs; [
        egl-wayland
        hyprpicker
        hyprshot
        lxqt.lxqt-policykit
        mtr-gui
        wayland
        wayland-protocols
        wayland-utils
        wev
        wf-recorder
        wl-clipboard
        wlr-randr
        wtype
      ];
    };
  };
}
