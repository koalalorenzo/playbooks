{
  description = "nixos generator and raspberrypis image builders";
  
  nixConfig = {
    extra-substituters = [ "https://raspberry-pi-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
    ];
  };
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixos-hardware.url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
    raspberry-pi-nix = {
      url = "github:tstat/raspberry-pi-nix";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager.url = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, raspberry-pi-nix, sops-nix, home-manager, nixpkgs-unstable, nixos-generators, ... }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      base-setup = { pkgs, lib, ... }: {
        system.stateVersion = "24.05";
        networking.hostName = "nixos";
        nixpkgs.config = {
          packageOverrides = pkgs: {
            unstable = import <nixos-unstable> {
              config = pkgs.config;
            };
          };
        };

      };

      home-lab = {pkgs, lib, ... }: {
          homelab.authorized_keys = [
            ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNkwS8ZkLWgSZh9o4y1Y+Wa07d251UQAX4u6V1DWRNk koalalorenzo@Lorenzos-MBP''
          ];
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
      };

      rpi-config = { pkgs, lib, ... }: {
        fileSystems."/".options = [ "noatime" ];
        # boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];

        # Wait for uptime so that it syncs properly
        systemd.additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
        systemd.services.systemd-time-wait-sync.wantedBy = [ "multi-user.target" ];

        console.enable = false;
        environment.systemPackages = with pkgs; [
          libraspberrypi
          raspberrypi-eeprom
        ];

        
        hardware = {
          raspberry-pi = {
            config = {
              all = {
                options.camera_auto_detect = {
                  enable = false;
                };
                
                base-dt-params = {
                  # enable autoprobing of bluetooth driver
                  # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
                  krnbt = {
                    enable = true;
                    value = "on";
                  };
                };
              };
            };
          };
        };
      };

    in {
      nixosConfigurations = {
        rpi4 = nixosSystem {
          system = "aarch64-linux";
          modules = [
            sops-nix.nixosModules.sops
            base-setup
            raspberry-pi-nix.nixosModules.raspberry-pi
            rpi-config
            ./rpi4.nix
            ./networking.nix
            ./common.nix
          ];
        };
        rpi5 = nixosSystem {
          system = "aarch64-linux";
          modules = [ 
            sops-nix.nixosModules.sops
            base-setup
            raspberry-pi-nix.nixosModules.raspberry-pi
            rpi-config
            ./rpi5.nix
            ./networking.nix
            ./common.nix
          ];
        };
      };
    };
}
