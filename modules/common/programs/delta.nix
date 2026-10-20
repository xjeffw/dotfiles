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
  cfg = modules.programs.delta;
in
{
  options.modules.programs.delta = {
    enable = mkBoolOpt (modules.desktop.enable && modules.dev.enable-all);
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = [
        # The bundled libxcb needs libXau/libXdmcp, which delta-nix's RPATH omits.
        (inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            for elf in "$out"/opt/delta/lib/libxcb*.so*; do
              if [ -f "$elf" ]; then
                ${pkgs.patchelf}/bin/patchelf --add-rpath \
                "${
                  lib.makeLibraryPath [
                    pkgs.libxau
                    pkgs.libxdmcp
                  ]
                }" "$elf"
              fi
            done
          '';
        }))
      ];
    };
  };
}
