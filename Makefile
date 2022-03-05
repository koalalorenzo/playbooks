ARGS ?=

run:
	ansible-playbook -i ./main.inventory default.yaml --limit @main.retry ${ARGS}
.PHONY: run

reboot:
	ansible-playbook -i ./main.inventory common/reboot.yaml ${ARGS}
.PHONY:reboot

%:
	ansible-playbook -i ./main.inventory $*.yaml
