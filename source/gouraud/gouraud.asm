; TODOs:
; - Fix pixel errors at border
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
FW_MUSIC_PLAYER_CHOICE      = 2 ; 0 = None, 1 = LSP, 2 = LSP_CIA, 3 = P61A, 4 = Pretracker
FW_LMB_EXIT_SUPPORT         = 1 ; allows abortion of intro with LMB
FW_MULTIPART_SUPPORT        = 0 ; DO NOT CHANGE (not supported for standalone mode)
FW_DYNAMIC_MEMORY_SUPPORT   = 1 ; enable dynamic memory allocation. Otherwise, use fw_ChipMemStack/End etc fields.
FW_MAX_MEMORY_STATES        = 4 ; the amount of memory states
FW_TOP_BOTTOM_MEM_SECTIONS  = 0 ; allow allocations from both sides of the memory
FW_64KB_PAGE_MEMORY_SUPPORT = 0 ; allow allocation of chip memory that doesn't cross the 64 KB page boundary
FW_MULTITASKING_SUPPORT     = 1 ; enable multitasking
FW_ROUNDROBIN_MT_SUPPORT    = 0 ; enable fair scheduling among tasks with same priority
FW_BLITTERTASK_MT_SUPPORT   = 0 ; enable single parallel task during large blits
FW_MAX_VPOS_FOR_BG_TASK     = 300 ; max vpos that is considered to be worth switching to a background task, if any
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

ENABLE_PART_MUSIC           = 0
PART_MUSIC_START_POS        = 0

        ENDC

GOURAUD_WIDTH      = 128
GOURAUD_PLANES     = 4

BENDIT_WIDTH    = 128
BENDIT_HEIGHT   = 128

CUBE_PRECALC_NUM = 16

NUM_RUBBER_FRAMES   = 33

CUBE_WIDTH      = 128
CUBE_HEIGHT     = 128
CUBE_PLANES     = 4
CUBE_X_OFFSET   = 0
CUBE_Y_OFFSET   = 0
CUBE_Y_CLIP     = 0

CUBE_MAX_SIZE   = 6400
GOURAUD_Z_DIST  = 182
CULLING_EXT     = 128
GOURAUD_Z_ADD   = 8192+1000      ; 8192 is currently safe lower limit, 2*8192 is safe upper limit

CUBE_BUF_WIDTH  = 128

gouraudColShift = 10
gouraudErrShift = 6

NUM_BQ_LINES    = 64

COP_PREAMBLE_INST   = 2 ; wait and bplcon0
COP_POST_INST       = 3 ; wait, 8x(sprctl + sprpos)
COP_INST_PER_LINE   = 2 ; bplptl, cop2lc, cop2lc, wait, 40 colors, skip, copjmp
COP_LIST_SIZE       = (500)*4

CHIPMEM_SIZE = ((CUBE_BUF_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES*3)+((CUBE_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES*NUM_RUBBER_FRAMES)+COP_LIST_SIZE*2
FASTMEM_SIZE = CUBE_PRECALC_NUM*cd_SIZEOF

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

;    - CHIP BSS   2 x 128 x 128 x 4 =  16384 (DB)
;    - CHIP BSS   3 x 128 x 128 x 4 =  24576 (3 line buffers for cube)
;    - CHIP BSS  32 x 128 x 128 x 4 = 262144 (Rubber buffers)
;
;    - FAST BSS        32 x 1424    =  45568 (Cube preprocessing) 12+3*3*2*2+8*3*2+8*2*2+12*(11*4+4+8*2)


        include "../framework/framework.i"

    STRUCTURE   BQLine,bq_SIZEOF
        ULONG   bql_BltCon01
        APTR    bql_BltCPt
        UWORD   bql_BltBMod
        UWORD   bql_BltAMod
        UWORD   bql_BltAPtLo
        APTR    bql_BltDPt
        UWORD   bql_BltSize
        LABEL   bql_SIZEOF

    STRUCTURE   BQFillCube,bq_SIZEOF
        ULONG   bqfc_BltCon01
        UWORD   bqfc_BltAMod
        UWORD   bqfc_BltDMod
        APTR    bqfc_BltAPt
        APTR    bqfc_BltDPt
        UWORD   bqfc_BltSize
        LABEL   bqfc_SIZEOF

    STRUCTURE   BQClear,bq_SIZEOF
        ULONG   bqc_BltCon01
        APTR    bqc_BltDPt
        UWORD   bqc_BltDMod
        UWORD   bqc_BltCDat
        UWORD   bqc_BltSize
        LABEL   bqc_SIZEOF

   STRUCTURE    CubeData,0
        ULONG   cd_PlanesToDraw
        UWORD   cd_LinesToDraw
        UWORD   cd_InnerLines
        STRUCT  cd_CubeNormals,3*3*2*2
        STRUCT  cd_Coords,8*3*2
        STRUCT  cd_ProjCoords,8*2*2
        STRUCT  cd_IntCubeLines,12*il_SIZEOF
        LABEL   cd_SIZEOF

    STRUCTURE   IntCubeLine,0
        STRUCT  il_Coords,22*4              ; must be first
        UWORD   il_NumCoords
        UBYTE   il_Flipped
        UBYTE   il_DzNeg

        UWORD   il_FromCoord
        UWORD   il_ToCoord
        UWORD   il_FromX
        UWORD   il_FromY
        UWORD   il_ToX
        UWORD   il_ToY
        UWORD   il_FromZ
        UWORD   il_ToZ
        LABEL   il_SIZEOF

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_LastPlanesPtr
        APTR    pd_CurrTransPtr
        APTR    pd_LastTransPtr
        APTR    pd_CurrCubeLinePtr
        APTR    pd_LastCubeLinePtr
        APTR    pd_LastLastCubeLinePtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        UBYTE   pd_CopListToggle
        UBYTE   pd_DbToggle
        UBYTE   pd_CubeBufToggle
        ALIGNWORD

        UWORD   pd_PartCountDown

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        APTR    pd_RubberBuffer
        APTR    pd_CubeLineBuffer1          ; ds.w    (CUBE_BUF_WIDTH/16)*CUBE_HEIGHT*CUBE_PLANES
        APTR    pd_CubeLineBuffer2          ; ds.w    (CUBE_BUF_WIDTH/16)*CUBE_HEIGHT*CUBE_PLANES
        APTR    pd_CubeLineBuffer3          ; ds.w    (CUBE_BUF_WIDTH/16)*CUBE_HEIGHT*CUBE_PLANES

        UWORD   pd_ScreenSinXOffset
        UWORD   pd_ScreenSinYOffset
        WORD    pd_ScreenX
        WORD    pd_ScreenY

        ULONG   pd_IntroFrameOffset
        ULONG   pd_RubberFrameOffset
        UWORD   pd_NumRubberFrames

        UWORD   pd_BenditYPos
        BOOL    pd_BenditKilled

        WORD    pd_Ax           ; order may not be changed! (movem)
        WORD    pd_Ay
        WORD    pd_Az
        WORD    pd_AxSpeed
        WORD    pd_AySpeed
        WORD    pd_AzSpeed
        UWORD   pd_CubeSize
        WORD    pd_CubeSizeDir

        BOOL    pd_QuitAsyncTask
        UWORD   pd_CubeSinePos
        UWORD   pd_CubeCosPos
        UWORD   pd_CubeCullingValue

        APTR    pd_CubeSceneRoutinePtr
        APTR    pd_CubeDataReadPtr
        APTR    pd_CubeDataWritePtr
        UWORD   pd_CalculatedCubeFrames
        UWORD   pd_PrecalculatedFrames
        APTR    pd_CubeScriptPointer

        APTR    pd_CubeDataPtr
        APTR    pd_CubePrecalcBuffer        ; ds.b    cd_SIZEOF*CUBE_PRECALC_NUM
        APTR    pd_CubePrecalcBufferEnd

        STRUCT  pd_BQLineInit,bq_SIZEOF
        STRUCT  pd_BQLines,NUM_BQ_LINES*bql_SIZEOF
        STRUCT  pd_BQFillCube,bqfc_SIZEOF
        STRUCT  pd_BQClearLineBuffer,bqc_SIZEOF

        STRUCT  pd_RubberPalette,32*cl_SIZEOF
        STRUCT  pd_BenditSprites,8*4

        STRUCT  pd_CubeCalcTask,ft_SIZEOF

        STRUCT  pd_LinesFromBuffer,NUM_BQ_LINES*2*2
        STRUCT  pd_LinesToBuffer,NUM_BQ_LINES*2*2
        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD      FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        move.w  #$000,color(a5)
        bsr     gou_init

        lea     gou_async_calc_task(pc),a0
        lea     pd_CubeCalcTask(a6),a1
        CALLFW  AddTask

        lea     gou_copperlist,a0
        CALLFW  SetCopper

        bsr     gou_clear_cube_line_buffer

        REPT    2
        bsr     gou_flip_db_frame
        bsr     gou_clear_cube_line_buffer
        ENDR

        bsr     gou_clear_rubber_buffers

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        move.l  #part_music_data,fw_MusicData(a6)
        move.l  #part_music_smp,fw_MusicSamples(a6)
        CALLFW  StartMusic
        ENDC
        ELSE
        CALLFW  StartMusic
        ENDC

        bsr     gou_intro
        bsr     gou_main

        CALLFW  SetBaseCopper

        lea     pd_CubeCalcTask(a6),a1
        CALLFW  RemTask
        rts

;--------------------------------------------------------------------

gou_init:
        bsr     gou_init_vars
        bsr     gou_init_blitter_queue

        CALLFW  SetBlitterQueueSingleFrame

        rts

;--------------------------------------------------------------------

gou_init_vars:
        move.l  #gou_cube_advance_scene_standard_movement,pd_CubeSceneRoutinePtr(a6)
        move.w  #4*2,pd_AxSpeed(a6)
        move.w  #-5*2,pd_AySpeed(a6)
        move.w  #-7*2,pd_AzSpeed(a6)
        move.w  #CUBE_MAX_SIZE,pd_CubeSize(a6)
        move.w  #((CUBE_MAX_SIZE*CUBE_MAX_SIZE)>>8)/GOURAUD_Z_DIST+CULLING_EXT,pd_CubeCullingValue(a6)

        move.w  #237*2,pd_Ax(a6)
        move.w  #32*2,pd_Ay(a6)
        move.w  #128*2,pd_Az(a6)

        move.w  #300,pd_CubeCosPos(a6)

        move.l  #CUBE_PRECALC_NUM*cd_SIZEOF,d0
        CALLFW  AllocFast
        move.l  a0,pd_CubePrecalcBuffer(a6)
        move.l  a0,pd_CubeDataWritePtr(a6)
        move.l  a0,pd_CubeDataReadPtr(a6)
        move.l  a0,pd_CubeDataPtr(a6)

        add.l   #CUBE_PRECALC_NUM*cd_SIZEOF,a0
        move.l  a0,pd_CubePrecalcBufferEnd(a6)

        move.l  #(COP_LIST_SIZE*2),d0
        CALLFW  AllocChip
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)
        lea     COP_LIST_SIZE(a0),a0
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        move.l  #(CUBE_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES*NUM_RUBBER_FRAMES,d0
        CALLFW  AllocChip
        move.l  a0,pd_RubberBuffer(a6)

        move.l  #((CUBE_BUF_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES)*3,d0
        CALLFW  AllocChip
        move.l  a0,pd_CubeLineBuffer1(a6)
        move.l  a0,pd_CurrCubeLinePtr(a6)

        lea     ((CUBE_BUF_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES)(a0),a0
        move.l  a0,pd_CubeLineBuffer2(a6)
        move.l  a0,pd_LastCubeLinePtr(a6)

        lea     ((CUBE_BUF_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES)(a0),a0
        move.l  a0,pd_CubeLineBuffer3(a6)
        move.l  a0,pd_LastLastCubeLinePtr(a6)

        lea     gou_gray_shuffle(pc),a2
        lea     gou_gray_palette(pc),a0
        lea     gou_sorted_palette(pc),a1
        moveq.l #16-1,d7
.palloop
        move.w  (a2)+,d0
        move.w  (a1)+,(a0,d0.w)
        dbra    d7,.palloop

        lea     gou_gray_shuffle(pc),a2
        lea     gou_gray_zebra_palette(pc),a0
        lea     gou_zebra_palette(pc),a1
        moveq.l #16-1,d7
.palloop2
        move.w  (a2)+,d0
        move.w  (a1)+,(a0,d0.w)
        dbra    d7,.palloop2

        lea     pd_BenditSprites(a6),a1
        lea     gou_bendit_sprite,a3
        move.l  a3,a2
        moveq.l #(BENDIT_WIDTH/16)-1,d7
.sprloop
        move.l  a3,a0
        adda.w  (a2)+,a0
        move.l  d0,(a0)
        move.l  a0,(a1)+
        dbra    d7,.sprloop

        move.w  #BENDIT_HEIGHT,pd_BenditYPos(a6)

        rts

;--------------------------------------------------------------------

gou_init_blitter_queue:
        lea     gou_bq_InitLineDraw(pc),a0
        move.l  a0,pd_BQLineInit+bq_Routine(a6)

        lea     gou_bq_LineDraw(pc),a0
        lea     pd_BQLines(a6),a1
        moveq.l #NUM_BQ_LINES-1,d7
.bqlloop
        move.l  a0,bq_Routine(a1)
        move.l  #blitter_temp_output_word,bql_BltDPt(a1)
        lea     bql_SIZEOF(a1),a1
        dbra    d7,.bqlloop

        lea     pd_BQFillCube(a6),a1
        lea     gou_bq_FillCube(pc),a0
        move.l  a0,bq_Routine(a1)
        move.l  #((BLTEN_AD|BLT_A)<<16)|BLTCON1F_EFE|BLTCON1F_DESC,bqfc_BltCon01(a1)
        ;move.l  #((BLTEN_AD|(~BLT_A&$ff))<<16)|BLTCON1F_EFE|BLTCON1F_DESC,bqfc_BltCon01(a1)
        move.l  #(((CUBE_BUF_WIDTH-CUBE_WIDTH)/8)<<16)|((GOURAUD_WIDTH-CUBE_WIDTH)/8),bqfc_BltAMod(a1)
        move.w  #((CUBE_WIDTH)>>4)|(((CUBE_HEIGHT-2*CUBE_Y_CLIP)*CUBE_PLANES)<<6),bqfc_BltSize(a1)

        lea     pd_BQClearLineBuffer(a6),a1
        lea     gou_bq_Clear(pc),a0
        move.l  a0,bq_Routine(a1)
        move.l  #((BLTEN_D|BLT_C)<<16),bqc_BltCon01(a1)
        move.w  #(CUBE_BUF_WIDTH-CUBE_WIDTH)/8,bqc_BltDMod(a1)
        clr.w   bqc_BltCDat(a1)
        move.w  #((CUBE_WIDTH)>>4)|(((CUBE_HEIGHT-2*CUBE_Y_CLIP)*CUBE_PLANES)<<6),bqc_BltSize(a1)

        rts

;--------------------------------------------------------------------

gou_intro:
        move.w  #1,pd_PartCountDown(a6)

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

        PUTMSG  10,<"Main Frame Start %ld">,fw_FrameCounterLong(a6)

.loop
        BLTWAIT
        CALLFW  TriggerBlitterQueue

        bsr     gou_flip_copperlists
        bsr     gou_flip_db_frame
        bsr     gou_flip_cube_buffer

        bsr     gou_update_screen_pos

        move.l  pd_CubeDataPtr(a6),a1
        bsr     gou_interpolate_outer_cube_lines

        moveq.l #16,d0
        lea     pd_RubberPalette(a6),a1
        CALLFW  DoFadePaletteStep

        move.l  pd_CurrCopListPtr(a6),a0
        move.l  pd_IntroFrameOffset(a6),d4
        bsr     gou_create_main_copperlist_nosprites

        CALLFW  JoinBlitterQueue

        bsr     gou_create_blitter_queue
        CALLFW  TerminateBlitterQueue

        bsr     gou_update_copper_list_pointers

        CALLFW  CheckMusicScript

        CALLFW  VSyncWithTask
        tst.w   pd_PartCountDown(a6)
        bne     .loop

        add.l   #$012302d3,pd_ScreenSinXOffset(a6)
        rts

.script
        dc.w    0*6,.flash-*
        dc.w    4*6,.flash-*
        dc.w    8*6,.quitintro-*
        dc.w    0

.flash
        add.l   #$015102d3,pd_ScreenSinXOffset(a6)
        moveq.l #16,d0
        lea     gou_gray_palette(pc),a0
        lea     pd_RubberPalette(a6),a1
        CALLFW  InitPaletteLerp

        moveq.l #16,d0
        moveq.l #16,d1
        lea     gou_mauve_palette(pc),a0
        lea     pd_RubberPalette(a6),a1
        CALLFW  FadePaletteTo

        move.l  pd_RubberFrameOffset(a6),pd_IntroFrameOffset(a6)

        rts

.quitintro
        clr.w   pd_PartCountDown(a6)
        rts

;--------------------------------------------------------------------

gou_main:
        move.w  #1,pd_PartCountDown(a6)

        move.w  #$fff,d0
        move.w  d0,color+17*2(a5)
        move.w  d0,color+21*2(a5)
        move.w  d0,color+25*2(a5)
        move.w  d0,color+29*2(a5)
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

        st      pd_BenditKilled(a6)

        moveq.l #16,d0
        lea     gou_gray_palette(pc),a0
        lea     pd_RubberPalette(a6),a1
        CALLFW  InitPaletteLerp

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

.loop
        BLTWAIT
        CALLFW  TriggerBlitterQueue

        bsr     gou_flip_copperlists
        bsr     gou_flip_db_frame
        bsr     gou_flip_cube_buffer

        bsr     gou_update_screen_pos

        cmp.w   #NUM_RUBBER_FRAMES,pd_NumRubberFrames(a6)
        beq.s   .norubadd
        addq.w  #1,pd_NumRubberFrames(a6)
.norubadd

        move.l  pd_CubeDataPtr(a6),a1
        bsr     gou_interpolate_outer_cube_lines

        bsr     gou_update_bendit_sprites

        moveq.l #16,d0
        lea     pd_RubberPalette(a6),a1
        CALLFW  DoFadePaletteStep

        move.l  pd_CurrCopListPtr(a6),a0
        move.l  pd_RubberFrameOffset(a6),d4
        bsr     gou_create_main_copperlist

        CALLFW  JoinBlitterQueue

        bsr     gou_create_blitter_queue
        CALLFW  TerminateBlitterQueue

        bsr     gou_update_copper_list_pointers

        CALLFW  CheckMusicScript

        CALLFW  VSyncWithTask
        tst     pd_PartCountDown(a6)
        bne     .loop

        st      pd_QuitAsyncTask(a6)
        rts

.script
        dc.w    48+32*6,.benditon-*
        dc.w    432,.benditoff-*
        dc.w    432+32*6,.fadezebra-*
        dc.w    (8+3*64)*6-32-15,.startclearing-*
        dc.w    (8+3*64)*6-15,.quitmain-*
        dc.w    0

.benditon
        clr.w   pd_BenditKilled(a6)
        rts

.benditoff
        st      pd_BenditKilled(a6)
        rts

.fadezebra
        move.w  #-9*2,pd_AxSpeed(a6)
        move.w  #-5*2,pd_AySpeed(a6)
        move.w  #6*2,pd_AzSpeed(a6)

        moveq.l #16,d0
        moveq.l #16,d1
        lea     gou_gray_zebra_palette(pc),a0
        lea     pd_RubberPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.startclearing
        move.l  #((BLTEN_D)<<16)|BLTCON1F_DESC,pd_BQFillCube+bqfc_BltCon01(a6)
        moveq.l #16,d0
        moveq.l #32,d1
        lea     gou_black_palette(pc),a0
        lea     pd_RubberPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.quitmain
        clr.w   pd_PartCountDown(a6)
        rts

;--------------------------------------------------------------------

gou_update_screen_pos:
        move.l  fw_SinTable(a6),a0
        move.w  pd_ScreenSinXOffset(a6),d0
        move.w  pd_ScreenSinYOffset(a6),d1
        addq.w  #8,d0
        add.w   #11,d1
        move.w  d0,pd_ScreenSinXOffset(a6)
        move.w  d1,pd_ScreenSinYOffset(a6)
        and.w   #1023*2,d0
        and.w   #1023*2,d1
        move.w  (a0,d0.w),d0
        move.w  (a0,d1.w),d1
        muls    #176*2,d0
        muls    #52*2,d1
        swap    d0
        swap    d1
        move.w  d0,pd_ScreenX(a6)
        move.b  d1,pd_ScreenY(a6)
        rts

;--------------------------------------------------------------------

gou_update_bendit_sprites:
        lea     pd_BenditSprites(a6),a2

        moveq.l #0,d0
        moveq.l #0,d1
        tst.w   pd_BenditKilled(a6)
        bne.s   .filldata

        move.w  #128+160-(BENDIT_WIDTH/2),d4
        sub.w   pd_ScreenX(a6),d4
        move.b  pd_ScreenY(a6),d1
        ext.w   d1

        add.w   #$6c,d1

        move.w  d1,d2
        add.w   #BENDIT_HEIGHT,d2
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
        REPT    (BENDIT_WIDTH/16)
        move.l  (a2)+,a0
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.w  #8,d1
        ENDR
        rts

;--------------------------------------------------------------------

gou_create_blitter_queue:
        lea     pd_BQClearLineBuffer(a6),a0
        move.l  pd_LastCubeLinePtr(a6),a1
        lea     CUBE_Y_CLIP*(CUBE_BUF_WIDTH/8)*CUBE_PLANES(a1),a1
        move.l  a1,bqc_BltDPt(a0)
        CALLFW  AddToBlitterQueue

        clr.l   pd_BQLineInit+bq_Next(a6)
        move.l  pd_CubeDataPtr(a6),a1
        bsr     gou_draw_inner_lines

        lea     pd_BQFillCube(a6),a0
        move.l  pd_LastPlanesPtr(a6),a1
        add.l   #((CUBE_X_OFFSET+CUBE_WIDTH-16)/8)+(CUBE_Y_OFFSET+CUBE_HEIGHT-CUBE_Y_CLIP-1)*(GOURAUD_WIDTH/8)*GOURAUD_PLANES+(GOURAUD_WIDTH/8)*(GOURAUD_PLANES-1),a1
        move.l  a1,bqfc_BltDPt(a0)

        move.l  pd_CurrCubeLinePtr(a6),a1
        lea     (CUBE_WIDTH-16)/8+(CUBE_HEIGHT-CUBE_Y_CLIP-1)*(CUBE_BUF_WIDTH/8)*CUBE_PLANES+(CUBE_BUF_WIDTH/8)*(CUBE_PLANES-1)(a1),a1
        move.l  a1,bqfc_BltAPt(a0)
        CALLFW  AddToBlitterQueue
.skip
        rts

;--------------------------------------------------------------------

gou_flip_copperlists:
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        not.b   pd_CopListToggle(a6)
        beq.s   .selb1
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        rts
.selb1
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        rts

gou_flip_db_frame:
        move.l  pd_CurrPlanesPtr(a6),pd_LastPlanesPtr(a6)
        move.l  pd_LastCubeLinePtr(a6),pd_LastLastCubeLinePtr(a6)
        move.l  pd_CurrCubeLinePtr(a6),pd_LastCubeLinePtr(a6)
        move.l  pd_RubberBuffer(a6),a0
        not.b   pd_DbToggle(a6)
        move.l  pd_RubberFrameOffset(a6),d0
        add.l   #(CUBE_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES,d0
        cmp.l   #((CUBE_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES*NUM_RUBBER_FRAMES),d0
        bne.s   .goodframe
        moveq.l #0,d0
.goodframe
        move.l  d0,pd_RubberFrameOffset(a6)
        adda.l  d0,a0
        move.l  a0,pd_CurrPlanesPtr(a6)

        move.b  pd_CubeBufToggle(a6),d0
        subq.b  #1,d0
        bmi.s   .cb2
        beq.s   .cb1
.cb3
        move.l  pd_CubeLineBuffer3(a6),pd_CurrCubeLinePtr(a6)
        move.b  d0,pd_CubeBufToggle(a6)
        rts
.cb2
        move.l  pd_CubeLineBuffer2(a6),pd_CurrCubeLinePtr(a6)
        move.b  #2,pd_CubeBufToggle(a6)
        rts
.cb1
        move.b  d0,pd_CubeBufToggle(a6)
        move.l  pd_CubeLineBuffer1(a6),pd_CurrCubeLinePtr(a6)
        rts

;--------------------------------------------------------------------

gou_update_copper_list_pointers:
        lea     gou_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

gou_create_main_copperlist:
        lea     pd_BenditSprites(a6),a1
        move.w  #sprpt,d1
        moveq.l #(BENDIT_WIDTH/16)*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

gou_create_main_copperlist_nosprites:
        lea     pd_RubberPalette(a6),a1
        moveq.l #16-1,d7
        move.w  #color,d1
.palloop
        move.w  d1,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d1
        dbra    d7,.palloop

        COPIMOVE $4200,bplcon0

        move.l  pd_RubberBuffer(a6),a1

        move.w  pd_ScreenX(a6),d0
        moveq.l #16,d2
        moveq.l #15,d1
        sub.w   d0,d2
        and.w   d1,d2       ; lower 4 bit
        move.w  d2,d5
        lsl.w   #4,d5
        or.w    d5,d2
        COPRMOVE d2,bplcon1
        add.w   d1,d0
        asr.w   #4,d0
        lsl.w   #3,d0
        neg.w   d0

        add.w   #$68,d0
        COPRMOVE d0,ddfstrt
        add.w   #$a0-$68,d0
        COPRMOVE d0,ddfstop

        move.w  #$6c81,d0
        move.w  pd_ScreenY(a6),d1
        add.w   d1,d0
        COPRMOVE d0,diwstrt
        add.w   #(CUBE_HEIGHT<<8)|($c1-$81),d0
        COPRMOVE d0,diwstop

        moveq.l #-2,d3
        moveq.l #CUBE_WIDTH/8,d2
        move.l  #((CUBE_WIDTH/8)*CUBE_HEIGHT*CUBE_PLANES*NUM_RUBBER_FRAMES),d5
        move.l  #(CUBE_WIDTH/8)*(CUBE_HEIGHT+4)*CUBE_PLANES,d6
        sub.w   #((CUBE_HEIGHT)<<8)-($07-$c1),d0
        ;move.w  #$6bd5,d0
        move.w  pd_NumRubberFrames(a6),d7
.cprloop
        lea     (a1,d4.l),a2
        COPPTMOVE a2,bplpt+0*4,d1
        adda.l  d2,a2
        COPPTMOVE a2,bplpt+1*4,d1
        adda.l  d2,a2
        COPPTMOVE a2,bplpt+2*4,d1
        adda.l  d2,a2
        COPPTMOVE a2,bplpt+3*4,d1

        add.l   d6,d4
        cmp.l   d5,d4
        blt.s   .nowrap
        sub.l   d5,d4
.nowrap
        add.w   #$400,d0
        bcc.s   .no255
        move.l  #$ffdffffe,(a0)+
.no255
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        dbra    d7,.cprloop

        move.b  #$38,d0
        move.w  #$100,d2

        move.l  d3,(a0)
        rts

;--------------------------------------------------------------------

gou_clear_cube_line_buffer:
        moveq.l #-1,d2

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_CurrCubeLinePtr(a6),bltdpt(a5)
        move.w  #((CUBE_BUF_WIDTH)>>4)|(((CUBE_HEIGHT)*CUBE_PLANES)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

gou_clear_rubber_buffers:
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_RubberBuffer(a6),bltdpt(a5)
        move.w  #(((CUBE_WIDTH*8)&1023)>>4)|(((CUBE_HEIGHT*CUBE_PLANES*2)&1023)<<6),bltsize(a5)
        CALLFW  VSyncWithTask
        CALLFW  VSyncWithTask
        BLTWAIT
        move.w  #(((CUBE_WIDTH*8)&1023)>>4)|(((CUBE_HEIGHT*CUBE_PLANES*2)&1023)<<6),bltsize(a5)
        CALLFW  VSyncWithTask
        CALLFW  VSyncWithTask
        rts

;--------------------------------------------------------------------

gou_flip_cube_buffer:
        move.l  pd_CubeDataReadPtr(a6),a0
        move.l  a0,pd_CubeDataPtr(a6)

        lea     cd_SIZEOF(a0),a1
        cmp.l   pd_CubePrecalcBufferEnd(a6),a1
        bne.s   .nowrap
        move.l  pd_CubePrecalcBuffer(a6),a1
.nowrap
        move.l  a1,pd_CubeDataReadPtr(a6)

        IF      DEBUG_DETAIL
        move.w  pd_PrecalculatedFrames(a6),d0
        cmp.w   #10,d0
        bgt.s   .okay
        PUTMSG  10,<"pd_PrecalculatedFrames=%d">,d0
.okay
        ENDC
        subq.w  #1,pd_PrecalculatedFrames(a6)
        rts

;--------------------------------------------------------------------

gou_async_calc_task:
        PUTMSG  10,<"%d: async_calc_task">,fw_FrameCounterLong(a6)
        move.l  pd_CubeDataPtr(a6),a1
        moveq.l #CUBE_PRECALC_NUM-1,d7
.cdloop
        lea     cd_IntCubeLines(a1),a0
        PUTMSG  20,<"IntCubeLines %p (%ld)">,a0,#il_SIZEOF
        lea     gou_cube_lines(pc),a2
        moveq.l #12-1,d6
.icloop move.l  (a2)+,il_FromCoord(a0) ; and il_ToCoord
        lea     il_SIZEOF(a0),a0
        dbra    d6,.icloop
        lea     cd_SIZEOF(a1),a1
        dbra    d7,.cdloop

.loop
.fillup
        move.w  pd_CalculatedCubeFrames(a6),d0
        cmp.w   #CUBE_PRECALC_NUM-1,pd_PrecalculatedFrames(a6)
        bge.s   .skipprecalc
        addq.w  #1,d0
        move.w  d0,pd_CalculatedCubeFrames(a6)
        move.l  pd_CubeDataWritePtr(a6),a0
        lea     cd_SIZEOF(a0),a1
        cmp.l   pd_CubePrecalcBufferEnd(a6),a1
        bne.s   .nowrap
        move.l  pd_CubePrecalcBuffer(a6),a1
.nowrap
        PUTMSG  40,<"Precalcing frame %p">,pd_CubeDataWritePtr(a6)
        PUSHM   a1
        move.l  pd_CubeSceneRoutinePtr(a6),a0
        jsr     (a0)
        move.l  pd_CubeDataWritePtr(a6),a1
        bsr     gou_calculate_cube_stuff
        bsr     gou_interpolate_inner_cube_lines
        POPM

        move.l  a1,pd_CubeDataWritePtr(a6)
        addq.w  #1,pd_PrecalculatedFrames(a6)
        bra     .fillup
.skipprecalc
.bufferfull

        CALLFW  Yield

        tst.w   pd_QuitAsyncTask(a6)
        beq     .loop

        PUTMSG  10,<"Async-Task terminates...">
        rts

;--------------------------------------------------------------------

MaxVerts = 8
MaxPlanes = 6
MaxLines = 12

PERSP2D MACRO           ;final projection from world to screen coords
        neg.w   d2      ;world +z is forward,screen perspective is away
        move.w  d2,-(sp)
        move.b  (sp)+,d2    ; shift d2 8 bits down
        ext.w   d2
        add.w   #GOURAUD_Z_DIST,d2  ; 78 and eye Z determines Field of View.
        divs    d2,d0
        divs    d2,d1
        add.w   #CUBE_WIDTH/2,d0    ;center horizontally on the screen
        ;asr.w   #1,d0
        add.w   #CUBE_HEIGHT/2,d1   ;center vertically
        ;asr.w   #1,d1
        ENDM

gou_calculate_cube_stuff:
        PUTMSG  50,<"Out CD %p">,a1
        ; rotate 3D object
        bsr     gou_rotate_cube

        lea     cd_CubeNormals-6+4(a1),a2
        lea     gou_cube_plane_coords(pc),a3     ; calculate which planes use which coords
        moveq.l #-1,d1
        lea     cd_PlanesToDraw(a1),a0
        move.l  d1,(a0)
        move.w  pd_CubeCullingValue(a6),d5
        moveq.l #0,d1           ; coords in use
        moveq.l #0,d2           ; lines in use
        moveq.l #0,d3           ; inner lines
        moveq.l #MaxPlanes-1,d7
.planeloop1
        addq.w  #6,a2
        move.l  (a3)+,d0
        cmp.w   (a2),d5
        dbmi    d7,.planeloop1
        bpl     .doneculling
        move.b  d7,(a0)+        ; write down first plane number (5 and decreasing)
        move.w  d0,d1           ; coordinates used for first plane
        swap    d0
        move.w  d0,d2
        subq.w  #1,d7
        bmi     .doneculling

.planeloop2
        addq.w  #6,a2
        move.l  (a3)+,d0
        cmp.w   (a2),d5
        dbmi    d7,.planeloop2
        bpl     .doneculling
        move.b  d7,(a0)+        ; write down second plane number (4 and decreasing)
        or.w    d0,d1           ; or coordinates used for second plane
        swap    d0
        move.w  d0,d4
        and.w   d2,d4
        or.w    d4,d3           ; inner lines
        or.w    d0,d2           ; used lines
        subq.w  #1,d7
        bmi.s   .doneculling

.planeloop3
        addq.w  #6,a2
        move.l  (a3)+,d0
        cmp.w   (a2),d5
        dbmi    d7,.planeloop3
        bpl.s   .doneculling
        move.b  d7,(a0)+        ; write down third plane number (3 and decreasing)

        or.w    d0,d1           ; or coordinates used for third plane
        swap    d0
        move.w  d0,d4
        and.w   d2,d4
        or.w    d4,d3           ; inner lines
        or.w    d0,d2           ; used lines

.doneculling
        move.w  d2,cd_LinesToDraw(a1)
        move.w  d3,cd_InnerLines(a1)
        move.w  d1,d7           ; save coordinate mask for loop below

        ; do projection on required coordinates
        lea     cd_Coords(a1),a0            ; rotated vertices
        lea     cd_ProjCoords(a1),a2        ; projected coords
        bra.s   .vertexl
.skip
        beq.s   .done
        addq.w  #6,a0
        addq.w  #4,a2
.vertexl
        lsr.w   #1,d7
        bcc.s   .skip
        movem.w (a0)+,d0-d2 ; x0,y0,z0
        PERSP2D ; d0/d1 result, d2 trashed
        PUTMSG  50,<"Proj %d,%d">,d0,d1
        move.w  d0,(a2)+
        move.w  d1,(a2)+
        bra.s   .vertexl
.done   rts

;--------------------------------------------------------------------

SETGRAYCOL0 MACRO
        ; 0
        ENDM

SETGRAYCOL1 MACRO
        ; 1
        bchg    d7,(a4)
        ENDM

SETGRAYCOL2 MACRO
        ; 3
        bchg    d7,(a4)
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL3 MACRO
        ; 7
        bchg    d7,(a4)
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL4 MACRO
        ; 15
        bchg    d7,(a4)
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL5 MACRO
        ; 11
        bchg    d7,(a4)
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL6 MACRO
        ; 9
        bchg    d7,(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL7 MACRO
        ; 8
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL8 MACRO
        ; 12
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL9 MACRO
        ; 13
        bchg    d7,0*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL10 MACRO
        ; 5
        bchg    d7,0*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL11 MACRO
        ; 4
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL12 MACRO
        ; 6
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL13 MACRO
        ; 14
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,2*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL14 MACRO
        ; 10
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        bchg    d7,3*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

SETGRAYCOL15 MACRO
        ; 2
        bchg    d7,1*(CUBE_BUF_WIDTH/8)(a4)
        ENDM

LINEDRAWSELECT MACRO
        add.w   d1,d1               ; 2*dx
        move.w  d2,d0               ; dy will become loopcount
        subq.w  #1,d0               ; loopcount
        bmi     .linedone
        ENDM

LINEDRAW MACRO
.enter\1
        PUTMSG  50,<"dtdz=%lx, dcol=%lx, zerror=%lx">,d5,a3,d6
        move.l  d5,a1               ; dtdz
        move.w  d2,d5               ; error = dy
        add.w   d2,d2               ; 2*dy
        subq.w  #1,d4
.yloop\@
        PUTMSG  50,<"dtdz=%lx, dcol=%lx, zerror=%lx x=%d, y=%d">,a1,a3,d6,d3,d4
        lea     (CUBE_BUF_WIDTH/8)*CUBE_PLANES(a4),a4
        addq.w  #1,d4               ; !!!!! ypos++

        sub.w   d1,d5               ; error -= 2 * dx
        bpl.s   .nox\@
        sub.l   a3,d6               ; zerror -= dcol (for y movement)
.morex\@
        IFGT    \3
        addq.w  #1,d3               ; !!!!! xpos++
        subq.w  #1,d7               ; bitpos
        bpl.s   .noai\@
        moveq.l #7,d7
        addq.w  #1,a4
        ELSE
        subq.w  #1,d3               ; !!!!! xpos--
        addq.w  #1,d7               ; bitpos
        bne.s   .noai\@
        moveq.l #-8,d7
        subq.w  #1,a4
        ENDC
.noai\@

        sub.l   a3,d6               ; zerror -= dcol (for x movement)
        bpl.s   .nozm\@
        add.w   d2,d5               ; error += 2 * dy
.morez\1
.morez\@
        PUTMSG  40,<"\1 ->> \2 LinePoint %d,%d %lx">,d3,d4,d6
        move.w  d4,(a2)+            ; add line point ypos
        move.w  d3,(a2)+            ; add line point xpos
        add.l   a1,d6               ; zerror += dtdz
        bmi.s   .morez\2
        tst.w   d5
        bra.s   .nozm\2
.nozm\@ add.w   d2,d5               ; error += 2 * dy
.nozm\1
        bmi.s   .morex\@
        bra.s   .ldone\@
.nox\@
        sub.l   a3,d6               ; zerror -= dcol (for y movement)
        bmi.s   .morez\@
.ldone\@
        SETGRAYCOL\4

        dbra    d0,.yloop\@
        bra     .linedone
        ENDM

LINEDRAW_SC MACRO
.enter\1
        move.w  d2,d5               ; error = dy
        add.w   d2,d2               ; 2*dy
.yloop\@
        lea     (CUBE_BUF_WIDTH/8)*CUBE_PLANES(a4),a4
        sub.w   d1,d5               ; error -= 2 * dx
        bpl.s   .ldone\@
.morex\@
        IFGT    \2
        subq.w  #1,d7               ; bitpos
        bpl.s   .noai\@
        moveq.l #7,d7
        addq.w  #1,a4
        ELSE
        addq.w  #1,d7               ; bitpos
        bne.s   .noai\@
        moveq.l #-8,d7
        subq.w  #1,a4
        ENDC
.noai\@
        add.w   d2,d5               ; error += 2 * dy
        bmi.s   .morex\@
.ldone\@
        SETGRAYCOL\3

        dbra    d0,.yloop\@
        bra     .linedone
        ENDM


ZEROIPOL MACRO
        subq.w  #1,d1               ; loopcount
.xloop\@
        IFGT    \1
        addq.w  #1,d3               ; !!!!! xpos++
        ELSE
        subq.w  #1,d3               ; !!!!! xpos--
        ENDC
        sub.l   d0,d6               ; zerror -= dcol (for y movement)
        dbmi    d1,.xloop\@
        bpl     .linedone
.morez\@
        PUTMSG  40,<"LinePoint %d,%d">,d3,d4
        move.w  d4,(a2)+            ; add line point ypos
        move.w  d3,(a2)+            ; add line point xpos
        add.l   d5,d6               ; zerror += dtdz
        dbmi    d1,.xloop\@
        bmi.s   .morez\@
        bra     .linedone
        ENDM


;--------------------------------------------------------------------
; a1 = cubedata
gou_interpolate_outer_cube_lines:
        PUTMSG  20,<"%d: ----- gou_interpolate_outer_cube_lines">,fw_FrameCounterLong(a6)
        move.w  cd_LinesToDraw(a1),d7
        sub.w   cd_InnerLines(a1),d7
        bne.s   .cont
        rts
.cont
        lea     cd_IntCubeLines(a1),a0
        lea     cd_ProjCoords(a1),a2
        lea     cd_Coords(a1),a3      ; z coords
        move.l  pd_CurrCubeLinePtr(a6),a4
.loop
        PUTMSG  20,<"Line %x">,d7
        lsr.w   #1,d7
        bcc     .skipline

        PUSHM   d7/a1-a4

        PUTMSG  40,<"%p/%p/%p/%p From/To %d - %d">,a0,a1,a2,a3,il_FromCoord-2(a0),il_ToCoord-2(a0)

        move.w  #GOURAUD_Z_ADD,d2
        move.w  il_FromCoord(a0),d0
        move.l  (a2,d0.w),il_FromX(a0)
        lsr.w   #1,d0
        add.w   il_FromCoord(a0),d0
        move.w  2*2(a3,d0.w),d0
        add.w   d2,d0
        move.w  d0,il_FromZ(a0)

        move.w  il_ToCoord(a0),d1
        move.l  (a2,d1.w),il_ToX(a0)
        lsr.w   #1,d1
        add.w   il_ToCoord(a0),d1
        move.w  2*2(a3,d1.w),d1
        add.w   d2,d1
        move.w  d1,il_ToZ(a0)

        move.w  d0,d2
        eor.w   d1,d2
        cmp.w   #1<<gouraudColShift,d2
        blt     .samecolorspecialcase

        PUTMSG  40,<"Z from %d to %d">,d0,d1

        lea     il_Coords(a0),a2

        move.w  d0,d6               ; will become zpos

        sub.w   d1,d0               ; deltaz
        neg.w   d0

        move.w  il_ToX(a0),d1
        move.w  il_FromX(a0),d3     ; startx
        sub.w   d3,d1               ; deltax
        move.w  il_ToY(a0),d2
        move.w  il_FromY(a0),d4
        sub.w   d4,d2               ; deltay
        smi     il_Flipped(a0)
        beq     .zerody
        bpl.s   .noflipy
        neg.w   d0                  ; flip deltaz
        neg.w   d1                  ; flip deltax
        neg.w   d2                  ; flip deltay
        move.w  il_ToX(a0),d3       ; swap startx
        move.w  il_ToY(a0),d4       ; swap starty
        move.w  il_ToZ(a0),d6       ; swap zpos
.noflipy
        PUTMSG  40,<"X/Y/Z=%d,%d,%d, DX/DY/DZ = %d/%d/%d">,d3,d4,d6,d1,d2,d0
        move.w  d6,d7
        lsr.w   #8,d7
        lsr.w   #16-(gouraudErrShift+8),d7 ; col
        lsl.w   #gouraudErrShift,d6 ; zpos

        tst.w   d0                  ; deltaz
        smi     il_DzNeg(a0)
        bmi.s   .noflipz
        not.w   d6                  ; $ffff - zpos
        neg.w   d0                  ; deltaz now negative
.noflipz
        neg.w   d0                  ; abs(deltaz)
        ext.l   d0
        lsl.l   #gouraudErrShift,d0 ; dcol

        PUTMSG  40,<"Col=%d, dcol=%ld, zpos=%x">,d7,d0,d6

        moveq.l #0,d5               ; dtdz
        move.w  d1,d5
        bpl.s   .noabsx
        neg.w   d5                  ; abs(dx)
.noabsx
        add.w   d2,d5               ; abs(dx)+dy (dy always positive)

        mulu    d5,d6               ; zerror = (dtdz>>16)*zpos
        swap    d5                  ; now really dtdz

        lsl.w   #2,d7               ; calculate color start routine
        move.w  d7,a1

        move.l  d0,a3
        move.w  d4,d0
        lsl.w   #6,d0               ; replaced mulu by shift
        ;mulu    #(CUBE_BUF_WIDTH/8)*CUBE_PLANES,d0
        adda.w  d0,a4               ; start pos y

        moveq.l #7,d7
        and.w   d3,d7
        move.w  d3,d0
        lsr.w   #3,d0
        adda.w  d0,a4

        tst.w   d1                  ; dx?
        bmi     .downleft

.downright
; d0.w =         loopcount.w
; d1.w = dx   ->      2*dx.w
; d2.w = dy   ->      2*dy.w
; d3.w = xpos ->      xpos.w
; d4.w = ypos ->      ypos.w
; d5.l = dtdz ->     error.w
; d6.l =            zerror.l
; d7.l =              bitpos
; a1.l =          dtdz.l
; a2.l = line output pointer
; a3.l =          dcol.l
; a4.l = bitplane pointer

        eor.w   #7,d7

        tst.b   il_DzNeg(a0)
        bmi.s   .downright_neg

        LINEDRAWSELECT
        jmp     .ruptab(pc,a1.w)
.ruptab
        bra.w   .enterrupm3
        bra.w   .enterrupm2
        bra.w   .enterrupm1
        bra.w   .enterrup0
        bra.w   .enterrup1
        bra.w   .enterrup2
        bra.w   .enterrup3
        bra.w   .enterrup4
        bra.w   .enterrup5
        bra.w   .enterrup6
        bra.w   .enterrup7
        bra.w   .enterrup8
        bra.w   .enterrup9
        bra.w   .enterrup10
        bra.w   .enterrup11
        bra.w   .enterrup12
        bra.w   .enterrup13
        bra.w   .enterrup14
        bra.w   .enterrup15
        bra.w   .enterrup15
        bra.w   .enterrup15
        bra.w   .enterrup15
        bra.w   .enterrup15
        bra.w   .enterrup15

.downright_neg
        LINEDRAWSELECT
        jmp     .rdowntab(pc,a1.w)
.rdowntab
        bra.w   .enterrdown0
        bra.w   .enterrdown0
        bra.w   .enterrdown0
        bra.w   .enterrdown0
        bra.w   .enterrdown1
        bra.w   .enterrdown2
        bra.w   .enterrdown3
        bra.w   .enterrdown4
        bra.w   .enterrdown5
        bra.w   .enterrdown6
        bra.w   .enterrdown7
        bra.w   .enterrdown8
        bra.w   .enterrdown9
        bra.w   .enterrdown10
        bra.w   .enterrdown11
        bra.w   .enterrdown12
        bra.w   .enterrdown13
        bra.w   .enterrdown14
        bra.w   .enterrdown15
        bra.w   .enterrdown16
        bra.w   .enterrdown17
        bra.w   .enterrdown18
        bra.w   .enterrdown19
        bra.w   .enterrdown20

.downleft
        neg.w   d1
        not.w   d7

        tst.b   il_DzNeg(a0)
        bmi.s   .downleft_neg

        LINEDRAWSELECT
        jmp     .luptab(pc,a1.w)
.luptab
        bra.w   .enterlupm3
        bra.w   .enterlupm2
        bra.w   .enterlupm1
        bra.w   .enterlup0
        bra.w   .enterlup1
        bra.w   .enterlup2
        bra.w   .enterlup3
        bra.w   .enterlup4
        bra.w   .enterlup5
        bra.w   .enterlup6
        bra.w   .enterlup7
        bra.w   .enterlup8
        bra.w   .enterlup9
        bra.w   .enterlup10
        bra.w   .enterlup11
        bra.w   .enterlup12
        bra.w   .enterlup13
        bra.w   .enterlup14
        bra.w   .enterlup15
        bra.w   .enterlup15
        bra.w   .enterlup15
        bra.w   .enterlup15
        bra.w   .enterlup15
        bra.w   .enterlup15

.downleft_neg
        LINEDRAWSELECT
        jmp     .ldowntab(pc,a1.w)
.ldowntab
        bra.w   .enterldown0
        bra.w   .enterldown0
        bra.w   .enterldown0
        bra.w   .enterldown0
        bra.w   .enterldown1
        bra.w   .enterldown2
        bra.w   .enterldown3
        bra.w   .enterldown4
        bra.w   .enterldown5
        bra.w   .enterldown6
        bra.w   .enterldown7
        bra.w   .enterldown8
        bra.w   .enterldown9
        bra.w   .enterldown10
        bra.w   .enterldown11
        bra.w   .enterldown12
        bra.w   .enterldown13
        bra.w   .enterldown14
        bra.w   .enterldown15
        bra.w   .enterldown16
        bra.w   .enterldown17
        bra.w   .enterldown18
        bra.w   .enterldown19
        bra.w   .enterldown20

.zerodydx
        PUTMSG  40,<"Zero DX/DY">
        moveq.l #0,d7
        moveq.l #0,d6
        move.b  il_FromZ(a0),d7
        lsr.w   #gouraudColShift-8,d7
        move.b  il_ToZ(a0),d6
        lsr.w   #gouraudColShift-8,d6
        sub.w   d6,d7
        beq.s   .linedone
        bpl.s   .noflipdz
        neg.w   d7
.noflipdz
        subq.w  #1,d7
.loopspotcols
        move.w  d4,(a2)+            ; add line point ypos
        move.w  d3,(a2)+            ; add line point xpos
        dbra    d7,.loopspotcols
        bra.s   .linedone
.zerody
        PUTMSG  40,<"Zero DY">
        tst.w   d1
        beq.s   .zerodydx
        lsl.w   #gouraudErrShift,d6 ; zpos
        tst.w   d0                  ; deltaz
        smi     il_DzNeg(a0)
        bmi.s   .noflipz2
        not.w   d6                  ; $ffff - zpos
        neg.w   d0                  ; deltaz now negative
.noflipz2
        neg.w   d0                  ; abs(deltaz)
        ext.l   d0
        lsl.l   #gouraudErrShift,d0 ; dcol
        moveq.l #0,d5               ; dtdz
        move.w  d1,d5
        bmi.s   .plainleft

; d0.l =                   dcol.l
; d1.w = dx   ->          loopcount.w
; d3.w =                       xpos.w
; d3.w =                       ypos.w
; d5.l =                   dtdz.l
; d6.l =                   zerror.l

.plainright
        mulu    d5,d6               ; zerror = (dtdz>>16)*zpos
        swap    d5                  ; now really dtdz
        ZEROIPOL 1

.plainleft
        neg.w   d5                  ; abs(dx)
        mulu    d5,d6               ; zerror = (dtdz>>16)*zpos
        swap    d5                  ; now really dtdz

        neg.w   d1
        ZEROIPOL -1

.linedone
        suba.l  a0,a2
        move.w  a2,d0
        lsr.w   #2,d0
        move.w  d0,il_NumCoords(a0)

        POPM

.skipline
        lea     il_SIZEOF(a0),a0
        tst.w   d7
        bne     .loop

        rts

.samecolorspecialcase
        PUTMSG  40,<"Same color special case from %d to %d">,d0,d1

        lea     il_Coords(a0),a2

        move.w  il_ToX(a0),d1
        move.w  il_FromX(a0),d3     ; startx
        sub.w   d3,d1               ; deltax
        move.w  il_ToY(a0),d2
        move.w  il_FromY(a0),d4
        sub.w   d4,d2               ; deltay
        smi     il_Flipped(a0)
        beq.s   .linedone
        bpl.s   .noflipy_sc
        neg.w   d1                  ; flip deltax
        neg.w   d2                  ; flip deltay
        move.w  il_ToX(a0),d3       ; swap startx
        move.w  il_ToY(a0),d4       ; swap starty
.noflipy_sc
        PUTMSG  50,<"X/Y=%d,%d, DX/DY = %d/%d">,d3,d4,d1,d2
        move.w  d0,d7
        ;rol.w   #(gouraudErrShift+2),d7
        asr.w   #8,d7
        asr.w   #16-(gouraudErrShift+8),d7 ; col

        PUTMSG  50,<"Col=%d">,d7

        lsl.w   #2,d7               ; calculate color start routine
        move.w  d7,a1

        lsl.w   #6,d4               ; replaced mulu by shift
        ;mulu    #(CUBE_BUF_WIDTH/8)*CUBE_PLANES,d4
        adda.w  d4,a4               ; start pos y

        moveq.l #7,d7
        and.w   d3,d7
        move.w  d3,d0
        lsr.w   #3,d0
        adda.w  d0,a4

        tst.w   d1                  ; dx?
        bmi     .downleft_sc

.downright_sc
; d0.w =         loopcount.w
; d1.w = dx   ->      2*dx.w
; d2.w = dy   ->      2*dy.w
; d3.w = xpos ->      xpos.w
; d4.w = ypos ->      ypos.w
; d7.l =              bitpos
; a4.l = bitplane pointer

        eor.w   #7,d7

        tst.b   il_DzNeg(a0)
        bmi.s   .downright_neg_sc

        LINEDRAWSELECT
        jmp     .ruptab_sc(pc,a1.w)
.ruptab_sc
        bra.w   .enterrup_sc0
        bra.w   .enterrup_sc0
        bra.w   .enterrup_sc0
        bra.w   .enterrup_sc0
        bra.w   .enterrup_sc1
        bra.w   .enterrup_sc2
        bra.w   .enterrup_sc3
        bra.w   .enterrup_sc4
        bra.w   .enterrup_sc5
        bra.w   .enterrup_sc6
        bra.w   .enterrup_sc7
        bra.w   .enterrup_sc8
        bra.w   .enterrup_sc9
        bra.w   .enterrup_sc10
        bra.w   .enterrup_sc11
        bra.w   .enterrup_sc12
        bra.w   .enterrup_sc13
        bra.w   .enterrup_sc14
        bra.w   .enterrup_sc15
        bra.w   .enterrup_sc15
        bra.w   .enterrup_sc15
        bra.w   .enterrup_sc15
        bra.w   .enterrup_sc15
        bra.w   .enterrup_sc15

.downright_neg_sc
        LINEDRAWSELECT
        jmp     .rdowntab_sc(pc,a1.w)
.rdowntab_sc
        bra.w   .enterrdown_sc0
        bra.w   .enterrdown_sc0
        bra.w   .enterrdown_sc0
        bra.w   .enterrdown_sc0
        bra.w   .enterrdown_sc1
        bra.w   .enterrdown_sc2
        bra.w   .enterrdown_sc3
        bra.w   .enterrdown_sc4
        bra.w   .enterrdown_sc5
        bra.w   .enterrdown_sc6
        bra.w   .enterrdown_sc7
        bra.w   .enterrdown_sc8
        bra.w   .enterrdown_sc9
        bra.w   .enterrdown_sc10
        bra.w   .enterrdown_sc11
        bra.w   .enterrdown_sc12
        bra.w   .enterrdown_sc13
        bra.w   .enterrdown_sc14
        bra.w   .enterrdown_sc15
        bra.w   .enterrdown_sc15
        bra.w   .enterrdown_sc15
        bra.w   .enterrdown_sc15
        bra.w   .enterrdown_sc15
        bra.w   .enterrdown_sc15

.downleft_sc
        neg.w   d1
        not.w   d7

        tst.b   il_DzNeg(a0)
        bmi.s   .downleft_neg_sc

        LINEDRAWSELECT
        jmp     .luptab_sc(pc,a1.w)
.luptab_sc
        bra.w   .enterlup_sc0
        bra.w   .enterlup_sc0
        bra.w   .enterlup_sc0
        bra.w   .enterlup_sc0
        bra.w   .enterlup_sc1
        bra.w   .enterlup_sc2
        bra.w   .enterlup_sc3
        bra.w   .enterlup_sc4
        bra.w   .enterlup_sc5
        bra.w   .enterlup_sc6
        bra.w   .enterlup_sc7
        bra.w   .enterlup_sc8
        bra.w   .enterlup_sc9
        bra.w   .enterlup_sc10
        bra.w   .enterlup_sc11
        bra.w   .enterlup_sc12
        bra.w   .enterlup_sc13
        bra.w   .enterlup_sc14
        bra.w   .enterlup_sc15
        bra.w   .enterlup_sc15
        bra.w   .enterlup_sc15
        bra.w   .enterlup_sc15
        bra.w   .enterlup_sc15
        bra.w   .enterlup_sc15

.downleft_neg_sc
        LINEDRAWSELECT
        jmp     .ldowntab_sc(pc,a1.w)
.ldowntab_sc
        bra.w   .enterldown_sc0
        bra.w   .enterldown_sc0
        bra.w   .enterldown_sc0
        bra.w   .enterldown_sc0
        bra.w   .enterldown_sc1
        bra.w   .enterldown_sc2
        bra.w   .enterldown_sc3
        bra.w   .enterldown_sc4
        bra.w   .enterldown_sc5
        bra.w   .enterldown_sc6
        bra.w   .enterldown_sc7
        bra.w   .enterldown_sc8
        bra.w   .enterldown_sc9
        bra.w   .enterldown_sc10
        bra.w   .enterldown_sc11
        bra.w   .enterldown_sc12
        bra.w   .enterldown_sc13
        bra.w   .enterldown_sc14
        bra.w   .enterldown_sc15
        bra.w   .enterldown_sc15
        bra.w   .enterldown_sc15
        bra.w   .enterldown_sc15
        bra.w   .enterldown_sc15
        bra.w   .enterldown_sc15

        LINEDRAW rupm3,rupm2,1,0
        LINEDRAW rupm2,rupm1,1,0
        LINEDRAW rupm1,rup0,1,0
        LINEDRAW rup0,rup1,1,0
        LINEDRAW rup1,rup2,1,1
        LINEDRAW rup2,rup3,1,2
        LINEDRAW rup3,rup4,1,3
        LINEDRAW rup4,rup5,1,4
        LINEDRAW rup5,rup6,1,5
        LINEDRAW rup6,rup7,1,6
        LINEDRAW rup7,rup8,1,7
        LINEDRAW rup8,rup9,1,8
        LINEDRAW rup9,rup10,1,9
        LINEDRAW rup10,rup11,1,10
        LINEDRAW rup11,rup12,1,11
        LINEDRAW rup12,rup13,1,12
        LINEDRAW rup13,rup14,1,13
        LINEDRAW rup14,rup15,1,14
        LINEDRAW rup15,rup15,1,15

        LINEDRAW lupm3,lupm2,-1,0
        LINEDRAW lupm2,lupm1,-1,0
        LINEDRAW lupm1,lup0,-1,0
        LINEDRAW lup0,lup1,-1,0
        LINEDRAW lup1,lup2,-1,1
        LINEDRAW lup2,lup3,-1,2
        LINEDRAW lup3,lup4,-1,3
        LINEDRAW lup4,lup5,-1,4
        LINEDRAW lup5,lup6,-1,5
        LINEDRAW lup6,lup7,-1,6
        LINEDRAW lup7,lup8,-1,7
        LINEDRAW lup8,lup9,-1,8
        LINEDRAW lup9,lup10,-1,9
        LINEDRAW lup10,lup11,-1,10
        LINEDRAW lup11,lup12,-1,11
        LINEDRAW lup12,lup13,-1,12
        LINEDRAW lup13,lup14,-1,13
        LINEDRAW lup14,lup15,-1,14
        LINEDRAW lup15,lup15,-1,15

        LINEDRAW rdown0,rdown0,1,0
        LINEDRAW rdown1,rdown0,1,1
        LINEDRAW rdown2,rdown1,1,2
        LINEDRAW rdown3,rdown2,1,3
        LINEDRAW rdown4,rdown3,1,4
        LINEDRAW rdown5,rdown4,1,5
        LINEDRAW rdown6,rdown5,1,6
        LINEDRAW rdown7,rdown6,1,7
        LINEDRAW rdown8,rdown7,1,8
        LINEDRAW rdown9,rdown8,1,9
        LINEDRAW rdown10,rdown9,1,10
        LINEDRAW rdown11,rdown10,1,11
        LINEDRAW rdown12,rdown11,1,12
        LINEDRAW rdown13,rdown12,1,13
        LINEDRAW rdown14,rdown13,1,14
        LINEDRAW rdown15,rdown14,1,15
        LINEDRAW rdown16,rdown15,1,15
        LINEDRAW rdown17,rdown16,1,15
        LINEDRAW rdown18,rdown17,1,15
        LINEDRAW rdown19,rdown18,1,15
        LINEDRAW rdown20,rdown19,1,15

        LINEDRAW ldown0,ldown0,-1,0
        LINEDRAW ldown1,ldown0,-1,1
        LINEDRAW ldown2,ldown1,-1,2
        LINEDRAW ldown3,ldown2,-1,3
        LINEDRAW ldown4,ldown3,-1,4
        LINEDRAW ldown5,ldown4,-1,5
        LINEDRAW ldown6,ldown5,-1,6
        LINEDRAW ldown7,ldown6,-1,7
        LINEDRAW ldown8,ldown7,-1,8
        LINEDRAW ldown9,ldown8,-1,9
        LINEDRAW ldown10,ldown9,-1,10
        LINEDRAW ldown11,ldown10,-1,11
        LINEDRAW ldown12,ldown11,-1,12
        LINEDRAW ldown13,ldown12,-1,13
        LINEDRAW ldown14,ldown13,-1,14
        LINEDRAW ldown15,ldown14,-1,15
        LINEDRAW ldown16,ldown15,-1,15
        LINEDRAW ldown17,ldown16,-1,15
        LINEDRAW ldown18,ldown17,-1,15
        LINEDRAW ldown19,ldown18,-1,15
        LINEDRAW ldown20,ldown19,-1,15

        LINEDRAW_SC rup_sc0,1,0
        LINEDRAW_SC rup_sc1,1,1
        LINEDRAW_SC rup_sc2,1,2
        LINEDRAW_SC rup_sc3,1,3
        LINEDRAW_SC rup_sc4,1,4
        LINEDRAW_SC rup_sc5,1,5
        LINEDRAW_SC rup_sc6,1,6
        LINEDRAW_SC rup_sc7,1,7
        LINEDRAW_SC rup_sc8,1,8
        LINEDRAW_SC rup_sc9,1,9
        LINEDRAW_SC rup_sc10,1,10
        LINEDRAW_SC rup_sc11,1,11
        LINEDRAW_SC rup_sc12,1,12
        LINEDRAW_SC rup_sc13,1,13
        LINEDRAW_SC rup_sc14,1,14
        LINEDRAW_SC rup_sc15,1,15

        LINEDRAW_SC lup_sc0,-1,0
        LINEDRAW_SC lup_sc1,-1,1
        LINEDRAW_SC lup_sc2,-1,2
        LINEDRAW_SC lup_sc3,-1,3
        LINEDRAW_SC lup_sc4,-1,4
        LINEDRAW_SC lup_sc5,-1,5
        LINEDRAW_SC lup_sc6,-1,6
        LINEDRAW_SC lup_sc7,-1,7
        LINEDRAW_SC lup_sc8,-1,8
        LINEDRAW_SC lup_sc9,-1,9
        LINEDRAW_SC lup_sc10,-1,10
        LINEDRAW_SC lup_sc11,-1,11
        LINEDRAW_SC lup_sc12,-1,12
        LINEDRAW_SC lup_sc13,-1,13
        LINEDRAW_SC lup_sc14,-1,14
        LINEDRAW_SC lup_sc15,-1,15

        LINEDRAW_SC rdown_sc0,1,0
        LINEDRAW_SC rdown_sc1,1,1
        LINEDRAW_SC rdown_sc2,1,2
        LINEDRAW_SC rdown_sc3,1,3
        LINEDRAW_SC rdown_sc4,1,4
        LINEDRAW_SC rdown_sc5,1,5
        LINEDRAW_SC rdown_sc6,1,6
        LINEDRAW_SC rdown_sc7,1,7
        LINEDRAW_SC rdown_sc8,1,8
        LINEDRAW_SC rdown_sc9,1,9
        LINEDRAW_SC rdown_sc10,1,10
        LINEDRAW_SC rdown_sc11,1,11
        LINEDRAW_SC rdown_sc12,1,12
        LINEDRAW_SC rdown_sc13,1,13
        LINEDRAW_SC rdown_sc14,1,14
        LINEDRAW_SC rdown_sc15,1,15

        LINEDRAW_SC ldown_sc0,-1,0
        LINEDRAW_SC ldown_sc1,-1,1
        LINEDRAW_SC ldown_sc2,-1,2
        LINEDRAW_SC ldown_sc3,-1,3
        LINEDRAW_SC ldown_sc4,-1,4
        LINEDRAW_SC ldown_sc5,-1,5
        LINEDRAW_SC ldown_sc6,-1,6
        LINEDRAW_SC ldown_sc7,-1,7
        LINEDRAW_SC ldown_sc8,-1,8
        LINEDRAW_SC ldown_sc9,-1,9
        LINEDRAW_SC ldown_sc10,-1,10
        LINEDRAW_SC ldown_sc11,-1,11
        LINEDRAW_SC ldown_sc12,-1,12
        LINEDRAW_SC ldown_sc13,-1,13
        LINEDRAW_SC ldown_sc14,-1,14
        LINEDRAW_SC ldown_sc15,-1,15


;--------------------------------------------------------------------

LINEIPOL MACRO
        move.w  d2,d7               ; error (=dy)
        add.w   d1,d1               ; 2*dx
        move.w  d2,d0
        add.w   d2,d2               ; 2*dy
        subq.w  #1,d0               ; loopcount (top word)
        bmi     .linedone
.yloop\@
        addq.w  #1,d4               ; !!!!! ypos++

        sub.w   d1,d7               ; error -= 2 * dx
        bpl.s   .nox\@
        sub.l   a3,d6               ; zerror -= dcol (for y movement)
.morex\@
        IFGT    \1
        addq.w  #1,d3               ; !!!!! xpos++
        ELSE
        subq.w  #1,d3               ; !!!!! xpos--
        ENDC

        add.w   d2,d7               ; error += 2 * dy
        sub.l   a3,d6               ; zerror -= dcol (for x movement)
        bpl.s   .nozm\@
.morez\@

        PUTMSG  40,<"LinePoint %d,%d">,d3,d4
        move.w  d4,(a2)+            ; add line point (ypos)
        move.w  d3,(a2)+            ; add line point (xpos)
        add.l   d5,d6               ; zerror += dtdz
        bmi.s   .morez\@
.nozm\@ tst.w   d7
        bmi.s   .morex\@

        dbra    d0,.yloop\@
        bra     .linedone
.nox\@
        sub.l   a3,d6               ; zerror -= dcol (for y movement)
        bpl.s   .ldone\@
.zmin\@
        PUTMSG  40,<"LinePoint %d,%d">,d3,d4
        move.w  d4,(a2)+            ; add line point (ypos)
        move.w  d3,(a2)+            ; add line point (xpos)
        add.l   d5,d6               ; zerror += dtdz
        bmi.s   .zmin\@
.ldone\@
        dbra    d0,.yloop\@
        bra     .linedone
        ENDM

;--------------------------------------------------------------------
; a1 = cubedata
gou_interpolate_inner_cube_lines:
        PUTMSG  20,<"%d: ----- gou_interpolate_inner_cube_lines">,fw_FrameCounterLong(a6)
        move.w  cd_InnerLines(a1),d7
        bne.s   .cont
        rts
.cont
        lea     cd_IntCubeLines(a1),a0
        lea     cd_ProjCoords(a1),a2
        lea     cd_Coords(a1),a3      ; z coords
.loop
        PUTMSG  50,<"Line %x">,d7
        lsr.w   #1,d7
        bcc     .skipline

        PUSHM   d7/a2-a3

        PUTMSG  40,<"%p/%p/%p/%p From/To %d - %d">,a0,a1,a2,a3,il_FromCoord-2(a0),il_ToCoord-2(a0)

        move.w  #GOURAUD_Z_ADD,d2
        move.w  il_FromCoord(a0),d0
        move.l  (a2,d0.w),il_FromX(a0)
        lsr.w   #1,d0
        add.w   il_FromCoord(a0),d0
        move.w  2*2(a3,d0.w),d0
        add.w   d2,d0
        move.w  d0,il_FromZ(a0)

        move.w  il_ToCoord(a0),d1
        move.l  (a2,d1.w),il_ToX(a0)
        lsr.w   #1,d1
        add.w   il_ToCoord(a0),d1
        move.w  2*2(a3,d1.w),d1
        add.w   d2,d1
        move.w  d1,il_ToZ(a0)

        PUTMSG  40,<"Z from %d to %d">,d0,d1

        lea     il_Coords(a0),a2
        move.l  a2,a3

        move.w  d0,d6               ; will become zpos

        sub.w   d1,d0               ; deltaz
        neg.w   d0

        move.w  il_ToX(a0),d1
        move.w  il_FromX(a0),d3     ; startx
        sub.w   d3,d1               ; deltax
        move.w  il_ToY(a0),d2
        move.w  il_FromY(a0),d4
        sub.w   d4,d2               ; deltay
        smi     il_Flipped(a0)
        bpl.s   .noflipy
        neg.w   d0                  ; flip deltaz
        neg.w   d1                  ; flip deltax
        neg.w   d2                  ; flip deltay
        move.w  il_ToX(a0),d3       ; swap startx
        move.w  il_ToY(a0),d4       ; swap starty
        move.w  il_ToZ(a0),d6       ; swap zpos
.noflipy
        PUTMSG  40,<"X/Y/Z=%d,%d,%d, DX/DY/DZ = %d/%d/%d">,d3,d4,d6,d1,d2,d0
        lsl.w   #gouraudErrShift,d6 ; zpos

        tst.w   d0                  ; deltaz
        smi     il_DzNeg(a0)
        bmi.s   .noflipz
        not.w   d6                  ; $ffff - zpos
        neg.w   d0                  ; deltaz now negative
.noflipz
        neg.w   d0                  ; abs(deltaz)
        ext.l   d0
        lsl.l   #gouraudErrShift,d0 ; dcol

        PUTMSG  40,<"dcol=%ld, zpos=%x">,d0,d6

        moveq.l #0,d5               ; dtdz
        move.w  d1,d5
        bpl.s   .noabsx
        neg.w   d5                  ; abs(dx)
.noabsx add.w   d2,d5               ; abs(dx)+dy (dy always positive)
        mulu    d5,d6               ; zerror = (dtdz>>16)*zpos
        swap    d5                  ; now really dtdz

        tst.w   d2
        beq     .contzerody

        move.l  d0,a3

        tst.w   d1                  ; dx?
        bmi     .downleft

.downright
; d0.w =                  loopcount.w
; d1.w = dx   ->               2*dx.w
; d2.w = dy   ->               2*dy.w
; d3.w = xpos ->               xpos.w
; d4.w = ypos ->               ypos.w
; d5.l =                   dtdz.l
; d6.l =                   zerror.l
; d7.l =                      error.w
; a3.l =                   dcol.l
;
        LINEIPOL 1

.downleft
        neg.w   d1

        LINEIPOL -1

.zerodydx
        PUTMSG  40,<"Zero DX/DY (inner)">
        moveq.l #0,d7
        moveq.l #0,d6
        move.b  il_FromZ(a0),d7
        lsr.w   #gouraudColShift-8,d7
        move.b  il_ToZ(a0),d6
        lsr.w   #gouraudColShift-8,d6
        sub.w   d6,d7
        beq.s   .linedone
        bpl.s   .noflipdz
        neg.w   d7
.noflipdz
        subq.w  #1,d7
.loopspotcols
        move.w  d4,(a2)+            ; add line point ypos
        move.w  d3,(a2)+            ; add line point xpos
        dbra    d7,.loopspotcols
        bra.s   .linedone
.contzerody
; d0.l =                   dcol.l
; d1.w = dx   ->          loopcount.w
; d3.w =                       xpos.w
; d3.w =                       ypos.w
; d5.l =                   dtdz.l
; d6.l =                   zerror.l

        tst.w   d1                  ; dx?
        beq.s   .zerodydx
        bmi     .plainleft
.plainright
        ZEROIPOL 1
.plainleft
        neg.w   d1
        ZEROIPOL -1

.linedone
        suba.l  a0,a2
        move.w  a2,d0
        lsr.w   #2,d0
        move.w  d0,il_NumCoords(a0)

        POPM

.skipline
        lea     il_SIZEOF(a0),a0
        tst.w   d7
        bne     .loop

        rts

;--------------------------------------------------------------------

COPYLINEDATA MACRO
        move.w  il_NumCoords(\1),d4
        beq.s   .lcskip\@
        btst    #\2,d5
        IF      \3
        beq.s   .lcrev\@
        ELSE
        bne.s   .lcrev\@
        ENDC
        PUTMSG  50,<"\2 %d coords fwd">,d4
        subq.w  #1,d4
.lcloop\@
        move.l  (\1)+,(\4)+                 ; write left part 1 (in order)
        dbra    d4,.lcloop\@
        bra.s   .lcskip\@
.lcrev\@
        PUTMSG  50,<"\2 %d coords bkw">,d4
        adda.w  d4,\1
        adda.w  d4,\1
        adda.w  d4,\1
        adda.w  d4,\1
        subq.w  #1,d4
.lcrloop\@
        move.l  -(\1),(\4)+                 ; write left part 1 (in order)
        dbra    d4,.lcrloop\@
.lcskip\@
        ENDM

; a1 = cubedata
gou_draw_inner_lines:
        moveq.l #0,d7
        move.b  cd_PlanesToDraw(a1),d7
        bpl.s   .cont
.done
        rts
.cont
        PUTMSG  40,<"Plane Number: %d">,d7
        PUSHM   a1
        lea     pd_BQLineInit(a6),a0
        CALLFW  AddToBlitterQueue
        POPM
        lea     pd_BQLines(a6),a4
        bsr.s   .doit
        moveq.l #0,d7
        move.b  cd_PlanesToDraw+1(a1),d7
        bmi.s   .done
        bsr.s   .doit
        moveq.l #0,d7
        move.b  cd_PlanesToDraw+2(a1),d7
        bmi.s   .done
.doit
        PUSHM   a1/a4
        lsl.w   #3,d7

        move.l  a1,a4
        lea     gou_cube_planes_to_lines(pc),a0
        movem.w (a0,d7.w),a0-a3

        adda.l  a4,a0
        adda.l  a4,a1
        adda.l  a4,a2
        adda.l  a4,a3

        PUTMSG  40,<"%p Lines %lx,%lx,%lx,%lx">,a1,il_FromCoord(a0),il_FromCoord(a1),il_FromCoord(a2),il_FromCoord(a3)

        move.l  il_FromCoord(a0),d4    ; and il_ToCoord (0)
        move.l  il_FromCoord(a1),d5    ; and il_ToCoord (1)
        cmp.w   d4,d5       ; to_0 == to_1 ?
        beq.s   .l1l_l2r_l3r_l4l            ; l1 linear, l2 reversed
        swap    d4
        cmp.w   d4,d5       ; from_0 == to_1 ?
        beq     .l1r_l2r_l3l_l4l            ; l1 reversed, l2 reversed

.l1l_l2l_l3l_l4r
        move.w  il_FromZ(a0),d4
        sub.w   il_FromZ(a2),d4
        move.w  d4,d6
        bpl.s   .nofl0
        neg.w   d6
.nofl0
        move.w  il_FromZ(a1),d5
        sub.w   il_ToZ(a3),d5
        move.w  d5,d7
        bpl.s   .nofr0
        neg.w   d7
.nofr0  cmp.w   d7,d6
        blt.s   .l1l_l2l_l3l_l4r_dz13 ; abs(dz02) < abs(dz13)
        ; dz02 dominant
        move.b  il_FromZ(a2),d6     ; startZ = coord 2
        moveq.l #0+0+0+8+0+0,d7
        tst.w   d4
        bpl     .contl
        moveq.l #0+0+0+8+0+32,d7
        move.b  il_FromZ(a0),d6     ; startZ = coord 0
        bra     .contl

.l1l_l2l_l3l_l4r_dz13
        ; dz13 dominant
        move.b  il_FromZ(a1),d6     ; startZ = coord 1
        moveq.l #0+0+0+8+16+0,d7
        tst.w   d5
        bmi     .contl
        move.b  il_ToZ(a3),d6       ; startZ = reversed coord 3
        moveq.l #0+0+0+8+16+32,d7
        bra     .contl

.l1l_l2r_l3r_l4l
        move.w  il_FromZ(a0),d4
        sub.w   il_ToZ(a2),d4
        move.w  d4,d6
        bpl.s   .nofl1
        neg.w   d6
.nofl1
        move.w  il_ToZ(a1),d5
        sub.w   il_FromZ(a3),d5
        move.w  d5,d7
        bpl.s   .nofr1
        neg.w   d7
.nofr1  cmp.w   d7,d6
        blt.s   .l1l_l2r_l3r_l4l_dz13 ; abs(dz02) < abs(dz13)
        ; dz02 dominant
        move.b  il_ToZ(a2),d6       ; startZ = reversed coord 2
        moveq.l #0+2+4+0+0+0,d7
        tst.w   d4
        bpl.s   .contl
        moveq.l #0+2+4+0+0+32,d7
        move.b  il_FromZ(a0),d6     ; startZ = coord 0
        bra.s   .contl

.l1l_l2r_l3r_l4l_dz13
        ; dz13 dominant
        move.b  il_ToZ(a1),d6       ; startZ = reversed coord 1
        moveq.l #0+2+4+0+16+0,d7
        tst.w   d5
        bmi.s   .contl
        move.b  il_FromZ(a3),d6     ; startZ = coord 3
        moveq.l #0+2+4+0+16+32,d7
        bra.s   .contl

.l1r_l2r_l3l_l4l
        move.w  il_ToZ(a0),d4
        sub.w   il_FromZ(a2),d4
        move.w  d4,d6
        bpl.s   .nofl2
        neg.w   d6
.nofl2
        move.w  il_ToZ(a1),d5
        sub.w   il_FromZ(a3),d5
        move.w  d5,d7
        bpl.s   .nofr2
        neg.w   d7
.nofr2  cmp.w   d7,d6
        blt.s   .l1r_l2r_l3l_l4l_dz13 ; abs(dz02) < abs(dz13)
        ; dz02 dominant
        move.b  il_FromZ(a2),d6     ; startZ = coord 2
        moveq.l #1+2+0+0+0+0,d7
        tst.w   d4
        bpl.s   .contl
        move.b  il_ToZ(a0),d6       ; startZ = reversed coord 0
        moveq.l #1+2+0+0+0+32,d7
        bra.s   .contl

.l1r_l2r_l3l_l4l_dz13
        ; dz13 dominant
        move.b  il_ToZ(a1),d6       ; startZ = reversed coord 1
        moveq.l #1+2+0+0+16+0,d7
        tst.w   d5
        bmi.s   .contl
        move.b  il_FromZ(a3),d6     ; startZ = coord 3
        moveq.l #1+2+0+0+16+32,d7

.contl
        moveq.l #0,d5
        sub.b   il_Flipped(a3),d5
        add.b   d5,d5
        sub.b   il_Flipped(a2),d5
        add.b   d5,d5
        sub.b   il_Flipped(a1),d5
        add.b   d5,d5
        sub.b   il_Flipped(a0),d5
        PUTMSG  50,<"copymode=%x/%x">,d5,d7
        eor.w   d7,d5

        and.w   #16+32,d7
        jmp     .jmptab(pc,d7.w)
.jmptab
        bra     .dz02dom_pl
        ds.b    (.jmptab+16)-*
        bra.s   .dz13dom_pl
        ds.b    (.jmptab+32)-*
        bra     .dz02dom_mi
        ds.b    (.jmptab+48)-*
        bra     .dz13dom_mi

.dz13dom_pl
        PUTMSG  40,<"DZ13 PL">
        lea     pd_LinesFromBuffer(a6),a4
        COPYLINEDATA a0,0,1,a4
        COPYLINEDATA a3,3,1,a4
        clr.w   (a4)+
        PUTMSG  50,<"Right">
        lea     pd_LinesToBuffer(a6),a4
        COPYLINEDATA a1,1,0,a4
        COPYLINEDATA a2,2,0,a4
        clr.w   (a4)+
        bra     .drawnow

.dz02dom_pl
        PUTMSG  40,<"DZ02 PL">
        lea     pd_LinesFromBuffer(a6),a4
        COPYLINEDATA a1,1,1,a4
        COPYLINEDATA a0,0,1,a4
        clr.w   (a4)+
        PUTMSG  50,<"Right">
        lea     pd_LinesToBuffer(a6),a4
        COPYLINEDATA a2,2,0,a4
        COPYLINEDATA a3,3,0,a4
        clr.w   (a4)+
        bra     .drawnow

.dz13dom_mi
        PUTMSG  40,<"DZ13 MI">
        lea     pd_LinesFromBuffer(a6),a4
        COPYLINEDATA a3,3,0,a4
        COPYLINEDATA a0,0,0,a4
        clr.w   (a4)+
        PUTMSG  50,<"Right">
        lea     pd_LinesToBuffer(a6),a4
        COPYLINEDATA a2,2,1,a4
        COPYLINEDATA a1,1,1,a4
        clr.w   (a4)+
        bra     .drawnow

.dz02dom_mi
        PUTMSG  40,<"DZ02 MI">
        lea     pd_LinesFromBuffer(a6),a4
        COPYLINEDATA a0,0,0,a4
        COPYLINEDATA a1,1,0,a4
        clr.w   (a4)+
        PUTMSG  50,<"Right">
        lea     pd_LinesToBuffer(a6),a4
        COPYLINEDATA a3,3,1,a4
        COPYLINEDATA a2,2,1,a4
        clr.w   (a4)+
        ;bra     .drawnow

.drawnow
        POPM
        lea     pd_LinesFromBuffer(a6),a0
        lea     pd_LinesToBuffer(a6),a2
        ext.w   d6
        asr.w   #gouraudColShift-8,d6
        add.w   d6,d6
.drawloop
        move.w  (a0)+,d1
        beq.s   .end
        move.w  (a0)+,d0
        move.w  (a2)+,d3
        beq.s   .end
        move.w  (a2)+,d2
        PUTMSG  40,<"%d: line %d,%d to %d,%d">,d6,d0,d1,d2,d3

        move.w  .graycodebits(pc,d6.w),d4
        bmi.s   .skipdraw
        PUSHM   a0/a1
        move.l  pd_CurrCubeLinePtr(a6),a0
        adda.w  d4,a0
        bsr     gou_draw_singledot_line_bq
        POPM
.skipdraw
        addq.w  #2,d6
        bra.s   .drawloop
.end
        ;clr.l   -bql_SIZEOF+bq_Next(a4)
        rts

        ; val grayCode3Bits = arrayOf(0, 1, 0, 2, 0, 1, 0, 2) -> 1,0,2,0,1,0
        ; val grayCode3Index = arrayOf(0, 1, 3, 2, 6, 7, 5, 4)

        ; val grayCode4Bits = arrayOf(0, 1, 2, 3, 2, 1, 0, 2, 0, 3, 0, 1, 3, 2, 3, 1) -> 1,2,3,2,1,0  ,2,0,3,0,1,3,2,3
        ; val grayCode4Index = arrayOf(0, 1, 3, 7, 15, 11, 9, 8, 12, 13, 5, 4, 6, 14, 10, 2)

.graycodebits
        dc.w    -1,-1,-1,0*(CUBE_BUF_WIDTH/8)
        dc.w    1*(CUBE_BUF_WIDTH/8),2*(CUBE_BUF_WIDTH/8),3*(CUBE_BUF_WIDTH/8),2*(CUBE_BUF_WIDTH/8),1*(CUBE_BUF_WIDTH/8),0*(CUBE_BUF_WIDTH/8)
        dc.w    2*(CUBE_BUF_WIDTH/8),0*(CUBE_BUF_WIDTH/8),3*(CUBE_BUF_WIDTH/8),0*(CUBE_BUF_WIDTH/8),1*(CUBE_BUF_WIDTH/8),3*(CUBE_BUF_WIDTH/8)
        dc.w    2*(CUBE_BUF_WIDTH/8),3*(CUBE_BUF_WIDTH/8)
        dc.w    -1,-1,-1,-1,-1
        dc.w    -1,-1,-1,-1
        dc.w    -1,-1,-1,-1,-1
        dc.w    -1,-1,-1,-1

;----------------------------------------------------------------------------------
; Draw regular blitter line to blitter queue
;
; in    d0.w    x0
;   d1.w    y0
;   d2.w    x1
;   d3.w    y1
;   a0  bitplane
;   a4  blitterqueue struct

gou_draw_singledot_line_bq:
        cmp.w   d1,d3
        bgt.s   .downward
        bne.s   .cont
        rts
.cont   exg     d0,d2
        exg     d1,d3
.downward
        move.w  d1,d5
        lsl.w   #6,d5               ; replaced mulu by shift (CUBE_BUF_WIDTH)
        ;mulu   d4,d5
        adda.w  d5,a0

        moveq.l #-16,d4
        and.w   d0,d4
        lsr.w   #3,d4
        add.w   d4,a0

        moveq.l #15,d4
        and.w   d0,d4
        ror.w   #4,d4
        or.w    #BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|(BLT_A&BLT_B^BLT_C),d4
        swap    d4

        sub.w   d0,d2
        bpl.s   .positiveDX
        neg.w   d2
        addq.w  #1,d4
.positiveDX
        sub.w   d1,d3
        cmp.w   d2,d3
        bls.s   .absDyLessThanAbsDx
        exg     d2,d3
        addq.w  #4,d4
.absDyLessThanAbsDx
        move.b  .octants(pc,d4.w),d4

        add.w   d3,d3       ; 2 * dy
        move.w  d3,d5
        sub.w   d2,d5       ; 2 * dy - dx
        bpl.s   .positiveGradient
        or.w    #BLTCON1F_SIGN,d4
.positiveGradient
        add.w   d5,d5       ; 4 * dy - 2 * dx
        ;cmp.w   #20,d2
        ;sgt     bql_LongLine(a4)
        add.w   d2,d2       ; 2 * dx
        add.w   d2,d2       ; 4 * dx
        add.w   d3,d3       ; 4 * dy

        move.w  d3,d0
        sub.w   d2,d3       ; 4 * (dy - dx)

        addq.w  #4,d2       ; extra word height
        lsl.w   #4,d2
        addq.w  #2,d2       ; width == 2

        move.l  d4,bql_BltCon01(a4)
        movem.w d0/d3/d5,bql_BltBMod(a4)  ; 4 * dy
        ;move.w d3,bql_BltAMod(a4)  ; 4 * (dy - dx)
        ;move.w d5,bql_BltAPtLo(a4) ; 4 * dy - 2 * dx
        move.l  a0,bql_BltCPt(a4)
        move.w  d2,bql_BltSize(a4)
        move.l  a4,a0
        CALLFW  AddToBlitterQueue
        lea     bql_SIZEOF(a4),a4
        rts

.octants
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_SUD                                ; octant 7
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_AUL                   ; octant 4
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_SUL                   ; octant 0
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_SUL|BLTCON1F_AUL      ; octant 3
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|0                                           ; octant 6
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_SUL                                ; octant 5
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_AUL                                ; octant 1
        dc.b    BLTCON1F_SING|BLTCON1F_LINE|BLTCON1F_SUL|BLTCON1F_AUL                   ; octant 2

;--------------------------------------------------------------------

gou_bq_InitLineDraw:
        PUTMSG  40,<"InitLineDraw">
        moveq.l #-1,d0
        move.w  #BLTCON1F_LINE,bltcon1(a5)
        move.w  #$8000,bltadat(a5)
        move.l  d0,bltafwm(a5)
        move.w  d0,bltbdat(a5)
        move.w  #(CUBE_BUF_WIDTH/8)*CUBE_PLANES,bltcmod(a5)
        BLTHOGON
        moveq.l #0,d0
        rts

gou_bq_LineDraw:
        PUTMSG  40,<"LineDraw %p">,a0
        move.l  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltcpt(a5)
        move.l  (a0)+,bltbmod(a5)
        move.l  (a0)+,bltapt+2(a5)
        move.l  (a0)+,bltdpt+2(a5)
        rts

gou_bq_FillCube:
        PUTMSG  40,<"FillCube">
        moveq.l #-1,d0
        lea     bltcon0(a5),a1
        move.l  (a0)+,(a1)+     ; bltcon0
        move.l  d0,(a1)+        ; bltafwm
        move.l  (a0)+,bltamod(a5)
        addq.l  #8,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)      ; bltsize
        rts

gou_bq_Clear:
        PUTMSG  40,<"Clear">
        move.l  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  (a0)+,bltdmod(a5)
        move.w  (a0)+,bltcdat(a5)
        move.w  (a0)+,bltsize(a5)
        rts

gou_bq_InPlaceModify:
        PUTMSG  40,<"InPlaceModify">
        BLTHOGON
        moveq.l #-1,d0
        lea     bltcon0(a5),a1
        move.l  (a0)+,(a1)+     ; bltcon0
        move.l  d0,(a1)+        ; bltafwm
        move.l  (a0)+,d0
        addq.l  #8,a1           ; skip bltcpt/bltbpt
        move.l  d0,(a1)+        ; bltapt
        move.l  d0,(a1)+        ; bltdpt(a5)
        move.w  (a0)+,d0
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.w  (a0)+,bltcdat(a5)
        move.w  (a0)+,(a1)
        BLTWAIT
        rts

gou_bq_ADCopy:
        PUTMSG  40,<"ADCopy">
        BLTHOGON
        lea     bltcon0(a5),a1
        move.l  (a0)+,(a1)+     ; bltcon0
        move.l  (a0)+,(a1)+     ; bltafwm
        move.l  (a0)+,bltamod(a5)
        addq.l  #8,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)      ; bltsize
        BLTWAIT
        rts


;--------------------------------------------------------------------
;--------------------------------------------------------------------

SinScale MACRO
        muls    (a5,\1.w),\2
        add.l   \2,\2
        add.l   \2,\2
        swap    \2
        ENDM

CosScale MACRO
        muls    (a0,\1.w),\2
        add.l   \2,\2
        add.l   \2,\2
        swap    \2
        ENDM

SinScaleK MACRO
        move.w  (a5,\1.w),\3
        muls    \3,\2
        add.l   \2,\2
        add.l   \2,\2
        swap    \2
        ENDM

CosScaleK MACRO
        move.w  (a0,\1.w),\3
        muls    \3,\2
        add.l   \2,\2
        add.l   \2,\2
        swap    \2
        ENDM

ScalePrev MACRO
        muls    \1,\2
        add.l   \2,\2
        add.l   \2,\2
        swap    \2
        ENDM

gou_rotate_cube: ; a1 = CubeData
        DISABLE_INTS
        PUSHM   a1/a5
        lea     cd_CubeNormals+3*3*2(a1),a1
        move.w  pd_CubeSize(a6),d7

        move.l  fw_SinTable(a6),a5
        move.l  fw_CosTable(a6),a0  ; suppress M68kDeadWrite
        movem.w pd_Ax(a6),a2-a4     ;ax,ay,az

        ; --- original formula ---
        ; x1 = x0*cos(az) - y0*sin(az)
        ; y1 = x0*sin(az) + y0*cos(az)
        ; z1 = z1

        ; x2 = x1
        ; y2 = y1*cos(ax) - z1*sin(ax)
        ; z2 = y1*sin(ax) + z1*cos(ax)

        ; x3 = z2*sin(ay) + x2*cos(ay)
        ; y3 = y2
        ; z3 = z2*cos(ay) - x2*sin(ay)
        ; ----

        ; x1 = sx*cos(az) - sy*sin(az)
        ; y1 = sx*sin(az) + sy*cos(az)

        ; z2 = y1*sin(ax) + sz*cos(ax)
        ; y3 = y1*cos(ax) - sz*sin(ax)

        ; x3 = z2*sin(ay) + x1*cos(ay)
        ; z3 = z2*cos(ay) - x1*sin(ay)

        ; for z-normal vector (0, 0, 1)

        ; z2 = s*cos(ax)
        ; y3 = -s*sin(ax)

        ; x3 = z2*sin(ay)
        ; z3 = z2*cos(ay)

        move.w  d7,d3
        move.w  d7,d2
        SinScale a2,d2          ;d2 = -y = s*sin(ax)
        neg.w   d2

        CosScale a2,d3          ;d3 = z2 = s*cos(ax)
        move.w  d3,d1
        SinScale a3,d1          ;d1 = x = z2*sin(ay) = s*cos(ax) * sin(ay)
        CosScale a3,d3          ;d3 = z = z2*cos(ay) = s*cos(ax) * cos(ay)

        movem.w  d1-d3,-(a1)    ;x/y/z

        ; for y-normal vector (0, 1, 0)
        ; x1 = s*sin(az) ; also used in x-normal
        ; y1 = s*cos(az) ; also used in x-normal

        ; z2 = y1*sin(ax)
        ; y3 = y1*cos(ax) = s*cos(az)*cos(ax)

        ; x3 = z2*sin(ay) - x1*cos(ay) = y1*sin(ax)*sin(ay) - x1*cos(ay) = s*cos(az)*sin(ax)*sin(ay) - s*sin(az)*cos(ay)
        ; z3 = z2*cos(ay) + x1*sin(ay) = y1*sin(ax)*cos(ay) + x1*sin(ay) = s*cos(az)*sin(ax)*cos(ay) + s*sin(az)*sin(ay)

        move.w  d7,d6
        SinScale a4,d7          ;d7 = x1 = s*sin(az)
        CosScale a4,d6          ;d6 = y1 = s*cos(az)

        move.w  d6,d3
        move.w  d3,d2
        CosScaleK a2,d2,d5      ;d2 = y = y1*cos(ax) = s*cos(az) * cos(ax)
        swap    d5              ;keep cos(ax) in upper word for later
        SinScaleK a2,d3,d0      ;d3 = z2 = y1*sin(ax) = s*cos(az) * sin(ax)
        swap    d0              ;keep sin(ax) in upper word for later

        move.w  d3,d1
        SinScaleK a3,d1,d5      ;d1 = z2*sin(ay) (keep sin(ay) in d5)
        move.w  d7,d4
        ScalePrev d5,d4         ;d4 = x1*sin(ay)

        CosScaleK a3,d3,d0      ;d3 = z2*cos(ay) (keep cos(ay) in d0)
        add.w   d4,d3           ;d3 = z = z2*cos(ay) + x1*sin(ay) = s*cos(az)*sin(ax)*cos(ay) + s*sin(az)*sin(ay)

        move.w  d7,d4
        ScalePrev d0,d4         ;d4 = x1*cos(ay)
        sub.w   d4,d1           ;d1 = x = z2*sin(ay) - x1*cos(ay) = s*cos(az)*sin(ax)*sin(ay) - s*sin(az)*cos(ay)

        movem.w d1-d3,-(a1)     ;x/y/z

        ; for x-normal vector (1, 0, 0)
        ; x1 = s*cos(az)
        ; y1 = s*sin(az)

        ; z2 = y1*sin(ax)
        ; y3 = y1*cos(ax) = s*sin(az)*cos(ax)

        ; x3 = z2*sin(ay) + x1*cos(ay) = y1*sin(ax)*sin(ay) + x1*cos(ay) = s*sin(az)*sin(ax)*sin(ay) + s*cos(az)*cos(ay)
        ; z3 = z2*cos(ay) - x1*sin(ay) = y1*sin(ax)*cos(ay) - x1*sin(ay) = s*sin(az)*sin(ax)*cos(ay) - s*cos(az)*sin(ay)

        swap    d5              ; d5 = cos(ax)
        move.w  d7,d2
        ScalePrev d5,d2         ; d2 = y = s*sin(az) * cos(ax)

        swap    d0              ; d0 = sin(ax)
        ScalePrev d0,d7         ; d7 = z2 = s*sin(az) * sin(ax)

        swap    d5              ; d5 = sin(ay)
        move.w  d7,d1
        ScalePrev d5,d1         ; d1 = z2*sin(ay) = s*sin(az) * sin(ax) * sin(ay)

        swap    d0              ; d0 = cos(ay)
        move.w  d6,d4
        ScalePrev d0,d4         ; d4 = x1*cos(ay) = s*cos(az)*cos(ay)
        add.w   d4,d1           ; d1 = x = z2*sin(ay) + x1*cos(ay) = s*sin(az)*sin(ax)*sin(ay) + s*cos(az)*cos(ay)

        ScalePrev d5,d6         ; d6 = x1*sin(ay) = s*cos(az)*sin(ay)

        move.w  d7,d3
        ScalePrev d0,d3         ; d3 = z2*cos(ay) = s*sin(az) * sin(ax) * cos(ay)
        sub.w   d6,d3           ; d3 = z = z2*cos(ay) - x1*sin(ay) = s*sin(az)*sin(ax)*cos(ay) - s*cos(az)*sin(ay)

        movem.w d1-d3,-(a1)    ;x/y/z

        move.w  d1,d0
        add.w   d0,d0
        move.w  d2,a2
        add.w   d2,a2
        move.w  d3,d7
        add.w   d7,d7

        movem.w 3*2(a1),d4-d6

        add.w   d4,d1
        add.w   d5,d2
        add.w   d6,d3

        lea     12(a1),a3

        add.w   (a3)+,d1
        add.w   (a3)+,d2
        add.w   (a3)+,d3
        move.l  a1,a3
        POPM
        ENABLE_INTS

        movem.w d1-d3,cd_Coords+6*3*2(a1)

        neg.w   d1
        neg.w   d2
        neg.w   d3
        movem.w d1-d3,cd_Coords+0*3*2(a1) ; 0*3*2(a1)

        add.w   d0,d1
        add.w   a2,d2
        add.w   d7,d3
        movem.w d1-d3,cd_Coords+1*3*2(a1)

        neg.w   d1
        neg.w   d2
        neg.w   d3
        movem.w d1-d3,cd_Coords+7*3*2(a1)

        sub.w   d4,d1
        sub.w   d4,d1
        sub.w   d5,d2
        sub.w   d5,d2
        sub.w   d6,d3
        sub.w   d6,d3
        movem.w d1-d3,cd_Coords+3*3*2(a1)

        neg.w   d1
        neg.w   d2
        neg.w   d3
        movem.w d1-d3,cd_Coords+5*3*2(a1)

        sub.w   d0,d1
        sub.w   a2,d2
        sub.w   d7,d3
        movem.w d1-d3,cd_Coords+4*3*2(a1)

        neg.w   d1
        neg.w   d2
        neg.w   d3
        movem.w d1-d3,cd_Coords+2*3*2(a1)

        ; create flipped normals
        movem.w (a3)+,d0-d7/a0
        neg.w   d0
        neg.w   d1
        neg.w   d2
        neg.w   d3
        neg.w   d4
        neg.w   d5
        neg.w   d6
        neg.w   d7
        exg     d0,a0
        neg.w   d0
        exg     d0,a0
        movem.w d0-d7/a0,(a3)
        rts

;--------------------------------------------------------------------

gou_cube_advance_scene_standard_movement:
        move.w  #1023*2,d6
        movem.w pd_Ax(a6),d0-d5
        add.w   d3,d0
        add.w   d4,d1
        add.w   d5,d2
        and.w   d6,d0
        and.w   d6,d1
        and.w   d6,d2
        movem.w d0-d2,pd_Ax(a6)
        rts

;********************************************************************

gou_gray_palette:
        ds.w    16

gou_gray_zebra_palette:
        ds.w    16

; https://gradient-blaster-grahambates.vercel.app/?points=000@0,379@5,dc6@9,fff@16&steps=256&blendMode=oklab&ditherMode=off&target=amigaOcs
gou_sorted_palette:
        dc.w    $413,$002,$023,$035,$257,$379,$589,$8a8
        dc.w    $bb8,$dc6,$dd7,$ed9,$eea,$eec,$ffd,$fff

gou_zebra_palette:
        dc.w    $134,$112,$011,$145,$022,$379,$123,$49a
        dc.w    $133,$4bb,$244,$6dc,$354,$aed,$455,$dfe

gou_gray_shuffle:
        dc.w    0*2,1*2,3*2,7*2,15*2,11*2,9*2,8*2,12*2,13*2,5*2,4*2,6*2,14*2,10*2,2*2

gou_mauve_palette:
        REPT    16
        dc.w    $413
        ENDR

gou_black_palette:
        ds.w    16

PLANELINEMASK  MACRO
        dc.w   ((1<<\1)|(1<<\2)|(1<<\3)|(1<<\4))
        ENDM

PLANECOORDMASK MACRO
        dc.w   (1<<\1)|(1<<\2)|(1<<\3)|(1<<\4)
        ENDM

PROJPLANE   MACRO
        dc.w    (\1)*4,(\2)*4,(\3)*4,(\4)*4
        ENDM

ROTATEDPLANE   MACRO
        dc.w    (\1)*6,(\2)*6,(\3)*6,(\4)*6
        ENDM

PLANELINES  MACRO
        dc.w    cd_IntCubeLines+(\1)*il_SIZEOF
        dc.w    cd_IntCubeLines+(\2)*il_SIZEOF
        dc.w    cd_IntCubeLines+(\3)*il_SIZEOF
        dc.w    cd_IntCubeLines+(\4)*il_SIZEOF
        ENDM

gou_cube_plane_coords:
        PLANELINEMASK  5,10,1,9
        PLANECOORDMASK 5,6,2,1

        PLANELINEMASK  4,5,6,7
        PLANECOORDMASK 4,5,6,7

        PLANELINEMASK  6,11,2,10
        PLANECOORDMASK 6,7,3,2

        PLANELINEMASK  7,8,3,11
        PLANECOORDMASK 7,4,0,3

        PLANELINEMASK  0,1,2,3
        PLANECOORDMASK 0,1,2,3

        PLANELINEMASK  4,9,0,8
        PLANECOORDMASK 4,5,1,0

;
;   0_____________1
;   /|           /|
;  /_|__________/ |
; |3 |         |2 |
; |  |         |  |
; |  |         |  |
; | 4|_________|__|5
; | /          | /
;7|/___________|/6
;
; lines:
;  0: 0 <-> 1
;  1: 1 <-> 2
;  2: 2 <-> 3
;  3: 3 <-> 0
;  4: 4 <-> 5
;  5: 5 <-> 6
;  6: 6 <-> 7
;  7: 7 <-> 4
;  8: 0 <-> 4
;  9: 1 <-> 5
; 10: 2 <-> 6
; 11: 3 <-> 7
gou_proj_cube_planes:
        ; attention, inverse order as plane number is counted backwards
        PROJPLANE 4,5,1,0
        PROJPLANE 0,1,2,3
        PROJPLANE 7,4,0,3
        PROJPLANE 6,7,3,2
        PROJPLANE 4,5,6,7
        PROJPLANE 5,6,2,1

gou_rotated_cube_planes:
        ; attention, inverse order as plane number is counted backwards
        ROTATEDPLANE 4,5,1,0
        ROTATEDPLANE 0,1,2,3
        ROTATEDPLANE 7,4,0,3
        ROTATEDPLANE 6,7,3,2
        ROTATEDPLANE 4,5,6,7
        ROTATEDPLANE 5,6,2,1

gou_cube_planes_to_lines:
        ; attention, inverse order as plane number is counted backwards
        PLANELINES  4,9,0,8
        PLANELINES  0,1,2,3
        PLANELINES  7,8,3,11
        PLANELINES  6,11,2,10
        PLANELINES  4,5,6,7
        PLANELINES  5,10,1,9

gou_cube_lines:
        dc.w    0*4,1*4  ;  0 -> 01
        dc.w    1*4,2*4  ;  1 -> 12
        dc.w    2*4,3*4  ;  2 -> 23
        dc.w    0*4,3*4  ;  3 -> 30

        dc.w    4*4,5*4  ;  4 -> 45
        dc.w    5*4,6*4  ;  5 -> 56
        dc.w    6*4,7*4  ;  6 -> 67
        dc.w    4*4,7*4  ;  7 -> 74

        dc.w    0*4,4*4  ;  4 -> 04
        dc.w    1*4,5*4  ;  5 -> 15
        dc.w    2*4,6*4  ;  6 -> 26
        dc.w    3*4,7*4  ;  7 -> 37

;--------------------------------------------------------------------

        section "gou_copper",data,chip

gou_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency

        COP_MOVE bplcon3,$0c00

        COP_MOVE fmode,$0000            ; fixes the aga modulo problem
        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon2,$0024
        COP_MOVE bpl1mod,(CUBE_WIDTH/8)*(CUBE_PLANES-1)
        COP_MOVE bpl2mod,(CUBE_WIDTH/8)*(CUBE_PLANES-1)

gou_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

gou_bendit_sprite:
        incbin  "../data/gouraud/bendit128x128x4.SPR"

blitter_temp_output_word:
        dc.w    0

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