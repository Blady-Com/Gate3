:: Tutorial : bat file
:: generates Ada prototype and builds executable file for tutorial 
:: Ada files are put in /src subdirectory
:: Will fail when file has upper case letters 
::      No simple way to convert to lower case => Windows shell is a pain !
:: 
@echo off
set gate3=..\gate3
set outdir=src
set file=%1

::  generate a single Ada file from glade file
	%gate3% -p -o %outdir%  %1.glade
        IF ERRORLEVEL 1 GOTO Erreur1

:: split Ada file into separate *.ads and *.adb files
	gnatchop -w %outdir%\%file%.ada %outdir%
::  generate executable
	gnatmake -p -Ptutorial %file%.adb
        IF ERRORLEVEL 1 GOTO Erreur2
GOTO End
:Erreur1
    echo gate3 could not generate Ada file with %1.glade!
    GOTO End
:Erreur2
    echo Could not compile Ada file %file%.adb
:End
