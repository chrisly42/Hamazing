del stham.exe
del "..\winuae\hd0\stham.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "stham.exe" "stham.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy stham.exe "..\winuae\hd0"
copy stham.exe "..\winuae\hd0\a.exe"

@echo /|set /p =stham.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae64" -config="configs\a500_rec.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
    @echo !!!!!!!!! oh no !!!!!!!!!!!!
    @pause
    del vc.cfg
:ok
