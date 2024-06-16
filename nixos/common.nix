{ config, lib, pkgs, system, sops, networking, ... }:
{
  imports = [ <home-manager/nixos> ];

  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
      # Free 2GB when 1024 GB are free
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (2048 * 1024 * 1024)}
    '';

    # Optionally disable local building
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # max-jobs = 0;
    };

    buildMachines = [ 
      {
        hostName = "nixos-builder.local";
        sshUser = "builder";
        sshKey = "/run/secrets/ssh_keys/builder";
        system = "aarch64-linux";
        maxJobs = 2;
        speedFactor = 2;
        # Supported features is badly documented, important to add these, 
        # otherwise many big packages will still get build locally.
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }
    ];

    # Sets up garbage collector
    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than 30d";
    };

    # Optimize automatically
    optimise.automatic = true;
    optimise.dates = [ "weekly" ];
  };

  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Avahi mdns local discovery
  services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = false;
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
  services.tailscale.extraUpFlags = "--ssh --accept-dns";
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
    retry
    tmux
    vim
    zfs
  ];

  users.users.koalalorenzo = {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = [ "wheel" "networkmanager" "consul" "nomad" "docker" ];
    openssh.authorizedKeys.keys = [
      ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNkwS8ZkLWgSZh9o4y1Y+Wa07d251UQAX4u6V1DWRNk''
      ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElGbiLlkcIihAz0Qix1lwHHunNr1c32PVNiVQn66fmC koalalorenzo@storage0''
    ];
  };

  home-manager.users.koalalorenzo = { pkgs, ... }: {
    home.stateVersion = "24.05";
    programs.zsh = {
      enable = true;
      oh-my-zsh = { 
        enable = true;
        plugins = ["git" "sudo" "nix-shell"];
        theme = "robyrussel";
      };
    };

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://atuin.elates.it";
        keymap_mode = "auto";
        exit_mode = "return-query";
        filter_mode = "host";
        
        sync = {
          records = true;
        };
        
        dotfiles = {
          enabled = false;
        };
      };
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keys = lib.mkForce [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNkwS8ZkLWgSZh9o4y1Y+Wa07d251UQAX4u6V1DWRNk'' ];

  boot.tmp.cleanOnBoot = true;

  environment.variables.EDITOR = "hx";

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."ssh_keys/builder" = {
      owner = "root";
      mode = "0644";
      sopsFile = ./secrets/builder.sops.yaml;
    };

    secrets."ssh_keys/builder.pub" = {
      owner = "root";
      mode = "0644";
      sopsFile = ./secrets/builder.sops.yaml;
    };
  };
}
