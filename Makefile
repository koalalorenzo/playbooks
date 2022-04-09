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
	ansible-playbook -i ./main.inventory $*.yaml
