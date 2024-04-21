{ config, lib, pkgs, ... }:
with lib;
let
  inherit (lib.my) mkBoolOpt;
  inherit (builtins) readFile;
  inherit (config) user modules;
  inherit (modules) programs;
  cfg = modules.linux;
in {
  options.modules.linux.systemd-boot.enable = mkBoolOpt false;

  config = {
    i18n.defaultLocale = mkDefault "en_US.UTF-8";
    time.timeZone = mkDefault "America/New_York";
    nix.settings.trusted-users = [ "root" "${user.name}" ];
    environment.pathsToLink = [ "/libexec" ];
    security.sudo.wheelNeedsPassword = false;
    system.autoUpgrade.enable = false;
    system.autoUpgrade.allowReboot = false;

    ## Increase open file limits
    ## Fixes various "too many open files" errors
    systemd.extraConfig = ''
      DefaultLimitNOFILE=1048576
      DefaultTimeoutStopSec=45
      DefaultIOAccounting=yes
    '';
    security.pam.loginLimits = [{
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }];
    boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 1164444;

    environment.sessionVariables = {
      SSH_AUTH_SOCK = "/run/user/1000/ssh-agent.socket";
      _GLOBAL_ENV_LOADED = "1";
    };

    services.dbus.enable = true;
    services.openssh.enable = true;
    services.openssh.ports = mkDefault [ 22 ];
    services.openssh.openFirewall = true;
    services.openssh.settings.PermitRootLogin = "prohibit-password";
    services.openssh.settings.PasswordAuthentication = true;
    services.openssh.settings.X11Forwarding = false;
    programs.mosh.enable = true;
    programs.fuse.userAllowOther = true;

    fileSystems."/mnt/huge" = mkDefault {
      device = "jeff@jeff-home:/mnt/huge";
      fsType = "fuse.sshfs";
      options = [
        "user"
        "noauto"
        "nodev"
        "suid"
        "exec"
        "allow_other"
        "idmap=user"
        "transform_symlinks"
        "IdentityFile=/home/jeff/.ssh/id_rsa"
        "reconnect"
        "noatime"
      ];
      noCheck = true;
    };

    # TODO: find out why this is necessary; this was recommended somewhere
    networking.firewall.allowedTCPPorts = [ 445 139 ]
      ++ optionals programs.spotify.enable [ 57621 ];
    networking.firewall.allowedUDPPorts = [ 137 138 ]
      ++ optionals programs.spotify.enable [ 5353 ];

    boot.loader = mkIf cfg.systemd-boot.enable {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      systemd-boot.enable = true;
      systemd-boot.consoleMode = "auto";
      systemd-boot.configurationLimit = 30;
    };

    users.extraUsers.${user.name} = {
      isNormalUser = true;
      home = "${user.home}";
      description = "${user.full-name}";
      extraGroups =
        [ "audio" "input" "users" "wheel" "video" "docker" "libvirtd" ];
      uid = 1000;
    };

    users.users.${user.name}.openssh.authorizedKeys.keys =
      [ (readFile ./id_rsa.pub) ];

    environment.systemPackages = with pkgs; [
      ananicy-cpp
      binutils
      coreutils
      curl
      file
      fscrypt-experimental
      inetutils
      iotop
      kmon
      libtool
      lsof
      mtr
      nix-index
      openssh
      openssl
      pinentry-curses
      pkg-config
      psmisc
      readline
      sshfs
      tcpdump
      tmux
      tomb
      wget
      xdg-utils
    ];
  };
}
