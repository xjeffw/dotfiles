{ config, options, pkgs, lib, inputs, modulesPath, ... }:
with lib;
with lib.my;
let inherit (config) user;
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = {
    modules = {
      linux.systemd-boot.enable = true;
      desktop.enable = false;
      dev.enable-all = true;
      programs.mpv.enable = true;
      programs.kitty.enable = true;
      services.protonvpn.configFile =
        "/private/wg-quick/protonvpn-US-NY-306.conf";
    };

    environment.systemPackages = with pkgs; [ linux-firmware ];

    networking.useDHCP = true;

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/47e5286f-f005-4c20-bc46-35f68059137b";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/08BB-C318";
        fsType = "vfat";
      };
      "/mnt/huge" = {
        device = "/dev/md127";
        fsType = "ext4";
      };
    };

    boot.initrd.availableKernelModules =
      [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];

    hardware.cpu.intel.updateMicrocode = true;
    hardware.enableAllFirmware = true;

    networking.firewall.enable = false;
    networking.firewall.allowedTCPPorts = [ ];
    networking.firewall.allowedUDPPorts = [ ];

    services.deluge.enable = false;
    services.deluge.web.enable = false;

    services.plex.enable = true;
    services.plex.dataDir = "/mnt/huge/jeff-home/var/lib/plex";

    users.users.${user.name}.extraGroups = [ "deluge" ];

    services.samba = {
      enable = true;
      settings = {
        global = {
          "disable netbios" = "yes";
          workgroup = "WORKGROUP";
          "server string" = "JEFF-HOME";
          "netbios name" = "JEFF-HOME";
          security = "user";
          # "use sendfile" = "yes";
          # "max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          # "hosts allow" = "127.0.0.1 localhost 192.168. 192.168.1.161 192.168.1.168";
          # "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        huge = {
          path = "/mnt/huge";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          # "force user" = "jeff";
          # "force group" = "users";
          "valid users" = "jeff";
          # "public" = "no";
          "writable" = "yes";
        };
      };
    };

    services.openvpn.servers = {
      # torguard = { config = "config /root/vpn/torguard.conf"; };
    };

    system.stateVersion = "22.11";
  };
}
