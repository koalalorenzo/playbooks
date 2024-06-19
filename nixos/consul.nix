{ config, lib, pkgs, boot, sops, ... }: {
  # Install packages
  environment.systemPackages = with pkgs; [
    retry
  ];

  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 21000; to = 21255; } # Consul Sidecar Proxy
    ];

    allowedTCPPorts = [
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
      8301 # Consul: LAN Serf
      8302 # Consul: WAN Serf
      8502 # Consul: gRPC
      8503 # Consul: gRPC TLS
      8600 # Consul: DNS
    ];

    allowedUDPPortRanges = [
      { from = 21000; to = 21255; } # Consul Sidecar Proxy
    ];
  };


  # Load Secrets
  sops = {
    defaultSopsFile = ./secrets/consul.sops.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."consul/certs/dc1-server-consul-0-key.pem" = {
      restartUnits = [ "consul.service" ];
      owner = "consul";
    };
    secrets."consul/certs/dc1-server-consul-0.pem" = {
      restartUnits = [ "consul.service" ];
      owner = "consul";
    };
    secrets."consul/certs/consul-agent-ca-key.pem" = {
      restartUnits = [ "consul.service" ];
      owner = "consul";
    };
    secrets."consul/certs/consul-agent-ca.pem" = {
      restartUnits = [ "consul.service" ];
      owner = "consul";
    };

    secrets."consul/encryption.hcl" = {
      restartUnits = [ "consul.service" ];
      owner = "consul";
      path = "/etc/consul.d/encryption.hcl";
    };
  };

  # Load Configuration for Consul
  services.consul.enable = true;
  services.consul.package = pkgs.unstable.consul;
  systemd.services.consul.serviceConfig.Type = "notify";
  systemd.services.consul.after = ["network-online.target" "tailscaled.service"];
  systemd.services.consul.wants = [ "network-online.target" ];

  environment.etc = {
    "consul.d/consul.hcl" = {
      text = ''
          data_dir = "/opt/consul"
          datacenter = "dc1"
          server = true
          bootstrap_expect = 3
          bind_addr = "0.0.0.0"
          advertise_addr = "{{ GetPrivateInterfaces | include \"network\" \"100.64.0.0/10\" | attr \"address\" }}"

          ui_config {
            enabled = true
          }

          telemetry { 
            prometheus_retention_time = "90s"
          }

          retry_join = ["consul.elates.it"]

          tls {
             defaults {
                ca_file = "/run/secrets/consul/certs/consul-agent-ca.pem"
                cert_file = "/run/secrets/consul/certs/dc1-server-consul-0.pem"
                key_file = "/run/secrets/consul/certs/dc1-server-consul-0-key.pem"

                verify_incoming = true
                verify_outgoing = true
             }
             internal_rpc {
                verify_server_hostname = true
             }
          }

          acl = {
            enabled = false
            default_policy = "allow"
            enable_token_persistence = true
          }

          auto_encrypt {
            allow_tls = true
          }
      '';
    };
  };
}

