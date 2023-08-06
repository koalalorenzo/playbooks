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

## How to Run
You can run all or a specific one:

```bash
# Generic playbooks
make common.yaml
# Specific playbook
make common/reboot.yaml
```

It is possible to pass arguments to `ansible-playbook` like so:

```bash
# Reboot every DNS server
make common/reboot -e ARGS="-l dns"
```

Secrets are encrypted using PGP/GPG. Please make sure to have your Yubikey handy
when running to allow your device to decrypt the secrets

This setup is WIP, and uses Nomad to orchestrate the workload. Some of the
workloads are deployed in .hcl files.

## Nomad Workloads
After the Ansible playbook install, there are some system services/tools needed
to run the main services in my home lab. To deploy you need first to install
these services by running:

```bash
cd system
make
```

Please makesure that `NOMAD_ADDR` env variable is pointing to the right endpoint

After that you should be able to access `nomad.{{ main_domain }}` (in my case
nomad.elates.it). Check that all the jobs are running correctly and volumes 
plugins are operational. If all looks good you can create the volumes and 
deploy the new services:

```bash
cd services
make 
```

Et voila! 