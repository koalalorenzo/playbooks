{ config, lib, pkgs, networking, ... }:
let
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in
{
  imports = [ 
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>

    # ./networking.nix
    ./common.nix
    ./consul.nix
    ./nomad.nix
    ./nomad-client.nix
    # ./nomad-server.nix

    # Sops encryption
    "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/10dc39496d5b027912038bde8d68c836576ad0bc.tar.gz";
    }}/modules/sops"
  ];

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" "x86_64-linux" ];

  networking.hostName = "batch0";

  ## Boot EFI
  boot.loader.systemd-boot.enable = true;
  
  ## Boot GRUB
  # boot.loader.grub.device = "nodev";

  ## Homelab options:
  homelab.nomad.node_class = "batch";
  homelab.nomad.traefik = false;
  homelab.nomad.options = ''"driver.denylist" = "exec,java"'';
  homelab.nomad.meta = ''"run_batch" = "true"'';
  
  
  ## Is it a VM?
  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;
  console.enable = true;
  
  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = true;
  
  # virtualisation.qemu.guestAgent.enable = true;
  services.qemuGuest.enable = true;

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
