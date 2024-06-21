{ config, lib, pkgs, boot, sops, ... }: {
  # Disable upstream / stable alloy and uses the one in unstable channel
  disabledModules = [ "services/monitoring/alloy.nix" ];
  imports =
  [
    <nixos-unstable/nixos/modules/services/monitoring/alloy.nix>
  ];

  services.alloy = {
    enable = true;
    configPath = "/etc/alloy/config.alloy";
    package = pkgs.unstable.grafana-alloy;
    extraFlags = [
        "--server.http.listen-addr=0.0.0.0:27373"
        "--server.http.enable-pprof=false"
        "--cluster.enabled=true"
        "--cluster.join-addresses=100.98.104.116:27372,100.77.141.108:27373"
        "--cluster.rejoin-interval=60s"
        "--cluster.name=elates.it"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 27373 ];
  networking.firewall.allowedUDPPorts = [ 27373 ];

  systemd.services.alloy = {
    serviceConfig = {
      EnvironmentFile = "/run/secrets/alloy/vars";
      DynamicUser = lib.mkForce false;
    };

    reloadTriggers = ["/etc/alloy/config.alloy"];
    after = ["network-online.target" "tailscaled.service"];
    wants = [ "network-online.target" ];
  };

  environment.etc = {
    "alloy" = {
      source = ./etc/alloy;
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."alloy/vars" = {
      sopsFile = ./secrets/grafana-alloy.sops.yaml;
      restartUnits = [ "alloy.service" ];
    };
  };
}

