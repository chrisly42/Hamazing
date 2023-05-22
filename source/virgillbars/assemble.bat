del virgillbars.exe
del "..\winuae\hd0\virgillbars.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

pushd ..

tools\KingCon.exe @data/virgillbars/assets.txt
@if %ERRORLEVEL% NEQ 0 goto failed

tools\LSPConvert.exe data\music\dsr_68k_tune_2_v11.mod -setpos -v
@if %ERRORLEVEL% NEQ 0 goto failed

popd

vc -O2 -notmpfile -nostdlib -o "virgillbars.exe" "virgillbars.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy virgillbars.exe "..\winuae\hd0"
copy virgillbars.exe "..\winuae\hd0\a"

@echo /|set /p =virgillbars.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae" -config="configs\a500_hrt.uae" -log -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
    @echo !!!!!!!!! oh no !!!!!!!!!!!!
    @pause
    del vc.cfg
:ok
