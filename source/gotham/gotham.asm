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

FW_MUSIC_SUPPORT            = 0
FW_MUSIC_PLAYER_CHOICE      = 0 ; 0 = None, 1 = LSP, 2 = LSP_CIA, 3 = P61A, 4 = Pretracker (CPU DMA wait), 5 = Pretracker Turbo (Copper wait)
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
FW_VBL_MUSIC_IRQ            = 1 ; enable calling of VBL based music ticking (disable, if using CIA timing!)
FW_BLITTERQUEUE_SUPPORT     = 1 ; enable blitter queue support
FW_A5_A6_UNTOUCHED          = 1 ; speed up blitter queue if registers a5/a6 are never changed in main code

FW_LZ4_SUPPORT              = 0 ; compile in LZ4 decruncher
FW_DOYNAX_SUPPORT           = 0 ; compile in doynax decruncher
FW_ZX0_SUPPORT              = 0 ; compile in ZX0 decruncher

FW_DO_FANCY_WORKBENCH_STUFF = 0 ; enable pre- and post-hook (os startup only)

ENABLE_PART_MUSIC           = 0

        ENDC

GOTHAM_WIDTH    = 320
GOTHAM_HEIGHT   = 180
GOTHAM_PLANES   = 2

HAM_TECH_SAMPLE_SIZE = 24064

COP_LIST_SIZE   = 100*4
GOTHAM_BQ_SIZE  = 2048

CHIPMEM_SIZE = COP_LIST_SIZE*2+2*(GOTHAM_WIDTH/8)*GOTHAM_HEIGHT*GOTHAM_PLANES
FASTMEM_SIZE = 2048*4+4*GOTHAM_BQ_SIZE

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"


; Memory use:
; Playfields:
; - 320 x 180 x  3 x 2  =  43200

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_LastPlanesPtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        APTR    pd_CurrBQPtr
        APTR    pd_LastBQPtr
        APTR    pd_LastLastBQPtr
        UBYTE   pd_DbToggle
        ALIGNWORD
        UWORD   pd_BqToggle

        UWORD   pd_PartCountDown
        UWORD   pd_HamRotation
        UWORD   pd_HamZoom
        UWORD   pd_LinePattern
        BOOL    pd_EnableHamZoom

        APTR    pd_Blend1Ptr
        APTR    pd_Blend2Ptr

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        APTR    pd_DbBuffer1
        APTR    pd_DbBuffer2
        APTR    pd_BQBuffer1
        APTR    pd_BQBuffer2
        APTR    pd_BQBuffer3
        APTR    pd_BQBuffer4

        APTR    pd_HamTechSample

        STRUCT  pd_MeanwhilePalette,3*cl_SIZEOF
        STRUCT  pd_BlendPalette,15*cl_SIZEOF
        STRUCT  pd_HamTechPalette,15*cl_SIZEOF

        APTR    pd_BigSinCosTable

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        bsr.s   gth_init_vars

        lea     gth_copperlist,a0
        CALLFW  SetCopper

        bsr     gth_texts
        bsr     gth_init_sine_table
        bsr     gth_main

        CALLFW  SetBaseCopper

        rts

;--------------------------------------------------------------------

gth_init_vars:
        IFD     FW_DEMO_PART
        move.l  fw_GlobalUserData(a6),pd_HamTechSample(a6)
        ELSE
        move.l  #gth_psenough_ham,pd_HamTechSample(a6)
        ENDC

        move.l  #(COP_LIST_SIZE*2),d0
        CALLFW  AllocChip

        PUTMSG  10,<"Copperlist 1 %p">,a0
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)
        lea     COP_LIST_SIZE(a0),a0
        PUTMSG  10,<"Copperlist 2 %p">,a0
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        move.l  #2*(GOTHAM_WIDTH/8)*GOTHAM_HEIGHT*GOTHAM_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"DbBuffer %p">,a0
        move.l  a0,pd_DbBuffer1(a6)
        move.l  a0,pd_CurrPlanesPtr(a6)
        lea     (GOTHAM_WIDTH/8)*GOTHAM_HEIGHT*GOTHAM_PLANES(a0),a0
        move.l  a0,pd_DbBuffer2(a6)
        move.l  a0,pd_LastPlanesPtr(a6)

        move.l  #2048*4,d0
        CALLFW  AllocFast
        move.l  a0,pd_BigSinCosTable(a6)

        move.l  #4*GOTHAM_BQ_SIZE,d0
        CALLFW  AllocFast
        move.l  a0,pd_BQBuffer1(a6)
        move.l  a0,pd_CurrBQPtr(a6)
        clr.l   (a0)
        lea     GOTHAM_BQ_SIZE(a0),a0
        move.l  a0,pd_BQBuffer2(a6)
        move.l  a0,pd_LastBQPtr(a6)
        clr.l   (a0)
        lea     GOTHAM_BQ_SIZE(a0),a0
        move.l  a0,pd_BQBuffer3(a6)
        move.l  a0,pd_LastLastBQPtr(a6)
        clr.l   (a0)
        lea     GOTHAM_BQ_SIZE(a0),a0
        move.l  a0,pd_BQBuffer4(a6)
        clr.l   (a0)

        rts

;--------------------------------------------------------------------

gth_init_sine_table:
        move.l  fw_SinTable(a6),a0
        move.l  fw_CosTable(a6),a1
        move.w  (a1),d2
        move.l  pd_BigSinCosTable(a6),a2
        PUTMSG  10,<"BigSinCosTable %p">,a2
        move.w  #1023-1,d7
.bloop
        move.w  (a0)+,d0
        move.w  (a1)+,d1
        move.w  d0,(a2)+
        move.w  d1,(a2)+
        add.w   (a0),d0
        add.w   (a1),d1
        asr.w   #1,d0
        asr.w   #1,d1
        move.w  d0,(a2)+
        move.w  d1,(a2)+
        dbra    d7,.bloop

        move.w  (a0)+,d0
        move.w  (a1)+,d1
        move.w  d0,(a2)+
        move.w  d1,(a2)+
        add.w   (a0),d0
        add.w   d2,d1
        asr.w   #1,d0
        asr.w   #1,d1
        move.w  d0,(a2)+
        move.w  d1,(a2)+
        rts

;--------------------------------------------------------------------

gth_texts:
        move.w  #500,pd_PartCountDown(a6)

        move.l  #gth_gothamcity_text,pd_Blend1Ptr(a6)
        move.l  #gth_gotham_text,pd_Blend2Ptr(a6)

        moveq.l #3+15,d0
        moveq.l #0,d1
        lea     pd_MeanwhilePalette(a6),a1
        CALLFW  InitPaletteLerpSameColor

        moveq.l #3,d0
        moveq.l #32,d1
        lea     gth_red_palette(pc),a0
        lea     pd_MeanwhilePalette(a6),a1
        CALLFW  FadePaletteTo

        lea     .script(pc),a0
        CALLFW  InstallScript

.loop   CALLFW  VSyncWithTask
        bsr     gth_flip_db_frame

        CALLFW  CheckScript

        moveq.l #3,d0
        lea     pd_MeanwhilePalette(a6),a1
        CALLFW  DoFadePaletteStep

        moveq.l #15,d0
        lea     pd_BlendPalette(a6),a1
        CALLFW  DoFadePaletteStep

        bsr     gth_create_texts_copperlist

        bsr     gth_update_copper_list_pointers

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

.script
        dc.w    30,.fade_in_blend1_slow-*
        dc.w    160,.fade_in_blend2-*
        dc.w    180,.fade_in_blend1-*
        dc.w    195,.fade_in_blend2-*
        dc.w    220,.fade_in_blend1-*
        dc.w    228,.fade_in_blend2-*
        dc.w    280,.gotham-*
        dc.w    300,.fade_in_blend1-*
        dc.w    310,.fade_in_blend2-*
        dc.w    330,.fade_in_greenish_blend1-*
        dc.w    340,.fade_in_blend2-*
        dc.w    355,.fade_in_greenish_blend1-*
        dc.w    410,.ham-*
        dc.w    420,.fade_out_meanwhile-*
        dc.w    425,.fade_in_blend1-*
        dc.w    430,.fade_in_greenish_blend1-*
        dc.w    435,.fade_in_blend1-*
        dc.w    450,.fade_in_blend2-*
        dc.w    0

.fade_in_blend1
        moveq.l #32,d1
        lea     gth_red_blend1_palette(pc),a0
        bra.s   .fade

.fade_in_blend1_slow
        moveq.l #64,d1
        lea     gth_red_blend1_palette(pc),a0
        bra.s   .fade

.fade_in_greenish_blend1
        moveq.l #32,d1
        lea     gth_greenish_blend1_palette(pc),a0
        bra.s   .fade

.fade_in_blend2
        moveq.l #32,d1
        lea     gth_red_blend2_palette(pc),a0
.fade
        moveq.l #15,d0
        lea     pd_BlendPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.fade_out_meanwhile
        moveq.l #3,d0
        moveq.l #32,d1
        lea     gth_black_palette(pc),a0
        lea     pd_MeanwhilePalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.gotham move.l  #gth_hameelinna_text,pd_Blend1Ptr(a6)
        rts

.ham    move.l  #gth_ham_text,pd_Blend2Ptr(a6)
        rts

;--------------------------------------------------------------------

gth_main:
        move.w  #170,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueSingleFrame
        bsr     gth_clear_db_buffers

        move.w  #$8000,pd_LinePattern(a6)
        move.w  #288,pd_HamZoom(a6)

        moveq.l #15,d0
        lea     gth_invisible_line_palette(pc),a0
        lea     pd_BlendPalette(a6),a1
        CALLFW  InitPaletteLerp

        moveq.l #15,d0
        moveq.l #32,d1
        lea     gth_white_line_palette(pc),a0
        lea     pd_BlendPalette(a6),a1
        CALLFW  FadePaletteTo

        moveq.l #15,d0
        lea     gth_black_palette(pc),a0
        lea     pd_HamTechPalette(a6),a1
        CALLFW  InitPaletteLerp

        moveq.l #15,d0
        moveq.l #32,d1
        lea     gth_ham_tech_palette(pc),a0
        lea     pd_HamTechPalette(a6),a1
        CALLFW  FadePaletteTo

        lea     .script(pc),a0
        CALLFW  InstallScript

        TERMINATE_BLITTER_QUEUE

.loop   CALLFW  VSyncWithTask
        bsr     gth_flip_db_frame
        bsr     gth_flip_bq_buffer

        move.l  pd_LastLastBQPtr(a6),a0
        tst.l   (a0)
        beq.s   .skipempty
        BLTWAIT
        CALLFW  TriggerCustomBlitterQueue
.skipempty

        CALLFW  CheckScript
        move.l  pd_CurrBQPtr(a6),a4
        bsr     gth_draw_ham

        TERMINATE_BLITTER_QUEUE

        ror.w   pd_LinePattern(a6)
        tst.w   pd_EnableHamZoom(a6)
        beq.s   .nohamzoom
        move.w  pd_HamZoom(a6),d0
        move.w  d0,d1
        lsr.w   #5,d1
        add.w   d1,d0
        move.w  d0,pd_HamZoom(a6)
.nohamzoom

        CALLFW  JoinBlitterQueue

        BLTWAIT
        move.l  pd_CurrBQPtr(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        bsr     gth_fix_bq_for_clear

        moveq.l #15,d0
        lea     pd_BlendPalette(a6),a1
        CALLFW  DoFadePaletteStep

        moveq.l #15,d0
        lea     pd_HamTechPalette(a6),a1
        CALLFW  DoFadePaletteStep

        bsr     gth_create_main_copperlist

        CALLFW  JoinBlitterQueue

        bsr     gth_update_copper_list_pointers

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

.script
        dc.w    1,.done1-*
        dc.w    2,.done2-*
        dc.w    10,.pattern2-*
        dc.w    20,.pattern3-*
        dc.w    25,.done1echo-*
        dc.w    27,.done2echo-*
        dc.w    30,.pattern4-*
        dc.w    40,.pattern5-*
        dc.w    42,.killaudioloops-*
        dc.w    50,.pattern8-*
        dc.w    60,.pattern12-*
        dc.w    70,.pattern16-*
        dc.w    138,.fadeout-*
        dc.w    0

.done1
        move.w  #HAM_TECH_SAMPLE_SIZE/2,aud0+ac_len(a5)
        move.l  pd_HamTechSample(a6),aud0+ac_ptr(a5)
        move.w  #64,aud0+ac_vol(a5)
        move.w  #350,aud0+ac_per(a5)
        move.w  #DMAF_SETCLR|DMAF_AUD0,dmacon(a5)
        rts

.done2
        move.w  #HAM_TECH_SAMPLE_SIZE/2,aud1+ac_len(a5)
        move.l  pd_HamTechSample(a6),aud1+ac_ptr(a5)
        move.w  #64,aud1+ac_vol(a5)
        move.w  #349,aud1+ac_per(a5)
        move.w  #DMAF_SETCLR|DMAF_AUD1,dmacon(a5)
        rts

.done1echo
        move.w  #HAM_TECH_SAMPLE_SIZE/2,aud2+ac_len(a5)
        move.l  pd_HamTechSample(a6),aud2+ac_ptr(a5)
        move.w  #16,aud2+ac_vol(a5)
        move.w  #340,aud2+ac_per(a5)
        move.w  #DMAF_SETCLR|DMAF_AUD2,dmacon(a5)
        rts

.done2echo
        move.w  #HAM_TECH_SAMPLE_SIZE/2,aud3+ac_len(a5)
        move.l  pd_HamTechSample(a6),aud3+ac_ptr(a5)
        move.w  #16,aud3+ac_vol(a5)
        move.w  #341,aud3+ac_per(a5)
        move.w  #DMAF_SETCLR|DMAF_AUD3,dmacon(a5)
        rts

.pattern2
        move.w  #$8080,pd_LinePattern(a6)
        rts

.pattern3
        move.w  #$8420,pd_LinePattern(a6)
        rts

.pattern4
        move.w  #$8888,pd_LinePattern(a6)
        rts

.pattern5
        move.w  #$a264,pd_LinePattern(a6)
        rts

.pattern8
        move.w  #$aaaa,pd_LinePattern(a6)
        rts

.pattern12
        move.w  #$fafa,pd_LinePattern(a6)
        rts

.pattern16
        move.w  #$ffff,pd_LinePattern(a6)
        st      pd_EnableHamZoom(a6)
        moveq.l #15,d0
        moveq.l #32,d1
        lea     gth_line_only_palette(pc),a0
        lea     pd_BlendPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.killaudioloops
        move.l  fw_EmptySprite(a6),a0
        moveq.l #1,d0
        move.l  a0,aud0+ac_ptr(a5)
        move.w  d0,aud0+ac_len(a5)
        move.l  a0,aud1+ac_ptr(a5)
        move.w  d0,aud1+ac_len(a5)
        move.l  a0,aud2+ac_ptr(a5)
        move.w  d0,aud2+ac_len(a5)
        move.l  a0,aud3+ac_ptr(a5)
        move.w  d0,aud3+ac_len(a5)
        rts

.fadeout
        ;move.w  #DMAF_SETCLR|DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3,dmacon(a5)

        moveq.l #15,d0
        moveq.l #32,d1
        lea     gth_black_palette(pc),a0
        lea     pd_BlendPalette(a6),a1
        CALLFW  FadePaletteTo

        moveq.l #15,d0
        moveq.l #32,d1
        lea     gth_black_palette(pc),a0
        lea     pd_HamTechPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

;--------------------------------------------------------------------

gth_flip_db_frame:
        move.l  pd_CurrPlanesPtr(a6),pd_LastPlanesPtr(a6)
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        move.l  pd_DbBuffer2(a6),pd_CurrPlanesPtr(a6)
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        rts
.selb1
        move.l  pd_DbBuffer1(a6),pd_CurrPlanesPtr(a6)
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        rts

;--------------------------------------------------------------------

gth_flip_bq_buffer:
        move.l  pd_LastBQPtr(a6),pd_LastLastBQPtr(a6)
        move.l  pd_CurrBQPtr(a6),pd_LastBQPtr(a6)
        move.w  pd_BqToggle(a6),d0
        subq.w  #4,d0
        and.w   #3*4,d0
        move.w  d0,pd_BqToggle(a6)
        lea     pd_BQBuffer1(a6),a0
        move.l  (a0,d0.w),pd_CurrBQPtr(a6)
        rts

;--------------------------------------------------------------------

gth_update_copper_list_pointers:
        lea     gth_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

gth_clear_db_buffers:
        BLTHOGON
        BLTWAIT

        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_DbBuffer1(a6),bltdpt(a5)
        move.w  #((GOTHAM_WIDTH*2)>>4)|((GOTHAM_HEIGHT*GOTHAM_PLANES)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

gth_draw_ham:
        bsr     gth_blitter_line_init_bq

        move.l  pd_BigSinCosTable(a6),a0
        move.w  pd_HamRotation(a6),d0
        tst.w   pd_EnableHamZoom(a6)
        beq.s   .norotate
        add.w   #64,d0
        move.w  d0,pd_HamRotation(a6)
        and.w   #2047*4,d0

        move.b  (a0,d0.w),d0
        ext.w   d0
        lsl.w   #4,d0
        and.w   #2047*4,d0

.norotate
        move.l  (a0,d0.w),d6
        move.w  d6,d7       ; cos
        swap    d6          ; sin
        move.w  pd_HamZoom(a6),d0
        muls    d0,d6
        muls    d0,d7
        swap    d6
        swap    d7

        lea     gth_ham_line_h(pc),a2
        bsr     gth_draw_path
        bsr     gth_draw_path
        bsr     gth_draw_path


gth_draw_path:
        move.w  (a2)+,d2
        move.w  (a2)+,d3
        PUTMSG  30,<"1: %d,%d">,d2,d3

        move.w  d2,d4
        move.w  d3,d5
        muls    d7,d2
        muls    d6,d5
        sub.l   d5,d2
        swap    d2

        muls    d7,d3
        muls    d6,d4
        add.l   d4,d3
        swap    d3
        add.w   #GOTHAM_WIDTH/2,d2
        add.w   #GOTHAM_HEIGHT/2+1,d3

        move.w  d2,d0
        move.w  d3,d1
.loop   move.w  (a2)+,d2
        beq.s   .done2
        move.w  (a2)+,d3

        move.w  d2,d4
        move.w  d3,d5
        muls    d7,d2
        muls    d6,d5
        sub.l   d5,d2
        swap    d2

        muls    d7,d3
        muls    d6,d4
        add.l   d4,d3
        swap    d3
        add.w   #GOTHAM_WIDTH/2-1,d2
        add.w   #GOTHAM_HEIGHT/2+1,d3

        movem.w d2-d3/d6,-(sp)
        PUTMSG  40,<"%d,%d to %d,%d">,d0,d1,d2,d3
        move.w  #GOTHAM_WIDTH-1,d4
        move.w  #GOTHAM_HEIGHT-2,d5
        bsr     gth_clip_line
        beq.s   .skipline
        PUTMSG  40,<"After Clip: %d,%d to %d,%d">,d0,d1,d2,d3

        move.l  pd_CurrPlanesPtr(a6),a0
        bsr     gth_draw_blitter_line_aa_bq
.skipline
        movem.w (sp)+,d0/d1/d6
        bra.s   .loop
.done2  rts

;--------------------------------------------------------------------

gth_fix_bq_for_clear:
        moveq.l #0,d0
        move.l  pd_LastBQPtr(a6),a0
        bra.s   .entry

.bqfixloop
        move.b  d0,9(a0)
.entry
        move.l  (a0),a0
        move.l  a0,d1
        bne.s   .bqfixloop
        rts

;--------------------------------------------------------------------

gth_create_texts_copperlist:
        moveq.l #-2,d3
        move.l  pd_CurrCopListPtr(a6),a0

        moveq.l #15*2,d0
        and.w   fw_FrameCounter(a6),d0
        lea     gth_red_noise(pc),a2
        adda.w  d0,a2
        lea     pd_MeanwhilePalette(a6),a1
        move.w  #color+1*2,d0
        moveq.l #3-1,d7
.mwloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),d1
        add.w   (a2)+,d1
        move.w  d1,(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.mwloop

        lea     gth_meanwhile_text,a1
        COPPTMOVE a1,bplpt+0*4,d0
        lea     (320/8)*18(a1),a1
        COPPTMOVE a1,bplpt+1*4,d0

        move.w  #$5207+(33<<8),(a0)+
        move.w  d3,(a0)+
        COPIMOVE $2200,bplcon0
        move.w  #$5207+((33+18)<<8),(a0)+
        move.w  d3,(a0)+
        COPIMOVE $0200,bplcon0

        lea     pd_BlendPalette(a6),a1
        moveq.l #15-1,d7
        move.w  #color+1*2,d0
.blloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.blloop

        move.l  pd_Blend1Ptr(a6),a1
        COPPTMOVE a1,bplpt+0*4,d0
        lea     (320/8)*23(a1),a1
        COPPTMOVE a1,bplpt+1*4,d0
        move.l  pd_Blend2Ptr(a6),a1
        COPPTMOVE a1,bplpt+2*4,d0
        lea     (320/8)*23(a1),a1
        COPPTMOVE a1,bplpt+3*4,d0

        move.w  #$5207+(78<<8),(a0)+
        move.w  d3,(a0)+
        COPIMOVE $4200,bplcon0
        move.w  #$5207+((78+23)<<8),(a0)+
        move.w  d3,(a0)+
        COPIMOVE $0200,bplcon0

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

gth_create_main_copperlist:
        moveq.l #-2,d3
        move.l  pd_CurrCopListPtr(a6),a0

        lea     pd_BlendPalette(a6),a1
        moveq.l #15-1,d7
        move.w  #color+1*2,d0
.mwloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.mwloop

        move.l  pd_CurrPlanesPtr(a6),a1
        COPPTMOVE a1,bplpt+0*4,d0
        lea     (GOTHAM_WIDTH/8)*GOTHAM_HEIGHT(a1),a1
        COPPTMOVE a1,bplpt+1*4,d0
        lea     gth_ham_text,a1
        COPPTMOVE a1,bplpt+2*4,d0
        lea     (320/8)*23(a1),a1
        COPPTMOVE a1,bplpt+3*4,d0

        COPIMOVE $2200,bplcon0

        move.w  #$5207+(78<<8),(a0)+
        move.w  d3,(a0)+
        COPIMOVE $4200,bplcon0
        move.w  #$5207+((78+23)<<8),(a0)+
        move.w  d3,(a0)+
        COPIMOVE $2200,bplcon0

        lea     pd_HamTechPalette(a6),a1
        moveq.l #15-1,d7
        move.w  #color+1*2,d0
.htloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.htloop

        lea     gth_ham_tech,a1
        COPPTMOVE a1,bplpt+2*4,d0
        lea     (320/8)*13(a1),a1
        COPPTMOVE a1,bplpt+3*4,d0

        move.w  #$5207+((78+23+66)<<8),(a0)+
        move.w  d3,(a0)+

        COPIMOVE $4200,bplcon0

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

        include "blitterline_bq.asm"
        include "clipping.asm"

;********************************************************************

gth_red_noise:
        dc.w    $000,$100,$100,$000,$200,$100,$000,$200
        dc.w    $000,$000,$200,$200,$000,$200,$100,$100
        dc.w    $000,$100,$100,$000

gth_red_palette:
        dc.w    $300,$700,$a00

gth_black_palette:
        ds.w    15

gth_red_blend1_palette:
        dc.w         $400,$800,$c00,$000,$400,$800,$c00
        dc.w    $000,$400,$800,$c00,$000,$400,$800,$c00

gth_red_blend2_palette:
        dc.w         $000,$000,$000,$400,$400,$400,$400
        dc.w    $800,$800,$800,$800,$c00,$c00,$c00,$c00

gth_greenish_blend1_palette:
        dc.w         $243,$586,$8ca,$000,$243,$586,$8ca
        dc.w    $000,$243,$586,$8ca,$000,$243,$586,$8ca

gth_invisible_line_palette:
        dc.w         $000,$000,$000
        dc.w    $400,$000,$000,$000
        dc.w    $800,$000,$000,$000
        dc.w    $c00,$000,$000,$000

gth_white_line_palette:
        dc.w         $888,$888,$fff
        dc.w    $400,$855,$855,$daa
        dc.w    $800,$c55,$c55,$faa
        dc.w    $c00,$f55,$f55,$faa

gth_line_only_palette:
        dc.w         $888,$888,$fff
        dc.w    $000,$888,$888,$fff
        dc.w    $000,$888,$888,$fff
        dc.w    $000,$888,$888,$fff

gth_ham_tech_palette:
        dc.w         $888,$888,$fff
        dc.w    $444,$888,$888,$fff
        dc.w    $888,$888,$888,$fff
        dc.w    $ccc,$888,$888,$fff

TDPOINT MACRO
        dc.w    ((\1)-(GOTHAM_WIDTH/2))<<8
        dc.w    ((\2)-(103))<<8
        ENDM
gth_ham_line_h:
        ; H
        TDPOINT 63,74
        TDPOINT 78,74
        TDPOINT 78,96
        TDPOINT 100,96
        TDPOINT 100,74
        TDPOINT 116,74
        TDPOINT 116,132
        TDPOINT 100,132
        TDPOINT 100,110
        TDPOINT 78,110
        TDPOINT 78,132
        TDPOINT 63,132
        TDPOINT 63,74
        dc.w    0

gth_ham_line_a1:
        ; A (outside)
        TDPOINT 123,132
        TDPOINT 147,74
        TDPOINT 162,74
        TDPOINT 187,132
        TDPOINT 171,132
        TDPOINT 166,121
        TDPOINT 143,121
        TDPOINT 139,132
        TDPOINT 123,132
        dc.w    0

gth_ham_line_a2:
        ; A (inside)
        TDPOINT 147,110
        TDPOINT 155,92
        TDPOINT 162,110
        TDPOINT 147,110
        dc.w    0

gth_ham_line_m:
        ; M
        TDPOINT 194,74
        TDPOINT 210,74
        TDPOINT 225,97
        TDPOINT 239,74
        TDPOINT 256,74
        TDPOINT 256,132
        TDPOINT 241,132
        TDPOINT 241,98
        TDPOINT 225,121
        TDPOINT 209,98
        TDPOINT 209,132
        TDPOINT 194,132
        TDPOINT 194,74
        dc.w    0

        IFND    FW_DEMO_PART
        dc.w    1 ; avoid hunk shortening that leaves dirty memory on kick 1.3
        ENDC

;********************************************************************

;--------------------------------------------------------------------

        section "gth_copper",data,chip

gth_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$5281          ; window start
        COP_MOVE diwstop,$06c1          ; window stop
        COP_MOVE ddfstrt,$0038          ; bitplane start

        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00

        COP_MOVE fmode,$0000            ; fixes the aga modulo problem

        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon1,$0000
        COP_MOVE bplcon2,$0024          ; turn off all bitplanes, set scroll values to 0, sprites in front
        COP_MOVE bpl1mod,0
        COP_MOVE bpl2mod,0

        COP_MOVE color+0*2,$000

gth_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

gth_meanwhile_text:
        incbin  "../data/gotham/meanwhile320x18x4.BPL"

gth_gothamcity_text:
        incbin  "../data/gotham/gothamcity320x23x4.BPL"

gth_gotham_text:
        incbin  "../data/gotham/gotham320x23x4.BPL"

gth_hameelinna_text:
        incbin  "../data/gotham/hameelinna320x23x4.BPL"

gth_ham_text:
        incbin  "../data/gotham/ham320x23x4.BPL"

gth_ham_tech:
        incbin  "../data/gotham/hamtechnology320x13x4.BPL"

blitter_temp_output_word:
        dc.w    0

        IFND    FW_DEMO_PART
        section "gth_sample",data,chip
gth_psenough_ham:
        incbin  "../data/gotham/hamtechnology.raw"

        ENDC
        END