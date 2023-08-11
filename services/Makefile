JOB_CMD ?= plan
JOBS := $(wildcard *.job.hcl)
VOLUMES := $(wildcard *.volume.hcl)
VARIABLES := $(wildcard *.vars.hcl.asc)

$(VARIABLES):
	gpg -q --decrypt restic.vars.hcl.asc | nomad var put -in=hcl -force -
.PHONY: $(VARIABLES)

$(VOLUMES):
	-nomad volume create $@
.PHONY: $(VOLUMES)

$(JOBS): 
	nomad $(JOB_CMD) $@
.PHONY: $(JOBS)

variables: $(VARIABLES)
volumes: $(VOLUMES)
jobs: $(JOBS)

all: variables volumes jobs
.PHONY: all

.DEFAULT_GOAL := all