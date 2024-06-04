{ config, pkgs, lib, ... }:
{
  # READ MORE:
  # https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4
  # Add Hardware:
  # nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
  imports = [
    <nixos-hardware/raspberry-pi/4>
  ];
  
  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    
    # Enable GPU
    hardware.raspberry-pi."4".fkms-3d.enable = true;
    
    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };

  
  console.enable = false;
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
}
