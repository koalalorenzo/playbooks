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

  # Avahi mdns local discovery
  services.avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
  };  

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = lib.mkDefault false;
    PermitRootLogin = lib.mkDefault "no";
  };

  # Adds tailscale connectivity
  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = "--ssh --accept-routes";
  services.tailscale.package = pkgs.unstable.tailscale;

  # At and Cron for scheduling
  services.atd.enable = true;
  services.cron.enable = true;

  # Various packages needed 
  environment.systemPackages = with pkgs; [
    acl
    age
    curl
    git
    gnupg
    helix
    htop
    iotop
    iperf
    mailutils
    mosh
    python3 # Ansible requires it
    retry
    service-wrapper
    tmux
    vim
    zfs
  ];

  users.users.koalalorenzo = {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = [ "wheel" "networkmanager" "consul" "nomad" "docker" ];
    openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNkwS8ZkLWgSZh9o4y1Y+Wa07d251UQAX4u6V1DWRNk'' ];
  };

  users.users.root.openssh.authorizedKeys.keys = lib.mkForce [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNkwS8ZkLWgSZh9o4y1Y+Wa07d251UQAX4u6V1DWRNk'' ];

  boot.tmp.cleanOnBoot = true;

  environment.variables.EDITOR = "hx";
}
