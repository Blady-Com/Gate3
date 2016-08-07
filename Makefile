.PHONY: bin/gate3

BUILD=Debug

GPRBUILD   = gprbuild
GPRINSTALL = gprinstall
GPRCLEAN   = gprclean

all : bin/gate3
	echo all

bin/gate3 :
	$(GPRBUILD) -p -XBUILD=$(BUILD) -P src/gate3.gpr

