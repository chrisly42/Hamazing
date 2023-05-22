; Storyboard:
; Partname     | Runtime | Pt | Chip Hunk + Dynamic = Total | Fast Hunk + Dynamic = Total | Disk Space | LOC
; Gotham       |  0:13.5 | -- |      9 KB     28 KB   37 KB |      3 KB     16 KB   19 KB |    4+17 KB | 1200
; -----------------------------------------------------------------------------------------------------------
; Music        |  2:35   | 19 |                      156 KB |                       15 KB |      91 KB |
; Bulb         |  0:59   |  0 |     54 KB    177 KB  231 KB |     58 KB    194 KB  252 KB |      59 KB | 3700
; STHam        |  0:28   |  7 |     87 KB     93 KB  180 KB |      9 KB      0 KB    9 KB |      70 KB | 1800
; Kaleidoscope |  0:54   |10.5|    148 KB    143 KB  291 KB |     19 KB    394 KB  413 KB |     150 KB | 6400
; Hexagon      |  0:13   |17.5|      4 KB    <64 KB  <68 KB |      5 KB     18 KB   23 KB |       4 KB |  900
; -----------------------------------------------------------------------------------------------------------
; Music 2      |  2:35   | 21 |                      172 KB |                       22 KB |     123 KB |
; Rubbercube   |  0:24   |  0 |      0 KB    291 KB  291 KB |     11 KB     44 KB   55 KB |       5 KB | 3000
; Virgillbars  |  0:52   |  4 |     15 KB    204 KB  208 KB |     11 KB    244 KB  255 KB |      14 KB | 3300
; Blend        |  1:15   | 11 |     43 KB    192 KB  234 KB |     25 KB    401 KB  426 KB |   50+xx KB | 5800
; -----------------------------------------------------------------------------------------------------------
; Music 3      |  1:45   | 14 |                       45 KB |                       12 KB |      24 KB |
; Endpart      |         |  0 |      5 KB    159 KB  164 KB |      2 KB      2 KB    4 KB |       3 KB |  900
;

trackmo:
        PUTMSG  10,<"%d: Trackmo start!">,fw_FrameCounterLong(a6)
.restart
        btst    #6,$bfe001
        bne.s   .part1
        lea     .secondmusicandgouraudloadinghook(pc),a0
        move.l  a0,fw_PrePartLaunchHook(a6)

        lea     .gotham(pc),a0
        CALLFW  ExecuteNextPart

        bra     .part2

.part1
        lea     .gotham(pc),a0
        lea     .musicandbulbloadinghook(pc),a1
        bsr     .executenextwithhook

        lea     .bulb(pc),a0
        lea     .sthamloadinghook(pc),a1
        bsr     .executenextwithhook

        lea     .stham(pc),a0
        lea     .kaleidoscopeloadinghook(pc),a1
        bsr     .executenextwithhook

        move.l  #256*256*2,d0
        CALLFW  AllocFast
        move.l  a0,fw_GlobalUserData(a6)
        PUTMSG  10,<"Kaleidoscope pattern %p">,a0

        ; this memory should not go away!
        CALLFW  PushMemoryState

        lea     .kaleidoscope(pc),a0
        lea     .hexagonpreploadinghook(pc),a1
        bsr     .executenextwithhook

        lea     .hexagon(pc),a0
        lea     .secondmusicloadinghook(pc),a1
        bsr     .executenextwithhook

        CALLFW  StopMusic

        ; High/Top memory
        CALLFW  FlipAllocationDirection
        CALLFW  PopMemoryState
        CALLFW  DropCurrentMemoryAllocations

        lea     .second_music_data(pc),a0
        CALLFW  FindFile
        move.l  de_MemorySize(a1),d0
        ; allocate LSP space
        CALLFW  AllocFast
        move.l  a0,fw_MusicData(a6)

        ; check how much ram we need for samples
        lea     .second_music_samples(pc),a0
        CALLFW  FindFile
        move.l  de_MemorySize(a1),d0

        ; allocate sample space
        CALLFW  AllocChip
        move.l  a0,fw_MusicSamples(a6)

        ; this memory should not go away!
        CALLFW  PushMemoryState

        lea     .decrunch2ndmusic(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask

        lea     .gouraud(pc),a0
        CALLFW  PreloadPart

        ; Bottom/Low memory again
        CALLFW  FlipAllocationDirection

        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  WaitUntilTaskFinished

        ; Free music packed
        CALLFW  PopMemoryState
        ; Free kaleidoscope memory
        CALLFW  PopMemoryState
        CALLFW  DropCurrentMemoryAllocations

.part2
        lea     .gouraud(pc),a0
        lea     .virgillbarsloadinghook(pc),a1
        bsr     .executenextwithhook

        lea     .virgillbars(pc),a0
        lea     .blendloadinghook(pc),a1
        bsr     .executenextwithhook

        lea     .blend(pc),a0
        lea     .unloadpreloaded(pc),a1
        bsr     .executenextwithhook

        CALLFW  FlipAllocationDirection
        CALLFW  PopMemoryState
        CALLFW  DropCurrentMemoryAllocations
        CALLFW  FlipAllocationDirection
        CALLFW  DropCurrentMemoryAllocations

.endpartpart
        lea     .end_music_data(pc),a0
        CALLFW  LoadAndDecrunchFile
        move.l  a0,fw_MusicData(a6)

        lea     .end_music_samples(pc),a0
        CALLFW  LoadAndDecrunchFile
        move.l  a0,fw_MusicSamples(a6)

        CALLFW  PushMemoryState

        lea     .endpart(pc),a0
        CALLFW  ExecuteNextPart

        CALLFW  StopMusic

        CALLFW  PopMemoryState
        CALLFW  DropCurrentMemoryAllocations

        clr.w   fw_FrameCounter(a6)
        bra     .restart

.executenextwithhook
        move.l  a1,fw_PrePartLaunchHook(a6)
        CALLFW  ExecuteNextPart
        rts

;--------------------------------------------------------------------

.musicandbulbloadinghook
        lea     .psenough(pc),a0
        CALLFW  FindFile
        move.l  de_DiskLength(a1),d0
        PUSHM   a1
        CALLFW  AllocFast
        POPM
        move.l  a0,fw_GlobalBonusData+gbd_PsPackedBuffer(a6)
        move.l  de_MemorySize(a1),d0
        CALLFW  AllocChip
        move.l  a0,fw_GlobalUserData(a6)

        lea     .loadmusicandbulb(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.sthamloadinghook
        bsr.s   .unloadpreloaded

        lea     .loadstham(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.kaleidoscopeloadinghook
        lea     .loadkaleidoscope(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.hexagonpreploadinghook
        bsr.s   .unloadpreloaded

        lea     .loadhexagon(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.secondmusicloadinghook
        bsr.s   .unloadpreloaded

        lea     .loadsecondmusic(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.unloadpreloaded
        CALLFW  FlipAllocationDirection
        CALLFW  DropCurrentMemoryAllocations
        CALLFW  FlipAllocationDirection
        rts

.virgillbarsloadinghook
        bsr.s   .unloadpreloaded

        lea     .loadvirgillbars(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.blendloadinghook
        bsr.s   .unloadpreloaded

        lea     .loadblend(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.endpartloadinghook
        bsr.s   .unloadpreloaded

        lea     .loadendpart(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

.secondmusicandgouraudloadinghook
        lea     .psenough(pc),a0
        CALLFW  FindFile
        move.l  de_DiskLength(a1),d0
        PUSHM   a1
        CALLFW  AllocFast
        POPM
        move.l  a0,fw_GlobalBonusData+gbd_PsPackedBuffer(a6)
        move.l  de_MemorySize(a1),d0
        CALLFW  AllocChip
        move.l  a0,fw_GlobalUserData(a6)

        lea     .loadmusicandgouraud(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        rts

;--------------------------------------------------------------------

.loadmusicandbulb
        lea     .psenough(pc),a0
        CALLFW  FindFile
        PUSHM   a1
        move.l  fw_GlobalBonusData+gbd_PsPackedBuffer(a6),a0
        CALLFW  LoadFileToBuffer
        POPM
        move.l  fw_GlobalBonusData+gbd_PsPackedBuffer(a6),a0
        move.l  fw_GlobalUserData(a6),a2
        CALLFW  DecrunchToBuffer

        CALLFW  FlipAllocationDirection

        lea     .first_music_data(pc),a0
        CALLFW  LoadAndDecrunchFile
        move.l  a0,fw_MusicData(a6)

        lea     .first_music_samples(pc),a0
        CALLFW  LoadAndDecrunchFile
        move.l  a0,fw_MusicSamples(a6)

        ; this memory should not go away!
        CALLFW  PushMemoryState

        lea     .bulb(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadstham
        CALLFW  FlipAllocationDirection

        lea     .stham(pc),a0
        CALLFW  PreloadPart

        lea     .hamphrey(pc),a0
        CALLFW  LoadFile
        move.l  a0,fw_GlobalUserData(a6)

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadkaleidoscope
        CALLFW  Yield
        tst.l   fw_GlobalUserData(a6)
        bne.s   .loadkaleidoscope

        CALLFW  FlipAllocationDirection
        CALLFW  DropCurrentMemoryAllocations

        lea     .kaleidoscope(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadhexagon
        CALLFW  FlipAllocationDirection

        lea     .hexagon(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadsecondmusic
        lea     .second_music_data(pc),a0
        CALLFW  LoadFile
        move.l  a0,fw_GlobalBonusData+gbd_LSPPackedBuffer(a6)

        lea     .second_music_samples(pc),a0
        CALLFW  LoadFile
        move.l  a0,fw_GlobalBonusData+gbd_SamplePackedBuffer(a6)

        CALLFW  PushMemoryState

        CALLFW  TrackloaderDiskMotorOff
        rts

.decrunch2ndmusic
        lea     .second_music_data(pc),a0
        CALLFW  FindFile
        move.l  fw_GlobalBonusData+gbd_LSPPackedBuffer(a6),a0
        move.l  fw_MusicData(a6),a2
        CALLFW  DecrunchToBuffer

        lea     .second_music_samples(pc),a0
        CALLFW  FindFile
        move.l  fw_GlobalBonusData+gbd_SamplePackedBuffer(a6),a0
        move.l  fw_MusicSamples(a6),a2
        CALLFW  DecrunchToBuffer
        rts

.loadvirgillbars
        CALLFW  FlipAllocationDirection

        lea     .virgillbars(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadendpart
        CALLFW  Yield
        tst.l   fw_GlobalUserData(a6)
        beq.s   .loadendpart

        CALLFW  FlipAllocationDirection

        lea     .endpart(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadmusicandgouraud
        lea     .psenough(pc),a0
        CALLFW  FindFile
        PUSHM   a1
        move.l  fw_GlobalBonusData+gbd_PsPackedBuffer(a6),a0
        CALLFW  LoadFileToBuffer
        POPM
        move.l  fw_GlobalBonusData+gbd_PsPackedBuffer(a6),a0
        move.l  fw_GlobalUserData(a6),a2
        CALLFW  DecrunchToBuffer

        CALLFW  FlipAllocationDirection

        lea     .second_music_data(pc),a0
        CALLFW  LoadAndDecrunchFile
        move.l  a0,fw_MusicData(a6)

        lea     .second_music_samples(pc),a0
        CALLFW  LoadAndDecrunchFile
        move.l  a0,fw_MusicSamples(a6)

        ; this memory should not go away!
        CALLFW  PushMemoryState

        lea     .gouraud(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.loadblend
        CALLFW  FlipAllocationDirection

        lea     .blend(pc),a0
        CALLFW  PreloadPart

        CALLFW  TrackloaderDiskMotorOff
        rts

.gotham dc.b    "Gotham",0
.bulb   dc.b    "Bulb",0
.kaleidoscope
        dc.b    "Kaleidoscope",0
.hexagon
        dc.b    "Hexagon",0
.gouraud
        dc.b    "Rubbercube",0
.virgillbars
        dc.b    "VirgillBars",0
.blend
        dc.b    "Blend",0
.stham
        dc.b    "STHam",0
.endpart
        dc.b    "Endpart",0
.psenough
        dc.b    "HamTech.smp",0
.hamphrey
        dc.b    "HAMphrey.raw",0
.first_music_data
        dc.b    "1st.lsmus",0
.first_music_samples
        dc.b    "1st.lsbnk",0
.second_music_data
        dc.b    "2nd.lsmus",0
.second_music_samples
        dc.b    "2nd.lsbnk",0
.end_music_data
        dc.b    "End.lsmus",0
.end_music_samples
        dc.b    "End.lsbnk",0
        even
.end