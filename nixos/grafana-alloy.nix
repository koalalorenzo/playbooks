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
        "--cluster.join-addresses=home.elates.it:27373"
        "--cluster.rejoin-interval=60s"
        "--cluster.name=elates.it"
    ];
  };

  systemd.services.alloy.serviceConfig.EnvironmentFile = "/run/secrets/alloy/vars";
  systemd.services.alloy.reloadTriggers = ["/etc/alloy/config.alloy"];

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

