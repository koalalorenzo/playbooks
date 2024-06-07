{ config, lib, pkgs, boot, sops, ... }: {
  nixpkgs.config.allowUnfree = true;
  # Install packages
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 20000; to = 32000; } # Nomad: Port Allocation
    ];

    allowedTCPPorts = [
      4646 # Nomad: API / UI
      4647 # Nomad: RCP API
      4648 # Nomad: WAN Gossip
    ];

    allowedUDPPorts = [
      4647 # Noamd: RCP API
      4648 # Noamd: WAN Gossip
    ];

    allowedUDPPortRanges = [
      { from = 20000; to = 32000; } # Nomad: Port Allocation
    ];
  };

  services.nomad = {
    enable = true;
    package = pkgs.unstable.nomad;
    dropPrivileges = false;
    extraSettingsPaths = [ "/etc/nomad.d" ];
  };

  environment.etc = {
    "nomad.d/nomad.hcl" = {
      text = ''
        datacenter = "dc1"
        data_dir  = "/opt/nomad/data"
        bind_addr = "0.0.0.0"

        log_rotate_duration = "24h"
        log_rotate_max_files = 7

        telemetry {
         collection_interval = "60s", # Must match or less than prometheus scrape_interval
         publish_allocation_metrics = true,
         publish_node_metrics = true,
         prometheus_metrics = true
        }

        ui {
          enabled = true
          consul {
            ui_url = "http://consul.elates.it/ui"
          }
        }

        consul {
          address = "127.0.0.1:8500"

          # The service name to register the server and client with Consul.
          server_service_name = "nomad"
          client_service_name = "nomad-client"
          auto_advertise = true
          server_auto_join = true
          client_auto_join = true
        }

        advertise {
          # Defaults to the first private IP address. Using Tailscale instead
          http = "{{ GetInterfaceIP \"tailscale0\" }}"
          rpc = "{{ GetInterfaceIP \"tailscale0\" }}"
          serf = "{{ GetInterfaceIP \"tailscale0\" }}"
        }
      '';
    };
  };
}

