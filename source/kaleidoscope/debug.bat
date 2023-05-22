del kaleidoscope.exe
del "..\winuae\hd0\kaleidoscope.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -g -hunkdebug -O2 -notmpfile -nostdlib -o "kaleidoscope.exe" "kaleidoscope.asm"

copy kaleidoscope.exe "..\winuae\hd0"
copy kaleidoscope.exe "..\winuae\hd0\a"

copy "..\winuae\hd0\s\debug-sequence" "..\winuae\hd0\s\startup-sequence"
@echo /|set /p =kaleidoscope.exe >>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae64" -config="configs\a500_debug.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg
