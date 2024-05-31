{ config, lib, pkgs, networking, ... }:
{
  # Backup service (Push to Storage0 via local network)
  systemd.services.vrising-backup = {
    enable = true;
    serviceConfig.Type = "oneshot";
    serviceConfig.User = "koalalorenzo";
    path = with pkgs; [ 
      bash
      rsync
      openssh
    ];
    script = ''
      rsync -avzh --delete --exclude "*.log" --progress /opt/vrising 192.168.197.5:/main/share/
    '';
  };

  systemd.timers.vrising-backup = {
    enable = true;
    wantedBy = [ "timers.target" ];
    partOf = [ "vrising-backup.service" ];
    timerConfig = {
      OnCalendar = "*-*-* *:58:00";
      Unit = "vrising-backup.service";
    };
  };
}
