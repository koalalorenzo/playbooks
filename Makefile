ARGS ?=

ANSIBLE_CONFIG=facts.cfg

.EXPORT_ALL_VARIABLES:

deps:
	# Disabled datadog as we don't use it anymore
	# ansible-galaxy install datadog.datadog
.PHONY: deps

run: deps
	ansible-playbook -i ./inventory.yaml default.yaml ${ARGS}
.PHONY: run

reboot:
	ansible-playbook -i ./inventory.yaml common/reboot.yaml ${ARGS}
.PHONY: reboot

%:
	ansible-playbook -i ./inventory.yaml $*.yaml ${ARGS}

apt_upgrade:
	ansible all -i ./inventory.yaml --become \
		-m apt -a "update_cache=yes cache_valid_time=86400"
	ansible all -i ./inventory.yaml --become \
		-m apt -a "upgrade=yes"
.PHONY: apt_upgrade

.DEFAULT_GOAL := run
