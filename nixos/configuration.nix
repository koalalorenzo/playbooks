{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports =
  [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./nomad.nix
    
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/f1b0adc27265274e3b0c9b872a8f476a098679bd.tar.gz";
    }}/modules/sops"
  ];


  networking.hostName = "compute2"; # Define your hostname.

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "compute2";
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

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
  };

  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = "--ssh --accept-dns";

  services.atd.enable = true;
  services.cron.enable = true;
  
  environment.systemPackages = [
    pkgs.acl
    pkgs.age
    pkgs.gnupg
    pkgs.curl
    pkgs.grafana-agent
    pkgs.helix
    pkgs.htop
    pkgs.iotop
    pkgs.python3 # Ansible requires it
    pkgs.iperf
    pkgs.mosh
    pkgs.retry
    pkgs.vim
    pkgs.tmux
    pkgs.zfs
    pkgs.service-wrapper
  ];

  users.users.koalalorenzo = {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = [ "wheel" "networkmanager" "consul" "nomad" "docker" ];
  };
  
  # First version being used for the setup. Do not change it in the future, 
  # unless it is a brand new setup from scratch. It is used for compatibility
  # reasons and for migrated data between versions after upgrade.
  system.stateVersion = "23.11"; # Don't change it
}
