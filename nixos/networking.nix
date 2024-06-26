{ config, lib, pkgs, networking, sops, ... }:
{
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;
  networking.usePredictableInterfaceNames = lib.mkForce true;

  # Sets DNS to Cloudflare
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.networkmanager.dns = "none";
  services.resolved.enable = false;

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
  networking.firewall.logRefusedConnections = true;

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = ["100.64.0.0/10"];
    bantime = "5m";
    bantime-increment = { 
      enable = true;
      maxtime = "24h";
    };
  };

  # Allow Mosh and SSH
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPortRanges = [{ from = 60000; to = 61000; }];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."networks/LookMa.nmconnection" = {
      owner = "root";
      path = "/etc/NetworkManager/system-connections/LookMa.nmconnection";
      sopsFile = ./secrets/networks.sops.yaml;
    };

    secrets."networks/LookMa5G.nmconnection" = {
      owner = "root";
      path = "/etc/NetworkManager/system-connections/LookMa5G.nmconnection";
      sopsFile = ./secrets/networks.sops.yaml;
    };
  };
}
