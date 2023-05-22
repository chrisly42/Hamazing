del gouraud.exe
del "..\winuae\hd0\gouraud.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "gouraud.exe" "gouraud.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy gouraud.exe "..\winuae\hd0"
copy gouraud.exe "..\winuae\hd0\a"

@echo /|set /p =gouraud.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae64" -config="configs\a1200_hrt.uae" -log -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
    @echo !!!!!!!!! oh no !!!!!!!!!!!!
    @pause
    del vc.cfg
:ok
