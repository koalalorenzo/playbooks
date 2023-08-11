JOBS := $(wildcard *.job.hcl)
VARIABLES := $(wildcard *.vars.sops.hcl)

$(VARIABLES):
	sops -d $@ | nomad var put -in=hcl -force -
.PHONY: $(VARIABLES)

$(JOBS):
	nomad plan $@
	nomad run $@
.PHONY: $(JOBS)

all: $(VARIABLES) $(JOBS)
.PHONY: all

.DEFAULT_GOAL := all