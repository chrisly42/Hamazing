# Hamazing by Desire

This is the source code of Hamazing and PLatOS demo framework.

It's supposed to build on a Windows machine (sorry).
Some of the stuff was originally part of
[Axis' Planet Rocklobster framework](https://github.com/AxisOxy/Planet-Rocklobster)
and that may show in structure and some of the tools used.

## Building

Go into the `source/hamazing` directory and type `build.bat`.

Each part can be run as a standalone executable for testing by entering
the part's source directory and running `assemble.bat`.

Note that you need to supply Kickstart roms for WinUAE in the
`source/winuae/Roms` directory. AROS rom replacement _may_ work, but
your milage may vary. It doesn't run the trackmo for unknown reasons.

## Third party stuff

This software uses or provides binaries of

- LightSpeedPlayer, LSPConvert - https://github.com/arnaud-carre/LSPlayer
- Raspberry Casket Pretracker Replayer - https://github.com/chrisly42/PretrackerRaspberryCasket
- KingCon
- DevIl - http://openil.sourceforge.net
- WinUAE - http://www.winuae.net
- VASM - http://sun.hasenbraten.de/vasm
- Shrinkler - https://github.com/askeksa/Shrinkler
- LZ4 - https://github.com/lz4/lz4
- ZX0 - https://github.com/einar-saukas/ZX0
- Salvador - https://github.com/emmanuel-marty/salvador
- Doynamite68k

## Make your own demos!

You can use the framework to make your own demos or intros.
There is documentation inside the source code.
Right now, I'm not quite motivated to write more than necessary.

You can look at the effects to see how things are done.

But only lamers will copy code verbatim. 
Give credits where credits are due.

And now go and have some fun. Use the Blitter, Luke! Make Amiga Great Again!

Signing off, Chris 'platon42' Hodges