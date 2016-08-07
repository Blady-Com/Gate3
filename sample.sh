#!/bin/bash
#
# generates and builds sample files from the /glade directory
#
# scripts are a real pain for me !!!
echo
echo "generating sample examples from the glade directory"
echo
gate3="./gate3"
outdir="code"

examples=( editor calculator lady lorenz )
#
#
for example in "${examples[@]}"
do
#  generate Ada code from glade file
	$gate3 -p -d glade -o $outdir "${example}".glade
#  split Ada file into separate *.ads and *.adb files
	gnatchop -w $outdir/"${example}".ada $outdir
#  generate executable
	gnatmake -p -Psample.gpr "${example}".adb
	if [ "$?" -eq 0 ]; then
		echo
		echo "Example ${example} constructed"
        else
		echo
		echo "Problem to generate example ${example}"
	fi
	echo
done
echo
echo "gate3 tutorial : construction completed."
echo "    examples are in the current directory"
echo
