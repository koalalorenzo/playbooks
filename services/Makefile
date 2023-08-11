JOB_CMD ?= plan
JOBS := $(wildcard *.job.hcl)
VOLUMES := $(wildcard *.volume.hcl)
VARIABLES := $(wildcard *.vars.sops.hcl)

$(VARIABLES):
	sops -d $@ | nomad var put -in=hcl -force -
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