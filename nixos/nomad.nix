{ config, lib, pkgs, boot, ... }: {
    # Install packages
    environment = with pkgs; {
      systemPackages = [
        pkgs.nomad_1_6
        pkgs.consul
        pkgs.bzip2
        pkgs.gnupg
        pkgs.wget
        pkgs.curl
        pkgs.gnupg
        pkgs.nfs-utils
        pkgs.retry
        # pkgs.podman
        pkgs.docker
        pkgs.docker-compose
      ];
    };

    boot.kernel.sysctl = with boot; { 
      "net.bridge.bridge-nf-call-arptables" = "1"; 
      "net.bridge.bridge-nf-call-ip6tables" = "1"; 
      "net.bridge.bridge-nf-call-iptables" = "1"; 
    };

    services.consul.enable = true;

    networking.firewall = lib.mkMerge [
    { # Nomad And Consul
      allowedTCPPortRanges = [
        { from = 20000; to = 32000; } # Nomad: Port Allocation
        { from = 21000; to = 21255; } # Consul Sidecar Proxy
      ];

      allowedTCPPorts = [
        4646 # Nomad: API / UI
        4647 # Nomad: RCP API
        4648 # Nomad: WAN Gossip
        8300 # Consul: Server RPC
        8301 # Consul: LAN Serf
        8302 # Consul: WAN Serf
        8500 # Consul: HTTP
        8500 # Consul: HTTP
        8501 # Consul: HTTPS
        8502 # Consul: gRPC
        8503 # Consul: gRPC TLS
        8600 # Consul: DNS
        8600 # Consul: DNS
      ];

      allowedUDPPorts = [
        4647 # Noamd: RCP API
        4648 # Noamd: WAN Gossip
        8301 # Consul: LAN Serf
        8302 # Consul: WAN Serf
        8502 # Consul: gRPC
        8503 # Consul: gRPC TLS
        8600 # Consul: DNS
      ];

      allowedUDPPortRanges = [
        { from = 20000; to = 32000; } # Nomad: Port Allocation
        { from = 21000; to = 21255; } # Consul Sidecar Proxy
      ];
    }

    { # Apllication/Services 
      allowedTCPPorts = [
        # Application/services prots:
        53 # DNS / PiHole, AdGuard or Unbound
        80 # Traefik: HTTP
        443 # Traefik: HTTPS
        853 # DNS over TLS / QUIC
        8081 # Traefik
        1900 # Jellyfin DLNA / upnp
        7359 # Jellyfin autodiscovery
        7777 # Terraria
        5201 # Iperf 3
      ];

      allowedUDPPorts = [
        # Application/services prots:
        53 # DNS / PiHole, AdGuard or Unbound
        80 # Traefik HTTP
        443 # Traefik HTTPS
        853 # DNS over TLS / QUIC
        8081 # Traefik
        1900 # Jellyfin DLNA / upnp
        7359 # Jellyfin autodiscovery
        7777 # Terraria
        5201 # Iperf 3
        3478 # Steam Client
        4379 # Steam Client
        4380 # Steam Client
      ];

      allowedUDPPortRanges = [
        { from = 27000; to = 27100; } # Steam
        { from = 26900; to = 26950; } # 7d2d
      ];

      allowedTCPPortRanges = [
        { from = 27000; to = 27100; } # Steam
        { from = 26900; to = 26950; } # 7d2d
      ];
    }
    ];

    # Allows nfs cache
    services.cachefilesd.enable = true;
    
    virtualisation.containerd.enable = true;
    # virtualisation.podman.enable = true;
    virtualisation.cri-o.enable = true;
    virtualisation.containers.enable = true;
    
    services.nomad = {
      enable = true;
      package = pkgs.nomad_1_6;
      enableDocker = true;
      dropPrivileges = false;
      extraSettingsPaths = [ "/etc/nomad.d" ];
    };
}
