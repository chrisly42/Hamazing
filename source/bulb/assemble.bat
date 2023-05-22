del bulb.exe
del "..\winuae\hd0\bulb.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

pushd ..

tools\KingCon.exe @data/bulb/assets.txt
@if %ERRORLEVEL% NEQ 0 goto failed

tools\ZCP data/bulb/lamp_48x32x16.BPL data/bulb/lamp_48x32x16.zcp 48 32 -c data/bulb/lamp_48x32x16.chk
@if %ERRORLEVEL% NEQ 0 goto failed

popd

vc -O2 -notmpfile -nostdlib -o "bulb.exe" "bulb.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy bulb.exe "..\winuae\hd0"
copy bulb.exe "..\winuae\hd0\a"

@echo /|set /p =bulb.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae64" -config="configs\a500_hrt.uae" -log -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
    @echo !!!!!!!!! oh no !!!!!!!!!!!!
    @pause
    del vc.cfg
:ok
