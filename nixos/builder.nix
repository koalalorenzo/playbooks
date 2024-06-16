{ config, pkgs, lib, ... }:
{
  options = {
    homelab.authorized_keys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of public SSH keys to authorized";
      default = [];
    };
  };

  config = {
    networking.hostName = lib.mkDefault "nixos-builder";

    nix.settings = {
      experimental-features = [ "nix-command flakes" ];
      auto-optimise-store = true;
    };

    # Free 4GB when 2GB are left free
    nix.extraOptions = ''
      min-free = ${toString (2048 * 1024 * 1024)}
      max-free = ${toString (4096 * 1024 * 1024)}
    '';

    nixpkgs.config.allowUnfree = true;

    documentation.doc.enable = false;
    documentation.man.enable = false;
    documentation.nixos.enable = false;
    documentation.info.enable = false;

    boot.tmp.cleanOnBoot = true;

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Europe/Copenhagen";

    nix.settings.trusted-users = [ "builder" "nix-ssh" "@wheel" ];
    nix.settings.system-features = [ "kvm" "benchmark" "nixos-test" "big-parallel" ];
    nix.settings.max-jobs = 4; # Max 4 jobs
    nix.settings.cores = 0; # Use all available

    security.sudo.wheelNeedsPassword = false;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.users = {
      root.hashedPassword = "!"; # Disable root login
      builder = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = lib.mkMerge [
          config.homelab.authorized_keys
          [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrBQxkAWqTW7Wz+2HE9bA4yauFJ7/FgLRSpPHbabQ1E builder@nixos-builder'']
        ];
      };
    };

    # Automatic login at the console
    services.getty.autologinUser = "builder";

    nix.sshServe = {
      enable = true;
      write = true;
      keys = config.homelab.authorized_keys;
    };

    networking.networkmanager.enable = true;
    networking.firewall.allowedTCPPorts = [ 22 ];
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
 
    environment.variables.EDITOR = "hx";
    environment.systemPackages = with pkgs; [
      curl
      git
      gnupg
      helix
      htop
      iotop
      tmux
    ];
  }; # end nix config
}
