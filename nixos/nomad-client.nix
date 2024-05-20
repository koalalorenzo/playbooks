{ config, lib, pkgs, boot, sops, ... }: {
  options = {
    homelab.nomad = {
      node_class = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "compute";
      };

      meta = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      
      options = lib.mkOption {
        type = lib.types.str;
        default = "";
      };

      traefik = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      meta_traefik = lib.mkOption {
        type = lib.types.str;
        default = ''"traefik" = "true"'';
      };
    };
    # End homelab.nomad options
  };

  config = {
    # Install packages
    environment.systemPackages = with pkgs; [
      bzip2
      gnupg
      wget
      curl
      gnupg
      nfs-utils
      retry
      # podman
      docker
      docker-compose
    ];

    boot.kernel.sysctl = with boot; { 
      "net.bridge.bridge-nf-call-arptables" = "1"; 
      "net.bridge.bridge-nf-call-ip6tables" = "1"; 
      "net.bridge.bridge-nf-call-iptables" = "1"; 
    };

    networking.firewall = { 
      # Apllication/Services 
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
        3478 # Steam Client
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
      ];

      allowedUDPPortRanges = [
        { from = 4378;  to = 4380;  } # Steam P2P
        { from = 27000; to = 27100; } # Steam
        { from = 26900; to = 26950; } # 7d2d
      ];

      allowedTCPPortRanges = [
        { from = 4378;  to = 4380;  } # Steam P2P
        { from = 27000; to = 27100; } # Steam
        { from = 26900; to = 26950; } # 7d2d
      ];
    };

    # Allows nfs cache
    services.cachefilesd.enable = true;
  
    virtualisation.containerd.enable = true;
    # virtualisation.podman.enable = true;
    virtualisation.cri-o.enable = true;
    virtualisation.containers.enable = true;
    services.nomad.enableDocker = true;

    environment.etc = {
      "nomad.d/client.hcl" = {
        text = ''
            client {
              enabled = true
              servers = ["nomad.elates.it"]

              gc_interval = "5m"

              node_class = "${config.homelab.nomad.node_class}"

              # Uses Tailscale as network interface
              network_interface = "tailscale0"

              reserved {
                cpu    = 100
                memory = 256
              }

              artifact {
                disable_filesystem_isolation = true
              }

              meta {
                ${config.homelab.nomad.meta}
                ${if config.homelab.nomad.traefik  then config.homelab.nomad.meta_traefik else ""}
              }

              options {
                ${config.homelab.nomad.options}
              }
            }

            plugin "raw_exec" {
              config {
                enabled = true
              }
            }

            plugin "docker" {
              config {
                allow_privileged = true

                gc {
                  image       = true
                  image_delay = "72h"
                  container   = true
                }

                volumes {
                  # Allows mounting local paths
                  enabled = true
                }
              }
            }
        '';
      };
    };
    # end file edit
  };
  # End nix config 
}
