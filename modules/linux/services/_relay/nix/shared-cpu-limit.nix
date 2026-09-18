# Import into the NixOS configuration, then set relay.sharedCpuLimit.users.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.relay.sharedCpuLimit;
  helper = pkgs.writeScriptBin "relay-cpu-group" (
    lib.replaceStrings [ "#!/usr/bin/python3 -I" ] [ "#!${pkgs.python3}/bin/python3 -I" ] (
      builtins.readFile ../contrib/relay-cpu-group.py
    )
  );
in
{
  options.relay.sharedCpuLimit.users = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Users allowed to attach their Relay workers to the shared Nix CPU slice.";
  };
  config = lib.mkIf (cfg.users != [ ]) {
    environment.systemPackages = [ helper ];
    systemd.slices.relaywork.description = "Shared CPU budget for Nix and Relay workers";
    systemd.services.nix-daemon.serviceConfig.Slice = "relaywork.slice";
    systemd.services."relay-workers@" = {
      description = "Delegated Relay CPU groups for UID %i";
      serviceConfig = {
        Type = "simple";
        User = "%i";
        Slice = "relaywork.slice";
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
            command = "${helper}/bin/relay-cpu-group";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
