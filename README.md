# Lorenzo's Homelab
Set of Ansible playbooks, configuration and scripts for my home setup, developer 
machines and NAS.

Dependencies:

* Ansible
* Nomad
* Consul
* GNU Make
* Mozilla SOPS

**Important**: on macOS / Darwin it will use `caffeinate` command to prevent the
Mac from sleeping while running the playbooks. [Read more here](https://blog.setale.me/2022/08/12/How-to-prevent-your-Mac-from-sleeping-in-a-Makefile/)

## How to Ru## Nomad Workloads
There are some system services/tools needed to run the main services in my 
homelab. To deploy you need first to install these services by running:

```bash
make system/csi-*.job.hcl
```

Please makesure that `NOMAD_ADDR` env variable is pointing to the right endpoint

After that you should be able to access `nomad.{{ main_domain }}` (in my case
nomad.elates.it). Check that all the jobs are running correctly and volumes 
plugins are operational. If all looks good you can create the volumes and 
deploy the new services:

```bash
make services/*.hcl
```

Et voila! 

## Secrets

When creating a new host, you need to encrypt the file accordingly using age.
You can get the SSH-to-age key by running:

```bash
nix-shell -p ssh-to-age --run "ssh-keyscan ${IP_ADDRESS} | ssh-to-age"
```

where `${IP_ADDRESS}` is the host name/ip address. After adding the key to 
`.sops.yaml` file, We can update the files:


```bash
find . -type f -name "*.sops.*" -print -exec sops updatekeys {} -y \;
```

## Install on NixOS

Add the following channels, by running these commands as **root**:
```bash
nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://nixos.org/channels/nixos-24.05 nixos
nix-channel --update
```

Copy over the nix configurations:
```bash
rsync ./nixos/* nixos@${IP_ADDRESS}:/etc/nixos/
```

On the new machine start configuring it:

```bash
cd /etc/nixos/
cp configuration.example.nix configuration.nix

# Generate hardware config if not present 
nixos-generate-config # [ --no-filesystems ]

# Change, enable, disable and set things up:
vim configuration.nix

# Build the new system on next reboot:
nixos-rebuild boot --upgrade-all
```

Et voila! on next reboot the homelab node will be ready

After reboot, remember to check that everything is fine, login with Tailscale
and restart the daemons if needed:

```bash
sudo tailscale up
sudo systemctl restart consul.service nomad.service
sudo journalctl -f -u consul.service -u nomad.service
```

## NixOS generator (iso/images)

Crate a NixOS SD Image by running from `nixos` directory:

```bash
cd nixos
nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage'
```
