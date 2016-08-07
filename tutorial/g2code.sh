#!/bin/bash
#
# generate and build from file $1.glade located in current directory
# Ada files are put in /src subdirectory
# handle files with upper case letters
#
gate3="../gate3"
outdir="src"
file=$1
lc_file=${file,,}

#  generate a single Ada file from glade file
	$gate3 -p -o $outdir $file.glade
	if [ $? -ne 0 ]; then
		echo "gate3 : could not generate Ada file from $file.glade"
                exit 1
	fi
#  split Ada file into separate *.ads and *.adb files -- overwrite
	gnatchop -w $outdir/$lc_file.ada  $outdir
#  generate executable
	gnatmake -p -Ptutorial $lc_file.adb
	if [ $? -ne 0 ]; then
		echo "gnatmake : could not compile $lc_file.adb"
                exit 1
	fi

