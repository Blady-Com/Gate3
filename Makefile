.PHONY: bin/gate3

BUILD=Debug

GPRBUILD   = gprbuild
GPRINSTALL = gprinstall
GPRCLEAN   = gprclean

all : bin/gate3

bin/gate3 :
	$(GPRBUILD) -p -XBUILD=$(BUILD) -P src/gate3.gpr

reformat :
	gnatpp -M99 -rnb -XBUILD=$(BUILD) -P src/gate3.gpr

clean :
	$(GPRCLEAN) -XBUILD=$(BUILD) -P src/gate3.gpr

simple : bin/gate3
	./bin/gate3 -p -o code -d glade -t template simple.glade
	gnatchop -w code/simple.ada code
	$(GPRCLEAN) -P sample.gpr
	$(GPRBUILD) -p -P sample.gpr simple.adb
	@echo
	@echo "building and testing of gate3 finished."
	@echo
	@echo "launching simple demo"
	@echo
	./bin/simple
