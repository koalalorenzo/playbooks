{ config, lib, pkgs, services, ... }:
{
  ### Specific settings for my MacBook Pro 2016

  # imports = lib.mkMerge [
  #   # Apple T2 support
  #   "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/apple/t2"
  # ]

  # Adds applet2 loader
  # hardware.apple-t2.enableAppleSetOsLoader = true;

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
  environment = with pkgs; {
    systemPackages = [
      pkgs.nano # No ESC keyboard on my old mac
    ];
  };
}
