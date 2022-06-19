ARGS ?=

ANSIBLE_CONFIG=facts.cfg

.EXPORT_ALL_VARIABLES:

deps:
	ansible-galaxy install datadog.datadog
.PHONY: deps

run: deps
	ansible-playbook -i ./main.inventory default.yaml ${ARGS}
.PHONY: run

reboot:
	ansible-playbook -i ./main.inventory common/reboot.yaml ${ARGS}
.PHONY: reboot

%:
	ansible-playbook -i ./main.inventory $*.yaml ${ARGS}

apt_upgrade:
	ansible all -i ./main.inventory --become \
		-m apt -a "update_cache=yes cache_valid_time=86400"
	ansible all -i ./main.inventory --become \
		-m apt -a "upgrade=yes"
.PHONY: apt_upgrade

