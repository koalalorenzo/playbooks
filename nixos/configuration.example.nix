{ config, lib, pkgs, networking, ... }:
{
  imports = lib.mkMerge [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./common.nix
    ./nomad.nix

    # Sops encryption
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/f1b0adc27265274e3b0c9b872a8f476a098679bd.tar.gz";
    }}/modules/sops"
  ];

  # networking.hostName = "compute2";

  # Is it a VM?
  #services.spice-vdagentd.enable = true;

  # First version being used for the setup. Do not change it in the future, 
  # unless it is a brand new setup from scratch. It is used for compatibility
  # reasons and for migrated data between versions after upgrade.
  system.stateVersion = "23.11"; # Don't change it
}
