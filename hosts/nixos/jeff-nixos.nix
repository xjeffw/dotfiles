{
  config,
  options,
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}:
with lib;
let
  getMesaPkgs =
    pkgsBase: with pkgsBase; [
      libvdpau-va-gl
      libva
      libvdpau
      libva-vdpau-driver
    ];
  mesaPkgs = getMesaPkgs pkgs ++ (with pkgs; [ rocmPackages.clr.icd ]);
  mesaPkgs32 = getMesaPkgs pkgs.pkgsi686Linux;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = {
    host.optimize = true;
    modules = {
      linux.systemd-boot.enable = true;
      dev.enable-all = true;
      vfio.enable = true;
      desktop.enable = true;
      # desktop.amdgpu-fan = true;
      desktop.hyprland.extraConf = ''
        input {
            sensitivity = -0.5
            kb_options = ctrl:nocaps
        }
      '';
      desktop.hyprland.flake = false;
      programs.firefox.profilePath = "wandke3d.default-1713652437057";
      programs.mpv.extraConf = ''
        vo=gpu
        gpu-context=waylandvk
        gpu-api=vulkan
      '';
      services.protonmail.enable = true;
      services.protonvpn = {
        enable = false;
        configFile = "/private/wg-quick/protonvpn-jeff-nixos-1-US-NY-290.conf";
      };
      services.mpd = {
        enable = true;
        musicDirectory = "/mnt/huge/Music";
      };
    };

    services.ddclient.enable = true;
    services.ddclient.configFile = "/private/ddclient.conf";
    services.ddclient.interval = "1h";

    # services.deluge.enable = true;
    # services.deluge.web.enable = true;

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      virtualHosts."localhost" = {
        listen = [
          {
            addr = "localhost";
            port = 80;
          }
        ];
        locations."/" = {
          proxyPass = "http://localhost:8199";
          proxyWebsockets = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      linux-firmware
      libguestfs
      # ansel # darktable
      amdgpu_top
      # input-leap_git
      # waynergy_git
    ];

    environment.etc = {
      "machines/win10.xml".source = ./libvirt/win10.xml;
    };

    ## create virtual proxy devices for usb devices passed to qemu
    ## - this is needed so that qemu "-object input-linux,evdev=..." won't break
    ##   if the host device is temporarily disconnected
    services.persistent-evdev = {
      enable = true;
      devices = {
        persist-keyboard0 = "usb-Topre_Corporation_HHKB_Professional-event-kbd";
        persist-mouse0 = "usb-SteelSeries_SteelSeries_Prime_Mini_Wireless-event-mouse";
        persist-mouse1 = "usb-SteelSeries_SteelSeries_Prime_Mini_Wireless-event-if02";
        persist-mouse2 = "usb-SteelSeries_SteelSeries_Prime_Mini_Wireless-if01-event-kbd";
        persist-steam0 = "usb-Valve_Software_Steam_Controller-event-mouse";
      };
    };

    virtualisation.libvirtd.qemu.verbatimConfig = ''
      cgroup_device_acl = [
        "/dev/null",
        "/dev/full",
        "/dev/zero",
        "/dev/random",
        "/dev/urandom",
        "/dev/ptmx",
        "/dev/kvm",
        "/dev/kqemu",
        "/dev/rtc",
        "/dev/hpet",
        "/dev/tpm0",
        "/dev/input/by-id/uinput-persist-keyboard0",
        "/dev/input/by-id/uinput-persist-mouse0",
        "/dev/input/by-id/uinput-persist-mouse1",
        "/dev/input/by-id/uinput-persist-mouse2",
        "/dev/input/by-id/uinput-persist-steam0"
      ]

      namespaces = []
    '';

    networking.interfaces.enp6s0.useDHCP = true;
    networking.bridges.br0.interfaces = [ "enp6s0" ];
    networking.dhcpcd.enable = true;
    networking.dhcpcd.allowInterfaces = [ "br0" ];
    systemd.services.br0-netdev.wantedBy = [ "multi-user.target" ];
    networking.extraHosts = ''
      127.0.0.1       localhost
    '';

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/77f52a6d-7ee3-44c8-ade9-0628efb1b63f";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/644B-90E7";
        fsType = "vfat";
      };
      "/mnt/arch" = {
        device = "/dev/disk/by-label/arch_os_nvme";
        neededForBoot = true;
        fsType = "ext4";
      };
      "/nix" = {
        device = "/mnt/arch/nix";
        depends = [
          "/"
          "/mnt/arch"
        ];
        neededForBoot = true;
        fsType = "none";
        options = [ "bind" ];
      };
    };

    boot.kernelPackages = pkgs.linuxPackages;
    # boot.kernelPackages = pkgs.linuxPackages_zen;
    # boot.kernelPackages = pkgs.linuxPackages_latest;
    # boot.kernelPackages = pkgs.linuxPackages_6_6;
    # boot.kernelPackages = pkgs.linuxPackages_lqx;
    # boot.kernelPackages = pkgs.linuxPackages_cachyos;

    boot.kernelModules = [
      "kvm-amd"
      "i2c_dev"
    ];
    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    boot.initrd.kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "vfio_pci_core"
      "irqbypass"
      "iommufd"
      "amdgpu"
    ];
    boot.blacklistedKernelModules = [
      "nouveau"
      "nvidia"
    ];
    boot.kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "rd.driver.pre=vfio-pci"
      # "hugepagesz=1G"
      # "default_hugepagesz=1G"
      # "hugepages=17"
      "vfio-pci.ids=10de:2783,10de:22bc,1912:0014"
      "vfio-pci.disable_vga=1"
      # "vfio-pci.disable_idle_d3=1"
      # "pcie_aspm=off"
      "kvm.ignore_msrs=1"
      "kvm.report_ignored_msrs=0"
      "kvm_amd.nested=0"
      "mitigations=off"
    ];

    hardware.cpu.amd.updateMicrocode = true;
    hardware.enableAllFirmware = true;

    hardware.graphics = {
      enable = true;
      extraPackages = mesaPkgs;
      extraPackages32 = mesaPkgs32;
    };

    hardware.amdgpu = {
      opencl.enable = true;
    };

    nix.settings.max-jobs = 3;
    nix.settings.cores = 16;

    ### autogenerated by installer, do not edit
    system.stateVersion = "22.11";
  };
}
