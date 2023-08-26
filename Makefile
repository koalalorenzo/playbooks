ANSIBLE_ARGS ?=-K

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
	ansible-playbook -i ./inventory.yml common/reboot.yaml ${ANSIBLE_ARGS}
.PHONY: reboot

$(ALL_PLAYBOOKS) $(PLAYBOOKS): deps
	ansible-playbook -i ./inventory.yml $@ ${ANSIBLE_ARGS}
.PHONY: $(ALL_PLAYBOOKS) $(PLAYBOOKS)

all: deps
	ansible-playbook -i ./inventory.yml $(PLAYBOOKS) common/reboot-uptime.yaml ${ANSIBLE_ARGS}
.PHONY: all

apt_upgrade:
	ansible all -i ./inventory.yml --become \
		-m apt -a "update_cache=yes cache_valid_time=86400" ${ANSIBLE_ARGS}
	ansible all -i ./inventory.yml --become \
		-m apt -a "upgrade=full autoremove=true" ${ANSIBLE_ARGS}
.PHONY: apt_upgrade

################################################################################
# Nomad
################################################################################
NOMAD_ARGS ?=
NOMAD_JOB_CMD ?= plan
NOMAD_JOBS := $(wildcard */*.job.hcl)
NOMAD_VOLUMES := $(wildcard */*.volume.hcl)
NOMAD_VARIABLES := $(wildcard */*.vars.sops.hcl)

$(NOMAD_VARIABLES):
	sops -d $@ | nomad var put -in=hcl -force ${NOMAD_ARGS} -
.PHONY: $(NOMAD_VARIABLES)

$(NOMAD_VOLUMES):
	-nomad volume create ${NOMAD_ARGS} $@
.PHONY: $(NOMAD_VOLUMES)

$(NOMAD_JOBS):
	nomad $(NOMAD_JOB_CMD) $@
.PHONY: $(NOMAD_JOBS)

nomad_variables: $(NOMAD_VARIABLES)
nomad_volumes: $(NOMAD_VOLUMES)
nomad_jobs: $(NOMAD_JOBS)

.DEFAULT_GOAL := all
