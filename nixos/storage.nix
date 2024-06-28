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

    template.daily = {
      yearly = 0;
      monthly = 2;
      daily = 7;
      hourly = 3;

      autosnap  = true;
      autoprue  = true;
    }

    templates.frequent_changes = {
      yearly  = 0;
      monthly = 3;
      daily   = 8;
      hourly  = 24;
      # frequent_changes = 8;
      
      autosnap  = true;
      autoprune = true;
    };

    datasets.main.useTemplate = "default";
    datasets.main.recursive = true;
    datasets."main/share/postgres".useTemplate = "daily";
    datasets."main/share/redis".useTemplate = "daily";
    datasets."main/share/restic".useTemplate = "daily";
    
    datasets."main/share/7d2d".useTemplate = "frequent_changes";
    datasets."main/share/7d2d".recursive = true;
    datasets."main/share/vrising".useTemplate = "frequent_changes";
    datasets."main/share/web-static".useTemplate = "frequent_changes";
    
    # datasets."main/multimedia".useTemplate = "frequent_changes";
    datasets."main/downloads".useTemplate = "frequent_changes";

    # Time Machine 
    datasets."main/time-machine".useTemplate = "daily";
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

  ### Time Machine setup
  
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  users.extraUsers.time-traveller = { 
    name = "time-traveller"; 
    group = "users";
    shell = "/usr/sbin/nologin";
  };
  
  services.netatalk = {
    enable = true;
    
    extraConfig = ''
      mimic model = TimeCapsule6,106  # show the icon for the first gen TC
      log level = default:warn
      log file = /var/log/afpd.log
      hosts allow = 192.168.197.0/24 100.64.0.0/10
      
      [Time Machine]
      path = /main/time-machine
      valid users = time-traveller
      time machine = yes
    '';
  };

  systemd.services.macUserSetup = {
    description = "idempotent directory setup for ${user}'s time machine";
    requiredBy = [ "netatalk.service" ];
    script = ''
     mkdir -p 
      chown time-traveller:users /main/time-machine  # making these calls recursive is a switch
      chmod 0750 /main/time-machine                  # away but probably computationally expensive
      '';
  };

  networking.firewall.allowedTCPPorts = [ 548 636 ];
}
