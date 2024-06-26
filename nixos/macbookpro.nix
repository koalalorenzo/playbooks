{ config, lib, pkgs, services, ... }:
{
  ### Specific settings for my MacBook Pro 2016, with NixOS

  # imports = lib.mkMerge [
  #   # Apple T2 support
  #   "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/apple/t2"
  # ]

  # Adds applet2 loader
  # hardware.apple-t2.enableAppleSetOsLoader = true;

  # Enable SSD TRIM and adds better Filesystem performance
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # Is it a VM on Mac M1? Add rosetta for x86_64
  virtualisation.rosetta.enable = config.nixpkgs.localSystem.isAarch;

  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "b43" "bcma" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Disable lid close sleep
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchDocked = "ignore";
  services.upower.ignoreLid = true;

  # Provides hw info
  services.acpid.enable = true;

  # On MacOS
  services.mbpfan.enable = true;

  # Install packages
  environment.systemPackages = with pkgs; [
    acpi
    nano # No ESC keyboard on my old mac
  ];
}
