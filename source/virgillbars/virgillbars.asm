; TODOs:
; - Limit bar pos left and right depending on size
;
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
FW_64KB_PAGE_MEMORY_SUPPORT = 0 ; allow allocation of chip memory that doesn't cross the 64 KB page boundary
FW_MULTITASKING_SUPPORT     = 1 ; enable multitasking
FW_ROUNDROBIN_MT_SUPPORT    = 0 ; enable fair scheduling among tasks with same priority
FW_BLITTERTASK_MT_SUPPORT   = 0 ; enable single parallel task during large blits
FW_MAX_VPOS_FOR_BG_TASK     = 308 ; max vpos that is considered to be worth switching to a background task, if any
FW_SINETABLE_SUPPORT        = 1 ; enable creation of 1024 entries sin/cos table
FW_SCRIPTING_SUPPORT        = 1 ; enable simple timed scripting functions
FW_PALETTE_LERP_SUPPORT     = 0 ; enable basic palette fading functions
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
PART_MUSIC_START_POS        = 4
        ENDC

VGBARS_WIDTH     = 320
VGBARS_HEIGHT    = 180
VGBARS_PLANES    = 6

CAT_WIDTH = 64
CAT_HEIGHT = 128

AOLD_WIDTH  = 96
AOLD_HEIGHT = 112

LIGHTBREAK_WIDTH = 128
LIGHTBREAK_HEIGHT = 128

STAYBROKEN_WIDTH = 128
STAYBROKEN_HEIGHT = 128

MODSHIFT_SIZE    = (VGBARS_HEIGHT*(2+2))
BARLINE_WIDTH    = 1024

NUM_HISTORY_BUFS = 128

ROT_ANGLES = 124

COP_PREAMBLE_INST   = 128 ; bplptrs, sprite pointers
COP_POST_INST       = 16 ; wait
COP_INST_PER_LINE   = 1+3+1+2 ; wait, bplcon1, bpl1mod, bpl2mod, wait, line 0 color, line 0 color
COP_WOBBLE_INST_PER_LINE = 2+2 ; 2 waits, bpl1mod, bpl2mod
COP_LIST_SIZE       = (COP_PREAMBLE_INST+COP_INST_PER_LINE*VGBARS_HEIGHT+COP_POST_INST)*4
INTRO_COP_LIST_SIZE = 100*4

NUM_CHUNKY_PIXELS = 512

NUM_AHEAD_FRAMES = 18
AHEAD_CHIP_BUF_SIZE = 3*NUM_CHUNKY_PIXELS*2+(NUM_CHUNKY_PIXELS*2+920)+VGBARS_HEIGHT*2+NUM_CHUNKY_PIXELS+(BARLINE_WIDTH/8)*VGBARS_PLANES

NUM_BARS = 7
BAR_WIDTH = 32

CHIPMEM_SIZE = 2*COP_LIST_SIZE+2*INTRO_COP_LIST_SIZE+(BARLINE_WIDTH/8)*VGBARS_PLANES*2+NUM_CHUNKY_PIXELS*2*17+2*ROT_ANGLES*MODSHIFT_SIZE
FASTMEM_SIZE = 2*4096+65536+NUM_CHUNKY_PIXELS*2+2*ROT_ANGLES*VGBARS_HEIGHT*2+(NUM_BARS*(2*BAR_WIDTH)*BAR_WIDTH*3*2)

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"

; Process:
;
; 1. CPU: Draw interpolated bars with adds
;    In : pd_CurrChunkyPtr
;    Out: pd_CurrChunkyPtr
;
; 2. Blitter: Saturate and convert with blitter
;    In : pd_CurrChunkyPtr
;    Out: pd_CurrChunkyResultPtr
;
; 3. CPU: Take rotation offsets and calc left edge color
;    In : pd_CurrChunkyResultPtr
;    Out: pd_ChunkyLeftEdgeRGBPtr
;
; 4. Blitter: Copy precalculated bplcon1/mods and edge color to copperlist
;    In : pd_ChunkyLeftEdgeRGBPtr
;    Out: pd_CurrCopListPtr
;    Out: pd_FirstLineOffset
;
; 4b. CPU: Update first line pos
;    In : pd_FirstLineOffset
;    Out: pd_CurrCopListPtr
;
; 5. CPU: Convert to HAM pixels (and draw to p5/p6)
;    In : pd_CurrChunkyResultPtr
;    Out: pd_ChunkyHamPtr
;    Out: pd_CurrPlanesPtr (p5/p6)
;
; 6. CPU: C2P of HAM pixels
;    In : pd_ChunkyHamPtr
;    Out: pd_CurrPlanesPtr (p1-p4)
;
; 7. Blitter: Fill chunky data with dither pattern
;    In : -
;    Out: pd_CurrChunkyPtr
;
; Pipelined:
; 2. T-1: Blitter: Saturate and convert with blitter (idle cycles)
; 7. T-1: Blitter: Fill chunky data with dither pattern (idle cycles)
; --
; 4. T-2: Blitter: Copy precalculated bplcon1/mods and edge color to copperlist
; --
; 1. T+0: CPU: Draw interpolated bars with adds
; 3. T+1: CPU: Take rotation offsets and calc left edge color
; 5. T-3: CPU: Convert to HAM pixels (and draw to p5/p6)
; 6. T-3: CPU: C2P of HAM pixels
;
; Precalculate bar widths 32 to 63
; Between angle 171-214: 2x ham width
; Between angle 215-235: 4x ham width
; Between angle 236-245: 8x ham width
; Between angle 246-250: 16x ham width

    STRUCTURE   BarData,0
        UWORD   bd_Phase
        UWORD   bd_NomWidth
        UWORD   bd_PhaseSpeed
        UWORD   bd_Dist
        UWORD   bd_CurrXPos
        UWORD   bd_CurrWidth
        UWORD   bd_BarNum
        UWORD   bd_ColRed
        UWORD   bd_ColGreen
        UWORD   bd_ColBlue
        WORD    bd_FadePos
        ULONG   bd_IncRed
        ULONG   bd_IncGreen
        ULONG   bd_IncBlue
        LABEL   bd_SIZEOF

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_CurrChunkyPtr
        APTR    pd_LastChunkyPtr
        APTR    pd_CurrChunkyResultPtr
        APTR    pd_LastChunkyResultPtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        UBYTE   pd_DbToggle
        UBYTE   pd_CopperToggle
        ALIGNWORD

        UWORD   pd_PartCountDown
        UWORD   pd_SudokuDitherPos

        UWORD   pd_CopperSkewOffset
        UWORD   pd_CopperBplOffset

        UWORD   pd_OverlayXPos
        UWORD   pd_OverlayYPos
        UWORD   pd_OverlayXDir
        UWORD   pd_OverlayYDir
        BOOL    pd_OverlayKilled
        UWORD   pd_Angle
        UWORD   pd_LastAngle
        UWORD   pd_AnglePhase
        UWORD   pd_AngleWidth
        BOOL    pd_DecAngleWidth

        WORD    pd_FirstLineOffset
        UWORD   pd_HistoryNum
        UWORD   pd_HistorySub
        UWORD   pd_Wobble1Pos
        UWORD   pd_Wobble2Pos
        BOOL    pd_FadeOutWobble

        UWORD   pd_NextBeatFrame
        UWORD   pd_BeatZoom
        UWORD   pd_BeatSize

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        APTR    pd_IntroCopperList1
        APTR    pd_IntroCopperList2
        APTR    pd_DbBuffer
        APTR    pd_HistoryBuffer

        APTR    pd_ChunkyArray1Ptr
        APTR    pd_ChunkyArray2Ptr
        APTR    pd_ChunkySatPtr
        APTR    pd_ChunkySatRPtr
        APTR    pd_ChunkySatGPtr
        APTR    pd_ChunkySatBPtr
        APTR    pd_ChunkyResultRPtr
        APTR    pd_ChunkyResultGPtr
        APTR    pd_ChunkyResultBPtr
        APTR    pd_ChunkyResultRGB1Ptr
        APTR    pd_ChunkyResultRGB2Ptr
        APTR    pd_ChunkyLeftEdgeRGBPtr
        APTR    pd_ChunkyHamPtr

        APTR    pd_OneColorChangeTable      ; ds.b    4096
        APTR    pd_RedBlueTable             ; ds.b    4096
        APTR    pd_DiffTable                ; ds.b    65536

        APTR    pd_XPosBufferPtr
        APTR    pd_PreCalcedBarsPtr
        APTR    pd_WobbleDataPtr
        APTR    pd_ModShiftDataPtr

        STRUCT  pd_BQBuffer,1000

        STRUCT  pd_OverlaySprites,8*4
        STRUCT  pd_BarData,NUM_BARS*bd_SIZEOF
        STRUCT  pd_PreparationTask,ft_SIZEOF
        STRUCT  pd_CotTable,ROT_ANGLES*2
        STRUCT  pd_Mod40TableNeg,VGBARS_HEIGHT*2
        STRUCT  pd_Mod40TablePos,VGBARS_HEIGHT*2

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        move.l  #part_music_data,fw_MusicData(a6)
        move.l  #part_music_smp,fw_MusicSamples(a6)
        CALLFW  StartMusic
        ENDC
        IFD     PART_MUSIC_START_POS
        moveq.l #PART_MUSIC_START_POS,d0
        CALLFW  MusicSetPosition
        move.w  #1200,fw_MusicFrameCount(a6)
        ENDC
        ENDC

        bsr.s   vgb_init

        lea     vgb_copperlist,a0
        CALLFW  SetCopper

        bsr     vgb_intro
        bsr     vgb_main
        bsr     vgb_wobble

        CALLFW  SetBaseCopper
        rts

;--------------------------------------------------------------------

vgb_init:
        bsr     vgb_init_vars

        bsr     vgb_clear_chunky_buffers

        bsr     vgb_init_one_color_change_table
        bsr     vgb_init_red_blue_table

        ; needs to be done now, because copperlist will not be updated afterwards
        bsr     vgb_load_aold_sprites

        bsr     vgb_flip_db_frame
        bsr     vgb_flip_copper_frame
        bsr     vgb_create_main_copperlist
        bsr     vgb_fill_line_with_default

        bsr     vgb_flip_db_frame
        bsr     vgb_flip_copper_frame
        bsr     vgb_create_main_copperlist
        bsr     vgb_fill_line_with_default

        lea     .backgroundtasks(pc),a0
        lea     pd_PreparationTask(a6),a1
        CALLFW  AddTask

        rts

.backgroundtasks
        bsr     vgb_init_diff_table
        bsr     vgb_init_cot_table
        bsr     vgb_precalc_bars
        bsr     vgb_init_modshift_table
        bsr     vgb_init_mod40_table
        rts

;--------------------------------------------------------------------

vgb_init_vars:
        move.l  #(INTRO_COP_LIST_SIZE*2),d0
        CALLFW  AllocChip
        PUTMSG  10,<"Intro Copperlist 1 %p">,a0
        move.l  a0,pd_IntroCopperList1(a6)
        lea     INTRO_COP_LIST_SIZE(a0),a0
        PUTMSG  10,<"Intro Copperlist 2 %p">,a0
        move.l  a0,pd_IntroCopperList2(a6)

        move.l  #(COP_LIST_SIZE*2),d0
        CALLFW  AllocChip
        PUTMSG  10,<"Copperlist 1 %p">,a0
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)
        lea     COP_LIST_SIZE(a0),a0
        PUTMSG  10,<"Copperlist 2 %p">,a0
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        move.l  #(2*BARLINE_WIDTH/8)*VGBARS_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"DbBuffer %p">,a0
        move.l  a0,pd_DbBuffer(a6)
        move.l  a0,pd_CurrPlanesPtr(a6)

        move.l  #(NUM_BARS*(2*BAR_WIDTH)*BAR_WIDTH*3*2),d0
        CALLFW  AllocFast
        move.l  a0,pd_PreCalcedBarsPtr(a6)
        PUTMSG  10,<"pd_PreCalcedBarsPtr %p">,a0

        move.l  #2*ROT_ANGLES*VGBARS_HEIGHT*2,d0
        CALLFW  AllocFast
        move.l  a0,pd_XPosBufferPtr(a6)
        PUTMSG  10,<"pd_XPosBufferPtr %p">,a0

        move.l  #2*ROT_ANGLES*MODSHIFT_SIZE,d0
        CALLFW  AllocChip
        move.l  a0,pd_ModShiftDataPtr(a6)
        PUTMSG  10,<"pd_ModShiftDataPtr %p">,a0
        move.l  a0,pd_HistoryBuffer(a6)
        lea     (VGBARS_WIDTH/8)*VGBARS_PLANES*NUM_HISTORY_BUFS(a0),a0
        move.l  a0,pd_WobbleDataPtr(a6)

        move.l  #NUM_CHUNKY_PIXELS*2*17,d0
        CALLFW  AllocChip
        move.l  a0,pd_ChunkyArray1Ptr(a6)
        move.w  #NUM_CHUNKY_PIXELS*2,d2
        move.l  a0,pd_CurrChunkyPtr(a6)
        PUTMSG  10,<"Chunky Array Ptr %p">,a0
        adda.w  d2,a0
        adda.w  d2,a0
        adda.w  d2,a0
        move.l  a0,pd_ChunkyArray2Ptr(a6)
        move.l  a0,pd_LastChunkyPtr(a6)
        adda.w  d2,a0
        adda.w  d2,a0
        adda.w  d2,a0
        move.l  a0,pd_ChunkySatPtr(a6)
        move.l  a0,pd_ChunkySatRPtr(a6)
        PUTMSG  10,<"Chunky Sat Ptr %p">,a0
        adda.w  d2,a0
        move.l  a0,pd_ChunkySatGPtr(a6)
        adda.w  d2,a0
        move.l  a0,pd_ChunkySatBPtr(a6)
        adda.w  d2,a0
        move.l  a0,pd_ChunkyResultRPtr(a6)
        PUTMSG  10,<"Chunky R Ptr %p">,a0
        adda.w  d2,a0
        move.l  a0,pd_ChunkyResultGPtr(a6)
        PUTMSG  10,<"Chunky G Ptr %p">,a0
        adda.w  d2,a0
        move.l  a0,pd_ChunkyResultBPtr(a6)
        PUTMSG  10,<"Chunky B Ptr %p">,a0
        adda.w  d2,a0
        lea     NUM_CHUNKY_PIXELS(a0),a1
        move.l  a1,pd_ChunkyResultRGB1Ptr(a6)
        move.l  a1,pd_CurrChunkyResultPtr(a6)
        PUTMSG  10,<"Chunky RGB Ptr 1 %p">,a0
        adda.w  d2,a0
        adda.w  d2,a0
        lea     NUM_CHUNKY_PIXELS(a0),a1
        move.l  a1,pd_ChunkyResultRGB2Ptr(a6)
        move.l  a1,pd_LastChunkyResultPtr(a6)
        PUTMSG  10,<"Chunky RGB Ptr 2 %p">,a0
        adda.w  d2,a0
        adda.w  d2,a0
        move.l  a0,pd_ChunkyLeftEdgeRGBPtr(a6)
        PUTMSG  10,<"Chunky Left Edge RGB Ptr %p">,a0

        move.l  #2*4096+65536,d0
        CALLFW  AllocFast
        move.w  #4096,d0
        move.l  a0,pd_OneColorChangeTable(a6)
        adda.w  d0,a0
        move.l  a0,pd_RedBlueTable(a6)
        adda.w  d0,a0
        move.l  a0,pd_DiffTable(a6)

        move.l  #NUM_CHUNKY_PIXELS*2,d0
        CALLFW  AllocFast
        move.l  a0,pd_ChunkyHamPtr(a6)
        PUTMSG  10,<"Chunky Ham Ptr %p">,a0

        lea     pd_BarData(a6),a1
        lea     vgb_bars_colors(pc),a0
        lea     vgb_bars_dists(pc),a2
        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #0,d2
        moveq.l #39,d3
        moveq.l #NUM_BARS-1,d7
.bloop
        move.w  d0,(a1)+        ; bd_Phase
        add.w   #333,d0
        move.w  #BAR_WIDTH*256,(a1)+   ; bd_NomWidth
        move.w  d3,(a1)+        ; bd_PhaseSpeed
        addq.w  #7,d3
        move.w  (a2)+,(a1)+     ; bd_Dist
        clr.l   (a1)+           ; bd_CurrXPos/bd_CurrWidth
        move.w  d2,(a1)+        ; bd_BarNum
        move.w  (a0)+,(a1)+     ; bd_ColRed
        move.w  (a0)+,(a1)+     ; bd_ColGreen
        move.w  (a0)+,(a1)+     ; bd_ColBlue
        move.w  d1,(a1)+        ; bd_FadePos
        lea     3*4(a1),a1      ; bd_IncRed/bd_IncGreen/bd_IncBlue
        sub.w   #5461,d1
        addq.w  #1,d2
        dbra    d7,.bloop

        rts

;--------------------------------------------------------------------

vgb_init_cot_table:
        move.l  fw_CosTable(a6),a1
        lea     pd_CotTable(a6),a0
        PUTMSG  10,<"%d: CotTable %p">,fw_FrameCounterLong(a6),a0
        moveq.l #(ROT_ANGLES-1)-1,d7
        moveq.l #0,d0
        moveq.l #0,d5
        subq.w  #1,d5
.loop   move.l  #256<<14,d1
        divu    (a1),d1
        move.w  d1,(a0)+
        addq.l  #2*2,a1
        dbra    d7,.loop
        PUTMSG  10,<"%d: CotTable done">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

vgb_init_modshift_table:
        PUTMSG  10,<"%d: Calc modshift table">,fw_FrameCounterLong(a6)
        move.l  pd_ModShiftDataPtr(a6),a1
        move.l  pd_XPosBufferPtr(a6),a0
        moveq.l #ROT_ANGLES-1,d7
        moveq.l #0,d0
.loop1  PUSHM   d0/d7/a0/a1
        bsr     vgb_calc_skew
        POPM

        PUSHM   d0/d7/a0/a1
        bsr     vgb_calc_modshift
        POPM
        lea     MODSHIFT_SIZE(a1),a1
        lea     (VGBARS_HEIGHT*2)(a0),a0
        addq.w  #2,d0
        dbra    d7,.loop1

        moveq.l #(ROT_ANGLES-1)-1,d7
        moveq.l #-2,d0
.loop2  PUSHM   d0/d7/a0/a1
        bsr     vgb_calc_skew
        POPM

        PUSHM   d0/d7/a0/a1
        bsr     vgb_calc_modshift
        POPM
        lea     MODSHIFT_SIZE(a1),a1
        lea     (VGBARS_HEIGHT*2)(a0),a0
        subq.w  #2,d0
        dbra    d7,.loop2
        PUTMSG  10,<"%d: Calc modshift table done">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

vgb_init_one_color_change_table:
        move.l  pd_OneColorChangeTable(a6),a0
        PUTMSG  10,<"%d: pd_OneColorChangeTable %p">,fw_FrameCounterLong(a6),a0
        moveq.l #1,d0
        move.w  #$f00,d4
        move.w  #$0f0,d5
        clr.b   (a0)+               ; all colors the same
        move.w  #4095-1,d7
.loop
        move.w  d0,d1
        and.w   d4,d1               ; d1 = red (and $f00)
        moveq.l #$f,d3
        and.w   d0,d3               ; d3 = blue

        move.w  d0,d2
        and.w   d5,d2               ; d2 = green (and $0f0)
        bne.s   .gdiff              ; at least green diffs
        ; green does not differ
        tst.w   d1
        bne.s   .rdiff              ; at least red diffs
        move.b  #1*2,(a0)+          ; blue only diff
        bra.s   .good
.rdiff  tst.w   d3
        bne.s   .rbdiffnotg         ; red and blue diff, not green
        move.b  #4*2,(a0)+          ; red only diffs
        bra.s   .good
.gdiff
        tst.w   d1
        bne.s   .grdiff             ; at least green and red diff
        ; red does not differ
        tst.w   d3
        bne.s   .gbdiffnotr         ; green and blue diff, red same
        move.b  #2*2,(a0)+          ; green only diff
        bra.s   .good
.rbdiffnotg
        move.b  #(1+4)*2,(a0)+      ; only red and blue diff
        bra.s   .good
.gbdiffnotr
        move.b  #(1+2)*2,(a0)+      ; only green and blue diff
        bra.s   .good
.grdiff tst.w   d3
        bne.s   .rgbdiff            ; all colors diff
        ; blue does not differ
.rgdiffnotb
        move.b  #(2+4)*2,(a0)+      ; only green and red diff
        bra.s   .good
.rgbdiff
        move.b  #(1+2+4)*2,(a0)+    ; all colors diff
.good
        addq.w  #1,d0
        dbra    d7,.loop
        PUTMSG  10,<"%d: pd_OneColorChangeTable done">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

vgb_init_red_blue_table:
        move.l  pd_RedBlueTable(a6),a0
        PUTMSG  10,<"%d: pd_RedBlueTable %p">,fw_FrameCounterLong(a6),a0
        moveq.l #0,d0
        move.w  #4096-1,d7
.loop
        moveq.l #15,d2
        and.w   d0,d2
        move.w  d0,d1
        lsr.w   #4,d1
        and.w   #$f0,d1
        or.w    d1,d2
        move.b  d2,(a0)+
        addq.w  #1,d0
        dbra    d7,.loop
        PUTMSG  10,<"%d: pd_RedBlueTable done">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

vgb_init_diff_table:
        move.l  pd_DiffTable(a6),a0
        PUTMSG  10,<"%d: pd_DiffTable %p">,fw_FrameCounterLong(a6),a0
        add.l   #$10000,a0
        move.w  #256-1,d7
.oloop
        moveq.l #$f,d0
        and.w   d7,d0       ; low of upper
        move.w  d7,d1
        lsr.w   #4,d1       ; high of upper
        move.w  #256-1,d6
.loop
        moveq.l #$f,d3
        and.w   d6,d3       ; low of lower
        move.w  d6,d4
        lsr.w   #4,d4       ; high of lower

        sub.w   d0,d3       ; calc lower dist
        bpl.s   .noflip1
        neg.w   d3
.noflip1
        sub.w   d1,d4       ; calc upper dist
        bpl.s   .noflip2
        neg.w   d4
.noflip2
        cmp.w   d4,d3
        bgt.s   .takelow
        neg.w   d4
        move.b  d4,-(a0)
        dbra    d6,.loop
        dbra    d7,.oloop
        PUTMSG  10,<"%d: pd_DiffTable done">,fw_FrameCounterLong(a6)
        rts
.takelow
        move.b  d3,-(a0)
        dbra    d6,.loop
        dbra    d7,.oloop
        rts

;--------------------------------------------------------------------

vgb_init_mod40_table:
        lea     pd_Mod40TablePos(a6),a0
        PUTMSG  10,<"%d: pd_Mod40TablePos %p">,fw_FrameCounterLong(a6),a0
        move.l  a0,a1
        move.w  #(VGBARS_WIDTH/8)*VGBARS_PLANES,d2
        moveq.l #0,d0
        moveq.l #0,d1
        move.w  #VGBARS_HEIGHT-1,d7
.loop
        move.w  d0,(a0)+
        add.w   d2,d0
        sub.w   d2,d1
        move.w  d1,-(a1)
        dbra    d7,.loop
        PUTMSG  10,<"%d: pd_Mod40TablePos done">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

vgb_intro:
        move.w  #250,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueSingleFrame

        bsr     vgb_load_cat_sprites

        CALLFW  VSyncWithTask

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

        move.w  fw_MusicFrameCount(a6),d0
        moveq.l #4*6,d2
        move.w  d2,pd_BeatSize(a6)
        move.w  d0,d1
        divu    d2,d0
        swap    d0
        sub.w   d0,d1
        add.w   d2,d1
        move.w  d1,pd_NextBeatFrame(a6)

        move.w  #0,pd_Angle(a6)
        move.w  #0,pd_LastAngle(a6)
.loop
; ----------- Frame 1
        bsr     vgb_flip_db_frame
        bsr     vgb_flip_intro_copper_frame

        bsr     vgb_check_beat
        CALLFW  CheckMusicScript
        bsr     vgb_update_cat_sprite

        move.l  pd_ChunkyHamPtr(a6),a0
        lea     96(a0),a0
        move.l  pd_LastChunkyResultPtr(a6),a1
        lea     96*2(a1),a1
        move.w  #4*(BARLINE_WIDTH/8)+96/8+((BARLINE_WIDTH-NUM_CHUNKY_PIXELS)/2)/8,d0
        moveq.l #(VGBARS_WIDTH/16)-1,d7
        bsr     vgb_calc_ham_pixels

        move.l  pd_ChunkyHamPtr(a6),a0
        lea     96(a0),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     ((BARLINE_WIDTH-NUM_CHUNKY_PIXELS)/2+96)/8(a1),a1
        lea     (BARLINE_WIDTH/8)(a1),a2
        lea     (BARLINE_WIDTH/8)(a2),a3
        lea     (BARLINE_WIDTH/8)(a3),a4
        moveq.l #(VGBARS_WIDTH/16)-1,d7
        bsr     vgb_c2p_line

        bsr     vgb_create_intro_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

; ----------- Frame 2

        bsr     vgb_flip_intro_copper_frame

        bsr     vgb_check_beat
        CALLFW  CheckMusicScript
        bsr     vgb_update_cat_sprite

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_saturate_and_merge_320
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     vgb_calc_intro_bar_pos
        bsr     vgb_calc_realtime_bar_data
        bsr     vgb_draw_realtime_bars  ; draws bars with current angle
        bsr     vgb_fade_in_bars

        CALLFW  JoinBlitterQueue        ; now the saturate is ready for left edge fixing

        bsr     vgb_create_intro_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

.script
        dc.w    1200+36*6,.move_cat_up-*
        dc.w    1200+47*6,.changebeatto3syncope-*
        dc.w    1200+53*6,.changebeatto2syncope-*
        dc.w    1200+55*6,.changebeatto8syncope-*
        dc.w    1200+36*6+1+((CAT_HEIGHT)*128)/125,.stop_cat-*
        dc.w    1200+60*6,.changebeattonormal-*
        dc.w    1584,.move_cat_down-*
        dc.w    1584+1+((CAT_HEIGHT/2)*128)/125,.stop_and_kill_cat-*
        dc.w    0

.changebeatto3syncope
        move.w  #3*6,pd_BeatSize(a6)
        rts

.changebeatto2syncope
        move.w  #2*6,pd_BeatSize(a6)
        rts

.changebeatto8syncope
        move.w  #8*6,pd_BeatSize(a6)
        rts

.changebeattonormal
        move.w  #4*6,pd_BeatSize(a6)
        rts

.move_cat_up
        clr.w   pd_OverlayKilled(a6)
        move.w  #-1,pd_OverlayYDir(a6)
        rts

.stop_and_kill_cat
        st      pd_OverlayKilled(a6)

.stop_cat
        clr.w   pd_OverlayYDir(a6)
        rts

.move_cat_down
        move.w  #2,pd_OverlayYDir(a6)
        rts

;--------------------------------------------------------------------

vgb_main:
        CALLFW  SetBlitterQueueSingleFrame

        bsr     vgb_load_aold_sprites

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

.loop
; ----------- Frame 1
        bsr     vgb_flip_db_frame
        bsr     vgb_flip_copper_frame

        bsr     vgb_check_beat
        CALLFW  CheckMusicScript

        bsr     vgb_update_aold_sprite

        move.l  pd_ChunkyHamPtr(a6),a0
        move.l  pd_LastChunkyResultPtr(a6),a1
        move.w  #4*(BARLINE_WIDTH/8)+((BARLINE_WIDTH-NUM_CHUNKY_PIXELS)/2)/8,d0
        moveq.l #(NUM_CHUNKY_PIXELS/16)-1,d7
        bsr     vgb_calc_ham_pixels

        move.l  pd_ChunkyHamPtr(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     ((BARLINE_WIDTH-NUM_CHUNKY_PIXELS)/2)/8(a1),a1
        lea     (BARLINE_WIDTH/8)(a1),a2
        lea     (BARLINE_WIDTH/8)(a2),a3
        lea     (BARLINE_WIDTH/8)(a3),a4
        moveq.l #(NUM_CHUNKY_PIXELS/16)-1,d7
        bsr     vgb_c2p_line

        bsr     vgb_calc_new_angle
        bsr     vgb_fix_left_edge

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_update_skew_and_left_edge
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        CALLFW  JoinBlitterQueue

        bsr     vgb_update_skew_to_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

; ----------- Frame 2

        bsr     vgb_flip_copper_frame
        bsr     vgb_calc_new_angle

        bsr     vgb_check_beat
        CALLFW  CheckMusicScript

        bsr     vgb_update_aold_sprite

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_saturate_and_merge
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     vgb_calc_bar_pos
        bsr     vgb_draw_precalced_bars ; draws bars with current angle

        CALLFW  JoinBlitterQueue        ; now the saturate is ready for left edge fixing

        bsr     vgb_fix_left_edge

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_update_skew_and_left_edge ; prior angle image is done
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     vgb_update_skew_to_copperlist

        CALLFW  JoinBlitterQueue

        bsr     vgb_update_copper_list_pointers

        ;PUTMSG  10,<"Alt frame">
        CALLFW  VSyncWithTask

        cmp.w   #2736-8*6,fw_MusicFrameCount(a6)
        blt.s   .noinvert
        PUTMSG  20,<"%d: Flipping!">,fw_MusicFrameCount-2(a6)
        st      pd_DecAngleWidth(a6)
.noinvert
        cmp.w   #3120,fw_MusicFrameCount(a6)
        blt     .loop

        rts

.script
        dc.w    1968,.move_overlay_left-*
        dc.w    1968+32*6,.stop_overlay-*
        dc.w    2352,.move_overlay_down-*
        dc.w    2352+32*6,.stop_and_kill_overlay-*
        dc.w    0

.move_overlay_left
        clr.w   pd_OverlayKilled(a6)
        move.w  #-1,pd_OverlayXDir(a6)
        rts

.stop_and_kill_overlay
        st      pd_OverlayKilled(a6)

.stop_overlay
        clr.l   pd_OverlayXDir(a6)
        rts

.move_overlay_down
        move.w  #1,pd_OverlayYDir(a6)
        rts

;--------------------------------------------------------------------

vgb_wobble:
        CALLFW  SetBlitterQueueSingleFrame

        bsr     vgb_load_light_break_sprites

        move.w  #$6000,pd_HistorySub(a6)
        move.w  #8,pd_BeatZoom(a6)

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

; ----------- Frame 1
        bsr     vgb_flip_history_frame
        bsr     vgb_flip_copper_frame

        CALLFW  CheckMusicScript
        bsr     vgb_update_wobble_sprite

        move.l  pd_ChunkyHamPtr(a6),a0
        lea     96(a0),a0
        move.l  pd_LastChunkyResultPtr(a6),a1
        lea     96*2(a1),a1
        move.w  #4*(VGBARS_WIDTH/8),d0
        moveq.l #(VGBARS_WIDTH/16)-1,d7
        bsr     vgb_calc_ham_pixels_wobble

        move.l  pd_ChunkyHamPtr(a6),a0
        lea     96(a0),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     (VGBARS_WIDTH/8)(a1),a2
        lea     (VGBARS_WIDTH/8)(a2),a3
        lea     (VGBARS_WIDTH/8)(a3),a4

        moveq.l #(VGBARS_WIDTH/16)-1,d7
        bsr     vgb_c2p_line

        bsr     vgb_create_wobble_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

; ----------- Frame 2

        bsr     vgb_flip_copper_frame

        CALLFW  CheckMusicScript
        bsr     vgb_update_wobble_sprite

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_saturate_and_merge_320
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     vgb_calc_intro_bar_pos
        bsr     vgb_calc_realtime_bar_data
        bsr     vgb_draw_realtime_bars  ; draws bars with current angle
        ;bsr     vgb_draw_precalced_bars ; draws bars with current angle

        CALLFW  JoinBlitterQueue

        bsr     vgb_create_wobble_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

.loop
; ----------- Frame 1
        bsr     vgb_flip_history_frame
        bsr     vgb_flip_copper_frame

        CALLFW  CheckMusicScript
        bsr     vgb_update_wobble_sprite

        moveq.l #0,d5
        bsr     vgb_calc_wobble

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_update_wobble_modulos
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        move.l  pd_ChunkyHamPtr(a6),a0
        lea     96(a0),a0
        move.l  pd_LastChunkyResultPtr(a6),a1
        lea     96*2(a1),a1
        move.w  #4*(VGBARS_WIDTH/8),d0
        moveq.l #(VGBARS_WIDTH/16)-1,d7
        bsr     vgb_calc_ham_pixels_wobble

        move.l  pd_ChunkyHamPtr(a6),a0
        lea     96(a0),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     (VGBARS_WIDTH/8)(a1),a2
        lea     (VGBARS_WIDTH/8)(a2),a3
        lea     (VGBARS_WIDTH/8)(a3),a4

        moveq.l #(VGBARS_WIDTH/16)-1,d7
        bsr     vgb_c2p_line

        CALLFW  JoinBlitterQueue

        bsr     vgb_update_wobble_offset_to_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

; ----------- Frame 2

        bsr     vgb_flip_copper_frame

        CALLFW  CheckMusicScript
        bsr     vgb_update_wobble_sprite

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_saturate_and_merge_320
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     vgb_calc_intro_bar_pos
        bsr     vgb_calc_realtime_bar_data

        moveq.l #1,d5
        bsr     vgb_calc_wobble

        bsr     vgb_fade_fancy_bars
        CALLFW  JoinBlitterQueue

        lea     pd_BQBuffer(a6),a4
        bsr     vgb_blitter_update_wobble_modulos
        TERMINATE_BLITTER_QUEUE

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     vgb_draw_realtime_bars  ; draws bars with current angle
        ;bsr     vgb_draw_precalced_bars ; draws bars with current angle

        CALLFW  JoinBlitterQueue

        bsr     vgb_update_wobble_offset_to_copperlist
        bsr     vgb_update_copper_list_pointers

        CALLFW  VSyncWithTask

        cmp.w   #3504+28*6,fw_MusicFrameCount(a6)
        blt.s   .nofadeout
        st      pd_FadeOutWobble(a6)
        move.w  #4,pd_BeatZoom(a6)
.nofadeout
        cmp.w   #3888-4*6,fw_MusicFrameCount(a6)
        blt.s   .loop

        rts

.script
        dc.w    3120+32*6,.move_overlay_right-*
        dc.w    3120+56*6,.stop_overlay-*
        dc.w    3504,vgb_load_stay_broken_sprites-*
        dc.w    3504,vgb_load_stay_broken_sprites-*
        dc.w    3504+32*6,.move_overlay_left-*
        dc.w    3504+56*6,.stop_and_kill_overlay-*
        dc.w    0

.move_overlay_right
        clr.w   pd_OverlayKilled(a6)
        move.w  #1,pd_OverlayXDir(a6)
        rts

.stop_and_kill_overlay
        st      pd_OverlayKilled(a6)

.stop_overlay
        clr.l   pd_OverlayXDir(a6)
        rts

.move_overlay_left
        move.w  #-1,pd_OverlayXDir(a6)
        rts

;--------------------------------------------------------------------

vgb_flip_db_frame:
        move.l  pd_CurrChunkyPtr(a6),pd_LastChunkyPtr(a6)
        move.l  pd_CurrChunkyResultPtr(a6),pd_LastChunkyResultPtr(a6)
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        move.l  pd_DbBuffer(a6),a0
        lea     (BARLINE_WIDTH/8)*VGBARS_PLANES(a0),a0
        move.l  a0,pd_CurrPlanesPtr(a6)
        move.l  pd_ChunkyArray2Ptr(a6),pd_CurrChunkyPtr(a6)
        move.l  pd_ChunkyResultRGB2Ptr(a6),pd_CurrChunkyResultPtr(a6)
        rts
.selb1
        move.l  pd_DbBuffer(a6),pd_CurrPlanesPtr(a6)
        move.l  pd_ChunkyArray1Ptr(a6),pd_CurrChunkyPtr(a6)
        move.l  pd_ChunkyResultRGB1Ptr(a6),pd_CurrChunkyResultPtr(a6)
        rts

;--------------------------------------------------------------------

vgb_flip_history_frame:
        move.l  pd_CurrChunkyPtr(a6),pd_LastChunkyPtr(a6)
        move.l  pd_CurrChunkyResultPtr(a6),pd_LastChunkyResultPtr(a6)

        move.l  pd_HistoryBuffer(a6),a0
        move.w  pd_HistoryNum(a6),d0
        addq.w  #2,d0
        and.w   #(NUM_HISTORY_BUFS-1)*2,d0
        move.w  d0,pd_HistoryNum(a6)
        lea     pd_Mod40TablePos(a6),a1
        adda.w  (a1,d0.w),a0
        move.l  a0,pd_CurrPlanesPtr(a6)

        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        move.l  pd_ChunkyArray2Ptr(a6),pd_CurrChunkyPtr(a6)
        move.l  pd_ChunkyResultRGB2Ptr(a6),pd_CurrChunkyResultPtr(a6)
        rts
.selb1
        move.l  pd_ChunkyArray1Ptr(a6),pd_CurrChunkyPtr(a6)
        move.l  pd_ChunkyResultRGB1Ptr(a6),pd_CurrChunkyResultPtr(a6)
        rts

;--------------------------------------------------------------------

vgb_flip_copper_frame:
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        not.b   pd_CopperToggle(a6)
        beq.s   .selb1
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        rts
.selb1
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        rts

;--------------------------------------------------------------------

vgb_flip_intro_copper_frame:
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        not.b   pd_CopperToggle(a6)
        beq.s   .selb1
        move.l  pd_IntroCopperList2(a6),pd_CurrCopListPtr(a6)
        rts
.selb1
        move.l  pd_IntroCopperList1(a6),pd_CurrCopListPtr(a6)
        rts

;--------------------------------------------------------------------

vgb_update_copper_list_pointers:
        lea     vgb_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

vgb_clear_chunky_buffers:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_ChunkyArray1Ptr(a6),bltdpt(a5)
        move.w  #(17)|((NUM_CHUNKY_PIXELS)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

vgb_fill_line_with_default:
        move.l  pd_CurrPlanesPtr(a6),a0
        moveq.l #((BARLINE_WIDTH&1023)>>4)|((1)<<6),d3
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,255,0,0
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    5
        lea     (BARLINE_WIDTH)/8(a0),a0
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR
        rts

;--------------------------------------------------------------------

vgb_check_beat:
        move.w  fw_MusicFrameCount(a6),d0
        move.w  pd_NextBeatFrame(a6),d1
        cmp.w   d1,d0
        blt.s   .nobeat
        PUTMSG  10,<"Beat at %d/%d, next size %d">,d0,d1,pd_BeatSize-2(a6)
        add.w   pd_BeatSize(a6),d1
        move.w  d1,pd_NextBeatFrame(a6)
        move.w  #16,pd_BeatZoom(a6)
.nop
        rts
.nobeat move.w  pd_BeatZoom(a6),d0
        beq.s   .nop
        subq.w  #1,d0
        move.w  d0,pd_BeatZoom(a6)
        rts

;--------------------------------------------------------------------

vgb_calc_new_angle:
        tst.w   pd_DecAngleWidth(a6)
        beq.s   .inc
        move.w  pd_AngleWidth(a6),d1
        beq.s   .cont
        subq.w  #1,d1
        move.w  d1,pd_AngleWidth(a6)
        bra.s   .cont
.inc
        move.w  pd_AngleWidth(a6),d1
        cmp.w   #100*4,d1
        bge.s   .noinc
        addq.w  #1,d1
        move.w  d1,pd_AngleWidth(a6)
.noinc

.cont
        move.w  pd_Angle(a6),pd_LastAngle(a6)
        move.l  fw_SinTable(a6),a2
        move.w  pd_AnglePhase(a6),d0
        addq.w  #7,d0
        move.w  d0,pd_AnglePhase(a6)
        and.w   #1023*2,d0
        move.w  (a2,d0.w),d0
        muls    d1,d0
        swap    d0
        add.w   d0,d0
        ;moveq.l #0,d0
        move.w  d0,pd_Angle(a6)
        ;PUTMSG  10,<"Angle %d">,d0
        rts

;--------------------------------------------------------------------

vgb_calc_bar_pos:
        move.w  #256,d6
        move.w  pd_Angle(a6),d0
        beq.s   .standardwidth
        bpl.s   .noneg
        neg.w   d0
.noneg
        ; xw = w / cos(a)
        ; ci = m / xw = m / (w / cos(a)) = (m / w) * cos(a)
        lea     pd_CotTable(a6),a2
        move.w  (a2,d0.w),d6
.standardwidth

        move.l  fw_SinTable(a6),a2
        moveq.l #NUM_BARS-1,d7
        lea     pd_BarData(a6),a1
.bloop  movem.w bd_Phase(a1),d0-d4
        add.w   d2,d0       ; bd_Phase += bd_PhaseSpeed
        move.w  d0,bd_Phase(a1)
        lsr.w   #2,d0
        and.w   #1023*2,d0
        move.w  (a2,d0.w),d0
        muls    d3,d0
        swap    d0
        add.w   #(NUM_CHUNKY_PIXELS)/2,d0
        move.w  d0,bd_CurrXPos(a1)
        mulu    d6,d1
        swap    d1
        move.w  d1,bd_CurrWidth(a1)
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.bloop
        rts

;--------------------------------------------------------------------

vgb_calc_intro_bar_pos:
        move.l  fw_SinTable(a6),a2
        moveq.l #NUM_BARS-1,d7
        lea     pd_BarData(a6),a1
.bloop  movem.w bd_Phase(a1),d0-d4
        move.w  bd_FadePos(a1),d6
        add.w   d6,d6
        not.w   d6
        add.w   d2,d0       ; bd_Phase += bd_PhaseSpeed
        move.w  d0,bd_Phase(a1)
        lsr.w   #2,d0
        and.w   #1023*2,d0
        move.w  (a2,d0.w),d0
        muls    d3,d0
        swap    d0
        add.w   #(NUM_CHUNKY_PIXELS)/2,d0
        move.w  d0,bd_CurrXPos(a1)
        mulu    d6,d1
        swap    d1
        lsr.w   #8,d1
        add.w   #BAR_WIDTH,d1
        move.w  d1,bd_CurrWidth(a1)
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.bloop
        rts

;--------------------------------------------------------------------

vgb_fade_in_bars:
        lea     pd_BarData(a6),a1
        move.w  #256,d1
        moveq.l #NUM_BARS-1,d7
.bloop  move.w  bd_FadePos(a1),d0
        add.w   d1,d0
        bvc.s   .noover
        move.w  #$7fff,d0
.noover
        move.w  d0,bd_FadePos(a1)
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.bloop
        rts

;--------------------------------------------------------------------

vgb_fade_fancy_bars:
        lea     pd_BarData(a6),a1
        move.l  fw_SinTable(a6),a2
        moveq.l #NUM_BARS-1,d7
        tst.w   pd_FadeOutWobble(a6)
        bne.s   .fadeout
.bloop  move.w  bd_Phase(a1),d0
        add.w   bd_ColRed(a1),d0
        sub.w   bd_ColBlue(a1),d0
        and.w   #1023*2,d0
        move.w  (a2,d0.w),d0
        asr.w   #1,d0
        add.w   #$5ffe,d0
        cmp.w   #$7fff,bd_FadePos(a1)
        bne.s   .overwrite
        cmp.w   #$7c00,d0
        blt.s   .wait
.overwrite
        move.w  d0,bd_FadePos(a1)
.wait
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.bloop
        rts

.fadeout
.floop  move.w  bd_FadePos(a1),d0
        sub.w   #$200,d0
        bcc.s   .nozero
        moveq.l #0,d0
.nozero
        move.w  d0,bd_FadePos(a1)
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.floop
        rts

;--------------------------------------------------------------------

vgb_draw_precalced_bars:
        lea     pd_BarData(a6),a3

        moveq.l #NUM_BARS-1,d6
.bloop  movem.w bd_CurrXPos(a3),d0-d2
        add.w   pd_BeatZoom(a6),d1
        bsr     vgb_add_precalced_bar
        lea     bd_SIZEOF(a3),a3
        dbra    d6,.bloop
        rts

;--------------------------------------------------------------------

vgb_calc_realtime_bar_data:
        lea     pd_BarData(a6),a3

        moveq.l #NUM_BARS-1,d6
        moveq.l #0,d0
        subq.w  #1,d0
.bloop  movem.w bd_ColRed(a3),d2-d5
        tst.w   d5
        ble.s   .skip
        movem.w bd_CurrWidth(a3),d1
        add.w   d5,d5
        mulu    d5,d2
        lsr.l   #4,d2
        mulu    d5,d3
        lsr.l   #4,d3
        mulu    d5,d4
        lsr.l   #4,d4
        divu    d1,d2
        divu    d1,d3
        divu    d1,d4
        and.l   d0,d2
        and.l   d0,d3
        and.l   d0,d4
        lsl.l   #4,d2
        lsl.l   #4,d3
        lsl.l   #4,d4
        movem.l d2-d4,bd_IncRed(a3)
.skip
        lea     bd_SIZEOF(a3),a3
        dbra    d6,.bloop
        rts

;--------------------------------------------------------------------

vgb_draw_realtime_bars:
        lea     pd_BarData(a6),a3

        moveq.l #NUM_BARS-1,d6
.bloop  tst.w   bd_FadePos(a3)
        ble     .skip
        move.w  bd_CurrXPos(a3),d0
        move.w  bd_CurrWidth(a3),d1
        movem.l bd_IncRed(a3),d2-d4
        move.l  pd_CurrChunkyPtr(a6),a1
        add.w   d0,d0
        adda.w  d0,a1           ; go to x center

        add.w   pd_BeatZoom(a6),d1
        move.w  d1,d7
        subq.w  #1,d7

        add.w   d1,d1
        lea     (a1,d1.w),a2    ; right
        suba.w  d1,a1           ; left
        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #0,d5
.loop   add.l   d2,d0
        add.l   d3,d1
        add.l   d4,d5
        swap    d0
        swap    d1
        swap    d5
        add.w   d0,-(a2)
        add.w   d5,2*NUM_CHUNKY_PIXELS*2(a1)
        add.w   d5,2*NUM_CHUNKY_PIXELS*2(a2)
        add.w   d1,1*NUM_CHUNKY_PIXELS*2(a1)
        add.w   d1,1*NUM_CHUNKY_PIXELS*2(a2)
        add.w   d0,(a1)+
        swap    d0
        swap    d1
        swap    d5
        dbra    d7,.loop
.skip
        lea     bd_SIZEOF(a3),a3
        dbra    d6,.bloop
        rts

;--------------------------------------------------------------------

vgb_calc_wobble:
        move.l  pd_WobbleDataPtr(a6),a3
        lea     vgb_wobble_table(pc),a1
        lea     pd_Mod40TablePos(a6),a4

        moveq.l #0,d4
        move.w  pd_Wobble2Pos(a6),d4
        addq.w  #7,d4
        move.w  d4,pd_Wobble2Pos(a6)
        and.w   #$3fe,d4
        lea     (a1,d4.w),a2

        moveq.l #0,d4
        move.w  pd_Wobble1Pos(a6),d4
        addq.w  #2,d4
        move.w  d4,pd_Wobble1Pos(a6)
        and.w   #$3fe,d4
        adda.w  d4,a1

        move.w  #(NUM_HISTORY_BUFS-1)*2,d1
        moveq.l #0,d3
        move.w  #VGBARS_HEIGHT-1,d7
        move.w  pd_HistoryNum(a6),d4
        add.w   d5,d4

        moveq.l #(VGBARS_WIDTH/8),d6
        move.w  pd_HistorySub(a6),d5
.yloop
        move.w  (a1)+,d0
        lsr.w   #1,d0
        add.w   -(a2),d0
        sub.w   d5,d0
        bpl.s   .notrunc
        moveq.l #0,d0
.notrunc
        move.w  d0,-(sp)
        move.w  d4,d0
        sub.b   (sp)+,d0
        and.w   d1,d0

        exg     d3,d0
        sub.w   d3,d0
        neg.w   d0
        move.w  (a4,d0.w),d0
        move.w  d0,d2
        sub.w   d6,d2
        move.w  d2,(a3)+
        dbra    d7,.yloop

        sub.w   #$100,d5
        bcs.s   .skipmax
        move.w  d5,pd_HistorySub(a6)
.skipmax
        rts

;--------------------------------------------------------------------

vgb_calc_skew:
        moveq.l #(VGBARS_HEIGHT/2),d3
        move.w  d3,d1       ; error term
        add.w   d3,d3       ; xDec
        move.w  d3,d7
        subq.w  #1,d7       ; loop count

        lea     vgb_xpos_table(pc),a3
        tst.w   d0
        bpl.s   .rotright
        neg.w   d0
        move.w  (a3,d0.w),d2
        add.w   d2,d2       ; xInc
        move.w  d2,d0

.lineloopleft
        move.w  d0,(a0)+
        sub.w   d2,d1
        dble    d7,.lineloopleft
.extraleft
        subq.w  #2,d0
        add.w   d3,d1
        ble.s   .extraleft
        subq.w  #1,d7
        bpl.s   .lineloopleft
        rts

.rotright
        move.w  (a3,d0.w),d2
        add.w   d2,d2       ; xInc
        move.w  d2,d0
        neg.w   d0

.lineloopright
        move.w  d0,(a0)+
        sub.w   d2,d1
        dble    d7,.lineloopright
.extraright
        addq.w  #2,d0
        add.w   d3,d1
        ble.s   .extraright
        subq.w  #1,d7
        bpl.s   .lineloopright
        rts

;--------------------------------------------------------------------

; o0 = 0 -> adr0 = 0, mod = -42 + 2 loopmod = -42
; o1 = 2 -> adr0 = 2, mod = -42
; o2 = 2 -> adr
;
vgb_calc_modshift:
        move.w  #((BARLINE_WIDTH-VGBARS_WIDTH)-1)*2,d3
        move.w  #VGBARS_HEIGHT-1,d7
        moveq.l #0,d2
.yloop
        move.w  #(BARLINE_WIDTH-VGBARS_WIDTH),d0
        add.w   (a0)+,d0
        bpl.s   .noclipleft
        moveq.l #0,d0
.noclipleft
        cmp.w   d3,d0
        ble.s   .noclipright
        move.w  d3,d0
.noclipright
        asr.w   #1,d0
        moveq.l #15,d1
        moveq.l #16,d4
        sub.w   d0,d4
        and.w   d1,d4       ; lower 4 bit
        move.w  d4,d5
        lsl.w   #4,d5
        or.w    d5,d4
        move.w  d4,(a1)+

        add.w   d0,d1
        asr.w   #4,d1
        add.w   d1,d1
        ;subq.w  #2,d1

        moveq.l #-(VGBARS_WIDTH+16)/8,d6
        add.w   d1,d6
        sub.w   d2,d6
        move.w  d1,d2
        move.w  d6,(a1)+
        dbra    d7,.yloop
        rts

;--------------------------------------------------------------------

vgb_add_precalced_bar:
        move.w  d1,d7
        lsr.w   #1,d7
        subq.w  #1,d7
        move.l  pd_PreCalcedBarsPtr(a6),a0
        lsl.w   #5,d2       ; log2(BAR_WIDTH)
        sub.w   #BAR_WIDTH,d1
        cmp.w   #BAR_WIDTH,d1
        bge.s   .ext2
        add.w   d2,d1
        mulu    #(2*BAR_WIDTH)*3*2,d1
        adda.l  d1,a0
        move.l  pd_CurrChunkyPtr(a6),a1
        add.w   d0,d0
        adda.w  d0,a1           ; go to x center
        move.l  a1,a2
.nloop1
        movem.l (a0)+,d0-d5
        add.l   d2,2*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d1,1*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d0,(a1)+
        swap    d0
        swap    d1
        swap    d2
        add.l   d0,-(a2)
        add.l   d1,1*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d2,2*NUM_CHUNKY_PIXELS*2(a2)
        dbra    d7,.nloop2
        rts
.nloop2
        add.l   d5,2*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d4,1*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d3,(a1)+
        swap    d3
        swap    d4
        swap    d5
        add.l   d3,-(a2)
        add.l   d4,1*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d5,2*NUM_CHUNKY_PIXELS*2(a2)
        dbra    d7,.nloop1
        rts

.ext2
        sub.w   #BAR_WIDTH,d1
        lsr.w   #1,d1
        lsr.w   #1,d7
        add.w   d2,d1
        mulu    #(2*BAR_WIDTH)*3*2,d1
        adda.l  d1,a0
        move.l  pd_CurrChunkyPtr(a6),a1
        add.w   d0,d0
        adda.w  d0,a1           ; go to x center
        move.l  a1,a2
.ex2loop1
        movem.l (a0)+,d0-d5
        add.l   d2,2*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d1,1*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d0,(a1)+
        add.l   d2,2*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d1,1*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d0,(a1)+

        swap    d0
        swap    d1
        swap    d2
        add.l   d0,-(a2)
        add.l   d1,1*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d2,2*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d0,-(a2)
        add.l   d1,1*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d2,2*NUM_CHUNKY_PIXELS*2(a2)

        dbra    d7,.ex2loop3
        rts
.ex2loop3
        add.l   d5,2*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d4,1*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d3,(a1)+
        add.l   d5,2*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d4,1*NUM_CHUNKY_PIXELS*2(a1)
        add.l   d3,(a1)+

        swap    d3
        swap    d4
        swap    d5
        add.l   d3,-(a2)
        add.l   d4,1*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d5,2*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d3,-(a2)
        add.l   d4,1*NUM_CHUNKY_PIXELS*2(a2)
        add.l   d5,2*NUM_CHUNKY_PIXELS*2(a2)
        dbra    d7,.ex2loop1
        rts

;--------------------------------------------------------------------

vgb_precalc_bars:
        lea     vgb_bars_colors(pc),a4
        move.l  pd_PreCalcedBarsPtr(a6),a2
        moveq.l #NUM_BARS-1,d7
.barloop
        swap    d7
        moveq.l #BAR_WIDTH-1,d6
.wloop
        move.w  #BAR_WIDTH*2-1,d7
        sub.w   d6,d7

        moveq.l #0,d2
        subq.w  #1,d2

        movem.w (a4),d3-d5
        PUTMSG  40,<"RGB %lx %lx %lx">,d3,d4,d5
        swap    d3
        swap    d4
        swap    d5

        lsr.l   #4,d3
        divu    d7,d3
        and.l   d2,d3
        lsl.l   #4,d3

        lsr.l   #4,d4
        divu    d7,d4
        and.l   d2,d4
        lsl.l   #4,d4

        lsr.l   #4,d5
        divu    d7,d5
        and.l   d2,d5
        lsl.l   #4,d5

        PUTMSG  40,<"%d: %lx %lx %lx">,d7,d3,d4,d5

        addq.w  #1,d7
        and.w   #-2,d7
        move.w  d7,d0
        add.w   d0,d0
        add.w   d7,d0
        add.w   d0,d0
        lea     (a2,d0.w),a1
        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #0,d2
        lsr.w   #1,d7
        subq.w  #1,d7
.xloop
        add.l   d3,d0
        add.l   d4,d1
        add.l   d5,d2
        swap    d0
        swap    d1
        swap    d2
        movem.l d0-d2,-(a1)
        swap    d0
        swap    d1
        swap    d2
        add.l   d3,d0
        add.l   d4,d1
        add.l   d5,d2
        swap    d0
        swap    d1
        swap    d2
        move.w  d0,(a1)
        move.w  d1,4(a1)
        move.w  d2,8(a1)
        swap    d0
        swap    d1
        swap    d2
        dbra    d7,.xloop
        lea     (2*BAR_WIDTH)*3*2(a2),a2
        dbra    d6,.wloop
        swap    d7
        addq.l  #6,a4
        dbra    d7,.barloop
        rts

;--------------------------------------------------------------------

vgb_c2p_line:
        move.l  #$55555555,d3
        move.l  #$33333333,d4
        move.l  #$00ff00ff,d5
.loop
        move.l  (a0)+,d0
        lsl.l   #4,d0
        or.l    (a0)+,d0
        move.l  (a0)+,d1
        lsl.l   #4,d1
        or.l    (a0)+,d1

; a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0
; i3i2i1i0m3m2m1m0 j3j2j1j0n3n2n1n0 k3k2k1k0o3o2o1o0 l3l2l1l0p3p2p1p0

        move.l  d1,d2
        lsr.l   #8,d2
        eor.l   d0,d2
        and.l   d5,d2
        eor.l   d2,d0
        lsl.l   #8,d2
        eor.l   d2,d1

; a3a2a1a0e3e2e1e0 i3i2i1i0m3m2m1m0 c3c2c1c0g3g2g1g0 k3k2k1k0o3o2o1o0
; b3b2b1b0f3f2f1f0 j3j2j1j0n3n2n1n0 d3d2d1d0h3h2h1h0 l3l2l1l0p3p2p1p0

        move.l  d1,d2
        lsr.l   #1,d2
        eor.l   d0,d2
        and.l   d3,d2
        eor.l   d2,d0
        add.l   d2,d2
        eor.l   d2,d1

; a3b3a1b1e3f3e1f1 i3j3i1j1m3n3m1n1 c3d3c1d1g3h3g1h1 k3l3k1l1o3p3o1p1
; a2b2a0b0e2f2f0f0 i2j2i0j0m2n2m0n0 c2d2c0d0g2h2g0h0 k2l2k0l0o2p2o0p0

        move.w  d1,d2
        move.w  d0,d1
        swap    d1
        move.w  d1,d0
        move.w  d2,d1

; a3b3a1b1e3f3e1f1 i3j3i1j1m3n3m1n1 a2b2a0b0e2f2f0f0 i2j2i0j0m2n2m0n0
; c3d3c1d1g3h3g1h1 k3l3k1l1o3p3o1p1 c2d2c0d0g2h2g0h0 k2l2k0l0o2p2o0p0

        move.l  d1,d2
        lsr.l   #2,d2
        eor.l   d0,d2
        and.l   d4,d2
        eor.l   d2,d0
        lsl.l   #2,d2
        eor.l   d2,d1

; a3b3c3d3e3f3g3h3 i3j3k3l3m3n3o3p3 a2b2c2d2e2f2g2h2 i2j2k2l2m2n2o2p2
; a1b1c1d1e1f1g1h1 i1j1k1l1m1n1o1p1 a0b0c0d0e0f0g0h0 i0j0k0l0m0n0o0p0

        move.w  d1,(a1)+
        swap    d1
        move.w  d1,(a2)+
        move.w  d0,(a3)+
        swap    d0
        move.w  d0,(a4)+

        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

vgb_fix_left_edge:
        move.l  pd_XPosBufferPtr(a6),a2
        move.w  pd_LastAngle(a6),d0
        bpl.s   .noflip
        neg.w   d0
        add.w   #((ROT_ANGLES-1)*2),d0
.noflip mulu    #(VGBARS_HEIGHT*2)/2,d0
        adda.l  d0,a2

        move.l  pd_LastChunkyResultPtr(a6),a1
        ;lea     ((BARLINE_WIDTH-NUM_CHUNKY_PIXELS)/2)*2-64*2(a1),a1
        ;FIXME offset or something else is wrong here
        lea     96*2(a1),a1

        move.l  pd_ChunkyLeftEdgeRGBPtr(a6),a0
        moveq.l #(VGBARS_HEIGHT/12)-1,d7
.loop
        REPT    2
        movem.w (a2)+,d0-d5
        move.w  (a1,d0.w),(a0)+
        move.w  (a1,d1.w),(a0)+
        move.w  (a1,d2.w),(a0)+
        move.w  (a1,d3.w),(a0)+
        move.w  (a1,d4.w),(a0)+
        move.w  (a1,d5.w),(a0)+
        ENDR
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

vgb_calc_ham_pixels:
        move.l  pd_OneColorChangeTable(a6),a2
        move.l  pd_DiffTable(a6),a3
        move.l  pd_CurrPlanesPtr(a6),a4
        adda.w  d0,a4
        moveq.l #$000,d0    ; last color
        moveq.l #0,d3
.xloop
        moveq.l #16-1,d6
.loop   add.w   d4,d4
        add.w   d5,d5
        move.w  (a1)+,d1    ; new color
        eor.w   d1,d0
        beq.s   .setblue
        moveq.l #0,d2
        move.b  (a2,d0.w),d2
        jmp     .jmptab(pc,d2.w)

.setblue
        move.w  d1,d0           ; 4
        and.w   #15,d1          ; 4
        move.b  d1,(a0)+        ; 8
        addq.w  #1,d4           ; 4
                                ; 20
        dbra    d6,.loop
        bra     .done

.setgreen
        move.w  d1,d0           ; 4
        lsr.b   #4,d1           ; 14
        move.b  d1,(a0)+        ; 8
        addq.w  #1,d4           ; 4
        addq.w  #1,d5           ; 4
                                ; 34
        dbra    d6,.loop
        bra     .done

.setred
        move.w  d1,d0           ; 4
        move.b  -2(a1),(a0)+    ; 24
        addq.w  #1,d5           ; 4
                                ; 32
        dbra    d6,.loop
        bra     .done

.jmptab
        bra.s   .setblue    ; 0
        bra.s   .setblue    ; 1
        bra.s   .setgreen   ; 2
        bra.s   .pickgb     ; 3
        bra.s   .setred     ; 4
        bra.s   .pickrb     ; 5
        bra.s   .pickrg     ; 6
.slowpick                   ; 7
        eor.w   d1,d0
        PUTMSG  50,<"Slow pick to %x from %x!>,d1,d0
        move.b  d0,-(sp)
        move.w  (sp)+,d2        ; gbxx
        move.b  d1,d2           ; gbGB
        tst.b   (a3,d2.l)       ; if delta green < delta blue -> positive
        bpl.s   .pickrb2
        bra.s   .pickrg2

.pickgb
        eor.w   d1,d0
        move.b  d0,-(sp)
        move.w  (sp)+,d2        ; gbxx
        move.b  d1,d2           ; gbGB
        tst.b   (a3,d2.l)       ; if delta green < delta blue -> positive
        bpl.s   .prefblue
.prefgreen
        and.w   #$0f0,d1
        and.w   #$f0f,d0
        or.w    d1,d0
        lsr.b   #4,d1
        move.b  d1,(a0)+
        addq.w  #1,d4
        addq.w  #1,d5
        dbra    d6,.loop
        bra     .done

.pickrg
        eor.w   d1,d0
.pickrg2
        move.w  d0,d2
        lsl.w   #4,d2           ; rg00
        move.w  d1,d3
        lsr.w   #4,d3           ; 00RG
        move.b  d3,d2           ; rgRG
        tst.b   (a3,d2.l)       ; if delta red < delta green -> positive
        bpl.s   .prefgreen
        bra.s   .prefred

.pickrb eor.w   d1,d0
.pickrb2
        move.l  pd_RedBlueTable(a6),a3
        move.b  (a3,d0.w),-(sp)
        move.w  (sp)+,d2        ; rbxx
        move.b  (a3,d1.w),d2    ; rbRB
        move.l  pd_DiffTable(a6),a3
        tst.b   (a3,d2.l)       ; if delta red < delta blue -> positive
        bpl.s   .prefblue
.prefred
        IF      1
        move.w  d1,-(sp)        ; 8
        move.b  d0,1(sp)        ; 12
        move.w  (sp),d0         ; 8
        move.b  (sp)+,(a0)+     ; 20
                                ; 48
        ELSE
        and.w   #$f00,d1        ; 8
        and.w   #$0ff,d0        ; 8
        or.w    d1,d0           ; 4
        move.w  d1,-(sp)        ; 8
        move.b  (sp)+,(a0)+     ; 20
                                ; 48
        ENDC
        addq.w  #1,d5
        dbra    d6,.loop
        bra     .done

.prefblue
        and.w   #$00f,d1        ; 8
        and.w   #$ff0,d0        ; 8
        or.w    d1,d0           ; 4
        move.b  d1,(a0)+        ; 8
                                ; 28
        addq.w  #1,d4
        dbra    d6,.loop

.done
        move.w  d5,1*(BARLINE_WIDTH/8)(a4)
        move.w  d4,(a4)+
        dbra    d7,.xloop
        rts

;--------------------------------------------------------------------

vgb_calc_ham_pixels_wobble:
        move.l  pd_OneColorChangeTable(a6),a2
        move.l  pd_DiffTable(a6),a3
        move.l  pd_CurrPlanesPtr(a6),a4
        adda.w  d0,a4
        moveq.l #$000,d0    ; last color
        moveq.l #0,d3
.xloop
        moveq.l #16-1,d6
.loop   add.w   d4,d4
        add.w   d5,d5
        move.w  (a1)+,d1    ; new color
        eor.w   d1,d0
        beq.s   .setblue
        moveq.l #0,d2
        move.b  (a2,d0.w),d2
        jmp     .jmptab(pc,d2.w)

.setblue
        move.w  d1,d0           ; 4
        and.w   #15,d1          ; 4
        move.b  d1,(a0)+        ; 8
        addq.w  #1,d4           ; 4
                                ; 20
        dbra    d6,.loop
        bra     .done

.setgreen
        move.w  d1,d0           ; 4
        lsr.b   #4,d1           ; 14
        move.b  d1,(a0)+        ; 8
        addq.w  #1,d4           ; 4
        addq.w  #1,d5           ; 4
                                ; 34
        dbra    d6,.loop
        bra     .done

.setred
        move.w  d1,d0           ; 4
        move.b  -2(a1),(a0)+    ; 24
        addq.w  #1,d5           ; 4
                                ; 32
        dbra    d6,.loop
        bra     .done

.jmptab
        bra.s   .setblue    ; 0
        bra.s   .setblue    ; 1
        bra.s   .setgreen   ; 2
        bra.s   .pickgb     ; 3
        bra.s   .setred     ; 4
        bra.s   .pickrb     ; 5
        bra.s   .pickrg     ; 6
.slowpick                   ; 7
        eor.w   d1,d0
        PUTMSG  50,<"Slow pick to %x from %x!>,d1,d0
        move.b  d0,-(sp)
        move.w  (sp)+,d2        ; gbxx
        move.b  d1,d2           ; gbGB
        tst.b   (a3,d2.l)       ; if delta green < delta blue -> positive
        bpl.s   .pickrb2
        bra.s   .pickrg2

.pickgb
        eor.w   d1,d0
        move.b  d0,-(sp)
        move.w  (sp)+,d2        ; gbxx
        move.b  d1,d2           ; gbGB
        tst.b   (a3,d2.l)       ; if delta green < delta blue -> positive
        bpl.s   .prefblue
.prefgreen
        and.w   #$0f0,d1
        and.w   #$f0f,d0
        or.w    d1,d0
        lsr.b   #4,d1
        move.b  d1,(a0)+
        addq.w  #1,d4
        addq.w  #1,d5
        dbra    d6,.loop
        bra     .done

.pickrg
        eor.w   d1,d0
.pickrg2
        move.w  d0,d2
        lsl.w   #4,d2           ; rg00
        move.w  d1,d3
        lsr.w   #4,d3           ; 00RG
        move.b  d3,d2           ; rgRG
        tst.b   (a3,d2.l)       ; if delta red < delta green -> positive
        bpl.s   .prefgreen
        bra.s   .prefred

.pickrb eor.w   d1,d0
.pickrb2
        move.l  pd_RedBlueTable(a6),a3
        move.b  (a3,d0.w),-(sp)
        move.w  (sp)+,d2        ; rbxx
        move.b  (a3,d1.w),d2    ; rbRB
        move.l  pd_DiffTable(a6),a3
        tst.b   (a3,d2.l)       ; if delta red < delta blue -> positive
        bpl.s   .prefblue
.prefred
        move.w  d1,-(sp)        ; 8
        move.b  d0,1(sp)        ; 12
        move.w  (sp),d0         ; 8
        move.b  (sp)+,(a0)+     ; 20
                                ; 48
        addq.w  #1,d5
        dbra    d6,.loop
        bra     .done

.prefblue
        and.w   #$00f,d1        ; 8
        and.w   #$ff0,d0        ; 8
        or.w    d1,d0           ; 4
        move.b  d1,(a0)+        ; 8
                                ; 28
        addq.w  #1,d4
        dbra    d6,.loop

.done
        move.w  d5,1*(VGBARS_WIDTH/8)(a4)
        move.w  d4,(a4)+
        dbra    d7,.xloop
        rts

;--------------------------------------------------------------------

vgb_create_intro_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        lea     pd_OverlaySprites(a6),a1
        move.w  #sprpt,d1
        moveq.l #8*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        COPIMOVE $6a00,bplcon0
        COPIMOVE 0,bplcon1
        COPIMOVE $0038,ddfstrt
        COPIMOVE (-VGBARS_WIDTH)/8,bpl1mod
        COPIMOVE (-VGBARS_WIDTH)/8,bpl2mod

        move.l  pd_CurrPlanesPtr(a6),a1
        lea     ((BARLINE_WIDTH-VGBARS_WIDTH)/2)/8(a1),a1
        moveq.l #VGBARS_PLANES-1,d7
        move.w  #bplpt,d1
.bplloop
        move.l  a1,d0
        swap    d0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        move.w  a1,(a0)+
        addq.w  #2,d1

        lea     (BARLINE_WIDTH)/8(a1),a1
        dbra    d7,.bplloop

        moveq.l #-2,d3
        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

vgb_create_wobble_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2

        lea     pd_OverlaySprites(a6),a1
        move.w  #sprpt,d1
        moveq.l #8*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        COPIMOVE $6a00,bplcon0
        COPIMOVE 0,bplcon1
        COPIMOVE $0038,ddfstrt

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #2,d1
        move.w  d1,pd_CopperBplOffset(a6)

        move.l  pd_CurrPlanesPtr(a6),a1
        moveq.l #VGBARS_PLANES-1,d7
        move.w  #bplpt,d1
.bplloop
        move.l  a1,d0
        swap    d0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        move.w  a1,(a0)+
        addq.w  #2,d1

        lea     (VGBARS_WIDTH/8)(a1),a1
        dbra    d7,.bplloop

        move.l  a0,d1
        sub.l   a2,d1
        add.w   #8+2,d1
        move.w  d1,pd_CopperSkewOffset(a6)

        moveq.l #-2,d3
        move.w  #$5137,d0
        move.w  #$100,d2
        move.w  #VGBARS_HEIGHT-1,d7
        move.w  #-VGBARS_WIDTH/8,d4
.yloop  move.w  d0,d1
        move.b  #$df,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+

        add.w   d2,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+

        COPRMOVE d4,bpl1mod
        COPRMOVE d4,bpl2mod
        dbra    d7,.yloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

vgb_create_main_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2

        move.l  pd_CurrPlanesPtr(a6),a1
        moveq.l #VGBARS_PLANES-1,d7
        move.w  #bplpt,d1
.bplloop
        move.l  a1,d0
        swap    d0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        move.w  a1,(a0)+
        addq.w  #2,d1

        lea     (BARLINE_WIDTH)/8(a1),a1
        dbra    d7,.bplloop

        COPIMOVE $6a00,bplcon0

        lea     pd_OverlaySprites(a6),a1
        move.w  #sprpt,d1
        moveq.l #8*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperSkewOffset(a6)

        moveq.l #-2,d3
        move.w  #$51d5,d0
        move.w  #$100,d2
        move.w  #VGBARS_HEIGHT-1,d7
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+

        COPIMOVE (-VGBARS_WIDTH-16)/8,bpl1mod
        COPIMOVE (-VGBARS_WIDTH-16)/8,bpl2mod
        COPIMOVE 0,bplcon1

        add.w   d2,d0
        move.w  d0,d1
        move.b  #$3b,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $000,color
        COPIMOVE $000,color

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

vgb_load_cat_sprites:
        lea     vgb_cat_sprite_palette(pc),a1
        lea     color+17*2(a5),a0
        moveq.l #15-1,d7
.catpalloop
        move.w  (a1)+,(a0)+
        dbra    d7,.catpalloop

        lea     pd_OverlaySprites(a6),a1
        lea     vgb_cat_sprite,a3
        move.l  a3,a2
        moveq.l #(CAT_WIDTH/16)*2-1,d7
.sprloop2
        move.l  a3,a0
        adda.w  (a2)+,a0
        move.l  d0,(a0)
        move.l  a0,(a1)+
        dbra    d7,.sprloop2

        move.w  #VGBARS_WIDTH-CAT_WIDTH-2,pd_OverlayXPos(a6)
        move.w  #VGBARS_HEIGHT,pd_OverlayYPos(a6)
        clr.l   pd_OverlayXDir(a6)
        st      pd_OverlayKilled(a6)

        rts

;--------------------------------------------------------------------

vgb_update_cat_sprite:
        lea     pd_OverlaySprites(a6),a2

        moveq.l #0,d0
        moveq.l #0,d1
        tst.w   pd_OverlayKilled(a6)
        bne.s   .filldata

        move.w  pd_OverlayXPos(a6),d4
        move.w  pd_OverlayYPos(a6),d1
        add.w   pd_OverlayYDir(a6),d1
        move.w  d1,pd_OverlayYPos(a6)

        add.w   #128,d4
        add.w   #$52,d1

        move.w  d1,d2
        add.w   #CAT_HEIGHT,d2
        moveq.l #0,d0

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d0,d0       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d0,d0       ; ev8
        lsr.w   #1,d4       ; sh8-sh1 in d4
        addx.w  d0,d0       ; sh0
        or.w    d2,d0       ; ev7-ev0, sv8, ev8, sh0 in d0
        move.b  d4,d1       ; sv7-sv0, sh8-sh1 in d4
        tas     d0          ; att TAS sets bit 7
.filldata
        REPT    (CAT_WIDTH/16)
        move.l  (a2)+,a0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        move.l  (a2)+,a0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #8,d1
        ENDR
        rts

;--------------------------------------------------------------------

vgb_load_aold_sprites:
        move.w  #$ddd,color+17*2(a5)
        move.w  #$fff,color+21*2(a5)
        move.w  #$eee,color+25*2(a5)
        ;move.w  #$888,d0
        ;move.w  d0,color+18*2(a5)
        ;move.w  d0,color+22*2(a5)
        ;move.w  d0,color+26*2(a5)
        ;move.w  d0,color+30*2(a5)
        moveq.l #0,d0
        move.w  d0,color+19*2(a5)
        move.w  d0,color+23*2(a5)
        move.w  d0,color+27*2(a5)

        lea     pd_OverlaySprites(a6),a1
        lea     vgb_add_of_light_div_sprite,a3
        move.l  a3,a2
        moveq.l #(AOLD_WIDTH/16)-1,d7
.sprloop2
        move.l  a3,a0
        adda.w  (a2)+,a0
        move.l  d0,(a0)
        move.l  a0,(a1)+
        dbra    d7,.sprloop2

        move.l  fw_EmptySprite(a6),(a1)+
        move.l  fw_EmptySprite(a6),(a1)+

        move.w  #VGBARS_WIDTH,pd_OverlayXPos(a6)
        move.w  #VGBARS_HEIGHT-AOLD_HEIGHT-1,pd_OverlayYPos(a6)
        clr.l   pd_OverlayXDir(a6)
        st      pd_OverlayKilled(a6)
        rts

;--------------------------------------------------------------------

vgb_update_aold_sprite:
        lea     pd_OverlaySprites(a6),a2

        moveq.l #0,d0
        moveq.l #0,d1
        tst.w   pd_OverlayKilled(a6)
        bne.s   .filldata

        move.w  pd_OverlayXPos(a6),d4
        add.w   pd_OverlayXDir(a6),d4
        move.w  d4,pd_OverlayXPos(a6)
        move.w  pd_OverlayYPos(a6),d1
        add.w   pd_OverlayYDir(a6),d1
        move.w  d1,pd_OverlayYPos(a6)

        add.w   #128,d4
        add.w   #$52,d1

        move.w  d1,d2
        add.w   #AOLD_HEIGHT,d2
        moveq.l #0,d0

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d0,d0       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d0,d0       ; ev8
        lsr.w   #1,d4       ; sh8-sh1 in d4
        addx.w  d0,d0       ; sh0
        or.w    d2,d0       ; ev7-ev0, sv8, ev8, sh0 in d0
        move.b  d4,d1       ; sv7-sv0, sh8-sh1 in d4
        ;tas     d0          ; att TAS sets bit 7
.filldata
        REPT    (AOLD_WIDTH/16)
        move.l  (a2)+,a0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #8,d1
        ENDR
        rts

;--------------------------------------------------------------------

vgb_load_light_break_sprites:
        move.w  #$999,color+17*2(a5)
        move.w  #$bbb,color+21*2(a5)
        move.w  #$ddd,color+25*2(a5)
        move.w  #$fff,color+29*2(a5)
        move.w  #$888,d0
        move.w  d0,color+18*2(a5)
        move.w  d0,color+22*2(a5)
        move.w  d0,color+26*2(a5)
        move.w  d0,color+30*2(a5)
        moveq.l #0,d0
        move.w  d0,color+19*2(a5)
        move.w  d0,color+23*2(a5)
        move.w  d0,color+27*2(a5)
        move.w  d0,color+31*2(a5)

        lea     pd_OverlaySprites(a6),a1
        lea     vgb_light_break_sprite,a3
        move.l  a3,a2
        moveq.l #(LIGHTBREAK_WIDTH/16)-1,d7
.sprloop2
        move.l  a3,a0
        adda.w  (a2)+,a0
        move.l  d0,(a0)
        move.l  a0,(a1)+
        dbra    d7,.sprloop2

        move.w  #-LIGHTBREAK_WIDTH,pd_OverlayXPos(a6)
        move.w  #1,pd_OverlayYPos(a6)
        clr.l   pd_OverlayXDir(a6)
        st      pd_OverlayKilled(a6)
        rts

;--------------------------------------------------------------------

vgb_load_stay_broken_sprites:
        move.w  #$fff,color+17*2(a5)
        move.w  #$ddd,color+21*2(a5)
        move.w  #$bbb,color+25*2(a5)
        move.w  #$999,color+29*2(a5)
        lea     pd_OverlaySprites(a6),a1
        lea     vgb_stay_broken_sprite,a3
        move.l  a3,a2
        moveq.l #(STAYBROKEN_WIDTH/16)-1,d7
.sprloop2
        move.l  a3,a0
        adda.w  (a2)+,a0
        move.l  d0,(a0)
        move.l  a0,(a1)+
        dbra    d7,.sprloop2

        move.l  pd_CurrCopListPtr(a6),a0
        lea     pd_OverlaySprites(a6),a1
        move.w  #sprpt,d1
        moveq.l #8*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        rts

;--------------------------------------------------------------------

vgb_update_wobble_sprite:
        lea     pd_OverlaySprites(a6),a2

        moveq.l #0,d0
        moveq.l #0,d1
        tst.w   pd_OverlayKilled(a6)
        bne.s   .filldata

        move.w  pd_OverlayXPos(a6),d4
        add.w   pd_OverlayXDir(a6),d4
        move.w  d4,pd_OverlayXPos(a6)
        move.w  pd_OverlayYPos(a6),d1
        add.w   pd_OverlayYDir(a6),d1
        move.w  d1,pd_OverlayYPos(a6)

        add.w   #128,d4
        add.w   #$52,d1

        move.w  d1,d2
        add.w   #LIGHTBREAK_HEIGHT,d2
        moveq.l #0,d0

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d0,d0       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d0,d0       ; ev8
        lsr.w   #1,d4       ; sh8-sh1 in d4
        addx.w  d0,d0       ; sh0
        or.w    d2,d0       ; ev7-ev0, sv8, ev8, sh0 in d0
        move.b  d4,d1       ; sv7-sv0, sh8-sh1 in d4
        ;tas     d0          ; att TAS sets bit 7
.filldata
        REPT    (LIGHTBREAK_WIDTH/16)
        move.l  (a2)+,a0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #8,d1
        ENDR
        rts

;--------------------------------------------------------------------

vgb_update_wobble_offset_to_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        adda.w  pd_CopperBplOffset(a6),a0

        move.l  pd_WobbleDataPtr(a6),a3
        move.l  pd_HistoryBuffer(a6),a1
        adda.w  (a3)+,a1
        move.l  a1,d0
        moveq.l #(VGBARS_WIDTH/8),d1
        moveq.l #VGBARS_PLANES-1,d7
.bplloop
        add.l   d1,d0
        swap    d0
        move.w  d0,(a0)
        swap    d0
        move.w  d0,4(a0)
        addq.l  #8,a0
        dbra    d7,.bplloop
        rts

;--------------------------------------------------------------------

vgb_update_skew_to_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        addq.w  #2,a0

        move.l  pd_CurrPlanesPtr(a6),a1
        lea     ((BARLINE_WIDTH-VGBARS_WIDTH)/2)/8-4(a1),a1
        adda.w  pd_FirstLineOffset(a6),a1
        moveq.l #VGBARS_PLANES-1,d7
        move.w  #bplpt,d1
.bplloop
        move.l  a1,d0
        swap    d0
        move.w  d0,(a0)
        move.w  a1,4(a0)
        addq.w  #8,a0

        lea     (BARLINE_WIDTH)/8(a1),a1
        dbra    d7,.bplloop
        rts

;--------------------------------------------------------------------

vgb_blitter_update_wobble_modulos:
        move.l  pd_WobbleDataPtr(a6),a2
        addq.w  #2,a2
        move.l  pd_CurrCopListPtr(a6),a0
        adda.w  pd_CopperSkewOffset(a6),a0

        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+

        addq.l  #4,a0
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_copy_more,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        rts

.bq_copy
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(0<<16)|(COP_WOBBLE_INST_PER_LINE*4-2),bltamod(a5) ; and bltdmod
.bq_copy_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #(1|((VGBARS_HEIGHT-1)<<6)),(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

vgb_blitter_update_skew_and_left_edge:
        move.l  pd_ModShiftDataPtr(a6),a2
        move.w  pd_LastAngle(a6),d0
        bpl.s   .noflip
        neg.w   d0
        add.w   #((ROT_ANGLES-1)*2),d0
.noflip mulu    #MODSHIFT_SIZE/2,d0
        adda.l  d0,a2

        move.w  2(a2),pd_FirstLineOffset(a6)

        move.l  pd_CurrCopListPtr(a6),a0
        adda.w  pd_CopperSkewOffset(a6),a0

        addq.w  #8,a0

        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        move.w  #(1|(VGBARS_HEIGHT<<6)),(a4)+

        addq.w  #6,a2
        subq.w  #4,a0
        move.w  #(1|((VGBARS_HEIGHT-1)<<6)),d3

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_more,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        subq.w  #4,a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_more,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        lea     16(a0),a0

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_copy_edge,(a4)+
        move.l  pd_ChunkyLeftEdgeRGBPtr(a6),(a4)+
        move.l  a0,(a4)+
        move.w  #(1|(VGBARS_HEIGHT<<6)),(a4)+
        rts

.bq_copy
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(2<<16)|(COP_INST_PER_LINE*4-2),bltamod(a5) ; and bltdmod
.bq_copy_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy_edge
        move.w  #0,bltamod(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

vgb_blitter_saturate_and_merge:
        move.l  pd_LastChunkyPtr(a6),a2
        move.l  pd_ChunkySatPtr(a6),a1
        lea     ((NUM_CHUNKY_PIXELS*3))*2-2(a2),a2
        lea     ((NUM_CHUNKY_PIXELS*3))*2(a1),a1
        move.w  #(1|(NUM_CHUNKY_PIXELS<<6)),d3

        FIRST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_saturate_all,(a4)+
        move.l  a2,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        REPT    2
        lea     -NUM_CHUNKY_PIXELS*2(a2),a2
        lea     -NUM_CHUNKY_PIXELS*2(a1),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_saturate_more,(a4)+
        move.l  a2,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize
        ENDR

        move.l  pd_LastChunkyPtr(a6),a0
        move.l  pd_ChunkyResultRPtr(a6),a1
        move.l  pd_ChunkySatRPtr(a6),a2
        addq.l  #2,a0
        addq.l  #2,a2

        ;move.w  #(1)|((NUM_CHUNKY_PIXELS)<<6),d3

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_extract_rgb,(a4)+
        move.l  #((BLTEN_ABD+(((BLT_A|BLT_B)&BLT_C)&$ff))<<16)|(12<<28)|(12<<12),(a4)+
        move.w  #$0f00,(a4)+    ; bltcdat
        move.l  a2,(a4)+        ; bltbpt
        move.l  a0,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        lea     NUM_CHUNKY_PIXELS*2-2(a0),a0
        move.l  pd_ChunkyResultGPtr(a6),a1
        move.l  pd_ChunkySatGPtr(a6),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_extract_rgb,(a4)+
        move.l  #((BLTEN_ABD+(((BLT_A|BLT_B)&BLT_C)&$ff))<<16)|(0<<28)|(0<<12),(a4)+
        move.w  #$00f0,(a4)+    ; bltcdat
        move.l  a2,(a4)+        ; bltbpt
        move.l  a0,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        lea     NUM_CHUNKY_PIXELS*2(a0),a0
        move.l  pd_ChunkyResultBPtr(a6),a1
        move.l  pd_ChunkySatBPtr(a6),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_extract_rgb,(a4)+
        move.l  #((BLTEN_ABD+(((BLT_A|BLT_B)&BLT_C)&$ff))<<16)|(4<<28)|(4<<12),(a4)+
        move.w  #$000f,(a4)+    ; bltcdat
        move.l  a2,(a4)+        ; bltbpt
        move.l  a0,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        ;move.w  #(1)|((NUM_CHUNKY_PIXELS)<<6),d3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_rgb,(a4)+
        move.l  pd_ChunkyResultRPtr(a6),(a4)+
        move.l  pd_ChunkyResultGPtr(a6),(a4)+
        move.l  pd_ChunkyResultBPtr(a6),(a4)+
        move.l  pd_CurrChunkyResultPtr(a6),(a4)+
        move.w  d3,(a4)+

        lea     vgb_sudoku_dither(pc),a1
        move.w  pd_SudokuDitherPos(a6),d0
        sub.w   #9*2,d0
        bpl.s   .noresetdither
        moveq.l #2*9*2,d0
.noresetdither
        move.w  d0,pd_SudokuDitherPos(a6)
        adda.w  d0,a1

        move.w  #(1)|((NUM_CHUNKY_PIXELS/3)<<6),d3
        move.w  #(1)|(((NUM_CHUNKY_PIXELS+1)/3)<<6),d2

        ; pixel 1, red
        move.l  pd_LastChunkyPtr(a6),a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        ; pixel 2, red
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 3, red
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 1, green
        lea     (NUM_CHUNKY_PIXELS-2)*2(a0),a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        ; pixel 2, green
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 3, green
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 1, blue
        lea     (NUM_CHUNKY_PIXELS-2)*2(a0),a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        ; pixel 2, blue
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 3, blue
        addq.w  #2,a0
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        rts

.bq_saturate_all
        BLTHOGOFF
        BLTCON_SET_X AD,(BLT_A&BLT_C),8,0,BLTCON1F_DESC|BLTCON1F_IFE
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #0,d0
        move.l  d0,bltcmod(a5)  ; and bltbmod
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  #$0007,bltcdat(a5)
.bq_saturate_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_extract_rgb
        lea     bltcon0(a5),a1
        move.l  (a0)+,(a1)+     ; bltcon0/bltcon1
        move.w  (a0)+,bltcdat(a5)
        addq.l  #8,a1
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_merge_rgb
        BLTCON_SET ABCD,(BLT_A|BLT_B|BLT_C),0,0
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_dither
        BLTCON0_SET D,BLT_C,0
        move.w  #4,bltdmod(a5)
.bq_dither_more
        move.w  (a0)+,bltcdat(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  (a0)+,bltsize(a5)
        rts

;--------------------------------------------------------------------

vgb_blitter_saturate_and_merge_320:
        move.l  pd_LastChunkyPtr(a6),a2
        move.l  pd_ChunkySatPtr(a6),a1
        lea     ((NUM_CHUNKY_PIXELS*3)-96)*2-2(a2),a2
        lea     ((NUM_CHUNKY_PIXELS*3)-96)*2(a1),a1
        move.w  #(1|((VGBARS_WIDTH)<<6)),d3

        FIRST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_saturate_all,(a4)+
        move.l  a2,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        REPT    2
        lea     -NUM_CHUNKY_PIXELS*2(a2),a2
        lea     -NUM_CHUNKY_PIXELS*2(a1),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_saturate_more,(a4)+
        move.l  a2,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize
        ENDR

        move.l  pd_LastChunkyPtr(a6),a0
        move.l  pd_ChunkyResultRPtr(a6),a1
        move.l  pd_ChunkySatRPtr(a6),a2
        lea     96*2+2(a0),a0
        lea     96*2(a1),a1
        lea     96*2+2(a2),a2

        ;move.w  #(1)|((NUM_CHUNKY_PIXELS)<<6),d3

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_extract_rgb,(a4)+
        move.l  #((BLTEN_ABD+(((BLT_A|BLT_B)&BLT_C)&$ff))<<16)|(12<<28)|(12<<12),(a4)+
        move.w  #$0f00,(a4)+    ; bltcdat
        move.l  a2,(a4)+        ; bltbpt
        move.l  a0,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        lea     NUM_CHUNKY_PIXELS*2-2(a0),a0
        move.l  pd_ChunkyResultGPtr(a6),a1
        move.l  pd_ChunkySatGPtr(a6),a2
        lea     96*2(a1),a1
        lea     96*2(a2),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_extract_rgb,(a4)+
        move.l  #((BLTEN_ABD+(((BLT_A|BLT_B)&BLT_C)&$ff))<<16)|(0<<28)|(0<<12),(a4)+
        move.w  #$00f0,(a4)+    ; bltcdat
        move.l  a2,(a4)+        ; bltbpt
        move.l  a0,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        lea     NUM_CHUNKY_PIXELS*2(a0),a0
        move.l  pd_ChunkyResultBPtr(a6),a1
        move.l  pd_ChunkySatBPtr(a6),a2
        lea     96*2(a1),a1
        lea     96*2(a2),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_extract_rgb,(a4)+
        move.l  #((BLTEN_ABD+(((BLT_A|BLT_B)&BLT_C)&$ff))<<16)|(4<<28)|(4<<12),(a4)+
        move.w  #$000f,(a4)+    ; bltcdat
        move.l  a2,(a4)+        ; bltbpt
        move.l  a0,(a4)+        ; bltapt
        move.l  a1,(a4)+        ; bltdpt
        move.w  d3,(a4)+        ; bltsize

        move.l  pd_ChunkyResultRPtr(a6),a0
        move.l  pd_ChunkyResultGPtr(a6),a1
        move.l  pd_ChunkyResultBPtr(a6),a2
        lea     96*2(a0),a0
        lea     96*2(a1),a1
        lea     96*2(a2),a2
        ;move.w  #(1)|((NUM_CHUNKY_PIXELS)<<6),d3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_rgb,(a4)+
        move.l  a0,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+
        move.l  pd_CurrChunkyResultPtr(a6),a0
        lea     96*2(a0),a0
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        lea     vgb_sudoku_dither(pc),a1
        move.w  pd_SudokuDitherPos(a6),d0
        sub.w   #9*2,d0
        bpl.s   .noresetdither
        moveq.l #2*9*2,d0
.noresetdither
        move.w  d0,pd_SudokuDitherPos(a6)
        adda.w  d0,a1

        move.w  #(1)|(((VGBARS_WIDTH+3)/3)<<6),d3
        move.w  #(1)|(((VGBARS_WIDTH+4)/3)<<6),d2

        ; pixel 1, red
        move.l  pd_LastChunkyPtr(a6),a0
        lea     96*2(a0),a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        ; pixel 2, red
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 3, red
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 1, green
        lea     (NUM_CHUNKY_PIXELS-2)*2(a0),a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        ; pixel 2, green
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 3, green
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 1, blue
        lea     (NUM_CHUNKY_PIXELS-2)*2(a0),a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d3,(a4)+

        ; pixel 2, blue
        addq.w  #2,a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        ; pixel 3, blue
        addq.w  #2,a0
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_dither_more,(a4)+
        move.w  (a1)+,(a4)+
        move.l  a0,(a4)+
        move.w  d2,(a4)+

        rts

.bq_saturate_all
        BLTHOGOFF
        BLTCON_SET_X AD,(BLT_A&BLT_C),8,0,BLTCON1F_DESC|BLTCON1F_IFE
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #0,d0
        move.l  d0,bltcmod(a5)  ; and bltbmod
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  #$0007,bltcdat(a5)
.bq_saturate_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_extract_rgb
        lea     bltcon0(a5),a1
        move.l  (a0)+,(a1)+     ; bltcon0/bltcon1
        move.w  (a0)+,bltcdat(a5)
        addq.l  #8,a1
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_merge_rgb
        BLTCON_SET ABCD,(BLT_A|BLT_B|BLT_C),0,0
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_dither
        BLTCON0_SET D,BLT_C,0
        move.w  #4,bltdmod(a5)
.bq_dither_more
        move.w  (a0)+,bltcdat(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  (a0)+,bltsize(a5)
        rts

;********************************************************************

vgb_sudoku_dither:
        dc.w    5,8,1,7,9,2,3,6,4
        dc.w    6,7,2,8,4,3,5,9,1
        dc.w    4,3,9,6,5,1,7,8,2

vgb_bars_colors:
        dc.w    130,190,240
        dc.w    230,60,150
        dc.w    120,50,10
        dc.w    10,100,70
        dc.w    150,200,30
        dc.w    10,120,50
        dc.w    80,20,130

vgb_bars_dists:
        dc.w    130*4
        dc.w    -80*4
        dc.w    90*4
        dc.w    100*4
        dc.w    -140*4
        dc.w    -40*4
        dc.w    150*4

vgb_xpos_table:
        dc.w    0,1,3,4,6,7,9,11,12,14,15,17,18,20,22,23
        dc.w    25,27,28,30,32,33,35,37,38,40,42,44,45,47,49,51
        dc.w    53,54,56,58,60,62,64,66,68,70,72,74,76,78,81,83
        dc.w    85,87,90,92,94,97,99,102,105,107,110,113,116,118,121,124
        dc.w    128,131,134,137,141,144,148,152,155,159,164,168,172,177,181,186
        dc.w    191,196,202,207,213,219,225,232,239,246,254,262,270,279,288,298
        dc.w    309,320,331,344,357,372,387,404,421,441,462,485,511,538,570,604
        dc.w    643,687,737,795,862,942,1037,1154,1299,1486,1735,2083,2605,3475,5214,10429

vgb_cat_sprite_palette:
        incbin  "../data/virgillbars/PLT_Lolcat64x128x16.PAL"

        incbin  "../data/virgillbars/curtainsine.bin"
vgb_wobble_table:
        incbin  "../data/virgillbars/curtainsine.bin"
        incbin  "../data/virgillbars/curtainsine.bin"

;********************************************************************

;--------------------------------------------------------------------

        section "vgb_copper",data,chip

vgb_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$5281          ; window start
        COP_MOVE diwstop,$06c1          ; window stop
        COP_MOVE ddfstrt,$0030          ; bitplane start
vgb_ddfstop:
        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00
vgb_fmode:
        COP_MOVE fmode,$0000            ; fixes the aga modulo problem

        COP_MOVE color+0*2,$000
        COP_MOVE color+1*2,$000

        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon2,$0024          ; sprites in front

vgb_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

vgb_cat_sprite:
        incbin  "../data/virgillbars/PLT_Lolcat64x128x16.ASP"

vgb_add_of_light_div_sprite:
        incbin  "../data/virgillbars/additionsprite96x112x4.SPR"

vgb_light_break_sprite:
        incbin  "../data/virgillbars/lightbreak128x128x4.SPR"

vgb_stay_broken_sprite:
        incbin  "../data/virgillbars/staybroken128x128x4.SPR"

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        section "part_music_samples",data,chip      ; section for music playback
part_music_smp:
        incbin  "../data/music/dsr_68k_tune_2_v11.lsbank"

        section "part_music_data",data              ; section for music playback
part_music_data:
        incbin  "../data/music/dsr_68k_tune_2_v11.lsmusic"
        ENDC
        ENDC
        END