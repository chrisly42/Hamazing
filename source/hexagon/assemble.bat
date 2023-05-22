del hexagon.exe
del "..\winuae\hd0\hexagon.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

pushd ..

tools\KingCon.exe @data/hexagon/assets.txt
@if %ERRORLEVEL% NEQ 0 goto failed

tools\LSPConvert.exe data\music\desire_demo_68k_v6.mod -setpos -v
@if %ERRORLEVEL% NEQ 0 goto failed

popd

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "hexagon.exe" "hexagon.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy hexagon.exe "..\winuae\hd0"
copy hexagon.exe "..\winuae\hd0\a"

@echo /|set /p =hexagon.exe>"..\winuae\hd0\s\startup-sequence"

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
