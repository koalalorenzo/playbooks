{ config, lib, pkgs, boot, ... }: {
  # kernel needs to be compatible with zfs
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # boot.zfs.devNodes = "/dev/disk/by-partuuid/";

  boot.supportedFilesystems = [ "zfs" "ext4" "ntfs" ];
  boot.zfs.forceImportRoot = false;

  ### Sanoid for ZFS automatic backup
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

  ### Time Machine User setup
  users.extraUsers.time-traveller = { 
    name = "time-traveller"; 
    group = "users";
    shell = "/usr/sbin/nologin";
    hashedPassword = "$6$rounds=150000$kd0UPzA/qxc2n7XO$VC5/mgG2eDQiDQ3HyICNaxHzHO9q80A01jEFx.Q/uGjRXysxrS.IhNIDwg6o6turBZy4uBf99/NBVkwcLHmAo/";
  };

  ### NFS For Homelab volumes
  services.rpcbind.enable = true; # needed for NFS
  networking.firewall.allowedTCPPorts = [ 2049 ]; # Open port for NFS
  networking.firewall.allowPing = true;

  ### Samba for filesharing and Time Machine
  services.samba = {
    enable = true;
    securityType = "user";
    enableWinbindd = true;
    openFirewall = true;
    
    extraConfig = ''
      # Adds better support for iOS/iPadOS/macOS SMB Clients
      fruit:aapl = yes
      fruit:nfs_aces = no
      fruit:copyfile = no
      fruit:model = MacSamba

      # Improve security protocol
      client max protocol = default
      client min protocol = SMB2_10
      server max protocol = SMB3
      server min protocol = SMB2_10
      
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.197. 100.64.0.0/255.192.0.0 127.0.0.1 localhost
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

      "Time Machine" = {
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "6T";

        "comment" = "Time Machine";
        "path" = "/main/time-machine";

        "available" = "yes";
        "valid users" = "time-traveller, @users";
        "browseable" = "yes";
        "guest ok" = "no";
        "writable" = "yes";
        "public" = "no";
        "force user" = "time-traveller";
        "force group" = "users";
      }
    };
  };

  # Enable Windows Support
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Set up Avahi for Time Machine discovery
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}
