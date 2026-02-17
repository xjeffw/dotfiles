{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let inherit (config) user host modules;
in {
  config = {
    services.pcscd.enable = true;

    home-manager.users.${user.name} = { config, pkgs, ... }: {
      systemd.user.services.ssh-agent = {
        Unit = { Description = "SSH key agent"; };
        Install = { WantedBy = [ "default.target" ]; };
        Service = {
          Type = "forking";
          Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
          ExecStart = "${pkgs.openssh}/bin/ssh-agent -a $SSH_AUTH_SOCK";
        };
      };

      systemd.user.services.ssh-add = {
        Unit = {
          Description = "SSH key add";
          Requires = [ "ssh-agent.service" ];
          After = [ "ssh-agent.service" ];
        };
        Install = { WantedBy = [ "default.target" ]; };
        Service = {
          Type = "oneshot";
          Environment = [
            "SSH_AUTH_SOCK=%t/ssh-agent.socket"
            "PATH=/run/current-system/sw/bin"
          ];
          ExecStart = "${pkgs.expect}/bin/expect -f %h/bin/do-ssh-add";
        };
      };

      systemd.user.services.emacs = mkIf modules.programs.emacs.service.enable {
        Unit = {
          Description = "Emacs daemon";
          After = [ "default.target" ];
        };
        Install = mkIf modules.programs.emacs.service.install {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.emacs}/bin/emacs --fg-daemon";
          Restart = "no";
          Environment = [ "EMACSDIR=%h/.config/emacs.elpaca" ];
        };
      };

      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = (60 * 60 * 24 * 7);
        maxCacheTtl = (60 * 60 * 24 * 7);
        enableSshSupport = false;
        pinentry.package =
          (if host.gui then pkgs.pinentry-rofi else pkgs.pinentry-curses);
      };
    };
  };
}
