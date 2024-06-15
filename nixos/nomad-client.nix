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

      host_volumes = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
    # End homelab.nomad options
  };

  config = {
    # Install packages
    environment.systemPackages = with pkgs; [
      # podman
      bzip2
      curl
      docker
      gnupg
      nfs-utils
      moreutils
      retry
      wget
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
        1900 # Jellyfin DLNA / upnp
        3128 # Squid HTTP Proxy
        3478 # Steam Client
        5201 # Iperf 3
        7359 # Jellyfin autodiscovery
        7777 # Terraria
        8081 # Traefik
      ];

      allowedUDPPorts = [
        # Application/services prots:
        53 # DNS / PiHole, AdGuard or Unbound
        80 # Traefik HTTP
        443 # Traefik HTTPS
        853 # DNS over TLS / QUIC
        1900 # Jellyfin DLNA / upnp
        3128 # Squid HTTP Proxy
        3478 # Steam Client
        5201 # Iperf 3
        7359 # Jellyfin autodiscovery
        7777 # Terraria
        8081 # Traefik
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
    services.nomad.extraPackages = with pkgs; [
      bash
      curl
      wget
      bzip2
      gzip
      moreutils

      docker
      cni-plugins
      libcgroup
    ];

    environment.etc = lib.mkMerge [{
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
                ${if config.homelab.nomad.traefik  then ''"traefik" = "true"'' else ""}
              }

              options {
                ${config.homelab.nomad.options}
              }

              host_volume "ca-certificates" {
                path = "/etc/ssl/certs"
                read_only = true
              }
  
              ${ if config.homelab.nomad.traefik then ''
              host_volume "traefik" {
                path = "/etc/traefik"
                read_only = false
              }
              '' else ""}

              # Custom host_volumes
              ${config.homelab.nomad.host_volumes}
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
    }
    
    (lib.mkIf config.homelab.nomad.traefik {
      "traefik/.keep" = { 
        text = ''# KEEP FILE #'';
      };
    })
    
    ];

    systemd.services.nomad-drain-shutdown = {
      enable = true;
      description = "Automatic drain the nomad client when shutting down";

      serviceConfig.Type = "oneshot";
      serviceConfig.User = "root";
      path = with pkgs; [
        config.services.nomad.package
        bash
      ];

      script = ''
        nomad node drain -enable -self -ignore-system -yes -deadline 1m
      '';

      before = ["halt.target" "shutdown.target" "reboot.target"];
      # requisite = ["nomad.service" "tailscaled.service"];
      wantedBy = ["halt.target" "shutdown.target" "reboot.target"];
    };

  };
  # End nix config 
}
