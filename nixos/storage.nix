{ config, lib, pkgs, boot, ... }: {
  # kernel needs to be compatible with zfs
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # boot.zfs.devNodes = "/dev/disk/by-partuuid/";

  boot.supportedFilesystems = [ "zfs" "ext4" ];
  boot.zfs.forceImportRoot = false;

  services.rpcbind.enable = true; # needed for NFS
  networking.firewall.allowedTCPPorts = [ 2049 ]; # Open port for NFS

  ### Samba
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    
    extraConfig = ''
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.197. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0

      workgroup = WORKGROUP
      security = user
      
      # server string = smbnix
      # netbios name = smbnix
      # #use sendfile = yes
      # #max protocol = smb2
      # guest account = nobody
      # map to guest = bad user
    '';

    shares = {
      multimedia = {
        path = "/main/multimedia";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "koalalorenzo";
      };

      downloads = {
        path = "/main/downloads";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "koalalorenzo";
      };

      personal = {
        path = "/main/personal";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "koalalorenzo";
      };

      backups = {
        path = "/main/backups";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "koalalorenzo";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
}
