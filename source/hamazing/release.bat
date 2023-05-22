rem ############ PREPARE BUILD ############
@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

mkdir build

rem ############ BUILD DISK ############
..\tools\platosadf -ndb 2 build/demo.adf build/bootblock ../hamazing/layout.txt
@if %ERRORLEVEL% NEQ 0 goto failed

rem ############ START DEMO ############
"..\winuae\winuae64" -config="configs\a500_slow.uae" -log -s use_gui=no -s floppy0=%~dp0\build\demo.adf

rem ############ CLEANUP BUILD ############
del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
    @echo !!!!!!!!! oh no !!!!!!!!!!!!
    @pause
    del vc.cfg
:ok
