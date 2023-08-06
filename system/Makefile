JOBS := $(wildcard *.hcl)

$(JOBS):
	nomad plan $@
	nomad run $@
.PHONY: $(JOBS)

all: $(JOBS)
.PHONY: all

.DEFAULT_GOAL := all