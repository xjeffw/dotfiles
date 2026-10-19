# Import into the NixOS configuration, then set flux.sharedCpuLimit.users.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.flux.sharedCpuLimit;
  helper = pkgs.writeScriptBin "flux-cpu-group" (
    lib.replaceStrings [ "#!/usr/bin/python3 -I" ] [ "#!${pkgs.python3}/bin/python3 -I" ] (
      builtins.readFile ../contrib/flux-cpu-group.py
    )
  );
in
{
  options.flux.sharedCpuLimit.users = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Users allowed to attach their Flux workers to the shared Nix CPU slice.";
  };
  config = lib.mkIf (cfg.users != [ ]) {
    environment.systemPackages = [ helper ];
    systemd.slices.fluxwork.description = "Shared CPU budget for Nix and Flux workers";
    systemd.services.nix-daemon.serviceConfig.Slice = "fluxwork.slice";
    systemd.services."flux-workers@" = {
      description = "Delegated Flux CPU groups for UID %i";
      serviceConfig = {
        Type = "simple";
        User = "%i";
        Slice = "fluxwork.slice";
        Delegate = "cpu";
        DelegateSubgroup = "manager";
        ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
      };
    };
    security.sudo.extraRules = [
      {
        users = cfg.users;
        runAs = "root";
        commands = [
          {
            command = "${helper}/bin/flux-cpu-group";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
