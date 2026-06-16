include common.mk

all: sdk tests examples

sdk:
	cd targets$(SEP)65816 && $(MAKE) all

tests: sdk
	cd tests && $(MAKE) all

examples: sdk
	cd examples && $(MAKE) all

clean:
	cd targets$(SEP)65816 && $(MAKE) clean
	cd tests && $(MAKE) clean
	cd examples && $(MAKE) clean

.PHONY: all sdk tests examples clean
