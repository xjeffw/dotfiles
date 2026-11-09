{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (config) modules;
  cfg = modules.services.protonvpn;
in {
  options.modules.services.protonvpn = with types; {
    enable = mkBoolOpt (cfg.configFile != null);
    configFile = mkOpt (nullOr str) null;
    port = mkOpt (nullOr int) 51820;
    natpmp = {
      enable = mkBoolOpt true;
      gateway = mkOpt str "10.2.0.1";
    };
  };

  config = mkIf (cfg.enable && (cfg.configFile != null)) {
    networking.wg-quick.interfaces.wg0.configFile = cfg.configFile;

    networking.firewall.trustedInterfaces = [ "virbr0" ];

    networking.firewall.allowedUDPPorts =
      optionals (cfg.port != null) [ cfg.port ];
    networking.firewall.allowedTCPPorts =
      optionals (cfg.port != null) [ cfg.port ];

    networking.resolvconf.extraConfig = ''
      search_domains_append=mynetworksettings.com
      name_servers_append=192.168.1.1
    '';

    services.dnsmasq = {
      enable = true;
      settings = ({
        server = [ "10.2.0.1" "/lan/192.168.1.1" ];
      } // (mkIf config.virtualisation.libvirtd.enable {
        # prevent conflict with libvirtd's dnsmasq
        interface = "br0";
        bind-interfaces = true;
      }));
    };

    # Keep a NAT-PMP port forward open on the VPN server. Bound to the
    # wg-quick unit so it starts with the VPN and stops when it goes down.
    systemd.services.natpmpc = mkIf cfg.natpmp.enable {
      description = "NAT-PMP port forwarding for ProtonVPN";
      bindsTo = [ "wg-quick-wg0.service" ];
      after = [ "wg-quick-wg0.service" ];
      wantedBy = [ "wg-quick-wg0.service" ];
      path = [ pkgs.libnatpmp pkgs.gnused ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 10;
      };
      script = ''
        gw=${cfg.natpmp.gateway}
        last=""
        parse() { sed -n 's/^Mapped public port \([0-9]*\) .*/\1/p'; }
        while true; do
          if udp=$(natpmpc -a 1 0 udp 60 -g "$gw") &&
             tcp=$(natpmpc -a 1 0 tcp 60 -g "$gw"); then
            udp_port=$(parse <<< "$udp")
            tcp_port=$(parse <<< "$tcp")
            current="udp=$udp_port tcp=$tcp_port"
            if [ "$current" != "$last" ]; then
              echo "NAT-PMP assigned port: $tcp_port ($current)"
              last=$current
            fi
          else
            echo "ERROR with natpmpc command" >&2
            last=""
          fi
          sleep 45
        done
      '';
    };

    environment.systemPackages = with pkgs; [
      wireguard-tools
      libnatpmp
      dnsmasq
    ];
  };
}
