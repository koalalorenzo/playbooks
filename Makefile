# Add some caffeine to prevent sleep while running
ifeq ($(shell uname -s),Darwin)
SHELL := caffeinate -i bash
endif

################################################################################
# NixOS
################################################################################
NIXOS_HOSTS := compute0 compute1 compute2

nixos-config-sync_%:
	rsync -avzh --delete --progress --partial-dir=".rsync-partial" \
		--exclude "hardware-configuration.nix" \
		--exclude "configuration.nix" \
		nixos $*:/etc/

nixos-config-sync:
	$(foreach var,$(NIXOS_HOSTS),$(MAKE) nixos-config-sync_$(var) || exit 1;)
.PHONY: nixos-config-sync

nixos-channel-update_%:
	ssh $* sudo nix-channel --update

nixos-channel-update:
	$(foreach var,$(NIXOS_HOSTS),$(MAKE) nixos-rebuild_$(var) || exit 1;)
.PHONY: nixos-channel-update

nixos-rebuild_%:
	ssh $* sudo nixos-rebuild boot --upgrade-all

nixos-rebuild: nixos-channel-update
	$(foreach var,$(NIXOS_HOSTS),$(MAKE) nixos-rebuild_$(var) || exit 1;)
.PHONY: nixos-rebuild

$(NIXOS_HOSTS):
	$(MAKE) nixos-channel-update_$@ nixos-config-sync_$@ nixos-rebuild_$@
.PHONY: $(NIXOS_HOSTS)

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
