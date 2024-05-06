{ config, lib, pkgs, networking, ... }:
{
  imports = [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./common.nix
    # ./consul.nix
    # ./nomad.nix
    # ./nomad-client.nix
    # ./nomad-server.nix

    # Sops encryption
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/10dc39496d5b027912038bde8d68c836576ad0bc.tar.gz";
    }}/modules/sops"
  ];

  # networking.hostName = "nixos";

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

  # Disable docs and manual pages
  documentation.doc.enable = false;
  documentation.man.enable = false;
  documentation.nixos.enable = false;
  documentation.info.enable = false;

  # First version being used for the setup. Do not change it in the future, 
  # unless it is a brand new setup from scratch. It is used for compatibility
  # reasons and for migrated data between versions after upgrade.
  system.stateVersion = "23.11"; # Don't change it
}
