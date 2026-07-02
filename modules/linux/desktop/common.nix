{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (config) user modules;
  cfg = config.modules.desktop;
  amdgpu-fan = pkgs.python3Packages.callPackage ./_amdgpu-fan.nix { };
  browser = (if modules.programs.firefox.default then
    "firefox.desktop"
  else
    "chromium.desktop");
in {
  options.modules.desktop = {
    enable = mkBoolOpt false;
    gnome.enable = mkBoolOpt cfg.enable;
    gnome.services.enable = mkBoolOpt false;
    qt = mkBoolOpt false;
    amdgpu-fan = mkBoolOpt false;
    steam = mkBoolOpt (pkgs.system != "aarch64-linux");
  };

  config = mkIf cfg.enable {
    host.gui = true;

    # services.tailscale.enable = true;

    xdg.mime.defaultApplications = {
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/unknown" = browser;
    };

    nixpkgs.overlays = optional cfg.gnome.enable (final: prev: {
      nautilus = prev.nautilus.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ (with prev.gst_all_1; [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
          prev.ffmpegthumbnailer
        ]);
      });
    });

    fonts.enableDefaultPackages = true;
    fonts.fontDir.decompressFonts = true;

    environment.systemPackages = with pkgs;
      [ gparted vulkan-tools libva-utils vdpauinfo clinfo ]
      ++ optional cfg.amdgpu-fan amdgpu-fan
      ++ optional (pkgs.system == "x86_64-linux") wine;

    systemd.services.amdgpu-fan = mkIf cfg.amdgpu-fan {
      enable = true;
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${amdgpu-fan}/bin/amdgpu-fan";
      };
    };

    xdg.mime.enable = true;

    console = {
      earlySetup = false;
      keyMap = "us";
      packages = with pkgs; [ terminus_font ];
      font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    };

    services.logind.settings.Login = {
      # don’t shutdown when power button is short-pressed
      HandlePowerKey = "ignore";
    };

    users.extraUsers.root.extraGroups =
      [ "audio" "input" "plugdev" "libvirtd" ];

    programs.dconf.enable = true;
    security.rtkit.enable = true;
    security.polkit.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    programs.gnome-disks.enable = cfg.gnome.enable;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
      browsing = true;
      webInterface = true;
    };

    services.gnome = mkIf cfg.gnome.services.enable {
      tracker.enable = true;
      tracker-miners.enable = true;
      sushi.enable = true;
    };

    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = mkDefault true;
      pulse.enable = true;
    };

    services.redshift = {
      enable = false;
      package = pkgs.gammastep;
      executable = "/bin/gammastep";
      temperature.day = 6250;
      temperature.night = 5750;
    };

    location = {
      provider = "manual";
      latitude = 38.98465;
      longitude = -77.094711;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    programs.steam = {
      enable = cfg.steam;
      # remotePlay.openFirewall = true;
      # dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      # gamescopeSession.package = pkgs.gamescope_git;
    };

    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
      lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
      ]);

    environment.sessionVariables.XCURSOR_THEME = "capitaine-cursors-white";
    environment.sessionVariables.XCURSOR_SIZE = "24";
    environment.sessionVariables.FREETYPE_PROPERTIES =
      "truetype:interpreter-version=38";

    home-manager.users.${user.name} = { config, pkgs, ... }:
      let
        gnomePackages = with pkgs;
          optionals cfg.gnome.enable [
            baobab
            dconf-editor
            eog
            evince
            ffmpegthumbnailer
            file-roller
            gedit
            gjs
            glib
            # gnome-podcasts
            gnome-usage
            gobject-introspection
            gthumb
            gtk3
            gtk4
            libadwaita
            libpulseaudio
            nautilus
            # themechanger
            # totem
          ];
        qtPackages = with pkgs;
          optionals cfg.qt [ qt5.full qt5.qtwayland qt5ct adwaita-qt ];
        cli = with pkgs;
          [
            # cava
            ddcutil
            keyd
            libinput
            libnotify
            ncpamixer
            pamixer
            playerctl
            slack-term
            usbutils
            xdg-user-dirs
          ] ++ [
            acpi
            exfat
            glib
            kernelshark
            linuxPackages.cpupower
            lm_sensors
            pciutils
            smartmontools
          ];
        gui = with pkgs;
          [ pinentry-rofi pavucontrol ]
          ++ optionals (pkgs.system == "x86_64-linux") [ slack ]
          ++ optionals cfg.steam [ steamcmd steam-tui ];
        x11 = with pkgs; [
          mesa-demos
          xev
          xkbcomp
          xkill
          xprop
          xrandr
          xrdb
          xset
          xwininfo
          xterm
        ];
        themes = with pkgs;
          [ vivid ] ++ [
            adw-gtk3
            capitaine-cursors
            # catppuccin-cursors
            # papirus-icon-theme
            catppuccin-papirus-folders
            catppuccin-sddm-corners
            adwaita-icon-theme
            gnome-icon-theme
          ] ++ optionals modules.desktop.qt
          [ plasma5Packages.qtstyleplugin-kvantum ];
        catppuccin-mocha = (pkgs.catppuccin-gtk.override {
          variant = "mocha";
          size = "compact";
          tweaks = [ "rimless" ];
        });
        catppuccin-macchiato = (pkgs.catppuccin-gtk.override {
          variant = "macchiato";
          size = "compact";
          tweaks = [ "normal" ];
        });
        catppuccin = [ pkgs.catppuccin catppuccin-mocha catppuccin-macchiato ];
        gammastep = [ pkgs.gammastep ];
      in {
        home.packages = gnomePackages ++ qtPackages ++ cli ++ gui ++ themes
          ++ x11 ++ catppuccin ++ gammastep;

        services.easyeffects = { enable = true; };
        services.pass-secret-service.enable = true;
        # services.gnome-keyring.enable = true;
        # services.gnome-keyring.components = [ "secrets" ];
        # services.udiskie.enable = true;

        gtk = {
          enable = true;
          font.name = "sans";
          font.size = 11;
          cursorTheme.name = "capitaine-cursors-white";
          cursorTheme.package = pkgs.capitaine-cursors;
          cursorTheme.size = 24;
          iconTheme.name = "Papirus";
          iconTheme.package = pkgs.catppuccin-papirus-folders;
          gtk4.theme = config.gtk.theme;
          # theme.name = "Catppuccin-Macchiato-Compact-Blue-Dark";
          # theme.package = catppuccin-macchiato;

          theme.name = "adw-gtk3-dark";
          theme.package = pkgs.adw-gtk3;

          # gtk4.extraConfig = { gtk-theme-name = "Adwaita"; };

          gtk3.bookmarks = [
            "file:///home/${user.name}/Downloads"
            "file:///home/jeff/code"
            "file:///mnt/huge/TV%20Shows"
            "file:///mnt/huge/Movies"
            "file:///mnt/huge/Torrents"
            "file:///mnt/huge/Youtube"
            "file:///mnt/huge/files"
          ];
        };

        home.file.".Xresources.d".source = ./Xresources.d;
        home.file.".Xresources".source =
          ./Xresources.d/.Xresources.TomorrowNight;
        xdg.configFile."cava/config".source = ./cava/config;

        qt = {
          enable = true;
        } // mkIf cfg.gnome.enable {
          platformTheme = "gnome";
          style.name = "adwaita-dark";
          style.package = pkgs.adwaita-qt;
        };
      };
  };
}
