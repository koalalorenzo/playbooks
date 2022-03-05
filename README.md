# Ansible Playbooks
Set of Ansible playbooks for my home setup, developer machines and NAS.

Dependencies:

* 1Password CLI
* Ansible
* GNU Make

## How to Run
Simply make sure to have access to 1Password:

```bash
# First time:
op signin my.1password.eu lorenzo@setale.me
# After the first time:
eval $(op signin my)
```

Then you can check the `main.inventory` file and run:

```bash
make run
```
