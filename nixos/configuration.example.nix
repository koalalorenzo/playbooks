{ config, lib, pkgs, networking, ... }:
{
  imports = [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    
    # ./macbookpro.nix
    # ./rpi4.nix

    ./networking.nix
    ./common.nix
    # ./consul.nix
    # ./nomad.nix
    # ./nomad-client.nix
    # ./nomad-server.nix

    # Sops encryption
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/master.tar.gz";
    }}/modules/sops"
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

  # networking.hostName = "nixos";

  ## Boot EFI
  # boot.loader.systemd-boot.enable = true;
  
  ## Boot GRUB
  # boot.loader.grub.device = "nodev";

  ## Homelab options:
  # homelab.nomad = {
  #  node_class = "compute";
  #  traefik = false;
  #  
  #  options = ''"driver.denylist" = "exec,java"'';
  #  meta = ''"key" = "valye"'';
  #  
  #  host_volumes = ''
  #    host_volume "vrising" {
  #      path = "/opt/vrising"
  #      read_only = false
  #    }
  #  '';
  # };
  
  ## Is it a VM?
  #services.spice-vdagentd.enable = true;
  #services.spice-autorandr.enable = true;
  #console.enable = true;
  
  #virtualisation.vmware.guest.enable = true;
  #virtualisation.vmware.guest.headless = true;

  #virtualisation.qemu.guestAgent.enable = true;
  #services.qemuGuest.enable = true;

  #virtualisation.virtualbox.guest.enable = true;

  #virtualisation.hypervGuest.enable = true;

  ## Disable docs and manual pages
  # documentation.doc.enable = false;
  # documentation.man.enable = false;
  # documentation.nixos.enable = false;
  # documentation.info.enable = false;

  # First version being used for the setup. Do not change it in the future, 
  # unless it is a brand new setup from scratch. It is used for compatibility
  # reasons and for migrated data between versions after upgrade.
  system.stateVersion = "24.05"; # Don't change it
}
