@echo off
::
echo builds and tests gate3
echo Windows version
::
::
gnatmake -p -Pgate3 -XLIBRARY_TYPE=relocatable
        IF ERRORLEVEL 1 GOTO Erreur:
::
echo building of gate3 successfull.
echo testing gate3 on simple glade file
::
gate3  -p -o code glade\simple.glade
gnatchop -w code\simple.ada code
gnatclean -Psample
gnatmake -p -Psample simple.adb
::
echo building and testing of gate3 finished.
::
echo launching simple demo
::
simple
GOTO End
:Erreur
    echo Unable to build gate3 !
    echo check that the following libraries are installed
    echo    -GtkAda
    echo    -Templates_Parser
    echo Note : On Windows, it is not possible to build static apps with Gtk !!
:End
