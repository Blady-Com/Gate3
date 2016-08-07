#!/bin/bash
#
# generate and build from file $1.glade located in /glade subdirectory
# Ada files are put in /code subdirectory
# handle files with upper case letters
#
gate3="./gate3"
outdir="code"
file=$1
lc_file=${file,,}

#  generate a single Ada file from glade file
	$gate3 -p -o $outdir $file.glade
	if [ $? -ne 0 ]; then
		echo "gate3 could not generate Ada file"
                exit 1
	fi
#  split Ada file into separate *.ads and *.adb files -- overwrite
	gnatchop -w $outdir/$lc_file.ada  $outdir
#  generate executable
	gnatmake -p -Psample.gpr $lc_file.adb

