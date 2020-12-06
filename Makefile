
run:
	ansible-playbook -i ./main.inventory default.yaml
.PHONY: run

reboot:
	ansible-playbook -i ./main.inventory common/reboot.yaml
.PHONY:reboot

%:
	ansible-playbook -i ./main.inventory $*.yaml