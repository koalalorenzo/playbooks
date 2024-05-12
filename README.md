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
nix-shell -p ssh-to-age --run 'ssh-keyscan storage0 | ssh-to-age'
```

where `storage0` is the host name/ip address. After adding the key to `.sops.yaml`
file, We can update the files:


```bash
find . -type f -name "*.sops.*" -print -exec sops updatekeys {} -y \;
```
