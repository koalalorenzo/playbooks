# Ansible Playbooks
Set of Ansible playbooks for my home setup, developer machines and NAS.

Dependencies:

* Ansible
* GNU Make
* Mozilla SOPS

**Important**: on macOS / Darwin it will use `caffeinate` command to prevent the
Mac from sleeping while running the playbooks.

## How to Run
You can run all or a specific one:

```bash
# All
make run
# Specific directory
make common
# Specific playbook
make common/reboot
```

It is possible to pass arguments to `ansible-playbook` like so:

```bash
# Reboot every DNS server
make common/reboot -e ARGS="-l dns"
```

Secrets are encrypted using PGP/GPG. Please make sure to have your Yubikey handy
when running to allow your device to decrypt the secrets
