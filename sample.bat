::
:: generates and builds sample files from the /glade directory
:: Window version
::
@echo off
set gate3=gate3
set outdir=code

FOR %%X  in (editor calculator lady lorenz) do (

:: generate Ada code from glade file
	%gate3% -p -d glade -o %outdir% %%X.glade

       IF ERRORLEVEL 1 GOTO Erreur
:: split Ada file into separate *.ads and *.adb files
	gnatchop -w %outdir%\%%X.ada %outdir%

:: generate executable
	gnatmake -p -Psample %%X.adb
        IF ERRORLEVEL 1 echo Could not compile
)

echo    gate3 tutorial : construction completed.
echo    examples are in the current directory
GOTO End
:Erreur
echo    gate3 tutorial : construction failed.
:End
