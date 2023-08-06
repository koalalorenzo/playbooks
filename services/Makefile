JOB_CMD ?= plan
JOBS := $(wildcard *.job.hcl)
VOLUMES := $(wildcard *.volume.hcl)

$(VOLUMES):
	-nomad volume create $@
.PHONY: $(VOLUMES)

$(JOBS): 
	nomad $(JOB_CMD) $@
.PHONY: $(JOBS)

volumes: $(VOLUMES)
jobs: $(JOBS)

all: volumes jobs
.PHONY: all

.DEFAULT_GOAL := all