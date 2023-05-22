del kaleidoscope.exe
del "..\winuae\hd0\kaleidoscope.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

pushd ..

tools\KingCon.exe @data/kaleidoscope/assets.txt
@if %ERRORLEVEL% NEQ 0 goto failed

tools\LSPConvert.exe data\music\desire_demo_68k_v6.mod -setpos -v
@if %ERRORLEVEL% NEQ 0 goto failed

popd

vc -O2 -notmpfile -nostdlib -o "kaleidoscope.exe" "kaleidoscope.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy kaleidoscope.exe "..\winuae\hd0"
copy kaleidoscope.exe "..\winuae\hd0\a"

@echo /|set /p =kaleidoscope.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae64" -config="configs\a500_hrt_more_mem.uae" -log -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
    @echo !!!!!!!!! oh no !!!!!!!!!!!!
    @pause
    del vc.cfg
:ok
