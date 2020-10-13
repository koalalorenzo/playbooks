
run:
	ansible-playbook -i ./main.inventory maintenance.yaml
.PHONY: run

reboot:
	ansible-playbook -i ./main.inventory common/reboot.yaml
.PHONY:reboot

%:
	ansible-playbook -i ./main.inventory $*.yaml