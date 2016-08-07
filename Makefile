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

