{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (builtins) readFile;
  inherit (lib.trivial) pipe;
  inherit (config) user host modules;
  inherit (host) darwin;
  cfg = modules.programs.mpv;
  pwd = "${host.config-dir}/modules/common/programs/mpv";
in {
  options.modules.programs.mpv = {
    enable = mkBoolOpt modules.desktop.enable;
    vapoursynth = mkBoolOpt (cfg.enable && pkgs.system != "aarch64-linux");
    extraConf = mkOpt types.str "";
    svp = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      # customize mpv build for plugins and vapoursynth-mvtools
      # mpv from pkgs-stable
      (final: prev:
        let
          mpvOpts = {
            scripts = with final.mpvScripts;
              [
                autoload
                mpv-playlistmanager
                # videoclip
                # cutter
                # thumbnail
                thumbfast
                uosc
              ] ++ optionals (!darwin) [ convert mpris ];
            extraMakeWrapperArgs = optionals cfg.vapoursynth [
              "--prefix"
              "LD_LIBRARY_PATH"
              ":"
              "${final.vapoursynth-mvtools}/lib/vapoursynth"
              "--prefix"
              "VAPOURSYNTH_LIB"
              ":"
              "${final.vapoursynth}/lib/vapoursynth"
              "--prefix"
              "VAPOURSYNTH_MVTOOLS_LIB"
              ":"
              "${final.vapoursynth-mvtools}/lib/vapoursynth"
            ];
          };
          wrapMpv = mpv-unwrapped:
            final.pkgs-stable.wrapMpv mpv-unwrapped mpvOpts;
          withVS = mpv-unwrapped:
            mpv-unwrapped.override { vapoursynthSupport = cfg.vapoursynth; };
          unwrapped = withVS final.mpv-unwrapped;
        in {
          mpv = pipe unwrapped [ wrapMpv (optimize config) ];
          mpv-unwrapped-bin = final.runCommand "mpv-unwrapped" { } ''
            mkdir -p $out/bin
            ln -s ${unwrapped}/bin/mpv $out/bin/mpv-unwrapped
          '';
          vapoursynth = final.pkgs-stable.vapoursynth;
          vapoursynth-mvtools = final.pkgs-stable.vapoursynth-mvtools;
        })
    ];

    home-manager.users.${user.name} = { config, pkgs, ... }:
      let
        link = config.lib.file.mkOutOfStoreSymlink;
        mpvExtraDarwin = optionalString darwin (''
          icc-profile-auto
          icc-force-contrast=300
        '' + optionalString (cfg.svp && !cfg.vapoursynth) ''
          input-ipc-server=/tmp/mpvsocket
        '');
        mpvExtraVapoursynth = lib.optionalString cfg.vapoursynth ''
          vf=format=yuv420p,vapoursynth=~~/motioninterpolation.vpy:8:12
        '';
        inputExtraVapoursynth = lib.optionalString cfg.vapoursynth ''
          Ctrl+i vf toggle format=yuv420p,vapoursynth=~~/motioninterpolation.vpy:8:12
        '';
        mpvRateSh = "${user.home}/bin.local/mpv-rate.sh";
        runMpvRate = arg: ''
          Ctrl+${arg} run "${mpvRateSh}" "''${filename}" "''${working-directory}" "''${path}" "${arg}"
        '';
        inputExtraMpvRate =
          foldl' (c: arg: c + runMpvRate (toString arg)) "" (range 1 5);
        mpvExtra = mpvExtraDarwin + mpvExtraVapoursynth;
        inputExtra = inputExtraVapoursynth + inputExtraMpvRate;
      in {
        home.packages = with pkgs;
          [ mpv mpv-unwrapped-bin ffmpeg ] # \
          ++ optionals (!darwin) [ mpvc celluloid ]
          ++ optionals cfg.vapoursynth [ vapoursynth vapoursynth-mvtools ];

        xdg.configFile = {
          "mpv/mpv.conf".text = (readFile ./mpv.conf) + mpvExtra
            + cfg.extraConf;
          "mpv/input.conf".text = (readFile ./input.conf) + inputExtra;
          "mpv/script-opts/stats.conf".source =
            link "${pwd}/script-opts/stats.conf";
          "mpv/lua-settings/mpv_thumbnail_script.conf".text =
            replaceStrings [ "__CACHE_DIR__" ]
            [ "${user.home}/.cache/mpv-thumbnail" ]
            (readFile ./lua-settings/mpv_thumbnail_script.conf);
          "mpv/motioninterpolation.vpy".source =
            link "${pwd}/motioninterpolation.vpy";
        };
      };
  };
}
