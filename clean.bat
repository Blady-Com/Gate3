::
:: clean sample files
:: Window verson
::
@echo off
echo cleaning samples
del calculator.exe
del editor.exe
del lorenz.exe
del lady.exe
del simple.exe
gnatclean -Psample.gpr
del code\*.ad?
::
echo cleaning completed !

