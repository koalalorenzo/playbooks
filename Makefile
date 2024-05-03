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
	ansible-galaxy collection install community.dns
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

################################################################################
# Nomad
################################################################################
NOMAD_ARGS ?=
NOMAD_JOB_CMD ?= run
# All jobs (including disabled ones)
NOMAD_JOBS := $(shell find . -type f -name '*.job.hcl')
NOMAD_VOLUMES := $(shell find . -type f -name '*.volume.hcl')
NOMAD_VARIABLES := $(shell find . -type f -name '*.vars.sops.hcl')

$(NOMAD_VARIABLES):
	sops -d $@ | nomad var put -in=hcl -force ${NOMAD_ARGS} -
.PHONY: $(NOMAD_VARIABLES)

$(NOMAD_VOLUMES):
	-nomad volume create ${NOMAD_ARGS} $@
.PHONY: $(NOMAD_VOLUMES)

$(NOMAD_JOBS):
	nomad $(NOMAD_JOB_CMD) ${NOMAD_ARGS} $@
.PHONY: $(NOMAD_JOBS)

nomad_system:
	$(MAKE) $(wildcard system/*.vars.sops.hcl)
	$(MAKE) $(wildcard system/*.job.hcl) -e NOMAD_ARGS="-detach"
	sleep 30
	$(MAKE) $(wildcard system/*.volume.hcl)

nomad_variables: $(wildcard system/*.volume.hcl) $(wildcard services/*.volume.hcl)
nomad_volumes: $(wildcard system/*.volume.hcl) $(wildcard services/*.volume.hcl)
nomad_jobs: $(wildcard system/*.volume.hcl) $(wildcard services/*.volume.hcl)
.DEFAULT_GOAL := all
