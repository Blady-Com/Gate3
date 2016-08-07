:: Build : bat file
:: generate and build from file %1.glade located in /glade subdirectory
:: Ada files are put in /code subdirectory
:: Will fail when file has upper case letters
::
@echo off
set gate3=gate3
set outdir=code
set file=%1

::  generate a single Ada file from glade file
	%gate3% -p -d glade -o %outdir%  glade\%1.glade
        IF ERRORLEVEL 1 GOTO Erreur1

:: split Ada file into separate *.ads and *.adb files
	gnatchop -w %outdir%\%file%.ada %outdir%
::  generate executable
	gnatmake -p -Psample %file%.adb
        IF ERRORLEVEL 1 GOTO Erreur2
GOTO End
:Erreur1
    echo gate3 could not generate Ada file with %1.glade!
    GOTO End
:Erreur2
    echo Could not compile Ada file %file%.adb
:End
