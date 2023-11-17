.PHONY: d_build
d_build:
	./scripts/build.sh -t d

.PHONY: c_run
c_run:
	./scripts/run.sh -b

-include $(LDDT_ROOT)/scripts/build.mk