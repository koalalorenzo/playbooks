# Ansible Playbooks
Set of Ansible playbooks for my home setup, developer machines and NAS.

Dependencies:

* Ansible
* GNU Make

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
