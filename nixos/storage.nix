{ config, lib, pkgs, boot, ... }: {
  # kernel needs to be compatible with zfs
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # boot.zfs.devNodes = "/dev/disk/by-partuuid/";

  boot.supportedFilesystems = [ "zfs" "ext4" "ntfs" ];
  boot.zfs.forceImportRoot = false;

  # Sanoid for ZFS automatic backup
  services.sanoid = {
    enable = true;
    
    templates.default = {
      yearly  = 4;
      monthly = 12;
      daily   = 32;
      hourly  = 24;
      
      autosnap  = true;
      autoprue  = true;
    };

    templates.frequent = {
      yearly  = 0;
      monthly = 3;
      daily   = 15;
      hourly  = 24;
      # frequent = 8;
      
      autosnap  = true;
      autoprune = true;
    };

    datasets.main.useTemplate = "default";
    datasets.main.recursive = true;
    datasets."main/share/postgres".useTemplate = "frequent";
    datasets."main/share/redis".useTemplate = "frequent";
    datasets."main/share/restic".useTemplate = "frequent";
    
    datasets."main/share/7d2d".useTemplate = "frequent";
    datasets."main/share/7d2d".recursive = true;
    datasets."main/share/vrising".useTemplate = "frequent";
    datasets."main/share/web-static".useTemplate = "frequent";
    
    # datasets."main/multimedia".useTemplate = "frequent";
    datasets."main/downloads".useTemplate = "frequent";
    # Disabled
    datasets."main/share/nix-cache".autosnap = false;
    datasets."main/share/nix-cache".autoprune = false;
  };

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
}
