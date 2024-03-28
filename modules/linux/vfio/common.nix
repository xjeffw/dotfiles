{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (config) user modules;
  cfg = modules.vfio;
in {
  options.modules.vfio = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      OVMF
      libvirt
      qemu
      qemu-utils
      scream
      virt-manager
    ];

    systemd.tmpfiles.rules = [
      "f /dev/shm/scream          0660 ${user.name} qemu-libvirtd -"
      "f /dev/shm/looking-glass   0660 ${user.name} qemu-libvirtd -"
    ];

    # (on libvirtd startup) set machine definitions from nix config
    systemd.services.vm-define = {
      enable = true;
      after = [ "libvirtd.service" ];
      # before = [ "libvirt-guests.service" ];
      wants = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        [ -d /etc/machines ] || exit 0
        for x in /etc/machines/*.xml ; do
          ${pkgs.libvirt}/bin/virsh define "$x" --validate
        done
      '';
    };

    systemd.services.libvirt-guests.after = [ "vm-define.service" ];

    systemd.user.services.scream = {
      enable = true;
      description = "Scream IVSHMEM";
      serviceConfig = {
        Type = "exec";
        ExecStart =
          "${pkgs.scream}/bin/scream -m /dev/shm/scream -o pulse -t 16 -v";
        Restart = "always";
        RestartSec = 60;
      };
      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 10;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "pipewire-pulse.service" ];
      bindsTo = [ "pipewire-pulse.service" ];
    };

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "start";
      onShutdown = "shutdown";
      qemu = {
        ovmf.enable = true;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    home-manager.users.${user.name} = { config, pkgs, ... }: { };
  };
}
