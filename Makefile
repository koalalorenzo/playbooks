ARGS ?=-K

PLAYBOOKS := $(wildcard *.yaml)
ALL_PLAYBOOKS := $(wildcard */*.yaml)
ANSIBLE_CONFIG=facts.cfg

# Add some caffeine to prevent sleep while running
ifeq ($(shell uname -s),Darwin)
SHELL := caffeinate -i bash
endif

deps:
	# Disabled datadog as we don't use it anymore
	# ansible-galaxy install datadog.datadog
	ansible-galaxy collection install community.sops
.PHONY: deps

reboot:
	ansible-playbook -i ./inventory.yml common/reboot.yaml ${ARGS}
.PHONY: reboot

$(ALL_PLAYBOOKS) $(PLAYBOOKS): deps
	ansible-playbook -i ./inventory.yml $@ ${ARGS}
.PHONY: $(ALL_PLAYBOOKS) $(PLAYBOOKS)

all: deps
	ansible-playbook -i ./inventory.yml $(PLAYBOOKS) common/reboot-uptime.yaml ${ARGS}
.PHONY: all

apt_upgrade:
	ansible all -i ./inventory.yaml --become \
		-m apt -a "update_cache=yes cache_valid_time=86400"
	ansible all -i ./inventory.yaml --become \
		-m apt -a "upgrade=yes"
.PHONY: apt_upgrade

.DEFAULT_GOAL := all
