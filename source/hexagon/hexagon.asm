; Framework settings

        IFD     FW_DEMO_PART
        IFD     FW_HD_DEMO_PART
        include "../hamazing/hdtrackmo_settings.i"
        ELSE
        include "../hamazing/trackmo_settings.i"
        ENDC
        ELSE
FW_STANDALONE_FILE_MODE     = 1 ; enable standalone (part testing)
FW_HD_TRACKMO_MODE          = 0 ; DO NOT CHANGE (not supported for standalone mode)

FW_MUSIC_SUPPORT            = 1
FW_MUSIC_PLAYER_CHOICE      = 2 ; 0 = None, 1 = LSP, 2 = LSP_CIA, 3 = P61A, 4 = Pretracker (CPU DMA wait), 5 = Pretracker Turbo (Copper wait)
FW_LMB_EXIT_SUPPORT         = 1 ; allows abortion of intro with LMB
FW_MULTIPART_SUPPORT        = 0 ; DO NOT CHANGE (not supported for standalone mode)
FW_DYNAMIC_MEMORY_SUPPORT   = 1 ; enable dynamic memory allocation. Otherwise, use fw_ChipMemStack/End etc fields.
FW_MAX_MEMORY_STATES        = 4 ; the amount of memory states
FW_TOP_BOTTOM_MEM_SECTIONS  = 0 ; allow allocations from both sides of the memory
FW_64KB_PAGE_MEMORY_SUPPORT = 1 ; allow allocation of chip memory that doesn't cross the 64 KB page boundary
FW_MULTITASKING_SUPPORT     = 1 ; enable multitasking
FW_ROUNDROBIN_MT_SUPPORT    = 0 ; enable fair scheduling among tasks with same priority
FW_BLITTERTASK_MT_SUPPORT   = 0 ; enable single parallel task during large blits
FW_MAX_VPOS_FOR_BG_TASK     = 308 ; max vpos that is considered to be worth switching to a background task, if any
FW_SINETABLE_SUPPORT        = 1 ; enable creation of 1024 entries sin/cos table
FW_SCRIPTING_SUPPORT        = 1 ; enable simple timed scripting functions
FW_PALETTE_LERP_SUPPORT     = 1 ; enable basic palette fading functions
FW_YIELD_FROM_MAIN_TOO      = 0 ; adds additional code that copes with Yield being called from main code instead of task
FW_VBL_IRQ_SUPPORT          = 0 ; enable custom VBL IRQ routine
FW_COPPER_IRQ_SUPPORT       = 0 ; enable copper IRQ routine support
FW_AUDIO_IRQ_SUPPORT        = 0 ; enable audio IRQ support (unimplemented)
FW_VBL_MUSIC_IRQ            = 0 ; enable calling of VBL based music ticking (disable, if using CIA timing!)
FW_BLITTERQUEUE_SUPPORT     = 1 ; enable blitter queue support
FW_A5_A6_UNTOUCHED          = 1 ; speed up blitter queue if registers a5/a6 are never changed in main code

FW_LZ4_SUPPORT              = 0 ; compile in LZ4 decruncher
FW_DOYNAX_SUPPORT           = 0 ; compile in doynax decruncher
FW_ZX0_SUPPORT              = 0 ; compile in ZX0 decruncher

FW_DO_FANCY_WORKBENCH_STUFF = 0 ; enable pre- and post-hook (os startup only)

ENABLE_PART_MUSIC           = 1
PART_MUSIC_START_POS        = 17

        ENDC

HEXAGON_WIDTH   = 320
HEXAGON_HEIGHT  = 254

COP_LIST_SIZE = 4000*4

HEXCHUNKY_WIDTH = 22
HEXCHUNKY_HEIGHT = 25

WINNER_WIDTH = 128
WINNER_HEIGHT = 128

CHIPMEM_SIZE = 100000
FASTMEM_SIZE = 2*4096*2

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_LastPlanesPtr
        APTR    pd_CurrChunkyPtr
        APTR    pd_LastChunkyPtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        UBYTE   pd_CopListToggle
        UBYTE   pd_DbToggle
        ALIGNWORD

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        UWORD   pd_ChunkyCopperListOffset

        UWORD   pd_Angle
        UWORD   pd_WinnerKilled
        UWORD   pd_WinnerXPos
        UWORD   pd_WinnerYPos
        UWORD   pd_WinnerXDir

        ULONG   pd_StartLineuu00VVvv
        UWORD   pd_StartLineUU
        ULONG   pd_EvenToOddLineuu00VVvvInc
        UWORD   pd_EvenToOddLineUUInc
        ULONG   pd_OddToEvenLineuu00VVvvInc
        UWORD   pd_OddToEvenLineUUInc

        APTR    pd_TexturePtr
        APTR    pd_ChunkyBuffer1
        APTR    pd_ChunkyBuffer2
        APTR    pd_ShadeTableXor
        APTR    pd_ShadeTableAdd1

        STRUCT  pd_PreparationTask,ft_SIZEOF
        STRUCT  pd_HexPalette,16*cl_SIZEOF
        STRUCT  pd_WinnerSprites,8*4

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        bsr     hex_init

        lea     hex_copperlist,a0
        CALLFW  SetCopper

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        move.l  #part_music_data,fw_MusicData(a6)
        move.l  #part_music_smp,fw_MusicSamples(a6)
        CALLFW  StartMusic
        IFD     PART_MUSIC_START_POS
        moveq.l #PART_MUSIC_START_POS,d0
        CALLFW  MusicSetPosition
        move.w  #6336,fw_MusicFrameCount(a6)
        ENDC
        ENDC
        ENDC

        bsr     hex_main

        CALLFW  StopMusic

        lea     pd_PreparationTask(a6),a1
        CALLFW  RemTask

        CALLFW  SetBaseCopper

        rts

;--------------------------------------------------------------------

hex_init:
        bsr     hex_init_vars
        bsr     hex_fill_chunky_buffers

        lea     .backgroundtasks(pc),a0
        lea     pd_PreparationTask(a6),a1
        CALLFW  AddTask

        rts

.backgroundtasks
        bsr     hex_init_shade_table
        rts

;--------------------------------------------------------------------

hex_init_vars:
        IFD     FW_DEMO_PART
        move.l  fw_GlobalUserData(a6),pd_TexturePtr(a6)
        ELSE
        move.l  #hex_kaleidoscope_texture,pd_TexturePtr(a6)
        ENDC
        move.l  #COP_LIST_SIZE,d0
        CALLFW  AllocChip64KB
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)

        move.l  #COP_LIST_SIZE,d0
        CALLFW  AllocChip64KB
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        move.l  #HEXCHUNKY_WIDTH*HEXCHUNKY_HEIGHT*2*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"ChunkyBuffer1 %p">,a0
        move.l  a0,pd_ChunkyBuffer1(a6)
        move.l  a0,pd_CurrChunkyPtr(a6)
        lea     HEXCHUNKY_WIDTH*HEXCHUNKY_HEIGHT*2(a0),a0
        move.l  a0,pd_ChunkyBuffer2(a6)
        move.l  a0,pd_LastChunkyPtr(a6)

        move.l  #2*4096*2,d0
        CALLFW  AllocFast
        move.l  a0,pd_ShadeTableXor(a6)
        PUTMSG  10,<"ShadeTableXor %p">,a0
        lea     4096*2(a0),a0
        move.l  a0,pd_ShadeTableAdd1(a6)
        PUTMSG  10,<"ShadeTableAdd1 %p">,a0


        lea     pd_WinnerSprites(a6),a1
        lea     hex_winners_sprites,a3
        move.l  a3,a2
        moveq.l #(WINNER_WIDTH/16)-1,d7
.sprloop
        move.l  a3,a0
        adda.w  (a2)+,a0
        move.l  d0,(a0)
        move.l  a0,(a1)+
        dbra    d7,.sprloop

        move.w  #HEXAGON_WIDTH,pd_WinnerXPos(a6)
        move.w  #0,pd_WinnerYPos(a6)
        rts

;--------------------------------------------------------------------

hex_init_shade_table:
        move.l  pd_ShadeTableXor(a6),a0
        move.l  a0,a1
        moveq.l #0,d0
.xorloop
        moveq.l #$11,d3
        moveq.l #15,d1
        cmp.b   d1,d0
        bhi.s   .upperset
        and.b   d1,d3
.upperset
        and.b   d0,d1
        bne.s   .lowerset
        subq.b  #1,d3
.lowerset
        move.w  d3,(a0)+
        addq.b  #1,d0
        bne.s   .xorloop

        moveq.l #15-1,d7
        move.l  #$01000100,d3
.xoroloop
        move.l  a1,a2
        move.w  #128-1,d6
.xor2loop
        move.l  (a2)+,d0
        add.l   d3,d0
        move.l  d0,(a0)+
        dbra    d6,.xor2loop
        dbra    d7,.xoroloop

        move.l  pd_ShadeTableAdd1(a6),a1
        moveq.l #0,d0
        move.w  #4096-1,d7
.sub1loop
        move.w  d0,d1
        add.w   -(a0),d1
        move.w  d1,(a1)+
        addq.w  #1,d0
        dbra    d7,.sub1loop

        rts

;--------------------------------------------------------------------

hex_main:
        PUTMSG  10,<"%d: Main part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        move.w  #2,copcon(a5)               ; enable copper danger (copper controlled blitter)

        REPT    2
        bsr     hex_flip_copperlists

        move.l  pd_CurrCopListPtr(a6),a0
        bsr     hex_hexagonchunky_create_copperlist
        ; offset is not known in first run!
        move.l  pd_CurrCopListPtr(a6),a0
        bsr     hex_hexagonchunky_create_copper_blittercopy
        ENDR

        move.w  #$fff,d0
        move.w  d0,color+17*2(a5)
        move.w  d0,color+21*2(a5)
        move.w  d0,color+25*2(a5)
        move.w  d0,color+29*2(a5)
        moveq.l #0,d0
        move.w  d0,color+19*2(a5)
        move.w  d0,color+23*2(a5)
        move.w  d0,color+27*2(a5)
        move.w  d0,color+31*2(a5)

        moveq.l #16,d0
        move.w  #$346,d1
        lea     pd_HexPalette(a6),a1
        CALLFW  InitPaletteLerpSameColor

        moveq.l #16,d0
        moveq.l #64,d1
        lea     hex_hexgrid_palette(pc),a0
        lea     pd_HexPalette(a6),a1
        CALLFW  FadePaletteTo

        lea     .script(pc),a0
        CALLFW  InstallScript

        lea     .musicscript(pc),a0
        CALLFW  InstallMusicScript

        PUTMSG  10,<"Chunky %p">,a0
.loop
        bsr     hex_flip_copperlists

        moveq.l #16,d0
        lea     pd_HexPalette(a6),a1
        CALLFW  DoFadePaletteStep

        lea     pd_HexPalette(a6),a1
        REPT    16
        move.w  pd_HexPalette+REPTN*cl_SIZEOF+cl_Color(a6),color+REPTN*4(a5)
        ENDR

        CALLFW  CheckScript
        CALLFW  CheckMusicScript

        bsr     hex_update_winner_sprites

        bsr     hex_do_rotozoomer

        bsr     hex_update_copper_list_pointers

        CALLFW  VSyncWithTask

        move.w  fw_LspMusicLength+2(a6),d0
        subq.w  #2,d0
        cmp.w   fw_MusicFrameCount(a6),d0
        bge.s   .loop

        rts

.script
        dc.w    120,.move_winner_left-*
        dc.w    120+WINNER_WIDTH,.stop_winner-*
        dc.w    400,.move_winner_right-*
        dc.w    400+WINNER_WIDTH/2,.stop_and_kill_winner-*
        dc.w    0

.musicscript
        dc.w    6720,.flash-*
        dc.w    6720+16*6,.startdarken-*
        dc.w    6720+32*6,.fadeout-*
        dc.w    0

.move_winner_left
        move.w  #-1,pd_WinnerXDir(a6)
        rts
.stop_and_kill_winner
        st      pd_WinnerKilled(a6)
.stop_winner
        clr.w   pd_WinnerXDir(a6)
        rts
.move_winner_right
        move.w  #2,pd_WinnerXDir(a6)
        rts

.flash
        PUTMSG  10,<"Flash!">
        moveq.l #16,d0
        move.w  #$fff,d1
        lea     pd_HexPalette(a6),a1
        CALLFW  InitPaletteLerpSameColor

        moveq.l #16,d0
        moveq.l #32,d1
        lea     hex_hexgrid_palette(pc),a0
        lea     pd_HexPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.startdarken
        PUTMSG  10,<"Start darken">
        lea     pd_PreparationTask(a6),a1
        move.b  #-20,LN_PRI(a1)
        lea     .brightentextureloop(pc),a0
        CALLFW  AddTask
        rts

.fadeout
        moveq.l #16,d0
        moveq.l #64,d1
        lea     hex_hexgrid_black_palette(pc),a0
        lea     pd_HexPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.brightentextureloop
        move.w  fw_MusicFrameCount(a6),d6
        add.w   #15,d6
        moveq.l #16-1,d7
.brloop
        PUSHM   d6/d7
        bsr     hex_brighten_tc_data
        POPM
.retry
        cmp.w   fw_MusicFrameCount(a6),d6
        blt.s   .contbr
        PUTMSG  10,<"Yielding">
        CALLFW  Yield
        bra.s   .retry
.contbr
        add.w   #15,d6
        dbra    d7,.brloop

        rts

;--------------------------------------------------------------------

hex_flip_copperlists:
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        move.l  pd_CurrChunkyPtr(a6),pd_LastChunkyPtr(a6)
        not.b   pd_CopListToggle(a6)
        beq.s   .selb1
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        move.l  pd_ChunkyBuffer2(a6),pd_CurrChunkyPtr(a6)
        rts
.selb1
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        move.l  pd_ChunkyBuffer1(a6),pd_CurrChunkyPtr(a6)
        rts

;--------------------------------------------------------------------

hex_update_copper_list_pointers:
        lea     hex_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

hex_update_winner_sprites:
        lea     pd_WinnerSprites(a6),a2

        moveq.l #0,d0
        moveq.l #0,d4
        tst.w   pd_WinnerKilled(a6)
        bne.s   .filldata

        move.w  pd_WinnerXPos(a6),d4
        add.w   pd_WinnerXDir(a6),d4
        move.w  d4,pd_WinnerXPos(a6)
        move.w  pd_WinnerYPos(a6),d1

        add.w   #128,d4
        add.w   #$52,d1

        move.w  d1,d2
        add.w   #WINNER_HEIGHT,d2
        moveq.l #0,d0

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d0,d0       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d0,d0       ; ev8
        lsr.w   #1,d4       ; sh8-sh1 in d4
        addx.w  d0,d0       ; sh0
        or.w    d2,d0       ; ev7-ev0, sv8, ev8, sh0 in d0
        or.w    d1,d4       ; sv7-sv0, sh8-sh1 in d4
        ;tas     d0          ; att TAS sets bit 7
.filldata
        REPT    (WINNER_WIDTH/16)
        move.l  (a2)+,a0
        move.w  d4,(a0)+
        move.w  d0,(a0)+
        addq.w  #8,d4
        ENDR
        rts

;--------------------------------------------------------------------

hex_fill_chunky_buffers:
        BLTHOGON
        BLTWAIT

        BLTCON_SET D,BLT_C,0,0
        move.w  #0,bltdmod(a5)
        move.w  #$346^$fff,bltcdat(a5)
        move.l  pd_ChunkyBuffer1(a6),bltdpt(a5)
        move.w  #(HEXCHUNKY_WIDTH*2)|((HEXCHUNKY_HEIGHT)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

hex_brighten_tc_data:
        move.l  pd_TexturePtr(a6),a0
        move.l  a0,a2
        add.l   #256*256*2,a2
        move.l  pd_ShadeTableAdd1(a6),a1
.loop   movem.w (a0),d0-d7
        add.w   d0,d0
        add.w   d1,d1
        add.w   d2,d2
        add.w   d3,d3
        add.w   d4,d4
        add.w   d5,d5
        add.w   d6,d6
        add.w   d7,d7
        move.w  (a1,d0.w),(a0)+
        move.w  (a1,d1.w),(a0)+
        move.w  (a1,d2.w),(a0)+
        move.w  (a1,d3.w),(a0)+
        move.w  (a1,d4.w),(a0)+
        move.w  (a1,d5.w),(a0)+
        move.w  (a1,d6.w),(a0)+
        move.w  (a1,d7.w),(a0)+
        cmp.l   a0,a2
        bne.s   .loop
        rts

;--------------------------------------------------------------------

hex_do_rotozoomer:
        add.w   #$074,pd_StartLineuu00VVvv+2(a6)
        addq.b  #1,pd_StartLineUU(a6)
        add.b   #44,pd_StartLineuu00VVvv(a6)

        move.l  fw_SinTable(a6),a0
        move.l  fw_CosTable(a6),a1
        move.w  pd_Angle(a6),d0
        addq.w  #4,d0
        move.w  d0,pd_Angle(a6)
        and.w   #1023*2,d0
        move.w  d0,d1
        lsr.w   #1,d1
        and.w   #1023*2,d1
        move.w  (a0,d1.w),d3 ; zoom
        lsr.w   #2,d3
        add.w   #64,d3

        move.w  (a1,d0.w),d4 ; acos (U)
        move.w  (a0,d0.w),d5 ; asin (V)
        ; scale
        muls    d3,d4
        muls    d3,d5
        swap    d4          ; UUuu
        swap    d5          ; VVvv
        PUTMSG  40,<"UUuu = %x, VVvv = %x">,d4,d5

        ; even to odd increment
        move.w  d4,d0
        asr.w   #1,d0
        add.w   d5,d0
        neg.w   d0          ; -asin - (acos / 2)
        move.b  d0,pd_EvenToOddLineuu00VVvvInc(a6)
        move.w  d0,pd_EvenToOddLineUUInc(a6)
        move.w  d5,d0
        asr.w   #1,d0
        neg.w   d0
        add.w   d4,d0       ; acos - (asin / 2)
        move.w  d0,pd_EvenToOddLineuu00VVvvInc+2(a6)

        ; odd to even increment
        move.w  d5,d0
        neg.w   d0
        add.w   d4,d0       ; -asin + acos
        move.b  d0,pd_OddToEvenLineuu00VVvvInc(a6)
        move.w  d0,pd_OddToEvenLineUUInc(a6)

        move.w  d5,d0
        add.w   d4,d0
        move.w  d0,pd_OddToEvenLineuu00VVvvInc+2(a6)

        swap    d5
        move.b  d4,-(sp)
        move.w  (sp)+,d5
        clr.b   d5
        swap    d5          ; uu__VVvv
        move.w  d4,-(sp)
        move.b  (sp)+,d4    ; xxxxxxUU

        move.l  pd_StartLineuu00VVvv(a6),d2 ; startuu00VVvv
        move.b  pd_StartLineUU(a6),d3       ; start______UU

        move.l  pd_CurrChunkyPtr(a6),a0
        move.l  pd_TexturePtr(a6),a1

        moveq.l #(HEXCHUNKY_HEIGHT/2)-1,d7
.yloop
        move.w  d7,-(sp)

        ; even line
        move.l  d2,d0       ; uu__VVvv
        move.w  d3,d1       ; ______UU

        moveq.l #HEXCHUNKY_WIDTH-1,d7
.xloop1
        moveq.l #0,d6
        move.w  d0,d6
        move.b  d1,d6
        add.l   d6,d6
        move.w  (a1,d6.l),(a0)+
        add.l   d5,d0
        addx.b  d4,d1
        dbra    d7,.xloop1

        move.b  pd_OddToEvenLineUUInc(a6),d6
        add.l   pd_OddToEvenLineuu00VVvvInc(a6),d2
        addx.b  d6,d3

        ; odd line
        move.l  d2,d0       ; uu__VVvv
        move.w  d3,d1       ; ______UU

        moveq.l #HEXCHUNKY_WIDTH-1,d7
.xloop2
        moveq.l #0,d6
        move.w  d0,d6
        move.b  d1,d6
        add.l   d6,d6
        move.w  (a1,d6.l),(a0)+
        add.l   d5,d0
        addx.b  d4,d1
        dbra    d7,.xloop2

        move.b  pd_EvenToOddLineUUInc(a6),d6
        add.l   pd_EvenToOddLineuu00VVvvInc(a6),d2
        addx.b  d6,d3

        move.w  (sp)+,d7
        dbra    d7,.yloop

        ; even line
        move.l  d2,d0       ; uu__VVvv
        move.w  d3,d1       ; ______UU

        moveq.l #HEXCHUNKY_WIDTH-1,d7
.xloop3
        moveq.l #0,d6
        move.w  d0,d6
        move.b  d1,d6
        add.l   d6,d6
        move.w  (a1,d6.l),(a0)+
        add.l   d5,d0
        addx.b  d4,d1
        dbra    d7,.xloop3

        rts

;--------------------------------------------------------------------

SKIPLINESNOOVR MACRO
        lsl.w   #8,d1
        add.w   d1,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        ENDM

; 256*9 + 43*2 instructions (plus a about 40 other insts) around 2500, plus 43*25 (plus two empty ones) insts = 1118

hex_hexagonchunky_create_copper_blittercopy:
        COPIMOVE DMAF_RASTER,dmacon ; disable display DMA
        COPBLITWAIT
        COPIMOVE BLTEN_AD|((BLT_A^BLT_C)&$ff),bltcon0
        COPIMOVE 0,bltcon1
        COPIMOVE $ffff,bltafwm
        COPIMOVE $ffff,bltalwm
        COPIMOVE $fff,bltcdat
        COPIMOVE 0,bltamod
        COPIMOVE 6,bltdmod

        move.l  pd_LastChunkyPtr(a6),a1
        COPPTMOVE a1,bltapt,d0
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_ChunkyCopperListOffset(a6),a1
        COPPTMOVE a1,bltdpt,d0
        COPIMOVE (1|(HEXCHUNKY_WIDTH*HEXCHUNKY_HEIGHT)<<6),bltsize
        rts

;--------------------------------------------------------------------

hex_hexagonchunky_create_copperlist:
        bsr     hex_hexagonchunky_create_copper_blittercopy
        moveq.l #-2,d3

        lea     pd_WinnerSprites(a6),a1
        move.w  #sprpt,d1
        moveq.l #(WINNER_WIDTH/16)*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma
        COPIMOVE $6200,bplcon0

        move.w  #$00df,d0
        moveq.l #$2c,d1
        SKIPLINESNOOVR

        lea     hex_hexgrid_data(pc),a2

        lea     4+8+4+2(a0),a1
        move.l  a1,d1
        swap    d1
        COPRMOVE d1,cop1lc

        lea     2500*4(a0),a4

        move.l  a4,a1
        suba.l  pd_CurrCopListPtr(a6),a1
        lea     6+HEXCHUNKY_WIDTH*2*4(a1),a1 ; first line is ignored
        move.w  a1,pd_ChunkyCopperListOffset(a6)

        move.l  a4,a3

        move.l  #(bpldat<<16),d2
        move.l  #((color+16*2)<<16)|$253,d1
        ;move.l  #((color)<<16)|$253,d1
        moveq.l #(25+2)-2,d6
.chloop
        moveq.l #((HEXAGON_WIDTH+16)/16)-1,d7
.xloop
        move.l  d2,(a3)+
        move.l  d1,(a3)+
        add.w   #$423,d1
        dbra    d7,.xloop
        move.l  #copjmp1<<16,(a3)+
        move.l  #$1fe<<16,(a3)+
        dbra    d6,.chloop

        move.l  a4,a3
        COPRMOVE a3,cop2lc+2

        moveq.l #2-1,d7
.iloop
        move.w  (a2)+,d2            ; unused
        move.w  #bpldat+1*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+2*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+3*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+4*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+5*2,(a0)+
        move.w  (a2)+,(a0)+

        lea     8+4(a0),a1
        COPRMOVE a1,cop1lc+2

        move.b  #$2f,d0
        add.w   #$100,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.l  #copjmp2<<16,(a0)+

        dbra    d7,.iloop

        moveq.l #12-1,d6
.drloop
        lea     44*4(a4),a4
        lea     8(a4),a3
        COPRMOVE a3,cop2lc+2

        moveq.l #10-1,d7
.y1loop
        move.w  (a2)+,d2            ; unused
        move.w  #bpldat+1*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+2*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+3*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+4*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+5*2,(a0)+
        move.w  (a2)+,(a0)+

        lea     8+4(a0),a1
        COPRMOVE a1,cop1lc+2

        move.b  #$33,d0
        add.w   #$100,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.l  #copjmp2<<16,(a0)+

        dbra    d7,.y1loop

        lea     44*4(a4),a4
        move.l  a4,a3
        COPRMOVE a3,cop2lc+2
        moveq.l #10-1,d7
.y2loop
        move.w  (a2)+,d2            ; unused
        move.w  #bpldat+1*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+2*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+3*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+4*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+5*2,(a0)+
        move.w  (a2)+,(a0)+

        lea     8+4(a0),a1
        COPRMOVE a1,cop1lc+2

        move.b  #$2f,d0
        add.w   #$100,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.l  #copjmp2<<16,(a0)+

        dbra    d7,.y2loop

        ;lea     -20*2*6(a2),a2
        dbra    d6,.drloop

        lea     44*4(a4),a4
        lea     8(a4),a3
        COPRMOVE a3,cop2lc+2

        moveq.l #12-1,d7
.y3loop
        move.w  (a2)+,d2            ; unused
        move.w  #bpldat+1*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+2*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+3*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+4*2,(a0)+
        move.w  (a2)+,(a0)+
        move.w  #bpldat+5*2,(a0)+
        move.w  (a2)+,(a0)+

        lea     8+4(a0),a1
        COPRMOVE a1,cop1lc+2

        move.b  #$33,d0
        add.w   #$100,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.l  #copjmp2<<16,(a0)+

        dbra    d7,.y3loop

        lea     hex_copperlist,a1
        COPPTMOVE a1,cop1lc,d1

        move.l  d3,(a0)
        rts

;--------------------------------------------------------------------

hex_hexgrid_palette:
        dc.w    $000,$ccc,$aaa,$888
        dc.w    $666,$9ac,$57a,$357
        dc.w    $0f0,$eee,$eee,$cc8
        dc.w    $884,$aa6,$a40,$620

hex_hexgrid_black_palette:
        REPT    16
        dc.w    $000
        ENDR

hex_hexgrid_data:
        incbin  "../data/hexagon/hexagon_reg16x254.EHB"

        section "hex_copper",data,chip

hex_copperlist:
        COP_MOVE dmacon,DMAF_RASTER|DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$2c81          ; window start
        COP_MOVE diwstop,$2cc1          ; window stop
        COP_MOVE ddfstrt,$0038          ; bitplane start
        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00
        COP_MOVE fmode,$0000            ; fixes the aga modulo problem
        COP_MOVE bplcon0,$0200

hex_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

hex_winners_sprites:
        incbin  "../data/hexagon/winners128x128x4.SPR"

        IFND    FW_DEMO_PART
        section "hex_kaleidoscope_texture",data
hex_kaleidoscope_texture:
        incbin  "../data/hexagon/kaleitc.raw"

        IFD     ENABLE_PART_MUSIC
        section "part_music_samples",data,chip      ; section for music playback
part_music_smp:
        incbin  "../data/music/desire_demo_68k_v6.lsbank"

        section "part_music_data",data              ; section for music playback
part_music_data:
        incbin  "../data/music/desire_demo_68k_v6.lsmusic"
        ENDC
        ENDC

        END