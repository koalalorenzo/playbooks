{ config, lib, pkgs, networking, ... }:
{
  # Enables flaeks:
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Sets up garbage collector
  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  # Free 2GB when 1024 GB are free
  nix.extraOptions = ''
    min-free = ${toString (1024 * 1024 * 1024)}
    max-free = ${toString (2048 * 1024 * 1024)}
  '';

  # Optimize automatically
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = true;

  # Sets DNS to Cloudflare
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.networkmanager.dns = "none";
  services.resolved.enable = false;

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
  networking.firewall.logRefusedConnections = true;
  services.fail2ban.enable = true;

  # Allow Mosh and SSH
  networking.firewall.allowedTCPPorts = with networking; [ 22 ];
  networking.firewall.allowedUDPPortRanges = with networking; [{ from = 60000; to = 61000; }];

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
  };

  # Adds tailscale connectivity
  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = "--ssh";

  # At and Cron for scheduling
  services.atd.enable = true;
  services.cron.enable = true;

  # Various packages needed 
  environment.systemPackages = with pkgs; [
    pkgs.acl
    pkgs.age
    pkgs.curl
    pkgs.git
    pkgs.gnupg
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
}
