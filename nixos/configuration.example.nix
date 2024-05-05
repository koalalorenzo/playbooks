{ config, lib, pkgs, networking, ... }:
{
  imports = lib.mkMerge [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./common.nix
    ./nomad.nix

    # Sops encryption
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/10dc39496d5b027912038bde8d68c836576ad0bc.tar.gz";
    }}/modules/sops"
  ];

  # networking.hostName = "batch0-qemu";

  # Is it a VM?
  #services.spice-vdagentd.enable = true;

  # First version being used for the setup. Do not change it in the future, 
  # unless it is a brand new setup from scratch. It is used for compatibility
  # reasons and for migrated data between versions after upgrade.
  system.stateVersion = "23.11"; # Don't change it
}
