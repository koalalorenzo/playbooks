{ config, pkgs, lib, ... }:
{
  # READ MORE:
  # https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4
  # Add Hardware:
  # nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
  imports = [
    <nixos-hardware/raspberry-pi/4>
  ];
  
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  # Optimization since I use microSD
  fileSystems."/".options = [ "noatime" ];

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    
    # Enable GPU
    raspberry-pi."4".fkms-3d.enable = true;
    
    deviceTree = {
      enable = true;
      filter = lib.mkForce "*rpi-4*.dtb";
    };

    enableRedistributableFirmware = true;
  };

  # Wait for uptime so that it syncs properly
  systemd.additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
  systemd.services.systemd-time-wait-sync.wantedBy = [ "multi-user.target" ];

  console.enable = false;
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
}
