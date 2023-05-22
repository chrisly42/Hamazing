rem ############ PREPARE BUILD ############
@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

rem copy demo config for vasm
copy "..\tools\hddemo.cfg" vc.cfg

mkdir build

rem ############ ASSEMBLE PARTS ############
..\tools\vc -O2 -notmpfile -nostdlib -o "build\bulb.exe" "..\bulb\bulb.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\hexagon.exe" "..\hexagon\hexagon.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\kaleidoscope.exe" "..\kaleidoscope\kaleidoscope.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\virgillbars.exe" "..\virgillbars\virgillbars.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\blend.exe" "..\blend\blend.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\stham.exe" "..\stham\stham.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\gotham.exe" "..\gotham\gotham.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\endpart.exe" "..\endpart\endpart.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vc -O2 -notmpfile -nostdlib -o "build\gouraud.exe" "..\gouraud\gouraud.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy "..\data\music\desire_demo_68k_v6.lsbank" build
copy "..\data\music\desire_demo_68k_v6.lsmusic" build
copy "..\data\music\dsr_68k_tune_2_v11.lsbank" build
copy "..\data\music\dsr_68k_tune_2_v11.lsmusic" build
copy "..\data\music\desire_68k_tune3_v2.lsbank" build
copy "..\data\music\desire_68k_tune3_v2.lsmusic" build
copy "..\data\gotham\hamtechnology.raw" build
copy "..\data\stham\PLT_HAMph_path_2_test08b_ham.raw" build
copy "..\data\blend\fiveimg2_ham.raw" build
copy "..\data\blend\fiveimg3_ham.raw" build
copy "..\data\blend\fiveimg4_ham.raw" build
copy "..\data\blend\fiveimg5_ham.raw" build
copy "..\data\blend\PLT_DSRLogo01c_ham.raw" build
copy "..\data\endpart\screenshots_320x1620.BPL" build

rem ############ ASSEMBLE BOOTBLOCK ############
copy "..\tools\vc.cfg" %~dp0

..\tools\vasmm68k_mot -m68000 -Fbin -phxass -o "build\bootblock" -I"%~dp0\..\includes" "..\framework\bootblock.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

rem ############ BUILD TRUNCATED DISK ############
..\tools\platosadf -ndb 3 -f -t build/hddemo.adf build/bootblock hdlayout.txt
@if %ERRORLEVEL% NEQ 0 goto failed

rem ############ ASSEMBLE HD LAUNCHER ############

..\tools\vc -O2 -notmpfile -nostdlib -o "build\hd_launcher.exe" "hd_launcher.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

copy build\hd_launcher.exe "..\winuae\hd0"

@echo /|set /p =hd_launcher.exe>"..\winuae\hd0\s\startup-sequence"

rem ############ START DEMO ############
"..\winuae\winuae64" -config="configs\a500_hd.uae" -log -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

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
