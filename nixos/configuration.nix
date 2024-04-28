{ config, lib, pkgs, networking, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports =
  [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./macbookpro.nix
    ./nomad.nix

    # Sops encryption
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/f1b0adc27265274e3b0c9b872a8f476a098679bd.tar.gz";
    }}/modules/sops"
  ];

  networking.hostName = "compute2";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  # Sets DNS to Cloudflare
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.networkmanager.dns = "none";
  services.resolved.enable = false;

  networking.wireless.networks = {
    "Look Ma, No Wires!" = {
      psk = "QMYK4KLNNU";
    };
    "Look Ma No Wires" = {
      psk = "QMYK4KLNNU";
    };
  };

  networking.firewall.enable = true;
  services.fail2ban.enable = true;
  networking.firewall.allowedTCPPorts = with networking; [ 22 ];
  networking.firewall.allowedUDPPortRanges = with networking; [{ from = 60000; to = 61000; }];

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
  };

  # Adds tailscale connectivity
  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = "--ssh --accept-dns";

  # At and Cron for scheduling
  services.atd.enable = true;
  services.cron.enable = true;

  # Various packages needed 
  environment.systemPackages = [
    pkgs.acl
    pkgs.age
    pkgs.curl
    pkgs.git
    pkgs.gnupg
    pkgs.grafana-agent
    pkgs.helix
    pkgs.htop
    pkgs.iotop
    pkgs.iperf
    pkgs.mosh
    pkgs.python3 # Ansible requires it
    pkgs.retry
    pkgs.service-wrapper
    pkgs.tmux
    pkgs.vim
    pkgs.zfs
  ];

  users.users.koalalorenzo = {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = [ "wheel" "networkmanager" "consul" "nomad" "docker" ];
  };

  environment.variables.EDITOR = "hx";
  
  # First version being used for the setup. Do not change it in the future, 
  # unless it is a brand new setup from scratch. It is used for compatibility
  # reasons and for migrated data between versions after upgrade.
  system.stateVersion = "23.11"; # Don't change it
}
