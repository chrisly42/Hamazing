; TODOs:
; - Some sprite effect? (boxes around appearing things?)
; - Sprite overlays
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
PART_MUSIC_START_POS        = 11

        ENDC

BLENDIMG_WIDTH      = 320
BLENDIMG_HEIGHT     = 180
BLENDIMG_PLANES     = 6

BLENDVIEW_WIDTH     = 320
BLENDVIEW_HEIGHT    = 180
BLENDVIEW_PLANES    = 6

ENDLOGO_WIDTH       = 320
ENDLOGO_HEIGHT      = 180
ENDLOGO_PLANES      = 6

PART_WIDTH      = 32
PART_HEIGHT     = 30

BLOCKS_WIDTH    = (BLENDVIEW_WIDTH/PART_WIDTH)
BLOCKS_HEIGHT   = (BLENDVIEW_HEIGHT/PART_HEIGHT)

NUM_BARS        = (BLENDVIEW_WIDTH/16)

MIN_CIRCLE_SIZE = 3
MAX_CIRCLE_SIZE = 50
CIRCLE_MASKS_SIZE = 10514
CIRCLE_SPEEDCODE_SIZE = 62784

NUM_CIRCLE_POTS = 6

COP_PREAMBLE_INST   = 16 ; bplptrs
COP_POST_INST       = 16 ; wait
COP_INST_PER_INTRO_LINE = 28
COP_INST_PER_BARS_LINE = 22 ; wait, 20 colors, nop
COP_INST_PER_HOLE_LINE = 11 ; wait, color 8, wait, color 1,2,3,4,5,6,7,8
COP_INST_PER_LINE   =  28 ; color 1,2,3,4,5,6,7 wait, 20*(line 8 color)
COP_LIST_SIZE       = (COP_PREAMBLE_INST+COP_INST_PER_LINE*BLENDVIEW_HEIGHT+COP_POST_INST)*4

CHIPMEM_SIZE = COP_LIST_SIZE*2+3*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT*BLENDVIEW_PLANES+BLENDVIEW_HEIGHT*4*8+CIRCLE_MASKS_SIZE+4
FASTMEM_SIZE = BLENDIMG_WIDTH*BLENDIMG_HEIGHT*2*3+CIRCLE_SPEEDCODE_SIZE


        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"


; Chip memory use:
;   - CHIP DATA: 320 x  180 x 6 x  1 =  43200 (original images)
;
;   - CHIP BSS : 320 x  180 x 6 x  1 =  43200 (loaded image)
;   - CHIP BSS : 320 x  180 x 6 x  2 =  86400 (db buffers)
;   - CHIP BSS : 320 x  180 x 1 x  2 =  14400 (empty and filled, used during circle precalc)
;   - CHIP BSS :  32 x   30 x 5 x  5 =   3600 (block target p1-p4 & p5|p6)
;   - CHIP BSS :   4 x  180 x   x  8 =   5760 (line-fix array)
;   - CHIP BSS :                  48 =  10488 (circle masks)
;   - CHIP BSS :   8 x  180 x      2 =  11520 (copperlists)
;
;   - CHIP BSS :  20 x  180 x 2 x  2 =  14400 (truecolor 16, recycled from above)
;   - CHIP BSS :   2 x  180 x      4 =   1440 (sine clip positions, db)
;   - CHIP BSS :   4 x  181 x      4 =   2896 (smc buffers)
;
; Total: 207 KB
;
; Fast memory use:
;   - FAST BSS : 320 x  180 x      2 = 230400 (True color buffer)
;   - FAST BSS : 320 x  180 x      1 = 115200 (True color buffer)
;   - FAST BSS :       4096 x 2 x  2 =  16384 (Shading tables, recycled)
;   - FAST BSS :                     =  61632 (Circle speedcode)
;   - FAST BSS :           2000      =   2000 (Blitterqueues)
;
; Mem Free: Chip: 89 of 498 KB (236/0 KB) | Fast: 106 of 445 KB (329/2 KB)
; Mem Free: Chip: 59 of 498 KB (266/0 KB) | Fast: 9 of 445 KB (426/2 KB)

    STRUCTURE   CirclePot,0
        UWORD   cp_Radius
        WORD    cp_CenterPosX
        WORD    cp_CenterPosY

        UWORD   cp_LastRadius
        ULONG   cp_LastPosOffset

        UWORD   cp_LastLastRadius
        ULONG   cp_LastLastPosOffset

        UWORD   cp_LRIAreaY

        UWORD   cp_TimeLeft
        UWORD   cp_RadPos
        UWORD   cp_Pair

        LABEL   cp_RelPosXLong
        UWORD   cp_RelPosSinXSpeed
        UWORD   cp_RelPosSinYSpeed
        LABEL   cp_RelPosYLong
        UWORD   cp_RelPosSinXOffset
        UWORD   cp_RelPosSinYOffset
        LABEL   cp_RelPosXInc
        UWORD   cp_RelPosXRadius
        LABEL   cp_RelPosYInc
        UWORD   cp_RelPosYRadius
        UWORD   cp_RelPosXCenter
        UWORD   cp_RelPosYCenter
        UWORD   cp_GreetingTimeRev

        UWORD   cp_LineFixTopYOffset
        ULONG   cp_PosOffset
        LONG    cp_PosTCOffset
        LONG    cp_InvertedOffset
        WORD    cp_FgRelPosX
        WORD    cp_FgRelPosY
        ULONG   cp_FgOffset
        UWORD   cp_CircleShift
        LONG    cp_FgTCOffset

        APTR    cp_CircleInfo
        APTR    cp_BgImage
        APTR    cp_BgTCImage
        APTR    cp_FgImage
        APTR    cp_FgTCImage
        APTR    cp_CircleFixupRoutine
        APTR    cp_PaintRoutine
        APTR    cp_PotScriptPtr
        APTR    cp_FrameRoutine
        LABEL   cp_SIZEOF

    STRUCTURE   CircleInfo,0
        UWORD   ci_LRIAreaY

        UWORD   ci_TopWidth
        UWORD   ci_TopHeight
        UWORD   ci_TopXOffset

        UWORD   ci_LeftWidth
        UWORD   ci_LeftXOffset

        UWORD   ci_RightWidth
        UWORD   ci_RightXOffset

        UWORD   ci_InnerBltSize
        UWORD   ci_InnerXOffset
        UWORD   ci_InnerBltMod

        ; this is generated runtime
        UWORD   ci_InnerBgOffset
        WORD    ci_InnerFgOffset

        UWORD   ci_TopBgOffset
        WORD    ci_TopFgOffset

        UWORD   ci_TopBottomOffsetAdv

        UWORD   ci_LeftBgOffset
        WORD    ci_LeftFgOffset

        UWORD   ci_RightBgOffset
        WORD    ci_RightFgOffset

        UWORD   ci_TopBottomMaskSize
        UWORD   ci_TopBottomBltSize

        UWORD   ci_LeftBltSize
        UWORD   ci_RightBltSize

        APTR    ci_TopMask
        APTR    ci_LeftMask
        APTR    ci_RightMask

        APTR    ci_LeftDotSetCode
        APTR    ci_LeftDotClearCode
        APTR    ci_RightDotSetCode
        APTR    ci_RightDotClearCode
        APTR    ci_LeftTCCode
        APTR    ci_RightTCCode
        LABEL   ci_SIZEOF

    STRUCTURE   BarData,0
        WORD    bd_Delay
        WORD    bd_EndPosCount
        WORD    bd_BarPos
        UWORD   bd_BarPosFract
        WORD    bd_BarSpeed
        UWORD   bd_BarSpeedFract
        UWORD   bd_LastLastLastBottomPos
        UWORD   bd_LastLastBottomPos
        UWORD   bd_LastBottomPos
        LABEL   bd_SIZEOF

    STRUCTURE   PartBlockInfo,0
        WORD    pbi_Phase
        UWORD   pbi_YPos
        APTR    pbi_OriginalImage
        APTR    pbi_TrueColorImage
        APTR    pbi_LastTrueColorImage
        ULONG   pbi_ScreenOffset
        APTR    pbi_SourceImgPtr
        UWORD   pbi_Copper7Offset
        UWORD   pbi_CopperEdgeOffset
        APTR    pbi_TempBuffer
        APTR    pbi_PalChangeRoutine
        APTR    pbi_PalApplyRoutine
        APTR    pbi_PhaseSequence
        APTR    pbi_SequencePtr
        STRUCT  pbi_CurrentColors,(7+PART_HEIGHT)*2
        STRUCT  pbi_TargetColors,(7+PART_HEIGHT)*2
        LABEL   pbi_SIZEOF

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_LastPlanesPtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        APTR    pd_CurrFixupBQPtr
        UBYTE   pd_DbToggle
        ALIGNWORD

        UWORD   pd_OldFrameCount
        UWORD   pd_FrameInc
        UWORD   pd_TCPicsDone
        UWORD   pd_PartCountDown
        UWORD   pd_SequenceBlocksLeft
        UWORD   pd_BeatRadAdd
        UWORD   pd_GreetingCount

        UWORD   pd_CircleShift
        UWORD   pd_LineFixToggle

        UWORD   pd_CopperChunkyOffset
        UWORD   pd_CurrGreetingsPalOffset

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        APTR    pd_DbBuffer1
        APTR    pd_DbBuffer2
        APTR    pd_ClipDotsBuffer
        APTR    pd_ClipFillBuffer

        APTR    pd_StaticFixupBQ1
        APTR    pd_StaticFixupBQ2
        APTR    pd_OriginalImage1
        APTR    pd_OriginalImage2
        APTR    pd_OriginalImage3
        APTR    pd_OriginalImage4
        APTR    pd_OriginalImage5
        APTR    pd_TrueColorImage1
        APTR    pd_TrueColorImage2
        APTR    pd_TrueColorImage3
        APTR    pd_TrueColorImage4
        APTR    pd_TrueColorImage5
        APTR    pd_CurrGreetingsImage
        APTR    pd_CurrGreetingsTCImage
        APTR    pd_TrueColor16Image
        APTR    pd_TrueColor16Image2
        APTR    pd_EndLogoBuffer
        APTR    pd_EndLogoP5P6Buffer

        APTR    pd_LineFix1Array
        APTR    pd_LineFix2Array
        APTR    pd_LineFix3Array
        APTR    pd_LineFix4Array
        APTR    pd_LineFix5Array
        APTR    pd_LineFix6Array
        APTR    pd_LineFix7Array
        APTR    pd_LineFix8Array

        APTR    pd_GreetingPosPtr
        APTR    pd_GreetingLinePtr

        APTR    pd_ShadeTableXor
        APTR    pd_ShadeTableSub1
        APTR    pd_CircleMasksBuffer
        APTR    pd_CircleSpeedcodeBuffer

        UWORD   pd_AllowLoadLastImage

        STRUCT  pd_PreparationTask,ft_SIZEOF
        STRUCT  pd_SpeedCodeTask,ft_SIZEOF
        STRUCT  pd_Parts,BLOCKS_HEIGHT*pbi_SIZEOF
        STRUCT  pd_Bars,NUM_BARS*bd_SIZEOF

        STRUCT  pd_CirclePots,NUM_CIRCLE_POTS*cp_SIZEOF
        STRUCT  pd_MinMaxY,BLENDVIEW_HEIGHT*4
        STRUCT  pd_CircleInfos,(MAX_CIRCLE_SIZE-MIN_CIRCLE_SIZE+1)*4

        LABEL   pd_EndLogoPalette ; 16*2
        STRUCT  pd_StaticFixup1BQBuffer,256
        STRUCT  pd_StaticFixup2BQBuffer,256
        STRUCT  pd_BQBuffer,1500

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
        move.w  #3888,fw_MusicFrameCount(a6)
        ENDC
        ENDC

        bsr.s   bln_init

        lea     bln_copperlist,a0
        CALLFW  SetCopper

        IF      1
        PUTMSG  10,<"%d: Waiting for first pic (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

.wait
        CALLFW  VSyncWithTask
        cmp.w   #1,pd_TCPicsDone(a6)
        blt.s   .wait

        bsr     bln_intro

        lea     bln_prepare_circle_speedcode(pc),a0
        lea     pd_SpeedCodeTask(a6),a1
        CALLFW  AddTask

        PUTMSG  10,<"%d: Waiting for third pic (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

.wait2
        CALLFW  VSyncWithTask
        cmp.w   #3,pd_TCPicsDone(a6)
        blt.s   .wait2

        bsr     bln_bars
        ELSE
        lea     bln_prepare_circle_speedcode(pc),a0
        lea     pd_SpeedCodeTask(a6),a1
        CALLFW  AddTask

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        moveq.l #14,d0
        CALLFW  MusicSetPosition
        move.w  #5040,fw_MusicFrameCount(a6)
        ENDC
        ENDC
        ENDC

        move.w  #4,pd_AllowLoadLastImage(a6)
        bsr     bln_holes
        bsr     bln_greetings
        bsr     bln_endlogo

        lea     pd_PreparationTask(a6),a1
        CALLFW  RemTask
        lea     pd_SpeedCodeTask(a6),a1
        CALLFW  RemTask

        CALLFW  SetBaseCopper

        rts

;--------------------------------------------------------------------

bln_init:
        move.w  #$000,color(a5)
        bsr     bln_init_vars

        bsr     bln_init_shade_table
        bsr     bln_init_bars

        lea     .backgroundtasks(pc),a0
        lea     pd_PreparationTask(a6),a1
        move.b  #5,LN_PRI(a1)
        CALLFW  AddTask

        rts

.backgroundtasks
        lea     bln_leaves_tc_10,a0
        move.l  pd_TrueColorImage1(a6),a1
        move.w  #(BLENDVIEW_HEIGHT*(BLENDVIEW_WIDTH/32))-1,d7
.xyloop
        move.w  (a0)+,(a1)
        lea     32*2(a1),a1
        dbra    d7,.xyloop

        addq.w  #1,pd_TCPicsDone(a6)

        PUTMSG  10,<"%d: Loading image 2">,fw_FrameCounter(a6)
        IFD     FW_DEMO_PART
        lea     bln_blend_image_2_filename(pc),a0
        CALLFW  FindFile
        move.l  pd_TrueColorImage2(a6),a0
        CALLFW  LoadFileToBuffer
        move.l  pd_TrueColorImage2(a6),a0
        move.l  pd_OriginalImage2(a6),a1
        CALLFW  DecompressZX0
        ENDC

        move.l  pd_OriginalImage2(a6),a0
        move.l  pd_TrueColorImage2(a6),a1
        move.w  #16*2+1*BLENDVIEW_HEIGHT*2,d0
        bsr     bln_calc_true_color_image

        addq.w  #1,pd_TCPicsDone(a6)

        IFD     FW_DEMO_PART
        cmp.w   #3,pd_AllowLoadLastImage(a6)
        bge.s   .skipwait
        CALLFW  TrackloaderDiskMotorOff
        ENDC

        PUTMSG  10,<"%d: Waiting to unlock image 3">,fw_FrameCounter(a6)
.wait
        CALLFW  Yield
        cmp.w   #3,pd_AllowLoadLastImage(a6)
        blt.s   .wait
.skipwait

        PUTMSG  10,<"%d: Loading image 3">,fw_FrameCounter(a6)
        IFD     FW_DEMO_PART
        lea     bln_blend_image_3_filename(pc),a0
        CALLFW  FindFile
        move.l  pd_TrueColorImage3(a6),a0
        CALLFW  LoadFileToBuffer
        move.l  pd_TrueColorImage3(a6),a0
        move.l  pd_OriginalImage3(a6),a1
        CALLFW  DecompressZX0
        ENDC

        move.l  pd_OriginalImage3(a6),a0
        move.l  pd_TrueColorImage3(a6),a1
        move.w  #16*2+2*BLENDVIEW_HEIGHT*2,d0
        bsr     bln_calc_true_color_image
        addq.w  #1,pd_TCPicsDone(a6)

        IFD     FW_DEMO_PART
        cmp.w   #4,pd_AllowLoadLastImage(a6)
        bge.s   .skipwait4
        CALLFW  TrackloaderDiskMotorOff
        ENDC

        PUTMSG  10,<"%d: Waiting to unlock image 4">,fw_FrameCounter(a6)
.wait4
        CALLFW  Yield
        cmp.w   #4,pd_AllowLoadLastImage(a6)
        blt.s   .wait4
.skipwait4

        PUTMSG  10,<"%d: Loading image 4">,fw_FrameCounter(a6)
        IFD     FW_DEMO_PART
        lea     bln_blend_image_4_filename(pc),a0
        CALLFW  FindFile
        move.l  pd_TrueColorImage4(a6),a0
        CALLFW  LoadFileToBuffer
        move.l  pd_TrueColorImage4(a6),a0
        move.l  pd_OriginalImage4(a6),a1
        CALLFW  DecompressZX0
        ENDC

        move.l  pd_OriginalImage4(a6),a0
        move.l  pd_TrueColorImage4(a6),a1
        move.w  #16*2+3*BLENDVIEW_HEIGHT*2,d0
        bsr     bln_calc_true_color_image
        addq.w  #1,pd_TCPicsDone(a6)

        IFD     FW_DEMO_PART
        cmp.w   #5,pd_AllowLoadLastImage(a6)
        bge.s   .skipwait5
        CALLFW  TrackloaderDiskMotorOff
        ENDC

        PUTMSG  10,<"%d: Waiting to unlock image 5">,fw_FrameCounter(a6)
.wait5
        CALLFW  Yield
        cmp.w   #5,pd_AllowLoadLastImage(a6)
        blt.s   .wait5
.skipwait5

        PUTMSG  10,<"%d: Loading image 5">,fw_FrameCounter(a6)
        IFD     FW_DEMO_PART
        lea     bln_blend_image_5_filename(pc),a0
        CALLFW  FindFile
        move.l  pd_TrueColorImage5(a6),a0
        CALLFW  LoadFileToBuffer
        move.l  pd_TrueColorImage5(a6),a0
        move.l  pd_OriginalImage5(a6),a1
        CALLFW  DecompressZX0
        ENDC

        move.l  pd_OriginalImage5(a6),a0
        move.l  pd_TrueColorImage5(a6),a1
        move.w  #16*2+4*BLENDVIEW_HEIGHT*2,d0
        bsr     bln_calc_true_color_image
        addq.w  #1,pd_TCPicsDone(a6)

        IFD     FW_DEMO_PART
        CALLFW  TrackloaderDiskMotorOff
        ENDC

        PUTMSG  10,<"%d: Prep task done!">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

bln_init_vars:
        lea     bln_greets_positions(pc),a0
        move.l  a0,pd_GreetingPosPtr(a6)
        lea     bln_greets_lines(pc),a0
        move.l  a0,pd_GreetingLinePtr(a6)

        IFD     FW_DEMO_PART
        lea     bln_blend_image_1,a0
        move.l  a0,pd_OriginalImage1(a6)
        move.l  a0,pd_OriginalImage3(a6)
        move.l  a0,pd_EndLogoBuffer(a6)

        move.l  #(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT*BLENDVIEW_PLANES,d0
        CALLFW  AllocChip
        move.l  a0,pd_OriginalImage2(a6)
        move.l  a0,pd_OriginalImage5(a6)
        move.l  a0,pd_EndLogoP5P6Buffer(a6)
        ELSE
        move.l  #bln_blend_image_1,pd_OriginalImage1(a6)
        move.l  #bln_blend_image_2,pd_OriginalImage2(a6)
        move.l  #bln_blend_image_3,pd_OriginalImage3(a6)
        move.l  #bln_blend_image_4,pd_OriginalImage4(a6)
        move.l  #bln_blend_image_5,pd_OriginalImage5(a6)
        move.l  #bln_endlogo_image,pd_EndLogoBuffer(a6)
        move.l  #bln_blend_image_1,pd_EndLogoP5P6Buffer(a6)
        ENDC

        move.l  #(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT*BLENDVIEW_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"ClipDotsBuffer %p">,a0
        IFD     FW_DEMO_PART
        move.l  a0,pd_OriginalImage4(a6)
        ENDC
        move.l  a0,pd_ClipDotsBuffer(a6)
        move.l  a0,pd_TrueColor16Image(a6)
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a0),a0
        PUTMSG  10,<"ClipFillBuffer %p">,a0
        move.l  a0,pd_ClipFillBuffer(a6)
        move.l  a0,pd_TrueColor16Image2(a6)

        move.l  #(COP_LIST_SIZE*2),d0
        CALLFW  AllocChip
        PUTMSG  10,<"Copperlist 1 %p">,a0
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)
        lea     COP_LIST_SIZE(a0),a0
        PUTMSG  10,<"Copperlist 2 %p">,a0
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        move.l  #2*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT*BLENDVIEW_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"DbBuffer %p">,a0
        move.l  a0,pd_DbBuffer1(a6)
        move.l  a0,pd_CurrPlanesPtr(a6)
        add.l   #(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT*BLENDVIEW_PLANES,a0
        move.l  a0,pd_DbBuffer2(a6)
        move.l  a0,pd_LastPlanesPtr(a6)

        ;move.l  #(PART_WIDTH/8)*PART_HEIGHT*(5)*BLOCKS_HEIGHT,d0
        move.l  #BLENDVIEW_HEIGHT*4*8,d0
        CALLFW  AllocChip
        PUTMSG  10,<"BlockTempBuffer %p">,a0
        lea     pd_LineFix1Array(a6),a2
        move.l  a0,(a2)+
        lea     BLENDVIEW_HEIGHT*4(a0),a1
        move.l  a1,(a2)+
        REPT    6
        lea     BLENDVIEW_HEIGHT*4(a1),a1
        move.l  a1,(a2)+
        ENDR

        move.w  #(PART_WIDTH/8)*PART_HEIGHT*5,d0
        lea     pd_Parts(a6),a1
        moveq.l #BLOCKS_HEIGHT-1,d7
        moveq.l #0,d1
.partloop
        move.w  #$8000,pbi_Phase(a1)
        move.w  d1,pbi_YPos(a1)
        move.l  a0,pbi_TempBuffer(a1)
        addq.w  #1,d1
        adda.w  d0,a0
        lea     pbi_SIZEOF(a1),a1
        dbra    d7,.partloop

        move.l  #BLENDIMG_WIDTH*BLENDIMG_HEIGHT*2,d0
        CALLFW  AllocFast
        PUTMSG  10,<"TrueColorImage 1/3 %p">,a0
        move.l  a0,pd_TrueColorImage1(a6)
        move.l  a0,pd_TrueColorImage3(a6)

        move.l  #BLENDIMG_WIDTH*BLENDIMG_HEIGHT*2,d0
        CALLFW  AllocFast
        PUTMSG  10,<"TrueColorImage 2/5 %p">,a0
        move.l  a0,pd_TrueColorImage2(a6)
        move.l  a0,pd_TrueColorImage5(a6)

        move.l  #BLENDIMG_WIDTH*BLENDIMG_HEIGHT*2,d0
        CALLFW  AllocFast
        PUTMSG  10,<"TrueColorImage 4 %p">,a0
        move.l  a0,pd_TrueColorImage4(a6)
        move.l  a0,pd_ShadeTableXor(a6)
        PUTMSG  10,<"ShadeTableXor %p">,a0
        lea     4096*2(a0),a0
        move.l  a0,pd_ShadeTableSub1(a6)
        PUTMSG  10,<"ShadeTableSub1 %p">,a0

        move.l  #CIRCLE_MASKS_SIZE,d0
        CALLFW  AllocChip
        PUTMSG  10,<"CircleMasksBuffer %p">,a0
        move.l  a0,pd_CircleMasksBuffer(a6)

        move.l  #CIRCLE_SPEEDCODE_SIZE,d0
        CALLFW  AllocFast
        PUTMSG  10,<"CircleSpeedcodeBuffer %p">,a0
        move.l  a0,pd_CircleSpeedcodeBuffer(a6)

        lea     pd_CirclePots(a6),a4
        lea     bln_circle_scripts(pc),a0
.scriptloop
        move.w  (a0)+,d0
        beq.s   .donescripts
        lea     -2(a0,d0.w),a1
        move.l  a1,cp_PotScriptPtr(a4)
        lea     cp_SIZEOF(a4),a4
        bra.s   .scriptloop
.donescripts

        rts

;--------------------------------------------------------------------

bln_init_shade_table:
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

        move.l  pd_ShadeTableXor(a6),a0
        move.l  pd_ShadeTableSub1(a6),a1
        moveq.l #0,d0
        move.w  #4096-1,d7
.sub1loop
        move.w  d0,d1
        sub.w   (a0)+,d1
        move.w  d1,(a1)+
        addq.w  #1,d0
        dbra    d7,.sub1loop

        rts

;--------------------------------------------------------------------

bln_init_bars:
        lea     pd_Bars(a6),a1
        lea     bln_bar_patterns(pc),a0
        moveq.l #0,d0
        move.w  #-BLENDVIEW_HEIGHT,d1
        moveq.l #(NUM_BARS/2)-1,d7
.loop1
        move.b  (a0)+,d2
        ext.w   d2
        mulu    #bd_SIZEOF,d2
        move.w  d0,bd_Delay(a1,d2.w)
        move.w  d1,bd_BarPos(a1,d2.w)
        move.w  #1,bd_BarSpeed(a1,d2.w)
        move.w  #5,bd_EndPosCount(a1,d2.w)
        add.w   #10,d0
        subq.w  #8,d1
        dbra    d7,.loop1

        moveq.l #(NUM_BARS/2)-1,d7
.loop2
        move.b  (a0)+,d2
        ext.w   d2
        mulu    #bd_SIZEOF,d2
        move.w  d0,bd_Delay(a1,d2.w)
        move.w  d1,bd_BarPos(a1,d2.w)
        move.w  #1,bd_BarSpeed(a1,d2.w)
        move.w  #5,bd_EndPosCount(a1,d2.w)
        add.w   #19,d0
        addq.w  #2,d1
        dbra    d7,.loop2
        rts

;--------------------------------------------------------------------

bln_clear_db_buffers:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_DbBuffer1(a6),bltdpt(a5)
        move.w  #((3*BLENDVIEW_WIDTH)>>4)|((BLENDVIEW_HEIGHT*4)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

bln_copy_image_to_buffer:
        BLTHOGON
        BLTWAIT
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #0,d0
        move.w  d0,bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  pd_CurrPlanesPtr(a6),bltdpt(a5)
        move.w  #((3*BLENDVIEW_WIDTH)>>4)|((BLENDVIEW_HEIGHT*2)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

bln_clear_clip_buffers:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_ClipDotsBuffer(a6),bltdpt(a5)
        move.w  #((BLENDVIEW_WIDTH)>>4)|((BLENDVIEW_HEIGHT*2)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

bln_intro:
        PUTMSG  10,<"%d: Intro (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        CALLFW  SetBlitterQueueSingleFrame

        bsr     bln_clear_db_buffers
        bsr     bln_flip_db_frame
        bsr     bln_create_intro_copperlist
        bsr     bln_flip_db_frame
        bsr     bln_create_intro_copperlist
        bsr     bln_update_copper_list_pointers

        lea     bln_a_part_sequence(pc),a0
        bsr     bln_load_part_sequences

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

.loop   CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame

        CALLFW  CheckMusicScript

        lea     pd_BQBuffer(a6),a4

        bsr     bln_handle_parts
        move.w  d7,pd_SequenceBlocksLeft(a6)
        bne.s   .noallownext
        PUTMSG  30,<"%d: Sequence done! (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #3,pd_AllowLoadLastImage(a6)
.noallownext

        TERMINATE_BLITTER_QUEUE
        ;lea     pd_BQBuffer(a6),a0
        ;sub.l   a0,a4
        ;PUTMSG  10,<"Queue size %ld">,a4

        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        cmp.l   a0,a4
        beq.s   .skiptrigger
        CALLFW  TriggerCustomBlitterQueue
.skiptrigger

        CALLFW  JoinBlitterQueue

        bsr     bln_update_copper_list_pointers

        cmp.w   #4656,fw_MusicFrameCount(a6)
        blt     .loop

        tst.w   pd_SequenceBlocksLeft(a6)
        bne.s   .loop

        rts

.script
        dc.w    4272,.load_seq_b-*
        dc.w    0

.load_seq_b
        cmp.w   #2,pd_TCPicsDone(a6)
        bge.s   .nowait

        PUTMSG  10,<"%d: Waiting for 2nd pic (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
.wait
        CALLFW  VSyncWithTask
        cmp.w   #2,pd_TCPicsDone(a6)
        blt.s   .wait

.nowait
        PUTMSG  10,<"%d: Intro B sequence (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        lea     bln_b_part_sequence(pc),a0
        bsr     bln_load_part_sequences
        rts

;--------------------------------------------------------------------

bln_bars:
        PUTMSG  10,<"%d: Bars (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        CALLFW  SetBlitterQueueSingleFrame

        move.l  pd_TrueColorImage3(a6),a0
        move.l  pd_TrueColor16Image(a6),a1
        bsr     bln_prepare_tc16_data

        move.l  pd_TrueColorImage2(a6),a0
        move.l  pd_TrueColor16Image2(a6),a1
        bsr     bln_prepare_tc16_data

        REPT    2
        CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame
        bsr     bln_create_bars_copperlist
        move.l  pd_OriginalImage2(a6),a0
        move.l  pd_TrueColor16Image2(a6),a1
        bsr     bln_prepare_striped_image
        bsr     bln_update_copper_list_pointers
        ENDR

.loop   CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame

        bsr     bln_draw_and_move_bars

        bsr     bln_update_copper_list_pointers

        cmp.w   #5040+30*6,fw_MusicFrameCount(a6)
        blt     .loop

        rts

;--------------------------------------------------------------------

bln_holes:
        PUTMSG  10,<"%d: Holes (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        CALLFW  SetBlitterQueueSingleFrame

        move.l  pd_OriginalImage4(a6),pd_CurrGreetingsImage(a6)
        move.l  pd_TrueColorImage4(a6),pd_CurrGreetingsTCImage(a6)
        move.w  #18+17,pd_GreetingCount(a6)
        bsr     bln_prepare_circle_masks

        lea     pd_SpeedCodeTask(a6),a1
        CALLFW  WaitUntilTaskFinished

        REPT    2
        CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame
        bsr     bln_create_hole_copperlist
        move.l  pd_OriginalImage3(a6),a0
        bsr     bln_copy_image_to_buffer

        move.l  pd_CurrFixupBQPtr(a6),a4
        bsr     bln_do_blitter_to_copper_fixup
        bsr     bln_update_copper_list_pointers
        ENDR

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

.wait
        CALLFW  VSyncWithTask
        cmp.w   #5040+32*6,fw_MusicFrameCount(a6)
        blt.s   .wait

        PUTMSG  10,<"%d: Starting holes (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        BLTWAIT

        move.w  fw_FrameCounter(a6),pd_OldFrameCount(a6)
.loop   CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  pd_CurrFixupBQPtr(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        CALLFW  CheckMusicScript

        move.w  fw_FrameCounter(a6),d0
        move.w  d0,d1
        sub.w   pd_OldFrameCount(a6),d1
        move.w  d0,pd_OldFrameCount(a6)
        move.w  d1,pd_FrameInc(a6)
        PUTMSG  20,<"%d: Inc %d">,d0,d1

        bsr     bln_do_all_circle_calc_updates

        CALLFW  JoinBlitterQueue

        bsr     bln_restore_necessary_circle_backgrounds

        bsr     bln_draw_all_circle_pots

        BLTHOGON
        BLTWAIT
        BLTHOGOFF

        bsr     bln_do_all_circle_ham_fixups

        bsr     bln_update_copper_list_pointers_safe

        tst.w   pd_GreetingCount(a6)
        bne.s   .loop

        move.w  #$00d0,bln_ddfstop+2
        move.w  #$0000,bln_fmode+2

        rts

.script
        dc.w    4,.agaboost-*
        dc.w    5808+48*6,.flash-*
        dc.w    5808+52*6,.flash-*
        dc.w    5808+56*6,.flash-*
        dc.w    5808+60*6,.flash-*
        dc.w    6192,.loadgreetings-*
        dc.w    0

.agaboost
        tst.w   fw_AgaChipset(a6)
        beq.s   .noaga
        move.w  #$00a0,bln_ddfstop+2
        move.w  #$0003,bln_fmode+2
.noaga

.flash
        move.w  #32,pd_BeatRadAdd(a6)
        rts

.loadgreetings
        PUTMSG  10,<"%d: Allow Loading of Image 5 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #5,pd_AllowLoadLastImage(a6)
        lea     pd_CirclePots(a6),a4
        lea     bln_circle_greetings_scripts(pc),a0
        moveq.l #0,d1
.scriptloop
        move.w  (a0)+,d0
        beq.s   .donescripts
        lea     -2(a0,d0.w),a1
        move.l  a1,cp_PotScriptPtr(a4)
        move.w  d1,cp_TimeLeft(a4)
        lea     cp_SIZEOF(a4),a4
        bra.s   .scriptloop
.donescripts
        rts

;--------------------------------------------------------------------

bln_greetings:
        PUTMSG  10,<"%d: Greetings (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        IFD    FW_DEMO_PART
        lea     .loader(pc),a0
        lea     pd_PreparationTask(a6),a1
        CALLFW  AddTask
        ENDC
        move.l  pd_CurrPlanesPtr(a6),pd_CurrGreetingsImage(a6)
        move.w  #7*2+2*BLENDVIEW_HEIGHT*2,pd_CurrGreetingsPalOffset(a6)

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

.loop   CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame

        CALLFW  CheckMusicScript

        bsr     bln_create_greetings_copperlist
        bsr     bln_update_copper_list_pointers

        cmp.w   #7344+60*6,fw_MusicFrameCount(a6)
        blt.s   .loop

        CALLFW  VSyncWithTask
        bsr     bln_create_andyou_copperlist
        bsr     bln_update_copper_list_pointers

        rts

        IFD     FW_DEMO_PART
.loader
        lea     .endlogofile(pc),a0
        CALLFW  FindFile
        move.l  pd_TrueColorImage2(a6),a0
        CALLFW  LoadFileToBuffer
        move.l  pd_TrueColorImage2(a6),a0
        move.l  pd_EndLogoBuffer(a6),a1
        CALLFW  DecompressZX0
        PUTMSG  10,<"%d: Endlogo loaded/decompressed (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        rts

.endlogofile
        dc.b    "Endlogo.raw",0
        even
        ENDC

.script
        dc.w    7344+48*6,.load_page_1-*
        dc.w    7344+51*6,.load_page_2-*
        dc.w    7344+54*6,.load_page_1-*
        dc.w    7344+56*6,.load_page_2-*
        dc.w    7728+8*6,.stopmusic-*
        dc.w    0

.load_page_1
        move.l  pd_OriginalImage4(a6),pd_CurrGreetingsImage(a6)
        move.w  #7*2+3*BLENDVIEW_HEIGHT*2,pd_CurrGreetingsPalOffset(a6)
        rts

.load_page_2
        move.l  pd_OriginalImage5(a6),pd_CurrGreetingsImage(a6)
        move.w  #7*2+4*BLENDVIEW_HEIGHT*2,pd_CurrGreetingsPalOffset(a6)
        rts

.stopmusic
        CALLFW  StopMusic
        rts

;--------------------------------------------------------------------

bln_endlogo:
        IFD     FW_DEMO_PART
        lea     pd_PreparationTask(a6),a1
        CALLFW  WaitUntilTaskFinished
        ENDC

        bsr     bln_prep_p5p6_mask
        bsr     bln_prep_endlogo_start

        lea     pd_EndLogoPalette(a6),a1
        move.w  #$fff,d0
        moveq.l #16-1,d7
.palloop
        move.w  d0,(a1)+
        dbra    d7,.palloop

        bsr     bln_init_shade_table

.loop2  CALLFW  VSyncWithTask

        CALLFW  CheckMusicScript

        cmp.w   #7728,fw_MusicFrameCount(a6)
        blt.s   .loop2

        bsr     bln_create_endlogo_copperlist
        bsr     bln_update_copper_list_pointers

        move.w  fw_FrameCounter(a6),d0
        add.w   #200,d0
        move.w  d0,pd_PartCountDown(a6)

.loop3  CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame

        CALLFW  CheckMusicScript

        bsr     bln_fade_step_from_white
        bsr     bln_palette_fade_step_from_white

        bsr     bln_create_endlogo_copperlist
        bsr     bln_update_copper_list_pointers

        move.w  fw_FrameCounter(a6),d0
        cmp.w   pd_PartCountDown(a6),d0
        blt.s   .loop3

        move.w  #17,pd_PartCountDown(a6)

.loop4  CALLFW  VSyncWithTask
        bsr     bln_flip_db_frame

        CALLFW  CheckMusicScript

        bsr     bln_fade_step_to_black
        bsr     bln_palette_fade_step_to_black

        bsr     bln_create_endlogo_copperlist
        bsr     bln_update_copper_list_pointers

        subq.w  #1,pd_PartCountDown(a6)
        bne.s   .loop4

        rts

;--------------------------------------------------------------------

bln_flip_db_frame:
        move.l  pd_CurrPlanesPtr(a6),pd_LastPlanesPtr(a6)
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        eor.w   #BLENDVIEW_HEIGHT*2,pd_LineFixToggle(a6)
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        move.l  pd_DbBuffer2(a6),pd_CurrPlanesPtr(a6)
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        lea     pd_StaticFixup2BQBuffer(a6),a0
        move.l  a0,pd_CurrFixupBQPtr(a6)
        rts
.selb1
        move.l  pd_DbBuffer1(a6),pd_CurrPlanesPtr(a6)
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        lea     pd_StaticFixup1BQBuffer(a6),a0
        move.l  a0,pd_CurrFixupBQPtr(a6)
        rts

;--------------------------------------------------------------------

bln_update_copper_list_pointers_safe:
.wait
        move.l  vposr(a5),d0
        and.l   #$1ff00,d0
        cmp.l   #(10)<<8,d0
        blt.s   .wait
bln_update_copper_list_pointers:
        lea     bln_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

bln_prepare_circle_speedcode:
        PUTMSG  10,<"%d: Preparing circle smc">,fw_FrameCounterLong(a6)
        lea     bln_circleinfo,a4
        move.l  pd_CircleSpeedcodeBuffer(a6),a2
        move.l  a2,a3
        add.l   #CIRCLE_SPEEDCODE_SIZE/2,a3
        moveq.l #3,d7
.rloop
        tst.w   (a4)
        beq.s   .done

        PUSHM   a1-a4
        move.w  d7,d0
        lea     pd_MinMaxY(a6),a0
        PUTMSG  40,<"MinMax %p">,a0
        bsr     bln_calc_circle
        POPM

        move.w  d7,d3
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d3
        neg.w   d3
        sub.w   #(BLENDVIEW_WIDTH/2)/8,d3

        move.w  d7,d0
        add.w   d0,d0
        add.w   d0,d0
        lea     pd_MinMaxY(a6),a0
        lea     (BLENDVIEW_HEIGHT/2)*4(a0),a0
        suba.w  d0,a0

        move.w  #%0000000110101000,d5   ; bclr dx,$yyyy(a0)
        ;move.w  #%0000000101101000,d5   ; bchg dx,$yyyy(a0)
        move.l  a2,ci_LeftDotClearCode(a4)
        move.l  a3,ci_RightDotClearCode(a4)
        PUTMSG  40,<"Bclr %p %p">,a2,a3
        bsr     bln_create_bset_bclr_code

        move.w  #%0000000111101000,d5   ; bset dx,$yyyy(a0)
        ;move.w  #%0000000101101000,d5   ; bchg dx,$yyyy(a0)
        move.l  a2,ci_LeftDotSetCode(a4)
        move.l  a3,ci_RightDotSetCode(a4)
        PUTMSG  40,<"Bset %p %p">,a2,a3
        bsr     bln_create_bset_bclr_code

        move.l  a2,ci_LeftTCCode(a4)
        move.l  a3,ci_RightTCCode(a4)
        PUTMSG  40,<"move.w %p %p">,a2,a3
        bsr     bln_create_tc_code

        lea     ci_SIZEOF(a4),a4
        addq.w  #1,d7
        bra.s   .rloop
.done
        suba.l  pd_CircleSpeedcodeBuffer(a6),a2
        add.l   a2,a2
        PUTMSG  10,<"%d: Done %ld bytes">,fw_FrameCounterLong(a6),a2
        CALLFW  FlushCaches
        rts

;--------------------------------------------------------------------

bln_create_tc_code:
        PUSHM   d3/d7
        move.w  d7,d3
        move.l  #BLENDVIEW_WIDTH*2,d6
        mulu    d6,d3
        neg.l   d3
        sub.l   #(BLENDVIEW_WIDTH/2)*2,d3
        move.w  #%0011000011101010,d5   ; move.w x(a2),(a0)+
        add.w   d7,d7
.scloop
        move.w  (a0)+,d0
        add.w   d0,d0
        add.w   d3,d0
        move.w  d5,(a2)+
        move.w  d0,(a2)+

        move.w  (a0)+,d0
        ;addq.w  #1,d0
        add.w   d0,d0
        add.w   d3,d0
        move.w  d5,(a3)+
        move.w  d0,(a3)+

        add.w   d6,d3
        dbra    d7,.scloop
        move.w  #'Nu',(a2)+
        move.w  #'Nu',(a3)+

        POPM
        rts

;--------------------------------------------------------------------

bln_create_bset_bclr_code:
        PUSHM   a0/d3/d7
        move.w  #7<<9,d2
        move.w  #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d6
        add.w   d7,d7
.scloop
        move.w  (a0)+,d0
        move.w  d0,d1
        asr.w   #3,d1
        add.w   d3,d1
        add.w   d0,d0
        move.b  d0,-(sp)
        move.w  (sp)+,d0
        and.w   d2,d0
        or.w    d5,d0
        move.w  d0,(a2)+
        move.w  d1,(a2)+

        move.w  (a0)+,d0
        ;addq.w  #1,d0
        move.w  d0,d1
        asr.w   #3,d1
        add.w   d3,d1
        add.w   d0,d0
        move.b  d0,-(sp)
        move.w  (sp)+,d0
        and.w   d2,d0
        or.w    d5,d0
        move.w  d0,(a3)+
        move.w  d1,(a3)+

        add.w   d6,d3
        dbra    d7,.scloop
        move.w  #'Nu',(a2)+
        move.w  #'Nu',(a3)+

        POPM
        rts

;--------------------------------------------------------------------

bln_draw_circle_color_1_2:
        move.l  ci_LeftDotClearCode(a1),a2
        move.l  ci_LeftDotSetCode(a1),a3
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        move.l  ci_RightDotClearCode(a1),a2
        move.l  ci_RightDotSetCode(a1),a3
        lea     -5*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jmp     (a2)

;--------------------------------------------------------------------

bln_draw_circle_color_3_4:
        move.l  ci_LeftDotClearCode(a1),a2
        move.l  ci_LeftDotSetCode(a1),a3
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        move.l  ci_RightDotClearCode(a1),a2
        move.l  ci_RightDotSetCode(a1),a3
        lea     -5*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jmp     (a2)

;--------------------------------------------------------------------

bln_draw_circle_color_5_6:
        move.l  ci_LeftDotClearCode(a1),a2
        move.l  ci_LeftDotSetCode(a1),a3
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        move.l  ci_RightDotClearCode(a1),a2
        move.l  ci_RightDotSetCode(a1),a3
        lea     -5*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jmp     (a2)

;--------------------------------------------------------------------

bln_draw_circle_color_7_8:
        move.l  ci_LeftDotClearCode(a1),a2
        move.l  ci_LeftDotSetCode(a1),a3
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        move.l  ci_RightDotClearCode(a1),a2
        move.l  ci_RightDotSetCode(a1),a3
        lea     -5*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a3)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jsr     (a2)
        lea     1*(BLENDVIEW_WIDTH/8)(a0),a0
        jmp     (a2)


;--------------------------------------------------------------------

bln_prep_p5p6_mask:
        move.l  pd_EndLogoBuffer(a6),a0
        lea     4*(BLENDIMG_WIDTH/8)(a0),a0
        lea     1*(BLENDIMG_WIDTH/8)(a0),a1
        move.l  pd_EndLogoP5P6Buffer(a6),a2
        moveq.l #-1,d0
        move.l  #(((BLENDIMG_WIDTH*BLENDVIEW_PLANES-BLENDIMG_WIDTH)/8)<<16)|((BLENDIMG_WIDTH*BLENDVIEW_PLANES-BLENDIMG_WIDTH)/8),d1
        move.w  #(BLENDIMG_WIDTH>>4)|(BLENDIMG_HEIGHT<<6),d3

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET ACD,BLT_A|BLT_C,0,0
        move.l  d0,bltafwm(a5)
        move.w  d1,bltcmod(a5)
        move.l  d1,bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltcpt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        rts

;--------------------------------------------------------------------

bln_prep_endlogo_start:
        move.l  pd_EndLogoBuffer(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_EndLogoP5P6Buffer(a6),a2
        moveq.l #-1,d0
        move.l  #(((BLENDIMG_WIDTH*BLENDVIEW_PLANES-BLENDIMG_WIDTH)/8)<<16)|((BLENDIMG_WIDTH*BLENDVIEW_PLANES-BLENDIMG_WIDTH)/8),d1
        move.w  #(BLENDIMG_WIDTH>>4)|(BLENDIMG_HEIGHT<<6),d3

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET ACD,BLT_A|BLT_C,0,0
        move.l  d0,bltafwm(a5)
        move.w  d1,bltcmod(a5)
        move.l  d1,bltamod(a5)
        move.l  a2,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    4
        lea     1*(BLENDIMG_WIDTH/8)(a0),a0
        lea     1*(BLENDIMG_WIDTH/8)(a1),a1
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a2,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        rts

;--------------------------------------------------------------------

bln_fade_step_to_black:
        move.l  pd_LastPlanesPtr(a6),a0       ; source p1
        move.l  pd_CurrPlanesPtr(a6),a4
        lea     3*(BLENDIMG_WIDTH/8)(a4),a1     ; mask
        move.l  a1,d4
        lea     1*(BLENDIMG_WIDTH/8)(a0),a1     ; source p2
        lea     1*(BLENDIMG_WIDTH/8)(a1),a2     ; source p3
        lea     1*(BLENDIMG_WIDTH/8)(a2),a3     ; source p4

        moveq.l #-1,d0
        move.l  #(((BLENDIMG_WIDTH*BLENDIMG_PLANES-BLENDIMG_WIDTH)/8)<<16)|((BLENDIMG_WIDTH*BLENDIMG_PLANES-BLENDIMG_WIDTH)/8),d1
        move.w  #(BLENDIMG_WIDTH>>4)|(BLENDIMG_HEIGHT<<6),d3

        ; create mask -- all bits, that are not black
        BLTHOGON
        BLTWAIT
        BLTCON_SET ABCD,(BLT_A|BLT_B|BLT_C),0,0
        move.l  d0,bltafwm(a5)
        move.l  d1,bltcmod(a5)
        move.l  d1,bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltbpt(a5)
        move.l  a2,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        BLTWAIT
        BLTCON0_SET ABCD,(BLT_A|BLT_C)&BLT_B,0
        move.l  d4,bltapt(a5)
        move.l  pd_EndLogoP5P6Buffer(a6),bltbpt(a5)
        move.l  a3,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)
        bra     bln_fade_step_down

;--------------------------------------------------------------------

bln_fade_step_from_white:
        move.l  pd_LastPlanesPtr(a6),a0       ; source p1
        move.l  pd_EndLogoBuffer(a6),a1
        move.l  pd_CurrPlanesPtr(a6),a4
        lea     3*(BLENDIMG_WIDTH/8)(a4),a2     ; mask
        move.l  a2,d4                           ; target p4 as temp mask

        moveq.l #-1,d0
        move.l  #(((BLENDIMG_WIDTH*BLENDIMG_PLANES-BLENDIMG_WIDTH)/8)<<16)|((BLENDIMG_WIDTH*BLENDIMG_PLANES-BLENDIMG_WIDTH)/8),d1
        move.w  #(BLENDIMG_WIDTH>>4)|(BLENDIMG_HEIGHT<<6),d3

        ; create mask -- all bits, that are NOT equal
        BLTHOGON
        BLTWAIT
        BLTCON_SET ACD,(BLT_A^BLT_C),0,0
        move.l  d0,bltafwm(a5)
        move.l  d1,bltcmod(a5)
        move.l  d1,bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    3
        lea     (BLENDIMG_WIDTH/8)(a0),a0       ; source p2/p3/p4
        lea     (BLENDIMG_WIDTH/8)(a1),a1       ; original p2/p3/p4

        BLTWAIT
        BLTCON0_SET ABCD,(BLT_A^BLT_C)|BLT_B,0
        move.l  a0,bltapt(a5)
        move.l  d4,bltbpt(a5)
        move.l  a1,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR
        ;bra     bln_fade_step_down

;--------------------------------------------------------------------

bln_fade_step_down:
        move.l  pd_LastPlanesPtr(a6),a0       ; source p1
        move.l  pd_CurrPlanesPtr(a6),a4
        lea     (BLENDIMG_WIDTH/8)(a0),a1              ; source p2
        lea     (BLENDIMG_WIDTH/8)(a1),a2              ; source p3
        lea     (BLENDIMG_WIDTH/8)(a2),a3              ; source p4

        ; plane 1: p1n = p1o ^ mask
        BLTWAIT
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; update mask: mask = p1n & mask
        BLTWAIT
        BLTCON0_SET ACD,BLT_A&BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a4,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 2: p2n = p2o ^ mask
        lea     (BLENDIMG_WIDTH/8)(a4),a4
        BLTWAIT
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a1,bltcpt(a5)
        move.l  a4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; update mask: mask = p2n & mask
        BLTWAIT
        BLTCON0_SET ACD,BLT_A&BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a4,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 3: p3n = p3o ^ mask
        lea     (BLENDIMG_WIDTH/8)(a4),a4
        BLTWAIT
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a2,bltcpt(a5)
        move.l  a4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 4: p4n = p4o ^ (p3n & mask)
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,BLT_C^(BLT_A&BLT_B),0
        move.l  d4,bltapt(a5)
        move.l  a4,bltbpt(a5)
        move.l  a3,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        rts

;--------------------------------------------------------------------

bln_prepare_circle_masks:
        PUTMSG  10,<"%d: Preparing circle masks">,fw_FrameCounterLong(a6)
        bsr     bln_clear_clip_buffers
        BLTWAIT

        lea     bln_circleinfo,a4
        lea     pd_CircleInfos(a6),a2
        move.l  pd_CircleMasksBuffer(a6),a3
        moveq.l #3,d7
.rloop
        tst.w   (a4)
        beq.s   .done

        move.l  a4,(a2)+

        PUSHM   a2-a4/d7
        move.w  d7,d0
        lea     pd_MinMaxY(a6),a0
        bsr     bln_calc_circle
        POPM

        lea     pd_MinMaxY(a6),a0
        move.l  pd_ClipDotsBuffer(a6),a1
        move.w  d7,d0
        bsr     bln_plot_circle

        move.w  d7,d0
        bsr     bln_fill_circle

        ; inner top position
        move.w  ci_LRIAreaY(a4),d0
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d0
        move.l  d0,d2
        move.w  d0,ci_LeftBgOffset(a4)
        move.w  d0,ci_RightBgOffset(a4)

        ; bg offset, relative to top/left
        add.w   ci_InnerXOffset(a4),d0
        move.w  d0,ci_InnerBgOffset(a4)

        ; fg offset, relative to center (usually a negative offset)
        moveq.l #(BLENDVIEW_HEIGHT/2),d0
        sub.w   ci_LRIAreaY(a4),d0
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d0
        neg.w   d0
        move.w  d0,ci_LeftFgOffset(a4)  ; fix x offset later
        move.w  d0,ci_RightFgOffset(a4)

        moveq.l #(BLENDVIEW_WIDTH/2)/8,d1
        sub.w   ci_InnerXOffset(a4),d1
        sub.w   d1,d0
        move.w  d0,ci_InnerFgOffset(a4)

        tst.w   ci_TopWidth(a4)
        beq.s   .skiptop

        bsr     bln_store_circle_top_mask
.skiptop

        tst.w   ci_LeftWidth(a4)
        beq.s   .skipleft

        bsr     bln_store_circle_left_mask
.skipleft

        tst.w   ci_RightWidth(a4)
        beq.s   .skipright

        bsr     bln_store_circle_right_mask
.skipright

        lea     pd_MinMaxY(a6),a0
        move.l  pd_ClipDotsBuffer(a6),a1
        move.w  d7,d0
        bsr     bln_plot_circle

        lea     ci_SIZEOF(a4),a4
        addq.w  #1,d7
        bra.s   .rloop

.done   suba.l  pd_CircleMasksBuffer(a6),a3
        PUTMSG  10,<"%d: Done %ld bytes">,fw_FrameCounterLong(a6),a3
        rts

;--------------------------------------------------------------------

bln_store_circle_left_mask:
        move.w  ci_LeftXOffset(a4),d0
        add.w   d0,ci_LeftBgOffset(a4)
        moveq.l #(BLENDVIEW_WIDTH/2)/8,d1
        sub.w   d0,d1
        sub.w   d1,ci_LeftFgOffset(a4)

        move.l  pd_ClipFillBuffer(a6),a1
        adda.w  d0,a1
        move.w  ci_LRIAreaY(a4),d0
        moveq.l #(BLENDVIEW_HEIGHT/2),d3
        sub.w   d0,d3           ; height
        add.w   d3,d3
        add.w   #1,d3
        mulu    #BLENDVIEW_WIDTH/8,d0
        adda.w  d0,a1

        move.w  ci_LeftWidth(a4),d0
        move.w  d0,d2
        mulu    d3,d2
        add.w   d2,d2           ; size in bytes

        moveq.l #BLENDVIEW_WIDTH/16,d4
        sub.w   d0,d4
        add.w   d4,d4           ; source modulo
        swap    d4

        lsl.w   #6,d3
        add.w   d0,d3

        move.l  a3,ci_LeftMask(a4)
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        move.l  d4,bltamod(a5)
        move.l  a1,bltapt(a5)
        move.l  a3,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.w  d3,ci_LeftBltSize(a4)

        adda.w  d2,a3
        rts

;--------------------------------------------------------------------

bln_store_circle_right_mask:
        move.w  ci_RightXOffset(a4),d0
        add.w   d0,ci_RightBgOffset(a4)
        moveq.l #(BLENDVIEW_WIDTH/2)/8,d1
        sub.w   d0,d1
        sub.w   d1,ci_RightFgOffset(a4)

        move.l  pd_ClipFillBuffer(a6),a1
        adda.w  d0,a1
        move.w  ci_LRIAreaY(a4),d0
        moveq.l #(BLENDVIEW_HEIGHT/2),d3
        sub.w   d0,d3           ; height
        add.w   d3,d3
        add.w   #1,d3
        mulu    #BLENDVIEW_WIDTH/8,d0
        adda.w  d0,a1

        move.w  ci_RightWidth(a4),d0
        move.w  d0,d2
        mulu    d3,d2
        add.w   d2,d2           ; size in bytes

        moveq.l #BLENDVIEW_WIDTH/16,d4
        sub.w   d0,d4
        add.w   d4,d4           ; source modulo
        swap    d4

        lsl.w   #6,d3
        add.w   d0,d3

        move.l  a3,ci_RightMask(a4)
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        move.l  d4,bltamod(a5)
        move.l  a1,bltapt(a5)
        move.l  a3,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.w  d3,ci_RightBltSize(a4)

        adda.w  d2,a3
        rts

;--------------------------------------------------------------------

bln_store_circle_top_mask:
        moveq.l #(BLENDVIEW_HEIGHT/2),d0
        sub.w   d7,d0
        move.w  d0,d1
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d1
        move.w  d1,d4
        move.w  ci_TopXOffset(a4),d2
        add.w   d2,d1
        move.w  d1,ci_TopBgOffset(a4)

        moveq.l #(BLENDVIEW_HEIGHT/2)+1,d3
        add.w   d7,d3
        sub.w   ci_TopHeight(a4),d3
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d3
        sub.w   #5*(BLENDVIEW_WIDTH/8),d3
        sub.w   d4,d3
        move.w  d3,ci_TopBottomOffsetAdv(a4)

        move.w  d7,d1
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d1
        neg.w   d1

        moveq.l #(BLENDVIEW_WIDTH/2)/8,d3
        sub.w   d2,d3
        sub.w   d3,d1
        move.w  d1,ci_TopFgOffset(a4)

        move.l  pd_ClipFillBuffer(a6),a1
        adda.w  d2,a1

        mulu    #BLENDVIEW_WIDTH/8,d0
        adda.l  d0,a1

        move.w  ci_TopWidth(a4),d0
        move.w  d0,d1
        mulu    ci_TopHeight(a4),d1
        add.w   d1,d1
        move.w  d1,ci_TopBottomMaskSize(a4)

        moveq.l #BLENDVIEW_WIDTH/16,d4
        sub.w   d0,d4
        add.w   d4,d4           ; source modulo
        swap    d4

        move.w  ci_TopHeight(a4),d3
        lsl.w   #6,d3
        add.w   d0,d3
        move.w  d3,ci_TopBottomBltSize(a4)

        move.l  a3,ci_TopMask(a4)
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        move.l  d4,bltamod(a5)
        move.l  a1,bltapt(a5)
        move.l  a3,bltdpt(a5)
        move.w  d3,bltsize(a5)

        adda.w  d1,a3
        rts

;--------------------------------------------------------------------

bln_fill_circle:
        move.w  d0,d3
        move.l  pd_ClipDotsBuffer(a6),a1
        move.l  pd_ClipFillBuffer(a6),a0
        lea     (BLENDVIEW_HEIGHT/2)*(BLENDVIEW_WIDTH/8)-2(a1),a1
        lea     (BLENDVIEW_HEIGHT/2)*(BLENDVIEW_WIDTH/8)-2(a0),a0
        moveq.l #BLENDVIEW_WIDTH/8,d4
        mulu    d4,d0
        adda.l  d0,a1
        adda.l  d0,a0

        move.w  #(BLENDVIEW_WIDTH/2)+1+15,d1
        move.w  #(BLENDVIEW_WIDTH/2),d2
        add.w   d3,d1       ; right border
        sub.w   d3,d2       ; left border
        lsr.w   #4,d1
        add.w   d1,d1
        adda.w  d1,a1
        adda.w  d1,a0

        lsr.w   #4,d2
        add.w   d2,d2
        sub.w   d1,d2
        neg.w   d2          ; width

        sub.w   d2,d4       ; modulo

        add.w   d3,d3
        addq.w  #1,d3       ; h = 2*r+1
        lsl.w   #6,d3
        lsr.w   #1,d2
        add.w   d2,d3       ; bltsize

        BLTHOGON
        BLTWAIT

        BLTCON_SET_X AD,BLT_A,0,0,BLTCON1F_EFE|BLTCON1F_DESC
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.w  d4,bltamod(a5)
        move.w  d4,bltdmod(a5)
        move.l  a1,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)
        rts

;--------------------------------------------------------------------
; d0.w = r

bln_calc_circle:
        lea     (BLENDVIEW_HEIGHT/2)*4(a0),a0 ; y (addr)
        move.w  d0,d1           ; dx = r
        add.w   d1,d1
        add.w   d1,d1
        move.l  a0,a2           ; y + dy (addr increases over time)
        lea     4(a0),a3        ; y - dy (addr decreases over time) PRE-DECREMENT!
        lea     4(a0,d1.w),a1   ; y + dx (addr decreases over time) PRE-DECREMENT!
        sub.w   d1,a0           ; y - dx (addr increases over time)
        ;MinMax done $00c12ec8, $00c12f34, $00c12f38, $00c12ec4
        PUTMSG  30,<"MinMax buffer %p, %p, %p, %p">,a0,a1,a2,a3
        moveq.l #0,d1           ; dy
        move.w  d0,d2
        lsr.w   #4,d2           ; t1 = r / 16
        move.w  #(BLENDVIEW_WIDTH/2),d5
        sub.w   d0,d2
.loop   add.w   d0,d2

        cmp.w   d0,d1
        bgt.s   .done

.loop2
        PUTMSG  40,<"dx,dy %d,%d">,d0,d1
        move.w  d5,d3
        sub.w   d0,d3           ; x - dx
        move.w  d5,d4
        add.w   d0,d4           ; x + dx

        PUTMSG  50,<"min[y + dy = y + %d] = x - dx = %d - %d = %d (%x)]">,d1,d5,d0,d3,d3
        PUTMSG  50,<"max[y + dy = y + %d] = x + dx = %d + %d = %d (%x)]">,d1,d5,d0,d4,d4
        PUTMSG  50,<"min[y - dy = y - %d] = x - dx = %d - %d = %d (%x)]">,d1,d5,d0,d3,d3
        PUTMSG  50,<"max[y - dy = y - %d] = x + dx = %d + %d = %d (%x)]">,d1,d5,d0,d4,d4
        move.w  d4,-(a3)        ; maxX[y - dy] = x + dx
        move.w  d3,-(a3)        ; minX[y - dy] = x - dx
        move.w  d3,(a2)+        ; minX[y + dy] = x - dx
        move.w  d4,(a2)+        ; maxX[y + dy] = x + dx

        addq.w  #1,d1           ; dy++
        add.w   d1,d2           ; t1 += dy
        sub.w   d0,d2           ; t1 = t1 - dx
        bmi.s   .loop

        subq.w  #1,d1           ; dy--
        move.w  d5,d3
        sub.w   d1,d3           ; x - dy
        move.w  d5,d4
        add.w   d1,d4           ; x + dy
        addq.w  #1,d1           ; dy++

        PUTMSG  50,<"min[y + dx = y + %d] = x - dy = %d - %d = %d (%x)]">,d0,d5,d1,d3,d3
        PUTMSG  50,<"max[y + dx = y + %d] = x + dy = %d + %d = %d (%x)]">,d0,d5,d1,d4,d4
        PUTMSG  50,<"min[y - dx = y - %d] = x - dy = %d - %d = %d (%x)]">,d0,d5,d1,d3,d3
        PUTMSG  50,<"max[y - dx = y - %d] = x + dy = %d + %d = %d (%x)]">,d0,d5,d1,d4,d4
        move.w  d4,-(a1)        ; maxX[y + dx] = x + dy
        move.w  d3,-(a1)        ; minX[y + dx] = x - dy
        move.w  d3,(a0)+        ; minX[y - dx] = x - dy
        move.w  d4,(a0)+        ; maxX[y - dx] = x + dy

        subq.w  #1,d0           ; dx--
        cmp.w   d0,d1
        ble.s   .loop2

.done   PUTMSG  30,<"MinMax done %p, %p, %p, %p">,a0,a1,a2,a3
        rts

;--------------------------------------------------------------------

bln_plot_circle:
        lea     (BLENDVIEW_HEIGHT/2)*4(a0),a0
        lea     (BLENDVIEW_HEIGHT/2)*(BLENDVIEW_WIDTH/8)(a1),a1
        moveq.l #BLENDVIEW_WIDTH/8,d3
        move.w  d0,d2
        mulu    d3,d2
        sub.l   d2,a1

        add.w   d0,d0
        move.w  d0,d1
        add.w   d1,d1
        sub.w   d1,a0
.yloop
        REPT    2
        move.w  (a0)+,d1
        move.w  d1,d2
        lsr.w   #3,d2
        not.w   d1
        bchg    d1,(a1,d2.w)
        ENDR
        add.w   d3,a1
        dbra    d0,.yloop
        rts

;--------------------------------------------------------------------

bln_update_circle_pot_info:
        move.w  cp_Pair(a4),d0
        lea     .circle_fixup_table(pc,d0.w),a0
        move.l  (a0)+,cp_CircleFixupRoutine(a4)
        move.l  (a0)+,d4

        movem.w cp_Radius(a4),d1-d3
        ;move.w  cp_CenterPosX(a4),d2
        ;move.w  cp_CenterPosY(a4),d3
        move.w  d1,d0
        cmp.w   #MIN_CIRCLE_SIZE,d0
        blt.s   .skip
        add.w   d1,d1
        add.w   d1,d1
        lea     pd_CircleInfos(a6),a1
        move.l  -MIN_CIRCLE_SIZE*4(a1,d1.w),a1
        move.l  a1,cp_CircleInfo(a4)

        move.w  d3,d1
        sub.w   d0,d1
        add.w   d1,d1
        add.w   d4,d1
        move.w  d1,cp_LineFixTopYOffset(a4)

        move.w  d3,d1
        mulu    #BLENDVIEW_WIDTH,d1
        add.l   d2,d1
        add.l   d1,d1
        move.l  d1,cp_PosTCOffset(a4)

        move.w  d3,d1
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d1
        move.w  d2,d0
        asr.w   #4,d0
        add.w   d0,d0
        add.w   d0,d1
        move.l  d1,cp_PosOffset(a4)
.skip
        rts

.circle_fixup_table
        dc.l    bln_draw_circle_color_1_2,0*BLENDVIEW_HEIGHT*4*2
        dc.l    bln_draw_circle_color_3_4,1*BLENDVIEW_HEIGHT*4*2
        dc.l    bln_draw_circle_color_5_6,2*BLENDVIEW_HEIGHT*4*2
        dc.l    bln_draw_circle_color_7_8,3*BLENDVIEW_HEIGHT*4*2

;--------------------------------------------------------------------

bln_restore_necessary_circle_backgrounds:
        lea     pd_CirclePots(a6),a4
        moveq.l #-1,d5
        moveq.l #NUM_CIRCLE_POTS-1,d7
.loop
        tst.l   cp_InvertedOffset(a4)
        bne.s   .skip

        move.w  cp_LastLastRadius(a4),d1
        cmp.w   cp_Radius(a4),d1
        blt.s   .skip
        cmp.w   #MIN_CIRCLE_SIZE,d1
        blt.s   .skip

        add.w   d1,d1
        add.w   d1,d1
        lea     pd_CircleInfos(a6),a1
        move.l  -MIN_CIRCLE_SIZE*4(a1,d1.w),a1

        move.l  pd_CurrPlanesPtr(a6),a0
        move.l  cp_BgImage(a4),a2
        move.l  cp_LastLastPosOffset(a4),d0
        sub.l   #(BLENDVIEW_HEIGHT/2)*(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES+(BLENDVIEW_WIDTH/2)/8,d0
        adda.l  d0,a0
        adda.l  d0,a2

        move.w  ci_RightBltSize(a1),d3
        beq.s   .skipright

        PUSHM   a0/a2
        move.w  ci_RightBgOffset(a1),d0
        adda.w  d0,a0
        adda.w  d0,a2

        move.w  ci_RightWidth(a1),d1
        sub.w   d1,d3
        add.w   d3,d3
        move.w  d3,d0
        add.w   d3,d3
        add.w   d0,d3
        add.w   d1,d3   ; * BLENDVIEW_PLANES

        moveq.l #(BLENDVIEW_WIDTH/16),d0
        sub.w   d1,d0
        add.w   d0,d0

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0,(a3)+
        ;BLTCON_SET D,0,0,0,(a3)+
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        addq.l  #8,a3
        move.l  a2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        POPM

.skipright
        move.w  ci_TopBottomBltSize(a1),d3
        beq.s   .skiptopbottom

        PUSHM   a0/a2
        move.w  ci_TopBgOffset(a1),d0
        adda.w  d0,a0
        adda.w  d0,a2

        move.w  ci_TopWidth(a1),d1
        sub.w   d1,d3
        add.w   d3,d3
        move.w  d3,d0
        add.w   d3,d3
        add.w   d0,d3
        add.w   d1,d3   ; * BLENDVIEW_PLANES

        moveq.l #(BLENDVIEW_WIDTH/16),d0
        sub.w   d1,d0
        add.w   d0,d0       ; modulo

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0,(a3)+
        ;BLTCON_SET D,0,0,0,(a3)+
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        addq.l  #8,a3
        move.l  a2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

        moveq.l #0,d0
        move.w  ci_TopBottomOffsetAdv(a1),d0
        add.w   #5*(BLENDVIEW_WIDTH/8),d0
        adda.l  d0,a0
        adda.l  d0,a2

        lea     bltapt(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        POPM

.skiptopbottom
        move.w  ci_LeftBltSize(a1),d3
        beq.s   .skipleft

        move.w  ci_LeftBgOffset(a1),d0
        adda.w  d0,a0
        adda.w  d0,a2

        move.w  ci_LeftWidth(a1),d1
        sub.w   d1,d3
        add.w   d3,d3
        move.w  d3,d0
        add.w   d3,d3
        add.w   d0,d3
        add.w   d1,d3   ; * BLENDVIEW_PLANES

        moveq.l #(BLENDVIEW_WIDTH/16),d0
        sub.w   d1,d0
        add.w   d0,d0

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0,(a3)+
        ;BLTCON_SET D,0,0,0,(a3)+
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        addq.l  #8,a3
        move.l  a2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

.skipleft

.skip
        lea     cp_SIZEOF(a4),a4
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_draw_all_circle_pots:
        lea     pd_CirclePots(a6),a4
        moveq.l #NUM_CIRCLE_POTS-1,d7
.loop
        cmp.w   #MIN_CIRCLE_SIZE,cp_Radius(a4)
        blt.s   .skip

        move.l  cp_FgImage(a4),a2
        add.l   cp_FgOffset(a4),a2
        move.l  cp_PosOffset(a4),d0
        sub.l   #(BLENDVIEW_HEIGHT/2)*(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES+(BLENDVIEW_WIDTH/2)/8,d0
        move.l  pd_CurrPlanesPtr(a6),a0
        move.l  cp_BgImage(a4),a3
        adda.l  d0,a0
        adda.l  d0,a3

        move.w  cp_CircleShift(a4),pd_CircleShift(a6)
        move.l  cp_CircleInfo(a4),a1

        PUSHM   d7
        pea     .retadd(pc)
        move.l  cp_PaintRoutine(a4),-(sp)
        rts
.retadd
        POPM
.skip
        lea     cp_SIZEOF(a4),a4
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_do_all_circle_calc_updates:
        move.w  pd_BeatRadAdd(a6),d0
        sub.w   pd_FrameInc(a6),d0
        bge.s   .noclip
        moveq.l #0,d0
.noclip move.w  d0,pd_BeatRadAdd(a6)

        lea     pd_CirclePots(a6),a4
        moveq.l #NUM_CIRCLE_POTS-1,d7
.loop
        move.w  cp_LastRadius(a4),cp_LastLastRadius(a4)
        move.l  cp_LastPosOffset(a4),cp_LastLastPosOffset(a4)
        move.w  cp_Radius(a4),cp_LastRadius(a4)
        move.l  cp_PosOffset(a4),cp_LastPosOffset(a4)
        move.w  pd_FrameInc(a6),d0
        sub.w   d0,cp_TimeLeft(a4)
        bcc.s   .nonoewscriptrout
        PUTMSG  10,<"Potscript %p">,cp_PotScriptPtr(a4)
        move.l  cp_PotScriptPtr(a4),d1
        beq.s   .nonoewscriptrout
        move.l  d1,a0
        move.w  (a0)+,d1
        beq.s   .nonoewscriptrout
        add.w   d1,cp_TimeLeft(a4)
        move.w  (a0)+,d0
        lea     -2(a0,d0.w),a1
        move.l  a0,cp_PotScriptPtr(a4)
        jsr     (a1)
.nonoewscriptrout
        move.l  cp_FrameRoutine(a4),d0
        beq.s   .noframeroutine
        move.l  d0,a0
        jsr     (a0)
.noframeroutine

        cmp.w   #MIN_CIRCLE_SIZE,cp_Radius(a4)
        blt.s   .skip

        move.w  cp_FgRelPosX(a4),d0
        move.w  d0,d1
        moveq.l #15,d2
        move.w  d0,d3
        add.w   d2,d3
        asr.w   #4,d3
        add.w   d3,d3
        neg.w   d0
        and.w   d0,d2
        ror.w   #4,d2
        move.w  d2,cp_CircleShift(a4)

        add.w   d1,d1
        ext.l   d1
        move.w  cp_FgRelPosY(a4),d0
        move.w  d0,d2
        muls    #BLENDVIEW_WIDTH*2,d0
        add.l   d0,d1
        move.l  d1,cp_FgTCOffset(a4)

        muls    #(BLENDVIEW_WIDTH/8)*BLENDVIEW_PLANES,d2
        ext.l   d3
        add.l   d3,d2
        move.l  d2,cp_FgOffset(a4)

        move.l  cp_CircleInfo(a4),a1
        move.w  ci_LRIAreaY(a1),cp_LRIAreaY(a4)
        lea     cp_SIZEOF(a4),a4
        dbra    d7,.loop
        rts

.skip
        moveq.l #(BLENDVIEW_HEIGHT/2),d0
        sub.w   cp_Radius(a4),d0
        move.w  d0,cp_LRIAreaY(a4)

        lea     cp_SIZEOF(a4),a4
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_do_all_circle_ham_fixups:
        lea     pd_CirclePots(a6),a4
        moveq.l #7,d0
        moveq.l #6,d1
        moveq.l #5,d2
        moveq.l #4,d3
        moveq.l #3,d4
        moveq.l #2,d5
        moveq.l #1,d6
        moveq.l #NUM_CIRCLE_POTS-1,d7
.loop
        cmp.w   #MIN_CIRCLE_SIZE,cp_Radius(a4)
        blt.s   .skip

        move.l  cp_CircleInfo(a4),a1
        move.l  cp_CircleFixupRoutine(a4),a3
        move.l  pd_CurrPlanesPtr(a6),a0
        add.l   cp_PosOffset(a4),a0
        swap    d7
        jsr     (a3)
        swap    d7

.skip
        lea     cp_SIZEOF(a4),a4
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_do_blitter_to_copper_fixup:
        move.w  pd_LineFixToggle(a6),d0
        eor.w   #BLENDVIEW_HEIGHT*2,d0
        move.l  pd_LineFix1Array(a6),a0
        adda.w  d0,a0

        move.l  pd_LastCopListPtr(a6),a1
        adda.w  pd_CopperChunkyOffset(a6),a1

        FIRST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_linecopy,(a4)+
        move.l  a0,(a4)+
        move.l  a1,(a4)+

        REPT    7
        addq.l  #4,a1
        lea     BLENDVIEW_HEIGHT*4(a0),a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_linecopy_more,(a4)+
        move.l  a0,(a4)+
        move.l  a1,(a4)+
        ENDR

        clr.l   (a3)

        rts

.bq_linecopy
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #COP_INST_PER_HOLE_LINE*4-2,d0
        move.l  d0,bltamod(a5)
.bq_linecopy_more
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #(BLENDVIEW_HEIGHT<<6)|1,bltsize(a5)
        rts

;--------------------------------------------------------------------

bln_draw_stenciled_circle:
        moveq.l #0,d7
        moveq.l #0,d5
        subq.w  #1,d5
        move.w  ci_RightBltSize(a1),d3
        beq.s   .skipright

        PUSHM   a0/a2-a4
        addq.w  #1,d3

        move.w  ci_RightBgOffset(a1),d0
        lea     -2(a0,d0.w),a0          ; target
        lea     -2(a3,d0.w),a3          ; source
        adda.w  ci_RightFgOffset(a1),a2
        subq.w  #2,a2

        ; mask in A, source in B, background in C
        moveq.l #(BLENDVIEW_WIDTH/16)*BLENDVIEW_PLANES-1,d0
        sub.w   ci_RightWidth(a1),d0
        add.w   d0,d0

        move.l  ci_RightMask(a1),d2
        subq.l  #2,d2
        moveq.l #(BLENDVIEW_WIDTH/8),d6

        lea     bltcon0(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a4)+
        move.w  pd_CircleShift(a6),(a4)+ ; bltcon1
        move.l  d5,(a4)+    ; bltafwm/bltalwm
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  #-2,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        adda.l  d6,a3

        lea     bltcpt(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize
        ENDR
        POPM

.skipright
        move.w  ci_InnerBltSize(a1),d3
        beq.s   .skipinner

        PUSHM   a0/a2-a3

        moveq.l #0,d0
        add.w   ci_InnerBgOffset(a1),a0
        subq.w  #2,a0
        move.w  ci_InnerBltMod(a1),d0
        adda.w  ci_InnerFgOffset(a1),a2
        subq.w  #2,a2

        lea     bltcon0(a5),a3
        tst.w   ci_LeftBltSize(a1)
        beq.s   .damnitnoleft

        move.l  #BLTEN_AD|BLT_A,d4
        or.w    pd_CircleShift(a6),d4
        swap    d4

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  d4,(a3)+    ; bltcon0
        move.w  d5,(a3)+    ; bltafwm
        move.w  d5,(a3)+    ; bltalwm
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        addq.l  #8,a3
        move.l  a2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        bra.s   .continner

.damnitnoleft
        BLTHOGON
        BLTWAIT
        BLTCON0_SET BCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a3)+
        move.w  pd_CircleShift(a6),(a3)+ ; bltcon1
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d5,bltadat(a5)
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        addq.l  #4,a3       ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

.continner
        POPM

        bsr     bln_do_circle_tc_fixup

.skipinner
        move.w  ci_TopBottomBltSize(a1),d3
        beq.s   .skiptopbottom

        PUSHM   a0/a2-a4
        addq.w  #1,d3

        move.w  ci_TopBgOffset(a1),d0
        lea     -2(a0,d0.w),a0          ; target
        lea     -2(a3,d0.w),a3          ; source
        adda.w  ci_TopFgOffset(a1),a2
        subq.w  #2,a2

        ; mask in A, source in B, background in C
        moveq.l #(BLENDVIEW_WIDTH/16)*BLENDVIEW_PLANES-1,d0
        sub.w   ci_TopWidth(a1),d0
        add.w   d0,d0       ; modulo

        move.l  ci_TopMask(a1),d2
        subq.l  #2,d2
        moveq.l #(BLENDVIEW_WIDTH/8),d6

        lea     bltcon0(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a4)+
        move.w  pd_CircleShift(a6),(a4)+ ; bltcon1
        move.l  d5,(a4)+    ; bltafwm/bltalwm
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  #-2,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        adda.l  d6,a3
        lea     bltcpt(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize
        ENDR

        moveq.l #0,d0
        move.w  ci_TopBottomOffsetAdv(a1),d0
        adda.l  d0,a0
        adda.l  d0,a2
        adda.l  d0,a3

        moveq.l #0,d0
        move.w  ci_TopWidth(a1),d1
        add.w   d1,d1
        move.w  ci_TopBottomMaskSize(a1),d0
        sub.w   d1,d0
        add.l   d0,d2
        neg.w   d1
        add.w   d1,d1
        subq.w  #2,d1

        lea     bltcpt(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.w  d1,bltamod(a5)
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        adda.l  d6,a3
        lea     bltcpt(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize
        ENDR

        POPM

.skiptopbottom
        move.w  ci_LeftBltSize(a1),d3
        beq.s   .skipleft

        PUSHM   a4
        addq.w  #1,d3

        move.w  ci_LeftBgOffset(a1),d0
        lea     -2(a0,d0.w),a0          ; target
        lea     -2(a3,d0.w),a3          ; source
        adda.w  ci_LeftFgOffset(a1),a2
        subq.w  #2,a2

        ; mask in A, source in B, background in C
        moveq.l #(BLENDVIEW_WIDTH/16)*BLENDVIEW_PLANES-1,d0
        sub.w   ci_LeftWidth(a1),d0
        add.w   d0,d0

        move.l  ci_LeftMask(a1),d2
        subq.l  #2,d2
        moveq.l #(BLENDVIEW_WIDTH/8),d6

        lea     bltcon0(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a4)+
        move.w  pd_CircleShift(a6),(a4)+ ; bltcon1
        move.l  d5,(a4)+    ; bltafwm/bltalwm
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  #-2,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        adda.l  d6,a3
        lea     bltcpt(a5),a4
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a3,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a0,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize
        ENDR

        POPM

.skipleft
        tst.l   d7
        beq.s   bln_do_circle_tc_fixup
        rts

;--------------------------------------------------------------------

bln_do_circle_tc_fixup:
        PUSHM   a0/a2-a3
        move.w  cp_LineFixTopYOffset(a4),d1
        add.w   pd_LineFixToggle(a6),d1

        move.l  cp_FgTCImage(a4),a2
        adda.l  cp_FgTCOffset(a4),a2

        move.l  pd_LineFix1Array(a6),a0
        adda.w  d1,a0
        move.l  ci_LeftTCCode(a1),a3
        jsr     (a3)

        move.l  cp_BgTCImage(a4),a2
        move.l  cp_InvertedOffset(a4),d0
        beq.s   .notinverted
        add.l   cp_FgTCOffset-cp_SIZEOF(a4),d0
        add.l   d0,a2
        bra.s   .invcont
.notinverted
        add.l   cp_PosTCOffset(a4),a2
.invcont
        move.l  pd_LineFix2Array(a6),a0
        adda.w  d1,a0
        move.l  ci_RightTCCode(a1),a3
        jsr     (a3)
        POPM
        moveq.l #1,d7
        rts

;--------------------------------------------------------------------

bln_draw_stenciled_circle_invert:
        moveq.l #0,d5
        subq.w  #1,d5
        move.w  ci_RightBltSize(a1),d3
        beq.s   .skipright

        PUSHM   a0/a2
        addq.w  #1,d3

        move.w  ci_RightBgOffset(a1),d0
        lea     -2(a0,d0.w),a0          ; target
        adda.w  ci_RightFgOffset(a1),a2
        subq.w  #2,a2

        ; mask in A, source in B, background in C
        moveq.l #(BLENDVIEW_WIDTH/16)*BLENDVIEW_PLANES-1,d0
        sub.w   ci_RightWidth(a1),d0
        add.w   d0,d0

        move.l  ci_RightMask(a1),d2
        subq.l  #2,d2
        moveq.l #(BLENDVIEW_WIDTH/8),d6

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a3)+
        move.w  pd_CircleShift(a6),(a3)+ ; bltcon1
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  #-2,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2

        lea     bltcpt(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        ENDR
        POPM

.skipright
        move.w  ci_TopBottomBltSize(a1),d3
        beq.s   .skiptopbottom

        PUSHM   a0/a2
        addq.w  #1,d3

        move.w  ci_TopBgOffset(a1),d0
        lea     -2(a0,d0.w),a0          ; target
        adda.w  ci_TopFgOffset(a1),a2
        subq.w  #2,a2

        ; mask in A, source in B, background in C
        moveq.l #(BLENDVIEW_WIDTH/16)*BLENDVIEW_PLANES-1,d0
        sub.w   ci_TopWidth(a1),d0
        add.w   d0,d0       ; modulo

        move.l  ci_TopMask(a1),d2
        subq.l  #2,d2
        moveq.l #(BLENDVIEW_WIDTH/8),d6

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a3)+
        move.w  pd_CircleShift(a6),(a3)+ ; bltcon1
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  #-2,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        lea     bltcpt(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        ENDR

        moveq.l #0,d0
        move.w  ci_TopBottomOffsetAdv(a1),d0
        adda.l  d0,a0
        adda.l  d0,a2

        moveq.l #0,d0
        move.w  ci_TopWidth(a1),d1
        add.w   d1,d1
        move.w  ci_TopBottomMaskSize(a1),d0
        sub.w   d1,d0
        add.l   d0,d2
        neg.w   d1
        add.w   d1,d1
        subq.w  #2,d1

        lea     bltcpt(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.w  d1,bltamod(a5)
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        lea     bltcpt(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        ENDR

        POPM

.skiptopbottom
        move.w  ci_LeftBltSize(a1),d3
        beq.s   .skipleft

        PUSHM   a0/a2
        addq.w  #1,d3

        move.w  ci_LeftBgOffset(a1),d0
        lea     -2(a0,d0.w),a0          ; target
        adda.w  ci_LeftFgOffset(a1),a2
        subq.w  #2,a2

        ; mask in A, source in B, background in C
        moveq.l #(BLENDVIEW_WIDTH/16)*BLENDVIEW_PLANES-1,d0
        sub.w   ci_LeftWidth(a1),d0
        add.w   d0,d0

        move.l  ci_LeftMask(a1),d2
        subq.l  #2,d2
        moveq.l #(BLENDVIEW_WIDTH/8),d6

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a3)+
        move.w  pd_CircleShift(a6),(a3)+ ; bltcon1
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  #-2,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

        REPT    5
        adda.l  d6,a0
        adda.l  d6,a2
        lea     bltcpt(a5),a3
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        move.l  d2,(a3)+    ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize
        ENDR

        POPM

.skipleft
        move.w  ci_InnerBltSize(a1),d3
        beq.s   .skipinner

        moveq.l #0,d0
        add.w   ci_InnerBgOffset(a1),a0
        subq.w  #2,a0
        move.w  ci_InnerBltMod(a1),d0
        adda.w  ci_InnerFgOffset(a1),a2
        subq.w  #2,a2

        lea     bltcon0(a5),a3
        BLTHOGON
        BLTWAIT
        BLTCON0_SET BCD,((BLT_A&BLT_B)|(~BLT_A&BLT_C)),0,(a3)+
        move.w  pd_CircleShift(a6),(a3)+ ; bltcon1
        move.l  d5,(a3)+    ; bltafwm/bltalwm
        move.w  d5,bltadat(a5)
        move.w  d0,bltcmod(a5)
        move.w  d0,bltbmod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a0,(a3)+    ; bltcpt
        move.l  a2,(a3)+    ; bltbpt
        addq.l  #4,a3       ; bltapt
        move.l  a0,(a3)+    ; bltdpt
        move.w  d3,(a3)+    ; bltsize

.skipinner
        bsr     bln_do_circle_tc_fixup
        rts

;--------------------------------------------------------------------

bln_draw_and_move_bars:
        lea     pd_Bars(a6),a1
        move.l  pd_CurrPlanesPtr(a6),a2
        move.l  pd_OriginalImage3(a6),a3
        move.l  pd_OriginalImage2(a6),a4
        move.l  pd_CurrCopListPtr(a6),a0
        adda.w  pd_CopperChunkyOffset(a6),a0
        move.l  a0,d4
        move.l  pd_TrueColor16Image(a6),a0
        move.l  pd_TrueColor16Image2(a6),d2

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A&~BLT_C,0,0
        move.l  #-1,bltafwm(a5)      ; also fills bltalwm
        move.w  #$8000,bltcdat(a5)

        moveq.l #NUM_BARS-1,d7
        moveq.l #NUM_BARS,d5
.loop
        subq.w  #1,bd_Delay(a1)
        bpl     .skip
        move.w  bd_BarPos(a1),d1
        bmi.s   .noendpos
        subq.w  #1,bd_EndPosCount(a1)
        bpl.s   .noendpos
        subq.w  #1,d5
        bra     .skip
.noendpos
        move.w  #BLENDVIEW_HEIGHT,d3
        add.w   d1,d3
        ble     .skipmove

        move.w  bd_LastLastBottomPos(a1),bd_LastLastLastBottomPos(a1)
        move.w  bd_LastBottomPos(a1),bd_LastLastBottomPos(a1)
        move.w  d3,bd_LastBottomPos(a1)
        move.l  a0,-(sp)
        lsl.w   #6,d3
        addq.w  #1,d3

        neg.w   d1
        move.w  d1,d6
        mulu    #(BLENDVIEW_WIDTH/8)*BLENDIMG_PLANES,d1
        lea     (a3,d1.l),a0

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A&~BLT_C,0,0
        move.l  #(((BLENDIMG_WIDTH*BLENDIMG_PLANES-16)/8)<<16)|((BLENDVIEW_WIDTH-16)/8),bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        mulu    #BLOCKS_WIDTH*4,d6

        REPT    2
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        lea     (BLENDVIEW_WIDTH/8)(a0),a0

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        lea     (BLENDVIEW_WIDTH/8)(a0),a0

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A|BLT_C,0
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    2
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        lea     (BLENDVIEW_WIDTH/8)(a0),a0

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A&~BLT_C,0,0
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        suba.l  #5*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT,a2

        move.w  bd_LastBottomPos(a1),d0
        move.w  bd_LastLastLastBottomPos(a1),d1
        sub.w   d0,d1
        ble.s   .noclr

        move.w  d3,-(sp)
        move.w  #BLENDVIEW_HEIGHT,d3
        sub.w   d0,d3

        lsl.w   #6,d3
        addq.w  #1,d3

        move.l  d2,a0
        move.w  d0,d1
        mulu    #(BLENDVIEW_WIDTH/16)*2,d1
        adda.w  d1,a0
        move.w  d0,d1
        mulu    #COP_INST_PER_BARS_LINE*4,d1
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A,0
        move.l  #(((BLENDVIEW_WIDTH/16)*2-2)<<16)|(COP_INST_PER_BARS_LINE*4-2),bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  d4,a0
        adda.w  d1,a0
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.w  d0,d1
        mulu    #(BLENDVIEW_WIDTH/8),d0
        mulu    #(BLENDIMG_WIDTH/8)*BLENDIMG_PLANES,d1

        lea     (a2,d0.l),a0
        adda.l  d1,a4

        BLTHOGON
        BLTWAIT
        BLTHOGOFF

        BLTCON_SET AD,BLT_A&~BLT_C,0,0
        move.l  #(((BLENDIMG_WIDTH*BLENDIMG_PLANES-16)/8)<<16)|((BLENDVIEW_WIDTH-16)/8),bltamod(a5)
        move.l  a4,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    2
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a0),a0
        lea     (BLENDVIEW_WIDTH/8)(a4),a4

        BLTHOGON
        BLTWAIT
        BLTHOGOFF

        move.l  a4,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a0),a0
        lea     (BLENDVIEW_WIDTH/8)(a4),a4

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A|BLT_C,0
        move.l  a4,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    2
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a0),a0
        lea     (BLENDVIEW_WIDTH/8)(a4),a4

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A&~BLT_C,0,0
        move.l  a4,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        lea     -5*(BLENDVIEW_WIDTH/8)(a4),a4
        suba.l  d1,a4
        suba.l  #5*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT,a0

        move.w  (sp)+,d3

.noclr
        move.l  (sp),a0

        adda.l  d6,a0

        move.l  bd_BarSpeed(a1),d6
        add.l   d6,bd_BarPos(a1)
        bmi.s   .down
        move.l  #$4000,bd_BarPos(a1)
        neg.l   d6
        asr.l   #1,d6
        move.l  d6,d1
        asr.l   #2,d1
        sub.l   d1,d6
.down
        add.l   #2000,d6
        move.l  d6,bd_BarSpeed(a1)

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A,0
        move.l  #(((BLENDVIEW_WIDTH/16)*2-2)<<16)|(COP_INST_PER_BARS_LINE*4-2),bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.l  (sp)+,a0

        bra.s   .skip

.skipmove
        move.l  bd_BarSpeed(a1),d6
        add.l   d6,bd_BarPos(a1)
        add.l   #2000,d6
        move.l  d6,bd_BarSpeed(a1)

.skip
        addq.l  #2,a2
        addq.l  #2,a3
        addq.l  #2,a4
        addq.l  #2,a0
        addq.l  #2,d2
        addq.l  #4,d4
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.loop
        move.l  d5,d0
        rts

;--------------------------------------------------------------------

bln_prepare_tc16_data:
        move.w  #((BLENDIMG_WIDTH/16)*BLENDIMG_HEIGHT)-1,d7
        moveq.l #16*2,d0
.loop   move.w  (a0),(a1)+
        adda.w  d0,a0
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_prepare_striped_image:
        move.l  pd_CurrPlanesPtr(a6),a2
        move.w  #(BLENDVIEW_WIDTH>>4)|(BLENDVIEW_HEIGHT<<6),d3
        moveq.l #(BLENDVIEW_WIDTH/16)-1,d7
        moveq.l #-1,d0
        BLTHOGON
        BLTWAIT
        BLTHOGOFF

        BLTCON0_SET AD,BLT_A&~BLT_C,0
        move.l  d0,bltafwm(a5)
        move.w  #(BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8,bltamod(a5)
        move.w  #(BLENDVIEW_WIDTH-BLENDVIEW_WIDTH)/8,bltdmod(a5)
        move.w  #$8000,bltcdat(a5)

        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    2
        lea     (BLENDVIEW_WIDTH/8)(a0),a0
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        lea     (BLENDVIEW_WIDTH/8)(a0),a0
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A|BLT_C,0
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     (BLENDVIEW_WIDTH/8)(a0),a0
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A&~BLT_C,0
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     (BLENDVIEW_WIDTH/8)(a0),a0
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  a0,bltapt(a5)
        move.l  a2,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.l  pd_CurrCopListPtr(a6),a0
        adda.w  pd_CopperChunkyOffset(a6),a0
        move.w  #(16>>4)|(BLENDVIEW_HEIGHT<<6),d3
        moveq.l #(BLENDVIEW_WIDTH/16)-1,d7
.xloop
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET AD,BLT_A,0
        move.l  #(((BLENDVIEW_WIDTH/16)*2-2)<<16)|(COP_INST_PER_BARS_LINE*4-2),bltamod(a5)

        move.l  a1,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)
        addq.l  #2,a1
        addq.l  #4,a0
        dbra    d7,.xloop
        rts

;--------------------------------------------------------------------

bln_load_part_sequences:
        move.l  a0,a2
        move.w  (a0)+,d5
        move.w  (a0)+,d6
        move.l  (a0)+,d4
        lea     pd_Parts(a6),a1
        moveq.l #BLOCKS_HEIGHT-1,d7
.loop
        move.w  (a0)+,pbi_Phase(a1)
        move.w  (a0)+,d0
        lea     (a2,d0.w),a3
        moveq.l #0,d0
        move.b  (a3)+,d0
        move.l  a3,pbi_SequencePtr(a1)

        move.w  pbi_YPos(a1),d1
        PUSHM   a0-a2/d4-d7
        move.l  d4,a3
        move.l  (a6,d5.w),a0
        move.l  (a6,d6.w),a2
        move.l  a0,pbi_OriginalImage(a1)
        move.l  a2,pbi_TrueColorImage(a1)
        jsr     (a3)
        POPM
        addq.w  #1,d1
        lea     pbi_SIZEOF(a1),a1
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_handle_parts:
        lea     pd_Parts(a6),a1
        moveq.l #BLOCKS_HEIGHT-1,d7
.loop
        tst.w   pbi_Phase(a1)
        bmi.s   .skip
        add.l   #$10000,d7
        PUSHM   a1/d7
        move.l  pbi_PalApplyRoutine(a1),a0
        jsr     (a0)
        move.l  pbi_PalChangeRoutine(a1),a0
        jsr     (a0)
        move.w  pbi_Phase(a1),d0
        move.l  pbi_PhaseSequence(a1),a0
        move.l  (a0,d0.w),a0
        addq.w  #4,d0
        move.w  d0,pbi_Phase(a1)
        jsr     (a0)
        POPM
        bra.s   .skipover
.skip   addq.w  #1,pbi_Phase(a1)
.skipover
        lea     pbi_SIZEOF(a1),a1
        dbra    d7,.loop
        swap    d7
        rts

;--------------------------------------------------------------------

bln_load_next_seq_part_in:
        move.l  pbi_SequencePtr(a1),a0
        moveq.l #0,d0
        move.w  d0,pbi_Phase(a1)
        move.b  (a0)+,d0
        bmi.s   .kill
        move.l  a0,pbi_SequencePtr(a1)
        move.l  pbi_OriginalImage(a1),a0
        move.l  pbi_TrueColorImage(a1),a2
        move.w  pbi_YPos(a1),d1
        bra     bln_load_new_block_fade_in
.kill   move.w  #$8000,pbi_Phase(a1)
        rts

;--------------------------------------------------------------------

bln_load_next_seq_part_out_in:
        move.l  pbi_SequencePtr(a1),a0
        moveq.l #0,d0
        move.w  d0,pbi_Phase(a1)
        move.b  (a0)+,d0
        bmi.s   .kill
        move.l  a0,pbi_SequencePtr(a1)
        move.l  pbi_OriginalImage(a1),a0
        move.l  pbi_TrueColorImage(a1),a2
        move.w  pbi_YPos(a1),d1
        bra     bln_load_new_block_fade_out_and_in
.kill   move.w  #$8000,pbi_Phase(a1)
        rts

;--------------------------------------------------------------------

bln_load_new_block_fade_in:
        move.l  a2,pbi_LastTrueColorImage(a1)
        add.w   d0,d0
        add.w   d0,d0
        ; calculate screen offset
        move.w  d1,d2
        mulu    #(BLENDVIEW_WIDTH/8)*PART_HEIGHT,d2
        move.l  d2,d3
        add.w   d0,d2
        move.l  d2,pbi_ScreenOffset(a1)

        add.w   d3,d3
        move.l  d3,d2
        add.w   d3,d2
        add.w   d3,d2
        add.w   d0,d2
        adda.l  d2,a0
        move.l  a0,pbi_SourceImgPtr(a1)

        ; init colors for fade-in
        lea     pbi_TargetColors(a1),a3
        lea     bln_images_palette(pc),a0
        moveq.l #0,d2
        moveq.l #7-1,d7
.primcloop
        move.w  d2,pbi_CurrentColors-pbi_TargetColors(a3)
        move.w  (a0)+,(a3)+
        dbra    d7,.primcloop

        moveq.l #0,d3
        move.w  d0,d3
        lsl.w   #4,d3
        move.w  d1,d2
        mulu    #BLENDIMG_WIDTH*PART_HEIGHT*2,d2
        add.l   d3,d2
        adda.l  d2,a2           ; x*2+y*320*2

        moveq.l #0,d2
        moveq.l #PART_HEIGHT-1,d7
.edgeloop
        move.w  d2,pbi_CurrentColors-pbi_TargetColors(a3)
        move.w  (a2),(a3)+
        lea     BLENDIMG_WIDTH*2(a2),a2
        dbra    d7,.edgeloop

        ; calculate copper edge offset
        move.w  pbi_Copper7Offset(a1),d2
        add.w   d0,d2
        add.w   d0,d2           ; x * 8
        add.w   #(7+1)*4,d2
        move.w  d2,pbi_CopperEdgeOffset(a1)

        move.l  #bln_fade_in_sequence,pbi_PhaseSequence(a1)
        move.l  #bln_palette_step_up,pbi_PalChangeRoutine(a1)
        lea     bln_palette_apply(pc),a0
        cmp.w   #5,d1
        bne.s   .nofix
        lea     bln_palette_apply_fix5(pc),a0
.nofix
        move.l  a0,pbi_PalApplyRoutine(a1)
        rts

;--------------------------------------------------------------------

bln_load_new_block_fade_out_and_in:
        add.w   d0,d0
        add.w   d0,d0
        ; calculate screen offset
        move.w  d1,d2
        mulu    #(BLENDVIEW_WIDTH/8)*PART_HEIGHT,d2
        move.l  d2,d3
        add.w   d0,d2
        move.l  d2,pbi_ScreenOffset(a1)

        add.w   d3,d3
        move.l  d3,d2
        add.w   d3,d2
        add.w   d3,d2
        add.w   d0,d2
        adda.l  d2,a0
        move.l  a0,pbi_SourceImgPtr(a1)

        moveq.l #0,d3
        move.w  d0,d3
        lsl.w   #4,d3
        move.w  d1,d2
        mulu    #BLENDIMG_WIDTH*PART_HEIGHT*2,d2
        add.l   d3,d2
        adda.l  d2,a2           ; x*2+y*320*2

        ; init new colors for fade-in
        lea     pbi_TargetColors+7*2(a1),a3
        moveq.l #PART_HEIGHT-1,d7
.edgeloop2
        move.w  (a2),(a3)+
        lea     BLENDIMG_WIDTH*2(a2),a2
        dbra    d7,.edgeloop2

        ; calculate copper edge offset
        move.w  pbi_Copper7Offset(a1),d2
        add.w   d0,d2
        add.w   d0,d2           ; x * 8
        add.w   #(7+1)*4,d2
        move.w  d2,pbi_CopperEdgeOffset(a1)

        ; init last colors for fade-out
        cmp.w   #5,d1
        bne.s   .noreadoutfix
        bsr     bln_palette_readout_fix5
        bra.s   .contreadoutfix
.noreadoutfix
        bsr     bln_palette_readout
.contreadoutfix

        move.l  #bln_fade_out_in_sequence,pbi_PhaseSequence(a1)
        move.l  #bln_palette_step_down,pbi_PalChangeRoutine(a1)
        lea     bln_palette_apply(pc),a0
        cmp.w   #5,d1
        bne.s   .nofix
        lea     bln_palette_apply_fix5(pc),a0
.nofix
        move.l  a0,pbi_PalApplyRoutine(a1)
        rts

;--------------------------------------------------------------------

bln_palette_step_up:
        lea     pbi_CurrentColors(a1),a0
        move.l  pd_ShadeTableXor(a6),a2
        moveq.l #(7+PART_HEIGHT)-1,d7
.looppal
        move.w  pbi_TargetColors-pbi_CurrentColors(a0),d0
        move.w  (a0),d1
        eor.w   d1,d0
        add.w   d0,d0
        add.w   (a2,d0.w),d1
        move.w  d1,(a0)+
        dbra    d7,.looppal
        rts

;--------------------------------------------------------------------

bln_palette_step_down:
        lea     pbi_CurrentColors(a1),a0
        move.l  pd_ShadeTableSub1(a6),a2
        moveq.l #(7+PART_HEIGHT)-1,d7
.looppal
        move.w  (a0),d0
        add.w   d0,d0
        move.w  (a2,d0.w),(a0)+
        dbra    d7,.looppal
        rts

;--------------------------------------------------------------------

bln_palette_fade_step_to_black:
        lea     pd_EndLogoPalette(a6),a0
        move.l  pd_ShadeTableSub1(a6),a2
        moveq.l #16-1,d7
.loop   move.w  (a0),d0
        add.w   d0,d0
        move.w  (a2,d0.w),(a0)+
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_palette_fade_step_from_white:
        lea     pd_EndLogoPalette(a6),a0
        lea     bln_endlogo_palette(pc),a1
        move.l  pd_ShadeTableXor(a6),a2
        moveq.l #16-1,d7
.loop   move.w  (a0),d1
        move.w  (a1)+,d0
        eor.w   d1,d0
        add.w   d0,d0
        sub.w   (a2,d0.w),d1
        move.w  d1,(a0)+
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_palette_apply:
        lea     pbi_CurrentColors(a1),a0
        move.l  pd_CurrCopListPtr(a6),a2
        adda.w  pbi_Copper7Offset(a1),a2
        REPT    7
        move.w  (a0)+,REPTN*4(a2)
        ENDR

        move.l  pd_CurrCopListPtr(a6),a2
        add.w   pbi_CopperEdgeOffset(a1),a2
        moveq.l #PART_HEIGHT-1,d7
.loop
        move.w  (a0)+,(a2)
        lea     (20+1)*4(a2),a2
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_palette_apply_fix5:
        lea     pbi_CurrentColors(a1),a0
        move.l  pd_CurrCopListPtr(a6),a2
        adda.w  pbi_Copper7Offset(a1),a2
        REPT    7
        move.w  (a0)+,REPTN*4(a2)
        ENDR

        move.l  pd_CurrCopListPtr(a6),a2
        add.w   pbi_CopperEdgeOffset(a1),a2
        moveq.l #(($100-$52)%PART_HEIGHT)-1,d7
.loop
        move.w  (a0)+,(a2)
        lea     (20+1)*4(a2),a2
        dbra    d7,.loop

        addq.w  #4,a2

        moveq.l #(PART_HEIGHT-(($100-$52)%PART_HEIGHT))-1,d7
.loop2
        move.w  (a0)+,(a2)
        lea     (20+1)*4(a2),a2
        dbra    d7,.loop2
        rts

;--------------------------------------------------------------------

bln_palette_readout:
        lea     pbi_CurrentColors+7*2(a1),a0
        move.l  pd_CurrCopListPtr(a6),a2
        add.w   pbi_CopperEdgeOffset(a1),a2
        moveq.l #PART_HEIGHT-1,d7
.loop
        move.w  (a2),(a0)+
        lea     (20+1)*4(a2),a2
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

bln_palette_readout_fix5:
        lea     pbi_CurrentColors+7*2(a1),a0
        move.l  pd_CurrCopListPtr(a6),a2
        add.w   pbi_CopperEdgeOffset(a1),a2
        moveq.l #(($100-$52)%PART_HEIGHT)-1,d7
.loop
        move.w  (a2),(a0)+
        lea     (20+1)*4(a2),a2
        dbra    d7,.loop

        addq.w  #4,a2

        moveq.l #(PART_HEIGHT-(($100-$52)%PART_HEIGHT))-1,d7
.loop2
        move.w  (a2),(a0)+
        lea     (20+1)*4(a2),a2
        dbra    d7,.loop2
        rts

;--------------------------------------------------------------------

bln_blit_intro_block_fade_in_0:
        move.l  pbi_SourceImgPtr(a1),a0
        move.l  pd_CurrPlanesPtr(a6),a2
        add.l   pbi_ScreenOffset(a1),a2
        move.l  pbi_TempBuffer(a1),a1

        ; copy plane 5 without first line to target screen
        lea     4*(BLENDIMG_WIDTH/8)(a0),a0            ; p5
        lea     4*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p5
        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_p5_p6,(a4)+
        move.l  a0,(a4)+
        move.l  a2,(a4)+

        ; copy plane 6 without first line to target screen
        lea     (BLENDIMG_WIDTH/8)(a0),a0              ; p6
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p6
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_p5_p6_more,(a4)+
        move.l  a0,(a4)+
        move.l  a2,(a4)+

        ; create p5|p6 mask in block temp
        lea     4*(PART_WIDTH/8)*PART_HEIGHT(a1),a1     ; buffer 5 (p5|p6)
        move.l  a1,d2
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_p5_p6,(a4)+
        move.l  a2,(a4)+
        lea     -1*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p5
        move.l  a2,(a4)+
        move.l  a1,(a4)+

        ; copy plane 1 without first line to block temp
        lea     -5*(BLENDIMG_WIDTH/8)(a0),a0           ; p1
        lea     -4*(PART_WIDTH/8)*PART_HEIGHT(a1),a1    ; buffer 5 (p5|p6)
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_initial_copy,(a4)+
        move.l  a0,(a4)+
        move.l  a1,(a4)+

        ; copy plane 2/3 without first line to block temp
        REPT    2
        lea     (PART_WIDTH/8)*PART_HEIGHT(a1),a1       ; buffer 2-3 (p2-p3)
        lea     (BLENDIMG_WIDTH/8)(a0),a0              ; p2-p3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_more,(a4)+
        move.l  a0,(a4)+
        move.l  a1,(a4)+
        ENDR

        ; copy plane 4 (masked) and set first line (color 8) to block temp
        lea     (PART_WIDTH/8)*PART_HEIGHT(a1),a1       ; buffer 4 (p4)
        lea     (BLENDIMG_WIDTH/8)(a0),a0              ; p4
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_special,(a4)+
        move.l  a0,(a4)+
        move.l  d2,(a4)+
        move.l  a1,(a4)+

        ; fill first line (color 8), clear rest to target screen
        lea     -1*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p4
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_fill_special,(a4)+
        move.l  a2,(a4)+

        ; copy p3 (masked with p5/p6 mask) to target screen
        lea     -(PART_WIDTH/8)*PART_HEIGHT(a1),a1      ; buffer 3 (p3)
        lea     -1*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_masked,(a4)+
        move.l  d2,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+

        ; copy p2 (masked with p5/p6 mask) to target screen
        lea     -(PART_WIDTH/8)*PART_HEIGHT(a1),a1      ; buffer 2 (p2)
        lea     -1*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p2
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_masked_more,(a4)+
        move.l  d2,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+

        lea     -(PART_WIDTH/8)*PART_HEIGHT(a1),a1      ; buffer 1 (p1)
        lea     -1*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p1
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_copy_masked_more,(a4)+
        move.l  d2,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+

        rts

.bq_initial_copy
        BLTCON0_SET AD,BLT_A,0
        move.l  #$7fffffff,bltafwm(a5)
        move.l  #((BLENDVIEW_WIDTH*BLENDIMG_PLANES-PART_WIDTH)/8)<<16,bltamod(a5)
.bq_copy_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_copy_special
        BLTCON0_SET BCD,BLT_A|(BLT_C&BLT_B),0
        move.l  #$80000000,bltafwm(a5)
        move.l  #((BLENDVIEW_WIDTH*BLENDIMG_PLANES-PART_WIDTH)/8)<<16,bltcmod(a5)
        move.w  #$ffff,bltadat(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        addq.l  #4,a1           ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_copy_p5_p6
        BLTCON_SET AD,BLT_A,0,0
        move.l  #$7fffffff,bltafwm(a5)
        move.l  #(((BLENDVIEW_WIDTH*BLENDIMG_PLANES-PART_WIDTH)/8)<<16)|((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltamod(a5)
.bq_copy_p5_p6_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_merge_p5_p6
        BLTCON0_SET ACD,BLT_A|BLT_C,0
        moveq.l #((BLENDVIEW_WIDTH-PART_WIDTH)/8),d0
        move.w  d0,bltcmod(a5)
        swap    d0
        move.l  d0,bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_fill_special
        BLTCON0_SET D,BLT_A,0
        move.w  #$ffff,bltadat(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltdmod(a5)
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),bltsize(a5)
        rts

.bq_copy_masked
        BLTCON0_SET ACD,BLT_A&(~BLT_C),0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #0,d0
        move.w  d0,bltcmod(a5)
        move.w  d0,bltamod(a5)
.bq_copy_masked_more
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

;--------------------------------------------------------------------

bln_blit_intro_block_fade_in_1:
        move.l  pd_LastPlanesPtr(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a2
        move.l  pbi_ScreenOffset(a1),d0
        adda.l  d0,a0
        adda.l  d0,a2
        move.l  pbi_TempBuffer(a1),a1

        ; copy plane 5 without first line to target screen
        lea     4*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p5
        lea     4*(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p5
        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_p5_p6,(a4)+
        move.l  a0,(a4)+
        move.l  a2,(a4)+

        ; copy plane 6 without first line to target screen
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p6
        lea     (BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT(a2),a2 ; p6
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_p5_p6_more,(a4)+
        move.l  a0,(a4)+
        move.l  a2,(a4)+

        lea     -2*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p4
        lea     -2*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p4
        bra.s   bln_blit_intro_block_fade_in_2b

.bq_copy_p5_p6
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((BLENDVIEW_WIDTH-PART_WIDTH)/8)<<16)|((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltamod(a5)
.bq_copy_p5_p6_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

;--------------------------------------------------------------------

bln_blit_intro_block_fade_in_2:
        move.l  pd_LastPlanesPtr(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a2
        move.l  pbi_ScreenOffset(a1),d0
        adda.l  d0,a0
        adda.l  d0,a2
        move.l  pbi_TempBuffer(a1),a1

        lea     3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p4
        lea     3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p4

bln_blit_intro_block_fade_in_2b:
        ; create tmp mask for p4
        lea     3*(PART_WIDTH/8)*PART_HEIGHT(a1),a1     ; buffer 4 (p4)
        move.l  a2,d2
        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_tmp_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  a1,(a4)+        ; a = target
        move.l  d2,(a4)+        ; d = mask

        ; merge tmp mask for p3
        lea     -1*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p3
        lea     -1*(PART_WIDTH/8)*PART_HEIGHT(a1),a1    ; buffer 3 (p3)
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_tmp_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; b = old mask
        move.l  a1,(a4)+        ; a = target
        move.l  d2,(a4)+        ; d = mask

        ; merge tmp mask for p2/p1
        REPT    2
        lea     -1*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p2/p1
        lea     -1*(PART_WIDTH/8)*PART_HEIGHT(a1),a1    ; buffer 2/1 (p2/p1)
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_tmp_mask_more,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; b = old mask
        move.l  a1,(a4)+        ; a = target
        move.l  d2,(a4)+        ; d = mask
        ENDR

        ; p1n = last_p1 ^ tmp
        lea     -3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_with_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  a2,(a4)+        ; d = new destination

        ; tmp = last_p1 & tmp
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_and_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  d2,(a4)+        ; d = new mask

        ; p2n = last_p2 ^ tmp
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p2
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p2
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_with_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  a2,(a4)+        ; d = new destination

        ; tmp = last_p2 & tmp
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_and_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  d2,(a4)+        ; d = new mask

        ; p3n = last_p3 ^ tmp
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p3
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_with_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  a2,(a4)+        ; d = new destination

        ; p4n = last_p4 ^ (tmp & last_p3)
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_final_xor,(a4)+
        move.l  a0,(a4)+        ; c = last p3
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p4
        move.l  a0,(a4)+        ; b = last p4
        move.l  d2,(a4)+        ; a = mask
        move.l  d2,(a4)+        ; d = new destination

        rts

.bq_tmp_mask
        BLTCON_SET ACD,BLT_A^BLT_C,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((BLENDVIEW_WIDTH-PART_WIDTH)/8)<<16)|((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltcmod(a5)
        move.w  #0,bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_merge_tmp_mask
        BLTCON0_SET ABCD,(BLT_A^BLT_C)|BLT_B,0
.bq_merge_tmp_mask_more
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_xor_with_mask
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.w  #((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_and_mask
        BLTCON0_SET ACD,BLT_A&BLT_C,0
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_final_xor
        BLTCON0_SET ABCD,BLT_B^(BLT_A&BLT_C),0
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

;--------------------------------------------------------------------

bln_blit_intro_block_final:
        move.l  pbi_SourceImgPtr(a1),a0
        move.l  pd_CurrPlanesPtr(a6),a2
        add.l   pbi_ScreenOffset(a1),a2

        ; copy plane 4 (masked) and set first line (color 8) to block temp
        lea     3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p4
        lea     3*(BLENDIMG_WIDTH/8)(a0),a0        ; p4
        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_copy_special,(a4)+
        move.l  a0,(a4)+
        move.l  a2,(a4)+

        TERM_ADD_TO_BLITTER_QUEUE a3
        rts

.bq_copy_special
        BLTCON_SET CD,BLT_A|BLT_C,0,0
        move.l  #$80000000,bltafwm(a5)
        move.w  #((BLENDVIEW_WIDTH*BLENDIMG_PLANES-PART_WIDTH)/8),bltcmod(a5)
        move.w  #((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltdmod(a5)
        move.w  #$ffff,bltadat(a5)
        move.l  (a0)+,bltcpt(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),bltsize(a5)
        rts

;--------------------------------------------------------------------

bln_blit_intro_block_fade_out_0:
        move.l  pd_LastPlanesPtr(a6),a0
        add.l   pbi_ScreenOffset(a1),a0
        move.l  pd_CurrPlanesPtr(a6),a2
        add.l   pbi_ScreenOffset(a1),a2
        move.l  pbi_TempBuffer(a1),a1

        ; create p5|p6 mask in block temp
        lea     4*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p5
        lea     4*(PART_WIDTH/8)*PART_HEIGHT(a1),a1     ; buffer 5 (p5|p6)
        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_p5_p6,(a4)+
        move.l  a0,(a4)+
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p6
        move.l  a0,(a4)+
        move.l  a1,(a4)+

        lea     -2*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p4
        lea     3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p4
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_remap_indexed,(a4)+
        move.l  a0,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+

        rts

.bq_merge_p5_p6
        BLTCON_SET ACD,BLT_A|BLT_C,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #((BLENDVIEW_WIDTH-PART_WIDTH)/8),d0
        move.w  d0,bltcmod(a5)
        swap    d0
        move.l  d0,bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_remap_indexed
        BLTCON0_SET BCD,(BLT_B&BLT_C)|BLT_A,0
        move.l  #$80000000,bltafwm(a5)
        move.w  #$ffff,bltadat(a5)
        move.w  #0,bltbmod(a5)
        move.w  #((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltdmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        addq.l  #4,a1           ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

;--------------------------------------------------------------------

bln_blit_intro_block_fade_out_1_change_dir:
        move.l  #bln_palette_step_up,pbi_PalChangeRoutine(a1)

bln_blit_intro_block_fade_out_1:
        move.l  pd_LastPlanesPtr(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a2
        move.l  pbi_ScreenOffset(a1),d0
        adda.l  d0,a0
        adda.l  d0,a2
        move.l  pbi_TempBuffer(a1),a1

        lea     3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p4
        lea     3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p4

        ; create tmp mask for p4
        move.l  a2,d2
        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_tmp_mask,(a4)+
        move.l  a0,(a4)+        ; c = last p4
        lea     -1*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p3
        move.l  a0,(a4)+        ; b = last p3
        lea     -1*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p2
        move.l  a0,(a4)+        ; a = last p2
        move.l  d2,(a4)+        ; d = mask

        ; merge tmp mask for p3
        lea     4*(PART_WIDTH/8)*PART_HEIGHT(a1),a1     ; buffer 5 (p5|p6)
        lea     -1*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_merge_tmp_mask,(a4)+
        move.l  a0,(a4)+        ; c = last p1
        move.l  a1,(a4)+        ; b = p5|p6
        move.l  d2,(a4)+        ; a = old mask
        move.l  d2,(a4)+        ; d = mask

        ; p1n = last_p1 ^ tmp
        lea     -3*(BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_with_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  a2,(a4)+        ; d = new destination

        ; tmp = p1n & tmp
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_and_mask,(a4)+
        move.l  a2,(a4)+        ; c = p1n
        move.l  d2,(a4)+        ; a = mask
        move.l  d2,(a4)+        ; d = new mask

        ; p2n = last_p2 ^ tmp
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p2
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p2
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_with_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  a2,(a4)+        ; d = new destination

        ; tmp = p2n & tmp
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_and_mask,(a4)+
        move.l  a2,(a4)+        ; c = p2n
        move.l  d2,(a4)+        ; a = mask
        move.l  d2,(a4)+        ; d = new mask

        ; p3n = last_p3 ^ tmp
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p3
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a2),a2 ; p3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_with_mask,(a4)+
        move.l  a0,(a4)+        ; c = last
        move.l  d2,(a4)+        ; a = mask
        move.l  a2,(a4)+        ; d = new destination

        ; p4n = last_p4 ^ (tmp & p3n)
        lea     (BLENDIMG_WIDTH/8)*BLENDIMG_HEIGHT(a0),a0 ; p4
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_final_xor,(a4)+
        move.l  a2,(a4)+        ; c = p3n
        move.l  a0,(a4)+        ; b = last p4
        move.l  d2,(a4)+        ; a = mask
        move.l  d2,(a4)+        ; d = new destination

        rts

.bq_tmp_mask
        BLTCON_SET ABCD,BLT_A|BLT_B|BLT_C,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((BLENDVIEW_WIDTH-PART_WIDTH)/8)<<16)|((BLENDVIEW_WIDTH-PART_WIDTH)/8),d0
        move.l  d0,bltcmod(a5)
        move.l  d0,bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_merge_tmp_mask
        BLTCON0_SET ABCD,(BLT_A|BLT_C)&BLT_B,0
        move.w  #0,bltbmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_xor_with_mask
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.w  #((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_and_mask
        BLTCON0_SET ACD,BLT_A&BLT_C,0
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

.bq_final_xor
        BLTCON0_SET ABCD,BLT_B^(BLT_A&BLT_C),0
        move.w  #((BLENDVIEW_WIDTH-PART_WIDTH)/8),bltbmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  #((PART_WIDTH>>4)|(PART_HEIGHT<<6)),(a1)+   ; bltsize
        rts

;--------------------------------------------------------------------

bln_calc_true_color_image:
        PUTMSG  10,<"TC Image %p">,a1
        lea     bln_images_palette-9*2(pc),a2
        lea     (a2,d0.w),a3
        move.w  #BLENDVIEW_HEIGHT,-(sp)
.lineloop
        moveq.l #(BLENDIMG_WIDTH/16)-1,d7
        move.w  (a3)+,d6              ; background color
        move.w  d6,8*2(a2)
        swap    d6
.wordloop
        move.w  5*(BLENDIMG_WIDTH/8)(a0),d5
        move.w  4*(BLENDIMG_WIDTH/8)(a0),d4
        move.w  3*(BLENDIMG_WIDTH/8)(a0),d3
        move.w  2*(BLENDIMG_WIDTH/8)(a0),d2
        move.w  1*(BLENDIMG_WIDTH/8)(a0),d1
        move.w  (a0)+,d0
        swap    d7
        move.w  #15,d7
.pixelloop
        clr.w   d6
        add.w   d3,d3
        addx.w  d6,d6
        add.w   d2,d2
        addx.w  d6,d6
        add.w   d1,d1
        addx.w  d6,d6
        add.w   d0,d0
        addx.w  d6,d6

        add.w   d5,d5
        bcs.s   .greenOrRed
        add.w   d4,d4
        bcs.s   .blue

        PUTMSG  50,<"Idx %d">,d6

        add.w   d6,d6
        move.w  (a2,d6.w),d6
        move.w  d6,(a1)+
        bra.s   .contloop

.greenOrRed
        add.w   d4,d4
        bcs.s   .green
.red
        PUTMSG  50,<"Red %d">,d6
        move.b  d6,(a1)
        swap    d6
        move.b  d6,1(a1)
        move.w  (a1)+,d6
        bra.s   .contloop

.green
        PUTMSG  50,<"Green %d">,d6
        move.w  d7,a4
        move.w  d6,d7
        lsl.w   #4,d7
        swap    d6
        and.w   #$f0f,d6
        or.w    d7,d6
        move.w  d6,(a1)+
        move.w  a4,d7
        bra.s   .contloop

.blue
        PUTMSG  50,<"Blue %d">,d6
        move.w  d7,a4
        move.w  d6,d7
        swap    d6
        and.w   #$ff0,d6
        or.w    d7,d6
        move.w  d6,(a1)+
        move.w  a4,d7
.contloop
        swap    d6
        dbra    d7,.pixelloop
        swap    d7
        dbra    d7,.wordloop
.nextline
        lea     5*(BLENDIMG_WIDTH/8)(a0),a0
        subq.w  #1,(sp)
        bne     .lineloop
        addq.w  #2,sp
        rts

;--------------------------------------------------------------------

bln_create_intro_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        COPIMOVE $6a00,bplcon0

        lea     bln_images_palette(pc),a1
        moveq.l #7-1,d7
        move.w  #color+9*2,d0
.palloop
        move.w  d0,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d0
        dbra    d7,.palloop

        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        move.l  #(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT,d2
.bplloop
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop

        moveq.l #-2,d3
        move.w  #$51d5,d0
        move.w  #BLENDVIEW_HEIGHT-1,d7
        move.w  #$100,d2

        move.l  a0,d1
        sub.l   a2,d1
        add.w  #4+2+8,d1
        move.w  d1,pd_CopperChunkyOffset(a6)

        lea     pd_Parts(a6),a1
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        moveq.l #0,d4
.cprloop
        subq.w  #1,d4
        bpl.s   .nocols
        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #2,d1
        move.w  d1,pbi_Copper7Offset(a1)
        lea     pbi_SIZEOF(a1),a1
        COPIMOVE $111,(color+1*2)
        COPIMOVE $333,(color+2*2)
        COPIMOVE $531,(color+3*2)
        COPIMOVE $544,(color+4*2)
        COPIMOVE $851,(color+5*2)
        COPIMOVE $a61,(color+6*2)
        COPIMOVE $c82,(color+7*2)
        moveq.l #PART_HEIGHT-1,d4
.nocols
        add.w   d2,d0
        bcc.s   .no256
        COPIMOVE 0,$1fe
.no256
        move.w  d0,d1
        move.b  #$3b,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+

        ;move.l  a0,d1
        ;sub.l   a2,d1
        ;addq.w  #2,d1
        ;move.w  d1,(a3)+
        REPT    10
        COPIMOVE $f0f,color+8*2
        COPIMOVE $0ff,color+8*2
        ENDR

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

bln_create_bars_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        COPIMOVE $6a00,bplcon0

        lea     bln_images_palette(pc),a1
        moveq.l #7-1,d7
        move.w  #color+9*2,d0
.palloop
        move.w  d0,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d0
        dbra    d7,.palloop

        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        move.l  #(BLENDVIEW_WIDTH/8)*BLENDVIEW_HEIGHT,d2
.bplloop
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop

        moveq.l #-2,d3
        move.w  #$51d5,d0
        move.w  #BLENDVIEW_HEIGHT-1,d7
        move.w  #$100,d2

        move.w  d0,(a0)+
        move.w  d3,(a0)+

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperChunkyOffset(a6)

        move.b  #$3b,d0
.cprloop
        add.w   d2,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+

        REPT    10
        COPIMOVE $f0f,color+8*2
        COPIMOVE $0ff,color+8*2
        ENDR
        COPIMOVE 0,$1fe

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

bln_create_hole_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        COPIMOVE $6a00,bplcon0

        COPIMOVE (BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8,bpl1mod
        COPIMOVE (BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8,bpl2mod

        moveq.l #7-1,d7
        move.w  #color+1*2,d0
.palloop2
        move.w  d0,(a0)+
        move.w  #$f0f,(a0)+
        addq.w  #2,d0
        dbra    d7,.palloop2

        lea     bln_images_palette(pc),a1
        moveq.l #7-1,d7
        move.w  #color+9*2,d0
.palloop
        move.w  d0,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d0
        dbra    d7,.palloop

        lea     2*BLENDVIEW_HEIGHT*2(a1),a1

        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        moveq.l #(BLENDVIEW_WIDTH/8),d2
.bplloop
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop

        moveq.l #-2,d3
        move.w  #$51d5,d0
        move.w  #BLENDVIEW_HEIGHT-1,d7
        move.w  #$100,d2

        move.l  a0,d1
        sub.l   a2,d1
        add.w  #4+2+8,d1
        move.w  d1,pd_CopperChunkyOffset(a6)
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        add.w   d2,d0

        COPRMOVE (a1)+,(color+8*2)

        move.w  d0,d1
        move.b  #$21,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+

        COPIMOVE $fff,(color+1*2)
        COPIMOVE $888,(color+2*2)

        COPIMOVE $ff0,(color+3*2)
        COPIMOVE $0ff,(color+4*2)

        COPIMOVE $f0f,(color+5*2)
        COPIMOVE $0f0,(color+6*2)

        COPIMOVE $f80,(color+7*2)
        COPIMOVE $8f8,(color+8*2)

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

bln_create_greetings_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        COPIMOVE $6a00,bplcon0

        COPIMOVE (BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8,bpl1mod
        COPIMOVE (BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8,bpl2mod

        move.l  pd_CurrGreetingsImage(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        moveq.l #(BLENDVIEW_WIDTH/8),d2
.bplloop
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop

        moveq.l #-2,d3
        move.w  #$51d5,d0
        move.w  #$100,d2
        lea     bln_images_palette(pc),a1
        adda.w  pd_CurrGreetingsPalOffset(a6),a1
        move.w  #BLENDVIEW_HEIGHT-1,d7
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        add.w   d2,d0

        COPRMOVE (a1)+,(color+8*2)
        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

bln_create_andyou_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2

        COPIMOVE $1200,bplcon0

        COPIMOVE 0,bpl1mod

        COPIMOVE $7e81,diwstrt
        COPIMOVE $dac1,diwstop
        COPIMOVE $0068,ddfstrt          ; bitplane start
        COPIMOVE $00a0,ddfstop          ; bitplane stop

        move.l  #bln_andyou_image,d0
        move.w  #bplpt+2,(a0)+
        move.w  d0,(a0)+
        move.w  #bplpt,(a0)+
        swap    d0
        move.w  d0,(a0)+

        COPIMOVE $fff,color+1*2

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

bln_create_endlogo_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        COPIMOVE $6a00,bplcon0

        COPIMOVE (ENDLOGO_WIDTH*ENDLOGO_PLANES-ENDLOGO_WIDTH)/8,bpl1mod
        COPIMOVE (ENDLOGO_WIDTH*ENDLOGO_PLANES-ENDLOGO_WIDTH)/8,bpl2mod

        move.l  pd_CurrPlanesPtr(a6),d0
        move.w  #bplpt,d1
        moveq.l #(ENDLOGO_WIDTH/8),d2
        moveq.l #4-1,d7
.bplloop
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop

        move.l  pd_EndLogoBuffer(a6),d0
        add.l   #4*(ENDLOGO_WIDTH/8),d0
        moveq.l #2-1,d7
.bplloop2
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop2

        moveq.l #-2,d3
        lea     pd_EndLogoPalette(a6),a1
        moveq.l #16-1,d7
        move.w  #color,d1
.palloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.palloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

bln_big_circle_rad_forward_update:
        bsr     bln_update_circle_sin_movement
        bsr     bln_update_circle_sin_rel_pos
        move.w  cp_RadPos(a4),d0
        lea     bln_circlerads(pc),a0
        moveq.l #0,d1
.retry
        add.w   pd_FrameInc(a6),d0
        move.b  (a0,d0.w),d1
        bne.s   .nowrap
        sub.w   #6*16,d0
        move.b  (a0,d0.w),d1
.nowrap
        move.w  d0,cp_RadPos(a4)
        cmp.w   cp_Radius(a4),d1
        beq.s   .noupdate
        move.w  d1,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts

;--------------------------------------------------------------------

bln_big_circle_rad_backward_update:
        bsr     bln_update_circle_sin_movement
        bsr     bln_update_circle_sin_rel_pos
        move.w  cp_RadPos(a4),d0
        sub.w   pd_FrameInc(a6),d0
        bmi.s   .endit
        move.w  d0,cp_RadPos(a4)
        lea     bln_circlerads(pc),a0
        moveq.l #0,d1
        move.b  (a0,d0.w),d1
        cmp.w   cp_Radius(a4),d1
        beq.s   .noupdate
        move.w  d1,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts
.endit
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.l  d0,cp_PaintRoutine(a4)
        move.l  d0,cp_FrameRoutine(a4)
.nop
        rts

;--------------------------------------------------------------------

bln_smaller_circle_rad_forward_update:
        bsr     bln_update_circle_sin_movement
        bsr     bln_update_circle_sin_rel_pos
        move.w  cp_RadPos(a4),d0
        lea     bln_circlerads_smaller(pc),a0
        moveq.l #0,d1
.retry
        add.w   pd_FrameInc(a6),d0
        move.b  (a0,d0.w),d1
        bne.s   .nowrap
        sub.w   #4*16,d0
        move.b  (a0,d0.w),d1
.nowrap
        move.w  d0,cp_RadPos(a4)
        cmp.w   cp_Radius(a4),d1
        beq.s   .noupdate
        move.w  d1,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts

;--------------------------------------------------------------------

bln_smaller_circle_rad_backward_update:
        bsr     bln_update_circle_sin_movement
        bsr     bln_update_circle_sin_rel_pos
        move.w  cp_RadPos(a4),d0
        sub.w   pd_FrameInc(a6),d0
        bmi.s   .endit
        move.w  d0,cp_RadPos(a4)
        lea     bln_circlerads_smaller(pc),a0
        moveq.l #0,d1
        move.b  (a0,d0.w),d1
        cmp.w   cp_Radius(a4),d1
        beq.s   .noupdate
        move.w  d1,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts
.endit
        lea     .nop(pc),a0
        move.l  a0,cp_PaintRoutine(a4)
        move.l  a0,cp_FrameRoutine(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.l  d0,cp_CircleInfo(a4)
.nop
        rts

;--------------------------------------------------------------------

bln_small_circle_rad_forward_update:
        bsr     bln_update_circle_sin_movement
        bsr     bln_update_circle_sin_rel_pos
        move.w  cp_RadPos(a4),d0
        lea     bln_circlerads_greets(pc),a0
        moveq.l #0,d1
.retry
        add.w   pd_FrameInc(a6),d0
        move.b  (a0,d0.w),d1
        bne.s   .nowrap
        sub.w   #4*16,d0
        move.b  (a0,d0.w),d1
.nowrap
        move.w  pd_BeatRadAdd(a6),d2
        lsr.w   #2,d2
        add.w   d2,d1
        move.w  d0,cp_RadPos(a4)
        cmp.w   cp_Radius(a4),d1
        beq.s   .noupdate
        move.w  d1,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts

;--------------------------------------------------------------------

bln_small_circle_rad_backward_update:
        bsr     bln_update_circle_sin_movement
        bsr     bln_update_circle_sin_rel_pos
        move.w  cp_RadPos(a4),d0
        sub.w   pd_FrameInc(a6),d0
        bmi.s   .endit
        move.w  d0,cp_RadPos(a4)
        lea     bln_circlerads_greets(pc),a0
        moveq.l #0,d1
        move.b  (a0,d0.w),d1
        cmp.w   cp_Radius(a4),d1
        beq.s   .noupdate
        move.w  d1,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts
.endit
        lea     .nop(pc),a0
        move.l  a0,cp_PaintRoutine(a4)
        move.l  a0,cp_FrameRoutine(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.l  d0,cp_CircleInfo(a4)
.nop
        rts

;--------------------------------------------------------------------

bln_update_circle_sin_movement:
        move.w  pd_FrameInc(a6),d1
        cmp.w   #2,d1
        beq.s   .fast2
        subq.w  #1,d1
        beq.s   .fast1
.loop
        move.l  cp_RelPosSinXSpeed(a4),d0
.floop
        add.l   d0,cp_RelPosSinXOffset(a4)
        dbra    d1,.floop
        rts

.fast1
        move.l  cp_RelPosSinXSpeed(a4),d0
        add.l   d0,cp_RelPosSinXOffset(a4)
        rts

.fast2
        move.l  cp_RelPosSinXSpeed(a4),d0
        add.l   d0,cp_RelPosSinXOffset(a4)
        add.l   d0,cp_RelPosSinXOffset(a4)
        rts

;--------------------------------------------------------------------

bln_update_circle_sin_rel_pos:
        move.l  fw_SinTable(a6),a0
        movem.w cp_RelPosSinXOffset(a4),d0-d5
        and.w   #1023*2,d0
        and.w   #1023*2,d1
        move.w  (a0,d0.w),d0
        move.w  (a0,d1.w),d1
        muls    d2,d0
        muls    d3,d1
        swap    d0
        swap    d1
        add.w   d4,d0
        add.w   d5,d1
        move.w  d0,cp_FgRelPosX(a4)
        move.w  d1,cp_FgRelPosY(a4)
        rts

;--------------------------------------------------------------------

bln_greeting_line_update:
        move.w  pd_FrameInc(a6),d5
        sub.w   d5,cp_GreetingTimeRev(a4)
        bpl.s   .dorad
        move.w  cp_Radius(a4),d4
        beq.s   .noupdate
        sub.w   d5,d4
        cmp.w   #MIN_CIRCLE_SIZE,d4
        blt.s   .kill
        bra.s   .checkmove
.dorad
        move.w  cp_RadPos(a4),d0
        lea     bln_circlerads_greets(pc),a0
        moveq.l #0,d4
        add.w   d5,d0
        move.b  (a0,d0.w),d4
        bne.s   .nowrap
        sub.w   #4*16,d0
        move.b  (a0,d0.w),d4
.nowrap
        move.w  d0,cp_RadPos(a4)
.checkmove
        cmp.w   #9,d4
        blt.s   .nomove
        move.l  cp_RelPosXLong(a4),d0
        move.l  cp_RelPosYLong(a4),d1
        movem.w cp_RelPosXInc(a4),d2/d3
        add.l   d2,d2
        add.l   d2,d2
        add.l   d3,d3
        add.l   d3,d3
        subq.w  #1,d5
.frloop
        add.l   d2,d0
        add.l   d3,d1
        dbra    d5,.frloop
        move.l  d0,cp_RelPosXLong(a4)
        move.l  d1,cp_RelPosYLong(a4)
        swap    d0
        swap    d1
        move.w  d0,cp_FgRelPosX(a4)
        move.w  d1,cp_FgRelPosY(a4)
.nomove
        cmp.w   cp_Radius(a4),d4
        beq.s   .noupdate
        move.w  d4,cp_Radius(a4)
        bra.s   bln_update_circle_pot_info
.noupdate
        rts
.kill   PUTMSG  10,<"%d: Greeting killed (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        subq.w  #1,pd_GreetingCount(a6)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.l  d0,cp_PaintRoutine(a4)
        move.l  d0,cp_FrameRoutine(a4)
        rts

;--------------------------------------------------------------------

bln_load_circle_nop:
        rts

bln_load_circle_eye_1:
        PUTMSG  10,<"%d: Load circle eye 1 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #112,cp_CenterPosX(a4)
        move.w  #51,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  d0,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #13,cp_RelPosSinXSpeed(a4)
        move.w  #14,cp_RelPosSinYSpeed(a4)

        move.w  #60*2,cp_RelPosXRadius(a4)
        move.w  #20*2,cp_RelPosYRadius(a4)
        move.w  #114,cp_RelPosXCenter(a4)
        move.w  #70,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage2(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage2(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_big_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_pos_eye_1_sunset:
        PUTMSG  10,<"%d: Load circle eye sunset 2 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #112,cp_CenterPosX(a4)
        move.w  #62,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  d0,cp_RadPos(a4)
        move.w  #1*8,cp_Pair(a4)
        clr.w   cp_RadPos(a4)
        move.l  #(112-112)*2+(62-51)*BLENDVIEW_WIDTH*2,cp_InvertedOffset(a4)

        move.w  #-15,cp_RelPosSinXSpeed(a4)
        move.w  #12,cp_RelPosSinYSpeed(a4)

        move.w  #20*2,cp_RelPosXRadius(a4)
        move.w  #30*2,cp_RelPosYRadius(a4)
        move.w  #107,cp_RelPosXCenter(a4)
        move.w  #43,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage2(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage2(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage3(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle_invert,cp_PaintRoutine(a4)
        move.l  #bln_smaller_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_pos_eye_2:
        PUTMSG  10,<"%d: Load circle eye 2 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #240,cp_CenterPosX(a4)
        move.w  #126,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  #2*8,cp_Pair(a4)
        move.w  d0,cp_Radius(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #7,cp_RelPosSinXSpeed(a4)
        move.w  #9,cp_RelPosSinYSpeed(a4)

        move.w  #40*2,cp_RelPosXRadius(a4)
        move.w  #60*2,cp_RelPosYRadius(a4)
        move.w  #104,cp_RelPosXCenter(a4)
        move.w  #83,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage2(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage2(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_big_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_pos_eye_2_skin:
        PUTMSG  10,<"%d: Load circle eye skin (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #240,cp_CenterPosX(a4)
        move.w  #117,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  d0,cp_RadPos(a4)
        move.w  #3*8,cp_Pair(a4)
        clr.w   cp_RadPos(a4)
        move.l  #(240-240)*2+(117-126)*BLENDVIEW_WIDTH*2,cp_InvertedOffset(a4)

        move.w  #-15,cp_RelPosSinXSpeed(a4)
        move.w  #12,cp_RelPosSinYSpeed(a4)

        move.w  #20*2,cp_RelPosXRadius(a4)
        move.w  #70*2,cp_RelPosYRadius(a4)
        move.w  #69,cp_RelPosXCenter(a4)
        move.w  #109,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage2(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage2(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage2(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage2(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle_invert,cp_PaintRoutine(a4)
        move.l  #bln_small_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_cham_bg_1:
        PUTMSG  10,<"%d: Load cham bg 1 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #272,cp_CenterPosX(a4)
        move.w  #34,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  #2*8,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #7,cp_RelPosSinXSpeed(a4)
        move.w  #9,cp_RelPosSinYSpeed(a4)

        move.w  #40*2,cp_RelPosXRadius(a4)
        move.w  #40*2,cp_RelPosYRadius(a4)
        move.w  #190,cp_RelPosXCenter(a4)
        move.w  #85,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage2(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage2(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_smaller_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_greets_bg_1:
        PUTMSG  10,<"%d: Load greets bg 1 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #176,cp_CenterPosX(a4)
        move.w  #75,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  #2*8,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #-13,cp_RelPosSinXSpeed(a4)
        move.w  #14,cp_RelPosSinYSpeed(a4)

        move.w  #11*2,cp_RelPosXRadius(a4)
        move.w  #14*2,cp_RelPosYRadius(a4)
        move.w  #27,cp_RelPosXCenter(a4)
        move.w  #106,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage4(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage4(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_small_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts


bln_load_circle_greets_bg_2:
        PUTMSG  10,<"%d: Load greets bg 2 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #128,cp_CenterPosX(a4)
        move.w  #149,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  #0*8,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #-15,cp_RelPosSinXSpeed(a4)
        move.w  #-17,cp_RelPosSinYSpeed(a4)

        move.w  #17*2,cp_RelPosXRadius(a4)
        move.w  #17*2,cp_RelPosYRadius(a4)
        move.w  #111,cp_RelPosXCenter(a4)
        move.w  #149,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage4(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage4(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_small_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_greets_bg_3:
        PUTMSG  10,<"%d: Load greets bg 3 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #80,cp_CenterPosX(a4)
        move.w  #32,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  #3*8,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #-16,cp_RelPosSinXSpeed(a4)
        move.w  #18,cp_RelPosSinYSpeed(a4)

        move.w  #13*2,cp_RelPosXRadius(a4)
        move.w  #13*2,cp_RelPosYRadius(a4)
        move.w  #162,cp_RelPosXCenter(a4)
        move.w  #25,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage4(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage4(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_small_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_greets_bg_4:
        PUTMSG  10,<"%d: Load greets bg 4 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #208,cp_CenterPosX(a4)
        move.w  #28,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  #1*8,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #19,cp_RelPosSinXSpeed(a4)
        move.w  #-15,cp_RelPosSinYSpeed(a4)

        move.w  #10*2,cp_RelPosXRadius(a4)
        move.w  #10*2,cp_RelPosYRadius(a4)
        move.w  #295,cp_RelPosXCenter(a4)
        move.w  #93,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage4(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage4(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_small_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts

bln_load_circle_greets_bg_5:
        PUTMSG  10,<"%d: Load greets bg 5 (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #48,cp_CenterPosX(a4)
        move.w  #118,cp_CenterPosY(a4)
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.w  #1*8,cp_Pair(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

        move.w  #-16,cp_RelPosSinXSpeed(a4)
        move.w  #-17,cp_RelPosSinYSpeed(a4)

        move.w  #10*2,cp_RelPosXRadius(a4)
        move.w  #11*2,cp_RelPosYRadius(a4)
        move.w  #297,cp_RelPosXCenter(a4)
        move.w  #155,cp_RelPosYCenter(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_OriginalImage4(a6),cp_FgImage(a4)
        move.l  pd_TrueColorImage4(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_small_circle_rad_forward_update,cp_FrameRoutine(a4)
        rts


; 23,106 (23) / 111,149 (30) / 162,25 (25) / 295,93 (24) / 297,155 (22)
;--------------------------------------------------------------------

bln_load_next_greeting:
        move.l  pd_GreetingPosPtr(a6),a0
        move.w  (a0)+,d0
        beq.s   .reallykill
        move.w  (a0)+,d1
        move.w  (a0)+,d2
        PUTMSG  10,<"%d: Next greeting at %d,%d Pair: %d">,fw_FrameCounterLong(a6),d0,d1,d2
        move.w  d0,cp_CenterPosX(a4)
        move.w  d1,cp_CenterPosY(a4)
        move.w  d2,cp_Pair(a4)
        move.l  a0,pd_GreetingPosPtr(a6)

        moveq.l #0,d0
        move.w  #MAX_CIRCLE_SIZE,cp_Radius(a4)
        move.w  d0,cp_RadPos(a4)
        move.l  d0,cp_InvertedOffset(a4)

.retry
        move.l  pd_GreetingLinePtr(a6),a0
        movem.w (a0)+,d0-d4
        PUTMSG  10,<"%d: Greeting from %d,%d to %d,%d, shift %d">,fw_FrameCounterLong(a6),d0,d1,d2,d3,d4

        move.w  d0,cp_FgRelPosX(a4)
        beq.s   .kill
        move.w  d1,cp_FgRelPosY(a4)

        move.l  a0,pd_GreetingLinePtr(a6)

        swap    d0
        swap    d1
        move.l  d0,cp_RelPosXLong(a4)
        move.l  d1,cp_RelPosYLong(a4)

        swap    d2
        swap    d3
        sub.l   d0,d2
        sub.l   d1,d3

        moveq.l #0,d0
        bset    d4,d0

        addq.w  #2,d4

        asr.l   d4,d2
        asr.l   d4,d3
        move.w  d2,cp_RelPosXInc(a4)
        move.w  d3,cp_RelPosYInc(a4)

        move.w  d0,cp_GreetingTimeRev(a4)
        add.w   #15,d0
        move.w  d0,cp_TimeLeft(a4)

        move.l  pd_OriginalImage3(a6),cp_BgImage(a4)
        move.l  pd_TrueColorImage3(a6),cp_BgTCImage(a4)
        move.l  pd_CurrGreetingsImage(a6),cp_FgImage(a4)
        move.l  pd_CurrGreetingsTCImage(a6),cp_FgTCImage(a4)
        move.l  #bln_draw_stenciled_circle,cp_PaintRoutine(a4)
        move.l  #bln_greeting_line_update,cp_FrameRoutine(a4)
        rts
.kill   tst.w   d1
        beq.s   .reallykill
        addq.l  #2,pd_GreetingLinePtr(a6)
        move.l  pd_OriginalImage5(a6),pd_CurrGreetingsImage(a6)
        move.l  pd_TrueColorImage5(a6),pd_CurrGreetingsTCImage(a6)
        bra.s   .retry

.reallykill
        moveq.l #0,d0
        move.w  d0,cp_Radius(a4)
        move.l  d0,cp_PaintRoutine(a4)
        move.l  d0,cp_FrameRoutine(a4)
        rts

;--------------------------------------------------------------------

bln_reverse_big_circle_to_backward:
        PUTMSG  10,<"%d: Reversing big circle (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.l  #bln_big_circle_rad_backward_update,cp_FrameRoutine(a4)
        rts

;--------------------------------------------------------------------

bln_reverse_smaller_circle_to_backward:
        PUTMSG  10,<"%d: Reversing smaller circle (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.l  #bln_smaller_circle_rad_backward_update,cp_FrameRoutine(a4)
        rts

;--------------------------------------------------------------------

bln_reverse_small_circle_to_backward:
        PUTMSG  10,<"%d: Reversing smaller circle (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.l  #bln_small_circle_rad_backward_update,cp_FrameRoutine(a4)
        rts

;********************************************************************

bln_blend_image_2_filename:
        dc.b    "cHAMeleon.raw",0
bln_blend_image_3_filename:
        dc.b    "Sunset.raw",0
bln_blend_image_4_filename:
        dc.b    "Greets1.raw",0
bln_blend_image_5_filename:
        dc.b    "Greets2.raw",0
        even

bln_bar_patterns:
        ;dc.b    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
        ;dc.b    19,0,18,1,17,2,16,3,15,4,14,5,13,6,12,7,11,8,10,9
        dc.b    0,2,4,6,8,10,12,14,16,18,19,17,15,13,11,9,7,5,3,1
        ;dc.b    19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
        ;dc.b    9,10,8,11,7,12,6,13,5,14,4,15,3,16,2,17,1,18,0,19
        ;dc.b    0,1,2,3,4,5,6,7,8,9,19,18,17,16,15,14,13,12,11,10
        ;dc.b    10,11,12,13,14,15,16,17,18,19,9,8,7,6,5,4,3,2,1,0
        even

bln_a_part_sequence:
        dc.w    pd_OriginalImage1,pd_TrueColorImage1
        dc.l    bln_load_new_block_fade_in
        dc.w    -6,bln_a_part_rnd_seq_row_1-bln_a_part_sequence
        dc.w    -3,bln_a_part_rnd_seq_row_2-bln_a_part_sequence
        dc.w    -9,bln_a_part_rnd_seq_row_3-bln_a_part_sequence
        dc.w    0,bln_a_part_rnd_seq_row_4-bln_a_part_sequence
        dc.w    -15,bln_a_part_rnd_seq_row_5-bln_a_part_sequence
        dc.w    -12,bln_a_part_rnd_seq_row_6-bln_a_part_sequence

bln_b_part_sequence:
        dc.w    pd_OriginalImage2,pd_TrueColorImage2
        dc.l    bln_load_new_block_fade_out_and_in
        dc.w    -12,bln_a_part_rnd_seq_row_1-bln_b_part_sequence
        dc.w    0,bln_a_part_rnd_seq_row_2-bln_b_part_sequence
        dc.w    -24,bln_a_part_rnd_seq_row_3-bln_b_part_sequence
        dc.w    -18,bln_a_part_rnd_seq_row_4-bln_b_part_sequence
        dc.w    -30,bln_a_part_rnd_seq_row_5-bln_b_part_sequence
        dc.w    -6,bln_a_part_rnd_seq_row_6-bln_b_part_sequence

bln_a_part_rnd_seq_row_1:
        dc.b    4,7,0,1,8,9,3,2,6,5,-1
        even
bln_a_part_rnd_seq_row_2:
        dc.b    5,0,4,3,9,8,7,2,6,1,-1
        even
bln_a_part_rnd_seq_row_3:
        dc.b    9,1,7,8,3,0,4,6,2,5,-1
        even
bln_a_part_rnd_seq_row_4:
        dc.b    1,2,8,3,9,4,5,7,0,6,-1
        even
bln_a_part_rnd_seq_row_5:
        dc.b    6,1,2,0,9,3,4,7,5,8,-1
        even
bln_a_part_rnd_seq_row_6:
        dc.b    8,6,3,1,7,0,5,4,9,2,-1
        even

bln_fade_in_sequence:
        dc.l    bln_blit_intro_block_fade_in_0
        dc.l    bln_blit_intro_block_fade_in_1
        REPT    15
        dc.l    bln_blit_intro_block_fade_in_2
        ENDR
        dc.l    bln_blit_intro_block_final
        dc.l    bln_blit_intro_block_final
        dc.l    bln_load_next_seq_part_in

bln_fade_out_in_sequence:
        dc.l    bln_blit_intro_block_fade_out_0
        REPT    13
        dc.l    bln_blit_intro_block_fade_out_1
        ENDR
        dc.l    bln_blit_intro_block_fade_out_1_change_dir
        dc.l    bln_blit_intro_block_fade_in_0
        dc.l    bln_blit_intro_block_fade_in_1
        REPT    15
        dc.l    bln_blit_intro_block_fade_in_2
        ENDR
        dc.l    bln_blit_intro_block_final
        dc.l    bln_blit_intro_block_final
        dc.l    bln_load_next_seq_part_out_in

;--------------------------------------------------------------------

bln_circle_scripts:
        dc.w    bln_circle1_script-*
        dc.w    bln_circle2_script-*
        dc.w    bln_circle3_script-*
        dc.w    bln_circle4_script-*
        dc.w    bln_circle5_script-*
        dc.w    bln_circle6_script-*
        dc.w    0

bln_circle1_script:
        dc.w    375,bln_load_circle_eye_1-*
        dc.w    281,bln_reverse_big_circle_to_backward-*
        ; 656
        dc.w    187,bln_load_circle_greets_bg_3-*
        dc.w    0

bln_circle2_script:
        dc.w    93,bln_load_circle_nop-*
        dc.w    187,bln_load_circle_pos_eye_1_sunset-*
        dc.w    281,bln_reverse_smaller_circle_to_backward-*
        ; 561
        dc.w    187,bln_load_circle_greets_bg_4-*
        dc.w    0

bln_circle3_script:
        dc.w    187,bln_load_circle_nop-*
        dc.w    328,bln_load_circle_pos_eye_2-*
        dc.w    234,bln_reverse_big_circle_to_backward-*
        ; 749
        dc.w    0

bln_circle4_script:
        dc.w    281,bln_load_circle_nop-*
        dc.w    93,bln_load_circle_pos_eye_2_skin-*
        dc.w    187,bln_reverse_small_circle_to_backward-*
        ; 561
        dc.w    187,bln_load_circle_greets_bg_5-*
        dc.w    0

bln_circle5_script:
        dc.w    375,bln_load_circle_nop-*
        dc.w    184,bln_load_circle_cham_bg_1-*
        dc.w    190,bln_reverse_smaller_circle_to_backward-*
        ; 749
        dc.w    187,bln_load_circle_greets_bg_1-*
        dc.w    0

bln_circle6_script:
        dc.w    469,bln_load_circle_nop-*
        ; 469
        dc.w    197,bln_load_circle_greets_bg_2-*
        dc.w    0

;--------------------------------------------------------------------

bln_circle_greetings_scripts:
        dc.w    bln_circle_greet1_script-*
        dc.w    bln_circle_greet2_script-*
        dc.w    bln_circle_greet3_script-*
        dc.w    bln_circle_greet4_script-*
        dc.w    bln_circle_greet5_script-*
        dc.w    bln_circle_greet6_script-*
        dc.w    0

bln_circle_greet1_script:
        dc.w    47,bln_load_circle_nop-*
        dc.w    187,bln_reverse_smaller_circle_to_backward-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    0

bln_circle_greet2_script:
        dc.w    94,bln_load_circle_nop-*
        dc.w    187,bln_reverse_smaller_circle_to_backward-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    0

bln_circle_greet3_script:
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    0

bln_circle_greet4_script:
        dc.w    187,bln_reverse_smaller_circle_to_backward-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    0

bln_circle_greet5_script:
        dc.w    141,bln_load_circle_nop-*
        dc.w    187,bln_reverse_smaller_circle_to_backward-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    1,bln_load_next_greeting-*
        dc.w    0

bln_circle_greet6_script:
        dc.w    187,bln_load_circle_nop-*
        dc.w    187,bln_reverse_smaller_circle_to_backward-*
        dc.w    0

        dc.w    $000 ; is required for true color image decoding
bln_images_palette:
        include "../data/blend/fiveimg_ham.pal.asm"

bln_leaves_tc_10:
        incbin  "../data/blend/leavestc_10.raw"

bln_endlogo_palette:
        include  "../data/blend/PLT_DSRLogo01c_ham.pal.asm"

        dc.l    0
bln_circlerads:
        include "circlerads.asm"
        dc.l    0
bln_circlerads_smaller:
        include "circlerads2.asm"
        dc.l    0
bln_circlerads_greets:
        include "circleradsgreets.asm"
        dc.l    0

bln_greets_positions:
        REPT    3
        dc.w    144,24,2*8
        dc.w    288,64,0*8
        dc.w    192,120,2*8
        dc.w    64,77,1*8
        dc.w    272,145,3*8
        dc.w    128,105,3*8
        dc.w    256,93,0*8

        dc.w    128,149,0*8
        dc.w    176,73,2*8
        dc.w    80,35,3*8
        dc.w    208,24,1*8
        dc.w    48,118,1*8
        ENDR
        dc.w    0

bln_greets_lines:
        ; greetings page 1, 18
        dc.w    25,48,79,17,7       ; Plush
        dc.w    17,53,218,168,8     ; Dead Hackers Society
        dc.w    15,68,66,97,7       ; Istari
        dc.w    22,140,85,102,7     ; Rebels
        dc.w    20,157,92,117,7     ; Nuance
        dc.w    102,27,163,60,7     ; Melon
        dc.w    93,36,154,74,7      ; Insane
        dc.w    72,46,158,95,7      ; Alcatraz
        dc.w    67,61,229,155,8     ; Five Finger Punch
        dc.w    143,143,173,160,6   ; TBL
        dc.w    162,59,251,9,7      ; Logicoma
        dc.w    168,74,240,32,7     ; Fnuque
        dc.w    159,98,283,26,8     ; Focus Design
        dc.w    168,113,304,32,8    ; Batman Group
        dc.w    219,169,292,128,7   ; Loonies
        dc.w    231,92,283,123,7    ; Noice
        dc.w    221,106,266,134,6   ; Void
        dc.w    263,73,311,46,6     ; SMFX
        dc.w    0

        ; greetings page 2, 17
        dc.w    13,158,90,112,7     ; Proxima
        dc.w    26,48,191,144,8     ; Software Failure
        dc.w    20,63,183,157,8     ; Attention Whore
        dc.w    21,170,101,126,7    ; Offence
        dc.w    31,15,177,100,8     ; Moods Plateau
        dc.w    74,58,182,121,7     ; Planet Jazz
        dc.w    82,28,182,85,7      ; Resistance
        dc.w    105,128,177,171,7   ; Oxyron
        dc.w    133,47,186,13,7     ; Abyss
        dc.w    177,74,272,17,7     ; Nectarine
        dc.w    183,86,283,30,7     ; Jumalauta
        dc.w    182,121,289,61,7    ; Spaceballs
        dc.w    182,156,284,98,7    ; Nah-Kolor
        dc.w    187,102,307,31,7    ; Spreadpoint
        dc.w    193,170,225,150,6   ; TEK
        dc.w    219,119,297,72,7    ; Cocoon
        dc.w    243,128,307,168,7   ; Lemon.
        dc.w    0
        dc.w    0

        IFND    FW_DEMO_PART
        dc.w    1 ; avoid hunk shortening that leaves dirty memory on kick 1.3
        ENDC

;********************************************************************

        section "bln_copper",data,chip

bln_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$5281          ; window start
        COP_MOVE diwstop,$06c1          ; window stop
        COP_MOVE ddfstrt,$0038          ; bitplane start
bln_ddfstop:
        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00
bln_fmode:
        COP_MOVE fmode,$0000            ; fixes the aga modulo problem

        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon1,$0000
        COP_MOVE bplcon2,$0024          ; turn off all bitplanes, set scroll values to 0, sprites in front
        ;COP_MOVE bpl1mod,(BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8
        ;COP_MOVE bpl2mod,(BLENDVIEW_WIDTH*BLENDVIEW_PLANES-BLENDVIEW_WIDTH)/8
        COP_MOVE bpl1mod,0
        COP_MOVE bpl2mod,0

bln_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

; This is not supposed to be in chip, but we need to balance out chip and fast mem usage
bln_circleinfo:
        include "circleinfo.asm"
        dc.w    0

bln_andyou_image:
        incbin  "../data/blend/andyou_128x92x2.BPL"

bln_blend_image_1:
        incbin  "../data/blend/fiveimg1_ham.raw"

        IFND    FW_DEMO_PART
        section "bln_cat",data,chip
bln_blend_image_2:
        incbin  "../data/blend/fiveimg2_ham.raw"
bln_blend_image_3:
        incbin  "../data/blend/fiveimg3_ham.raw"
bln_blend_image_4:
        incbin  "../data/blend/fiveimg4_ham.raw"
bln_blend_image_5:
        incbin  "../data/blend/fiveimg5_ham.raw"
bln_endlogo_image:
        incbin  "../data/blend/PLT_DSRLogo01c_ham.raw"

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