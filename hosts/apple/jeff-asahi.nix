{ config, lib, pkgs, inputs, modulesPath, ... }:
with lib;
let inherit (config) user;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-apple-silicon.nixosModules.default
    # use hyprland from github
    inputs.hyprland.nixosModules.default
  ] ++ (with inputs.chaotic.nixosModules; [
    nyx-cache
    nyx-overlay
    # mesa-git
    # scx
    # zfs-impermanence-on-shutdown
  ]);

  config = {
    ## host options
    modules = {
      desktop.enable = true;
      dev.enable-all = true;
      wayland.enable = true;
      wayland.hyprland.enable = true;
      wayland.hyprland.extraConf = ''
        input {
            sensitivity = 0.0
            kb_options = ctrl:nocaps,altwin:swap_alt_win
        }
      '';
      programs.alacritty.enable = true;
      services.protonmail.enable = true;
      services.protonvpn.enable = false;
      services.protonvpn.configFile =
        "/private/wg-quick/protonvpn-1-US-VA-14.conf";
    };
    host.optimize = false;
    ## asahi system
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;
    nixpkgs.hostPlatform = "aarch64-linux";
    hardware.asahi.peripheralFirmwareDirectory = ./firmware;
    hardware.asahi.useExperimentalGPUDriver = true;
    services.pipewire.alsa.support32Bit = mkForce false;
    ## kernel
    boot.initrd.availableKernelModules = [ "usb_storage" "sdhci_pci" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.kernelParams = [ "mitigations=off" ];
    ## hardware
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/306067e8-7411-4be4-b50e-b88cf4fb8e4c";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/4117-15EC";
        fsType = "vfat";
      };
    };
    swapDevices = [ ];
    ## networking
    networking.wireless.iwd.enable = true;
    networking.wireless.iwd.settings.General.EnableNetworkConfiguration = true;
    networking.useDHCP = true;
    # networking.firewall.enable = false;

    ## no pkgs.spotify for aarch64-linux yet
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ spotify-player ];
    };

    ### autogenerated by installer, do not edit
    system.stateVersion = "24.05";
  };
}
