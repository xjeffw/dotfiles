{ config, lib, pkgs, inputs, ... }:
with lib;
with lib.my;
let
  inherit (config) user host modules;
  inherit (host) darwin;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  gui = (modules.desktop.enable && pkgs.system != "aarch64-linux");
  cfg = config.modules.programs.spotify;
in {
  options.modules.programs.spotify = {
    enable = mkBoolOpt modules.desktop.enable;
    spotifyd.enable = mkBoolOpt (!darwin);
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

      home.packages = with pkgs; [ spotify-player ncspot sptlrx ];

      # spotify-player requires a Spotify Premium account.
      # If you get "No playback found":
      # 1. Run `spotify_player`
      # 2. Press 'd' to open the device menu.
      # 3. Select your local device or the spotifyd daemon.
      xdg.configFile."spotify-player/app.toml".text = ''
        theme = "Catppuccin-mocha"
        enable_streaming = "Always"
        default_device = "${host.name}-daemon"

        [device]
        name = "${host.name}"
        device_type = "computer"
        audio_backend = "rodio"
        bitrate = 160
        audio_cache = true
        normalization = true
      '';

      # ncspot configuration
      xdg.configFile."ncspot/config.toml".text = ''
        backend = "pulseaudio"
        shuffle = true
        bitrate = 320

        [theme]
        background = "#1e1e2e"
        primary = "#cdd6f4"
        secondary = "#bac2de"
        title = "#cba6f7"
        playing = "#a6e3a1"
        playing_selected = "#a6e3a1"
        playing_bg = "#181825"
        highlight = "#cdd6f4"
        highlight_bg = "#585b70"
        error = "#f38ba8"
        error_bg = "#1e1e2e"
        statusbar = "#181825"
        statusbar_progress = "#fab387"
        statusbar_bg = "#fab387"
        cmdline = "#cdd6f4"
        cmdline_bg = "#1e1e2e"
        search_match = "#f9e2af"
      '';

      programs.spicetify = mkIf gui {
        enable = true;
        # theme = spicePkgs.themes.text;
        theme = spicePkgs.themes.catppuccin;
        # colorScheme = "macchiatto";
        enabledExtensions = with spicePkgs.extensions; [
          shuffle
          hidePodcasts
          keyboardShortcut
          powerBar
        ];
      };

      services.spotifyd = mkIf cfg.spotifyd.enable {
        enable = true;
        package = pkgs.spotifyd.override {
          withPulseAudio = true;
          withMpris = true;
        };
        # run `spotifyd auth` to store credentials to ~/.cache/spotifyd/oauth
        settings = {
          global = {
            device_name = "${host.name}-daemon";
            device_type = "computer";
            backend = "pulseaudio";
            volume_controller = "softvol";
            bitrate = 160;
            audio_format = "S16";
            zeroconf_port = 5353;
          };
        };
      };
    };
  };
}
