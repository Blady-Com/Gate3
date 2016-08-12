.PHONY: bin/gate3

BUILD=Debug
PREFIX=/usr/local

GPRBUILD   = gprbuild
GPRINSTALL = gprinstall
GPRCLEAN   = gprclean

all : bin/gate3 simple

bin/gate3 :
	$(GPRBUILD) -p -XBUILD=$(BUILD) -P src/gate3.gpr

reformat :
	gnatpp -M99 -rnb -XBUILD=$(BUILD) -P src/gate3.gpr

clean :
	$(GPRCLEAN) -XBUILD=$(BUILD) -P src/gate3.gpr
	$(GPRCLEAN) -XBUILD=$(BUILD) -P sample.gpr
	$(RM) code/*
	$(RM) bin/*
	$(RM) obj/*

simple editor calculator lady lorenz : bin/gate3
	./bin/gate3 -p -o code -d glade -t template $@.glade
	gnatchop -w code/$@.ada code
	$(GPRBUILD) -p -P sample.gpr $@.adb
	@echo
	@echo "building and testing of gate3 finished."
	@echo
	@echo "launching simple demo"
	@echo
	./bin/$@

install :
	$(GPRINSTALL) -f -p --prefix=$(PREFIX) -XBUILD=$(BUILD) -P src/gate3.gpr

