#! /bin/bash
#
# build.sh - builds and tests gate3
#
#
echo "building gate3"
echo "Step 1 : compiling gate3"
echo
gnatmake -p -Pgate3
retcode=$?
if [ "$retcode" -ne 0 ]; then
	echo "unable to build gate3 !"
	echo "check that the following libraries are installed :"
        echo "       -GtkAda"
        echo "       -Templates_Parser"
        echo "default directory for project files :/usr/share/ada/adainclude"
	exit 2
fi
echo
echo "gate3 : build is successfull."
echo
echo "Step 2 : testing gate3 on a simple glade file"
echo
./gate3 -p -o code -d glade simple.glade
if [ $? -ne 0 ]; then
	echo "testing gate3 failed !"
	echo "send report to francois_fabien@hotmail.com"
	exit 2
fi
gnatchop -w code/simple.ada code
gnatclean -Psample
gnatmake -p -Psample simple.adb
echo
echo "building and testing of gate3 finished."
echo
echo "launching simple demo"
echo
./simple
