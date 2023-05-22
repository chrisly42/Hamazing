; TODOs:
; - Table effect for returning scroller...
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
FW_SCRIPTING_SUPPORT        = 0 ; enable simple timed scripting functions
FW_PALETTE_LERP_SUPPORT     = 0 ; enable basic palette fading functions
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

STHAM_WIDTH     = 320
STHAM_HEIGHT    = 180
STHAM_PLANES    = 6

BENTFONT_WIDTH  = 32
BENTFONT_HEIGHT = 32

BENTSCROLLER_WIDTH  = 128
BENTSCROLLER_HEIGHT = 180+2

BENTSPRITE_WIDTH    = 128
BENTSPRITE_HEIGHT   = 180

NUM_BARS    = 10
BAR_HEIGHT  = 18

CURTAIN_WIDTH   = 21    ; in words

COP_PREAMBLE_INST   = 200 ; bplptrs
COP_POST_INST       = 16 ; wait
COP_INST_PER_LINE   = 1+8+8+1 ; wait, 8 sprxctl, 8 sprxpos, 1 color
COP_CURTAIN_INST_PER_LINE = 8+1+CURTAIN_WIDTH ; 8 init pos, wait, 21 sprite pos
COP_LIST_SIZE       = (COP_PREAMBLE_INST+COP_CURTAIN_INST_PER_LINE*STHAM_HEIGHT+COP_POST_INST)*4

SPRITES_BUFFER_SIZE = (BENTSPRITE_WIDTH/16)*((BENTSPRITE_HEIGHT+2)*2*2)

CHIPMEM_SIZE = COP_LIST_SIZE*2+(BENTSCROLLER_WIDTH/8)*BENTSCROLLER_HEIGHT*3+SPRITES_BUFFER_SIZE*2+(CURTAIN_WIDTH*(CURTAIN_WIDTH+2)*16+2)*4
FASTMEM_SIZE = 4

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"


; Memory use:
; Playfields:
; - 320 x 180 x 24     = 172800 (6x2 db, 2 draw, 2 fill, 6 original, 2 spare)
;
; Scroller mapping:
; - Scroller texture (W*H): 16 Bit offsets
; - Table mapping texture: tx/ty, screen x/y, mask (pixel width)
;
;  move.w (a0)+,d0
;  move.w (a0)+,d1
;  move.w (a1,d0.w),d0
;  and.w  (a0)+,d0
;  or.w   d0,(a2,d1.w)
;

        STRUCTURE BarData,0
        WORD    bd_Delay
        LONG    bd_YPos
        WORD    bd_YSpeed
        LABEL   bd_SIZEOF

        STRUCTURE PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_LastPlanesPtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        APTR    pd_CurrScrollerPtr
        APTR    pd_LastScrollerPtr
        APTR    pd_CurrBentSpritesPtr
        UBYTE   pd_DbToggle
        ALIGNWORD

        UWORD   pd_PartCountDown

        UWORD   pd_CopperChunkyOffset

        APTR    pd_CopperList1
        APTR    pd_CopperList2

        UWORD   pd_LetterOffset
        UWORD   pd_LetterCountDown
        APTR    pd_ScrollTextPtr
        UWORD   pd_LetterOrOffset
        UWORD   pd_LetterOrCountDown

        UWORD   pd_CurtainOffset1
        UWORD   pd_CurtainOffset2
        LONG    pd_CurtainPos

        APTR    pd_CurtainDataPtr

        APTR    pd_HamphreyBuffer
        APTR    pd_BentScrollerBuffer1
        APTR    pd_BentScrollerBuffer2
        APTR    pd_BentScrollerTemp
        STRUCT  pd_DummyBarTop,bd_SIZEOF
        STRUCT  pd_Bars,NUM_BARS*bd_SIZEOF
        STRUCT  pd_DummyBarBottom,bd_SIZEOF
        STRUCT  pd_BentSprites1Ptrs,8*4
        STRUCT  pd_BentSprites2Ptrs,8*4
        STRUCT  pd_PreparationTask,ft_SIZEOF

        STRUCT  pd_BQBuffer,1000

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        bsr.s   sth_init

        lea     sth_copperlist,a0
        CALLFW  SetCopper

        lea     sth_hamphrey_palette+2(pc),a1
        moveq.l #15-1,d7
        lea     color+2(a5),a0
.blloop
        move.w  (a1)+,(a0)+
        dbra    d7,.blloop

        lea     .preptask(pc),a0
        lea     pd_PreparationTask(a6),a1
        CALLFW  AddTask

        bsr     sth_intro
        bsr     sth_main
        bsr     sth_curtain

        CALLFW  SetBaseCopper

        rts

.preptask
        IFD     FW_DEMO_PART
        move.l  fw_GlobalUserData(a6),a0
        move.l  pd_HamphreyBuffer(a6),a1
        PUTMSG  10,<"%d: Decrunching from %p to %p">,fw_FrameCounterLong(a6),a0,a1
        CALLFW  DecompressZX0
        PUTMSG  10,<"%d: Image decrunched until %p">,fw_FrameCounterLong(a6),a1
        clr.l   fw_GlobalUserData(a6)
        ENDC
        bsr     sth_create_curtain
        rts

;--------------------------------------------------------------------

sth_init:
        bsr     sth_init_vars
        bsr     sth_clear_sprites
        bsr     sth_clear_bent_buffer

        rts

;--------------------------------------------------------------------

sth_init_vars:
        move.l  #sth_scrolltext,pd_ScrollTextPtr(a6)
        move.w  #-1,pd_LetterOrCountDown(a6)

        IFND    FW_DEMO_PART
        move.l  #sth_hamphrey_pic,pd_HamphreyBuffer(a6)
        ELSE
        move.l  #(STHAM_WIDTH/8)*STHAM_HEIGHT*STHAM_PLANES*2,d0
        CALLFW  AllocChip
        move.l  a0,pd_HamphreyBuffer(a6)
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

        move.l  #(BENTSCROLLER_WIDTH/8)*BENTSCROLLER_HEIGHT*3,d0
        CALLFW  AllocChip
        PUTMSG  10,<"BentScrollerBuffer 1 %p">,a0
        move.l  a0,pd_BentScrollerBuffer1(a6)
        move.l  a0,pd_CurrScrollerPtr(a6)
        lea     (BENTSCROLLER_WIDTH/8)*BENTSCROLLER_HEIGHT(a0),a0
        PUTMSG  10,<"BentScrollerBuffer 2 %p">,a0
        move.l  a0,pd_BentScrollerBuffer2(a6)
        move.l  a0,pd_LastScrollerPtr(a6)
        lea     (BENTSCROLLER_WIDTH/8)*BENTSCROLLER_HEIGHT(a0),a0
        PUTMSG  10,<"BentScrollerTemp %p">,a0
        move.l  a0,pd_BentScrollerTemp(a6)

        move.l  #SPRITES_BUFFER_SIZE*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"BentSprites1Ptrs 1 %p">,a0
        lea     pd_BentSprites1Ptrs(a6),a1
        move.l  a1,pd_CurrBentSpritesPtr(a6)

        REPT    (BENTSPRITE_WIDTH/16)
        move.l  a0,(a1)+
        lea     ((BENTSPRITE_HEIGHT+2)*2*2)(a0),a0
        ENDR
        PUTMSG  10,<"BentSprites1Ptrs 2 %p">,a0
        REPT    (BENTSPRITE_WIDTH/16)
        move.l  a0,(a1)+
        lea     ((BENTSPRITE_HEIGHT+2)*2*2)(a0),a0
        ENDR

        ; curtain (<31KB)
        move.l  #(CURTAIN_WIDTH*(CURTAIN_WIDTH+2)*16+2)*4,d0
        CALLFW  AllocChip
        move.l  a0,pd_CurtainDataPtr(a6)

        lea     pd_DummyBarTop(a6),a1
        move.w  #-(NUM_BARS+1)*BAR_HEIGHT-256,d0
        move.w  d0,bd_YPos(a1)
        move.w  #(NUM_BARS-1)*10,d1
        moveq.l #10,d2
        moveq.l #NUM_BARS-1,d7
.barloop
        addq.l  #bd_SIZEOF,a1
        add.w   #BAR_HEIGHT,d0
        move.w  d1,bd_Delay(a1)
        move.w  d0,bd_YPos(a1)
        move.w  #100,bd_YSpeed(a1)
        sub.w   d2,d1
        addq.w  #5,d2
        dbra    d7,.barloop
        move.w  #STHAM_HEIGHT,bd_YPos+bd_SIZEOF(a1)
        rts

;--------------------------------------------------------------------

sth_intro:
        IFD     FW_DEMO_PART
        PUTMSG  10,<"%d: Intro part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        ELSE
        PUTMSG  10,<"%d: Intro part started">,fw_FrameCounterLong(a6)
        move.w  #400,pd_PartCountDown(a6)
        ENDC

.loop   CALLFW  VSyncWithTask
        bsr     sth_flip_db_frame

        bsr     sth_drop_bars
        bsr     sth_create_intro_copperlist

        bsr     sth_update_copper_list_pointers

        IFD     FW_DEMO_PART
        cmp.w   #3072,fw_MusicFrameCount(a6)
        blt.s   .loop
        ELSE
        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop
        ENDC

        rts

;--------------------------------------------------------------------

sth_main:
        IFD     FW_DEMO_PART
        PUTMSG  10,<"%d: Main part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        ELSE
        PUTMSG  10,<"%d: Main part started">,fw_FrameCounterLong(a6)
        ENDC
        move.w  #800,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueSingleFrame

        move.w  #$000,color(a5)
        REPT    2
        CALLFW  VSyncWithTask
        bsr     sth_flip_db_frame
        bsr     sth_create_sham_copperlist
        bsr     sth_update_copper_list_pointers
        ENDR

.loop   CALLFW  VSyncWithTask
        bsr     sth_flip_db_frame

        lea     pd_BQBuffer(a6),a4

        move.l  pd_BentScrollerTemp(a6),a0
        move.l  pd_LastScrollerPtr(a6),a2
        bsr     sth_scroll_buffer

        move.l  pd_CurrScrollerPtr(a6),a0
        move.l  pd_BentScrollerTemp(a6),a2
        bsr     sth_scroll_buffer

        bsr     sth_convert_scroller_to_sprites

        bsr     sth_push_in_letter

        TERMINATE_BLITTER_QUEUE

        BLTHOGON
        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue

        CALLFW  JoinBlitterQueue

        bsr     sth_update_copper_list_pointers

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

;--------------------------------------------------------------------

sth_curtain:
        IFD     FW_DEMO_PART
        PUTMSG  10,<"%d: Curtain part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        ELSE
        PUTMSG  10,<"%d: Curtain part started">,fw_FrameCounterLong(a6)
        ENDC
        move.w  #186,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueSingleFrame

        move.l  #482*CURTAIN_WIDTH*4,pd_CurtainPos(a6)

        REPT    1
        CALLFW  VSyncWithTask
        bsr     sth_flip_db_frame
        bsr     sth_create_simple_copperlist
        bsr     sth_update_copper_list_pointers
        ENDR

        REPT    2
        CALLFW  VSyncWithTask
        bsr     sth_flip_db_frame
        bsr     sth_create_curtain_copperlist
        move.l  a0,pd_CurrCopListPtr(a6)
        bsr     sth_create_simple_copperlist
        bsr     sth_update_copper_list_pointers
        ENDR

        move.w  #$000,color(a5)
        move.w  #$000,color+17*2(a5)
        move.w  #$311,color+21*2(a5)
        move.w  #$621,color+22*2(a5)
        move.w  #$a64,color+23*2(a5)
        move.w  #$da7,color+25*2(a5)
        move.w  #$cca,color+26*2(a5)
        move.w  #$bed,color+27*2(a5)
        move.w  #$3df,color+29*2(a5)
        move.w  #$6ef,color+30*2(a5)
        move.w  #$aff,color+31*2(a5)

.loop   CALLFW  VSyncWithTask
        bsr     sth_flip_db_frame

        bsr     sth_draw_curtain

        bsr     sth_update_copper_list_pointers

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

;--------------------------------------------------------------------

sth_flip_db_frame:
        move.l  pd_CurrPlanesPtr(a6),pd_LastPlanesPtr(a6)
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        move.l  pd_CurrScrollerPtr(a6),pd_LastScrollerPtr(a6)
        move.l  pd_HamphreyBuffer(a6),a0
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        lea     (STHAM_WIDTH/8)*STHAM_PLANES(a0),a0
        move.l  a0,pd_CurrPlanesPtr(a6)
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        move.l  pd_BentScrollerBuffer2(a6),pd_CurrScrollerPtr(a6)
        lea     pd_BentSprites2Ptrs(a6),a0
        move.l  a0,pd_CurrBentSpritesPtr(a6)
        rts
.selb1
        move.l  a0,pd_CurrPlanesPtr(a6)
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        move.l  pd_BentScrollerBuffer1(a6),pd_CurrScrollerPtr(a6)
        lea     pd_BentSprites1Ptrs(a6),a0
        move.l  a0,pd_CurrBentSpritesPtr(a6)
        rts

;--------------------------------------------------------------------

sth_update_copper_list_pointers:
        lea     sth_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

sth_clear_sprites:
        lea     pd_BentSprites1Ptrs(a6),a0
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  (a0),bltdpt(a5)
        move.w  #((BENTSPRITE_WIDTH)>>4)|(((BENTSPRITE_HEIGHT+2)*2*2)<<6),bltsize(a5)

        move.l  #(($52<<8)|0)<<16|(((($52+BENTSPRITE_HEIGHT)&$ff)<<8)|1),d0
        BLTWAIT
        moveq.l #8-1,d7
.loop   move.l  (a0)+,a1
        move.l  d0,(a1)
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

sth_clear_bent_buffer:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_BentScrollerBuffer1(a6),bltdpt(a5)
        move.w  #((BENTSCROLLER_WIDTH)>>4)|((BENTSCROLLER_HEIGHT*3)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

sth_push_in_letter:
        subq.w  #2,pd_LetterCountDown(a6)
        bpl.s   .nonew
        move.w  pd_LetterOffset(a6),pd_LetterOrOffset(a6)
        move.w  #44-28,pd_LetterOrCountDown(a6)
        move.w  #28,pd_LetterCountDown(a6)
        move.l  pd_ScrollTextPtr(a6),a0
        move.b  (a0)+,d0
        bne.s   .nowrap
        move.l  pd_ScrollTextPtr(a6),a0
        move.b  (a0)+,d0
.nowrap
        move.l  a0,pd_ScrollTextPtr(a6)
        sub.b   #'A',d0
        ext.w   d0
        lsl.w   #2+4,d0
        move.w  d0,d1
        add.w   d0,d0
        add.w   d1,d0
        move.w  d0,pd_LetterOffset(a6)
.nonew
        move.l  pd_LastScrollerPtr(a6),a1
        lea     (BENTSPRITE_HEIGHT)*(BENTSCROLLER_WIDTH/8)(a1),a1

        lea     sth_font_data(pc),a0
        move.w  pd_LetterOffset(a6),d0
        bmi.s   .clear
        adda.w  d0,a0
        addq.w  #8,d0
        move.w  d0,pd_LetterOffset(a6)

        move.l  #$88888888,d6
        REPT    2
        movem.l (a0)+,d0

        REPT    4
        move.l  d0,d4
        and.l   d6,d4
        move.l  d4,d5
        lsr.l   #1,d5
        or.l    d5,d4
        move.l  d4,d5
        lsr.l   #2,d5
        or.l    d5,d4
        move.l  d4,(a1)+
        rol.l   #1,d0
        ENDR
        ENDR

.second
        subq.w  #2,pd_LetterOrCountDown(a6)
        bmi.s   .skip
        move.w  pd_LetterOrOffset(a6),d0
        bmi.s   .skip
        move.l  pd_LastScrollerPtr(a6),a1
        lea     (BENTSPRITE_HEIGHT)*(BENTSCROLLER_WIDTH/8)(a1),a1

        lea     sth_font_data(pc),a0
        adda.w  d0,a0
        addq.w  #8,d0
        move.w  d0,pd_LetterOrOffset(a6)

        REPT    2
        movem.l (a0)+,d0

        REPT    4
        move.l  d0,d4
        and.l   d6,d4
        move.l  d4,d5
        lsr.l   #1,d5
        or.l    d5,d4
        move.l  d4,d5
        lsr.l   #2,d5
        or.l    d5,d4
        or.l    d4,(a1)+
        rol.l   #1,d0
        ENDR
        ENDR

.skip
        rts
.clear
        moveq.l #0,d0
        REPT    8
        move.l  d0,(a1)+
        ENDR
        move.l  #$88888888,d6
        bra.s   .second

;--------------------------------------------------------------------

sth_scroll_buffer:
        lea     1*(BENTSCROLLER_WIDTH/8)(a2),a2

        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.w  #4,a4
        move.l  #.bq_simple_shift_up,(a4)+
        move.l  #(((BENTSCROLLER_WIDTH-32)/8)<<16)|((BENTSCROLLER_WIDTH-32)/8),(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        move.w  #(32>>4)|(30<<6),(a4)+

        lea     (90-1)*(BENTSCROLLER_WIDTH/8)+(48/8)-2(a0),a0
        lea     (90-1)*(BENTSCROLLER_WIDTH/8)+(48/8)-2(a2),a2
        lea     sth_scroller_shift_1_bitmap+(90-30-1)*(BENTSCROLLER_WIDTH/8)+(48/8)-2,a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.w  #4,a4
        move.l  #.bq_shift_1,(a4)+
        move.l  #(((BENTSCROLLER_WIDTH-48)/8)<<16)|((BENTSCROLLER_WIDTH-48)/8),d0
        move.l  d0,(a4)+
        move.l  d0,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  #(48>>4)|((90-30)<<6),(a4)+

        lea     ((144-1)-(90-1))*(BENTSCROLLER_WIDTH/8)+(80/8)-(48/8)(a0),a0
        lea     ((144-1)-(90-1))*(BENTSCROLLER_WIDTH/8)+(80/8)-(48/8)(a2),a2
        lea     sth_scroller_shift_1_bitmap+(144-30-1)*(BENTSCROLLER_WIDTH/8)+(80/8)-2,a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.w  #4,a4
        move.l  #.bq_shift_1,(a4)+
        move.l  #(((BENTSCROLLER_WIDTH-80)/8)<<16)|((BENTSCROLLER_WIDTH-80)/8),d0
        move.l  d0,(a4)+
        move.l  d0,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  #(80>>4)|((144-90)<<6),(a4)+

        lea     (BENTSPRITE_HEIGHT-144+2)*(BENTSCROLLER_WIDTH/8)-(80/8)(a0),a0
        lea     (BENTSPRITE_HEIGHT-144+2)*(BENTSCROLLER_WIDTH/8)-(80/8)(a2),a2
        lea     sth_scroller_shift_1_bitmap+(BENTSPRITE_HEIGHT-30-1+2)*(BENTSCROLLER_WIDTH/8)-2,a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.w  #4,a4
        move.l  #.bq_shift_1,(a4)+
        moveq.l #0,d0
        move.l  d0,(a4)+
        move.l  d0,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  #(BENTSCROLLER_WIDTH>>4)|((BENTSPRITE_HEIGHT-144-1+2)<<6),(a4)+

        lea     -2*(BENTSCROLLER_WIDTH/8)(a0),a0
        lea     -2*(BENTSCROLLER_WIDTH/8)(a2),a2
        lea     sth_scroller_shift_2_bitmap+(BENTSPRITE_HEIGHT-157-1)*(80/8)-2,a1

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.w  #4,a4
        move.l  #.bq_shift_2,(a4)+
        move.l  #0|((BENTSCROLLER_WIDTH-80)/8),(a4)+
        move.l  #(((BENTSCROLLER_WIDTH-80)/8)<<16)|((BENTSCROLLER_WIDTH-80)/8),(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  #(80>>4)|((BENTSPRITE_HEIGHT-157-1)<<6),(a4)+

        rts

.bq_simple_shift_up
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_shift_1
        BLTCON_SET_X ABCD,(BLT_A&BLT_C)|(BLT_B&~BLT_C),1,0,BLTCON1F_DESC
        ;BLTCON_SET_X CD,BLT_C,1,0,BLTCON1F_DESC
        move.l  (a0)+,bltcmod(a5) ; and bltbmod
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_shift_2
        BLTCON_SET_X ABCD,(BLT_A&BLT_C)|(BLT_B&~BLT_C),2,0,BLTCON1F_DESC
        ;BLTCON_SET_X CD,BLT_C,2,0,BLTCON1F_DESC
        move.l  (a0)+,bltcmod(a5) ; and bltbmod
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

sth_convert_scroller_to_sprites:
        PREP_ADD_TO_BLITTER_QUEUE a3
        move.w  #(16>>4)|(BENTSPRITE_HEIGHT<<6),d3
        move.l  #.bq_generic_ad_with_all,d4
        move.l  #.bq_generic_ad,d5
        move.l  pd_CurrScrollerPtr(a6),a2
        move.l  pd_CurrBentSpritesPtr(a6),a0
        moveq.l #(BENTSPRITE_WIDTH/16)-1,d7
.sprloop
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  d4,(a4)+
        move.l  (a0)+,d0
        addq.l  #4,d0
        move.l  a2,(a4)+
        move.l  d0,(a4)+
        move.w  d3,(a4)+
        addq.w  #2,a2

        move.l  d5,d4

        dbra    d7,.sprloop

        TERM_ADD_TO_BLITTER_QUEUE a3
        rts

.bq_generic_ad_with_all
        BLTHOGOFF
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((BENTSCROLLER_WIDTH-16)/8)<<16)|2,bltamod(a5)
.bq_generic_ad
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

sth_drop_bars:
        lea     pd_Bars(a6),a1
        moveq.l #NUM_BARS-1,d7
.gravloop
        subq.w  #1,bd_Delay(a1)
        bpl.s   .skip
        move.l  bd_YPos(a1),d0
        move.w  bd_YSpeed(a1),d1
        add.w   #52,d1
        move.w  d1,bd_YSpeed(a1)
        ext.l   d1
        lsl.l   #6,d1
        add.l   d1,d0
        move.l  d0,bd_YPos(a1)
.skip
        lea     bd_SIZEOF(a1),a1
        dbra    d7,.gravloop

        moveq.l #NUM_BARS-1,d7
        moveq.l #BAR_HEIGHT,d2
.collloop
        lea     -bd_SIZEOF(a1),a1
        tst.w   bd_Delay(a1)
        bpl.s   .skip2

        move.w  bd_YPos(a1),d0
        move.w  bd_YSpeed(a1),d3
        asr.w   #1,d3
        move.w  d0,d1
        sub.w   d2,d1
        cmp.w   bd_YPos-bd_SIZEOF(a1),d1
        bge.s  .notopcoll
        move.w  bd_YPos-bd_SIZEOF(a1),d0
        add.w   d2,d0
        move.w  d0,bd_YPos(a1)
        move.w  d3,d1
        neg.w   d1
        move.w  d1,bd_YSpeed(a1)
        ;asr.w   #1,d1
        ;neg.w   d1
        add.w   d3,bd_YSpeed-bd_SIZEOF(a1)
.notopcoll
        move.w  d0,d1
        add.w   d2,d1
        cmp.w   bd_YPos+bd_SIZEOF(a1),d1
        blt.s   .nobottomcoll
        move.w  bd_YPos+bd_SIZEOF(a1),d0
        sub.w   d2,d0
        move.w  d0,bd_YPos(a1)
        move.w  d3,d1
        neg.w   d1
        move.w  d1,bd_YSpeed(a1)
        ;asr.w   #1,d1
        ;neg.w   d1
        add.w   d3,bd_YSpeed+bd_SIZEOF(a1)
.nobottomcoll
.skip2
        dbra    d7,.collloop

        rts

;--------------------------------------------------------------------

sth_create_curtain:
        move.l  pd_CurtainDataPtr(a6),a0
        PUTMSG  10,<"%d: Curtain %p">,fw_FrameCounterLong(a6),a0

        move.l  #(spr+0*sd_SIZEOF+sd_pos)<<16,d4
        move.l  #$1fe<<16,d3
        move.w  #(CURTAIN_WIDTH+2)*16,d7
.lineloop
        moveq.l #15,d0
        and.w   d7,d0
        lsr.w   #1,d0
        eor.w   #7,d0
        move.w  #($50<<8)|(64),d4
        sub.w   d0,d4

        moveq.l #CURTAIN_WIDTH,d5
        moveq.l #1,d1
        and.w   d7,d1
        lsl.w   #3,d1
        move.w  d7,d6
        lsr.w   #4,d6
        subq.w  #1,d6
        bmi.s   .tilem1
        subq.w  #1,d6
        bmi.s   .tilem2
        subq.w  #1,d6
        bmi.s   .tilem3
.blackloop
        subq.w  #1,d5
        move.l  d4,(a0)+
        addq.w  #8,d4
        dbra    d6,.blackloop

.tilem3
        subq.w  #1,d5
        bmi.s   .skipwhite
        move.w  d1,d2
        add.w   #spr+2*sd_SIZEOF+sd_pos,d2
        move.w  d2,(a0)+
        move.w  d4,(a0)+
        addq.w  #8,d4

.tilem2
        subq.w  #1,d5
        bmi.s   .skipwhite
        move.w  d1,d2
        add.w   #spr+4*sd_SIZEOF+sd_pos,d2
        move.w  d2,(a0)+
        move.w  d4,(a0)+
        addq.w  #8,d4

.tilem1
        subq.w  #1,d5
        bmi.s   .skipwhite
        move.w  d1,d2
        add.w   #spr+6*sd_SIZEOF+sd_pos,d2
        move.w  d2,(a0)+
        move.w  d4,(a0)+

.skipspecial
        subq.w  #1,d5
        bmi.s   .skipwhite
.whiteloop
        move.l  d3,(a0)+
        dbra    d5,.whiteloop
.skipwhite
        dbra    d7,.lineloop

        moveq.l #CURTAIN_WIDTH-1,d7
.emptylineloop
        move.l  d3,(a0)+
        dbra    d7,.emptylineloop

        PUTMSG  10,<"%d: Curtain done">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

sth_draw_curtain:
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperChunkyOffset(a6),a1

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)      ; also fills bltalwm
        moveq.l #0,d0
        move.l  d0,bltamod(a5)

        lea     sth_curtainsines(pc),a2
        lea     sth_curtainsines+256(pc),a3
        lea     sth_curtainsines+512(pc),a4
        move.w  #(CURTAIN_WIDTH*2)|((1)<<6),d3

        move.l  pd_CurtainDataPtr(a6),a0
        move.w  pd_CurtainOffset1(a6),d2
        addq.w  #2,d2
        move.w  d2,pd_CurtainOffset1(a6)
        move.w  pd_CurtainOffset2(a6),d5
        subq.w  #3,d5
        move.w  d5,pd_CurtainOffset2(a6)
        move.w  d5,d0
        add.w   d2,d0
        add.w   d2,d0
        lsr.w   #2,d0
        add.w   d2,d2
        add.w   d5,d5

        and.w   #254,d2
        and.w   #254,d5
        and.w   #254,d0

        move.l  pd_CurtainPos(a6),d4
        sub.l   #3*(CURTAIN_WIDTH*4),d4
        move.l  d4,pd_CurtainPos(a6)
        move.l  #(CURTAIN_WIDTH*4)*(((CURTAIN_WIDTH+2)*16)+1),d6
        move.w  #STHAM_HEIGHT-1,d7
        moveq.l #0,d1
.lineloop
        suba.w  d1,a0
        addq.b  #3*2,d2
        move.w  (a3,d2.w),d1

        subq.b  #2*2,d0
        add.w   (a3,d0.w),d1

        subq.b  #4*2,d5
        add.w   (a4,d5.w),d1

        ext.l   d1
        add.l   d4,d1
        bpl.s   .nocutoff
        moveq.l #0,d1
        bra.s   .nooverfl2
.nocutoff
        cmp.l   d6,d1
        blt.s   .nooverfl
        move.w  d6,d1
.nooverfl
        adda.w  d1,a0
.nooverfl2
        BLTWAIT
        movem.l a0/a1,bltapt(a5)        ; bltapt = a0, bltdpt = a1
        move.w  d3,bltsize(a5)
        lea     COP_CURTAIN_INST_PER_LINE*4(a1),a1
        dbra    d7,.lineloop
        rts

;--------------------------------------------------------------------

sth_create_sham_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0

        move.l  pd_CurrBentSpritesPtr(a6),a1
        move.w  #sprpt,d1
        moveq.l #(BENTSPRITE_WIDTH/16)*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        moveq.l #(STHAM_WIDTH)/8,d2
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

        COPIMOVE $6a00,bplcon0

        moveq.l #-2,d3
        move.w  #$51b5,d0
        move.w  #$100,d2

        lea     sth_sprite_xpos(pc),a1
        move.w  #$5200,d1
        move.w  #BENTSPRITE_HEIGHT-1,d7
        lea     sth_scroller_gradient(pc),a2
        moveq.l #-1,d5
        moveq.l #-1,d6
.cprloop
        move.w  #((($52+BENTSPRITE_HEIGHT)&$ff)<<7)|1,d4
        move.b  (a1)+,d1
        cmp.b   d5,d1
        beq.s   .skippos
        move.b  d1,d5

        move.w  d0,(a0)+
        move.w  d3,(a0)+

        lsr.b   #1,d1
        roxl.w  d4
        add.b   #$40,d1

        REPT    8
        COPRMOVE d4,spr+sd_ctl+REPTN*sd_SIZEOF
        ENDR
        REPT    8
        COPRMOVE d1,spr+sd_pos+REPTN*sd_SIZEOF
        addq.b  #8,d1
        ENDR
        bra.s   .addcol

.skippos
        move.w  d0,d1
        move.b  #$d5,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+
.addcol
        cmp.w   (a2),d6
        beq.s   .nocol
        move.w  (a2),d6
        COPRMOVE d6,color+17*2
        cmp.w   #BENTSPRITE_HEIGHT-1-31,d7
        bgt.s   .nocol
        sub.w   #$011,d6
        COPRMOVE d6,color+21*2
        cmp.w   #BENTSPRITE_HEIGHT-1-124,d7
        bgt.s   .nocol
        sub.w   #$011,d6
        COPRMOVE d6,color+25*2
        cmp.w   #BENTSPRITE_HEIGHT-1-160,d7
        bgt.s   .nocol
        sub.w   #$011,d6
        COPRMOVE d6,color+29*2
.nocol
        add.w   d2,d0
        addq.w  #2,a2

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

sth_create_intro_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0

        moveq.l #0,d5
        move.l  pd_CurrPlanesPtr(a6),d0
        lea     pd_Bars(a6),a1
        moveq.l #BAR_HEIGHT,d6
        moveq.l #NUM_BARS-1,d7
.findtopbar
        move.w  bd_YPos(a1),d4
        PUTMSG  40,<"%d: YPos %d">,d7,d4
        add.w   d6,d4
        bgt.s   .foundtopbar
        add.l   #BAR_HEIGHT*(2*(STHAM_WIDTH)/8)*STHAM_PLANES,d0
        addq.l  #bd_SIZEOF,a1
        dbra    d7,.findtopbar
        moveq.l #1,d5           ; no bar visible
        moveq.l #0,d6           ; zero height for first bar
        bra.s   .noaddsplit
.foundtopbar
        sub.w   d6,d4
        bpl.s   .noaddsplit
        add.w   d4,d6
        move.w  d4,d2
        neg.w   d2
        PUTMSG  30,<"Adding %d">,d2
        muls    #(2*(STHAM_WIDTH)/8)*STHAM_PLANES,d2
        add.l   d2,d0
        moveq.l #0,d4
.noaddsplit

        PUTMSG  20,<"Top Y %d, Height %d">,d4,d6
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        moveq.l #(STHAM_WIDTH)/8,d2
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
        move.w  #$5207,d0
        move.w  #$100,d2
        moveq.l #0,d7

        tst.w   d5
        bne.s   .allempty
        lea     sth_midbar_gradient(pc),a2
        tst.w   d4
        beq.s   .startbar

        COPIMOVE $0000,color
        COPIMOVE $0200,bplcon0
        add.w   d4,d7

        move.w  bd_YPos(a1),d1
        sub.w   bd_YPos-bd_SIZEOF(a1),d1
        sub.w   #BAR_HEIGHT,d1
        move.w  d1,d6
        move.w  d4,-(sp)
        sub.w   d4,d1

        move.w  d6,d4
        add.w   d4,d4
        moveq.l #0,d5
        subq.w  #1,d1
        bmi.s   .skipspecial
.firstloop
        sub.w   d2,d6
        bpl.s   .cont2
.again2
        addq.w  #2,d5
        add.w   d4,d6
        bmi.s   .again2
.cont2
        dbra    d1,.firstloop
.skipspecial
        move.w  (sp)+,d1
        subq.w  #1,d1
        beq.s   .oneline
        subq.w  #1,d1
        bra.s   .whiteloop

.startbar
        COPIMOVE $0000,color
        COPIMOVE $6a00,bplcon0

.barloop
        PUTMSG  30,<"Barloop at %d">,d7
        add.w   d6,d7
        move.w  d6,d1
        lsl.w   #8,d1
        add.w   d1,d0
        bcc.s   .no255
        move.w  #$ffdf,(a0)+
        move.w  d3,(a0)+
.no255
        move.w  d0,(a0)+
        move.w  d3,(a0)+

        addq.l  #bd_SIZEOF,a1
        move.w  bd_YPos(a1),d1
        sub.w   d7,d1
        beq.s   .nextbar

        COPIMOVE $0200,bplcon0
        cmp.w   #STHAM_HEIGHT,bd_YPos(a1)
        bge.s   .lastbar
.startfirstwhite
        PUTMSG  40,<"White dist %d">,d1
        add.w   d1,d7
        move.w  d1,d6
        move.w  d1,d4
        add.w   d4,d4
        moveq.l #0,d5
        subq.w  #1,d1
        beq.s   .oneline
        subq.w  #1,d1
.whiteloop
        add.w   d2,d0
        bcc.s   .no255b
        move.w  #$ffdf,(a0)+
        move.w  d3,(a0)+
.no255b
        move.b  #$3f,d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        ;sub.w   #128*2,d6
        sub.w   d2,d6
        bpl.s   .cont
.again
        addq.w  #2,d5
        add.w   d4,d6
        bmi.s   .again
.cont
        COPRMOVE (a2,d5.w),color
        move.b  #$3f+(STHAM_WIDTH/2),d0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $0000,color
        dbra    d1,.whiteloop
        move.b  #$07,d0

.oneline
        add.w   d2,d0
        bcc.s   .no255e
        move.w  #$ffdf,(a0)+
        move.w  d3,(a0)+
.no255e
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        ;COPIMOVE $0000,color

.nextbar
        cmp.w   #STHAM_HEIGHT,bd_YPos(a1)
        bge.s   .done
        COPIMOVE $6a00,bplcon0
        moveq.l #BAR_HEIGHT,d6
        bra.s   .barloop
.done
        move.l  d3,(a0)+
        rts
.lastbar
        lea     sth_bar_gradient(pc),a2
        move.w  d1,d7
        subq.w  #1,d7
        moveq.l #0,d5
        bra.s   .allloop
.allempty
        lea     sth_bar_gradient(pc),a2
        COPIMOVE $0200,bplcon0
        move.w  d4,d5
        neg.w   d5
        add.w   d5,d5
        move.w  #STHAM_HEIGHT-1,d7
.allloop
        COPRMOVE (a2,d5.w),color
        add.w   d2,d0
        bcc.s   .no255c
        move.w  #$ffdf,(a0)+
        move.w  d3,(a0)+
.no255c
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        addq.w  #2,d5
        dbra    d7,.allloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

sth_create_simple_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        COPIMOVE DMAF_SPRITE,dmacon ; disable sprite dma

        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        moveq.l #(STHAM_WIDTH)/8,d2
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

        COPIMOVE $6a00,bplcon0

        moveq.l #-2,d3
        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

sth_create_curtain_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2

        COPIMOVE DMAF_SPRITE,dmacon ; disable sprite dma

        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+0*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+1*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+2*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+3*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+4*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+5*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+6*sd_SIZEOF+sd_ctl
        COPIMOVE ($6<<8)|(0<<2)|(1<<1),spr+7*sd_SIZEOF+sd_ctl

        COPIMOVE %0000000000000000,spr+0*sd_SIZEOF+sd_dataB
        COPIMOVE %0000000000000000,spr+1*sd_SIZEOF+sd_dataB
        COPIMOVE %0010110111111111,spr+2*sd_SIZEOF+sd_dataB
        COPIMOVE %0001011011111111,spr+3*sd_SIZEOF+sd_dataB
        COPIMOVE %0010110111111111,spr+4*sd_SIZEOF+sd_dataB
        COPIMOVE %0001011011111111,spr+5*sd_SIZEOF+sd_dataB
        COPIMOVE %1110110100000000,spr+6*sd_SIZEOF+sd_dataB
        COPIMOVE %1111011010000000,spr+7*sd_SIZEOF+sd_dataB

        COPIMOVE %1111111111111111,spr+0*sd_SIZEOF+sd_dataa
        COPIMOVE %1111111111111111,spr+1*sd_SIZEOF+sd_dataa
        COPIMOVE %1101001001011011,spr+2*sd_SIZEOF+sd_dataa
        COPIMOVE %1110100100101101,spr+3*sd_SIZEOF+sd_dataa
        COPIMOVE %1101001001011011,spr+4*sd_SIZEOF+sd_dataa
        COPIMOVE %1110100100101101,spr+5*sd_SIZEOF+sd_dataa
        COPIMOVE %1100100000100010,spr+6*sd_SIZEOF+sd_dataa
        COPIMOVE %1110010000010001,spr+7*sd_SIZEOF+sd_dataa

        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #6-1,d7
        move.w  #bplpt,d1
        moveq.l #(STHAM_WIDTH)/8,d2
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

        COPIMOVE $6a00,bplcon0

        moveq.l #-2,d3
        move.w  #$5237,d0
        move.w  #$100,d2

        move.w  #$51d7,(a0)+
        move.w  d3,(a0)+

        move.l  a0,d1
        sub.l   a2,d1
        add.w   #8*4+4,d1
        move.w  d1,pd_CopperChunkyOffset(a6)

        move.w  #BENTSPRITE_HEIGHT-1,d7
.cprloop

        COPIMOVE ($50<<8)|(64-32),spr+0*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+1*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+2*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+3*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+4*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+5*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+6*sd_SIZEOF+sd_pos
        COPIMOVE ($50<<8)|(64-32),spr+7*sd_SIZEOF+sd_pos

        move.w  d0,(a0)+
        move.w  d3,(a0)+
        add.w   d2,d0

        move.l  #$1fe<<16,d1
        REPT    CURTAIN_WIDTH
        move.l  d1,(a0)+
        ENDR

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;********************************************************************

sth_scrolltext:
        ;dc.b    "HAMPHREY B IS REALLY LOOKING  HAMAZING  TODAY"
        dc.b    "HAMAZING    IT EVEN IMPRESSES HAMPHREY BOGART"
        dc.b    "                                "
        dc.b    0
        even

sth_curtainsines:
        incbin  "../data/stham/curtainsine.bin"

sth_hamphrey_palette:
        include "../data/stham/PLT_HAMph_path_2_test08b_ham.pal.asm"

; https://gradient-blaster-grahambates.vercel.app/?points=cff@0,09a@171&steps=256&blendMode=oklab&ditherMode=errorDiffusion&target=amigaOcs&ditherAmount=55
sth_scroller_gradient:
        dc.w    $cff,$dff,$cff,$cff,$cff,$cff,$cff,$cff
        dc.w    $cff,$cfe,$cff,$cff,$cfe,$cff,$bee,$cff
        dc.w    $cee,$bff,$bef,$cff,$aef,$bff,$aef,$bff
        dc.w    $aff,$bee,$aef,$bee,$bef,$aee,$aef,$bee
        dc.w    $aee,$aee,$aee,$aee,$aee,$aee,$aee,$ade
        dc.w    $aee,$aee,$aee,$aee,$ade,$9ee,$ade,$aee
        dc.w    $9de,$aee,$9dd,$ade,$9dd,$ade,$9dd,$aee
        dc.w    $9dd,$9dd,$9dd,$9de,$9dd,$9dd,$9dd,$9dd
        dc.w    $9dd,$9dd,$9dd,$9dd,$9cd,$9dd,$9cd,$9dd
        dc.w    $8dd,$8cd,$8dd,$7cd,$8dd,$8cd,$7dd,$8cd
        dc.w    $7cd,$8cd,$7cd,$7cd,$8cd,$7cd,$7cc,$7cd
        dc.w    $7cd,$7cd,$7cd,$7cc,$7cd,$7cc,$7cc,$7cd
        dc.w    $7cc,$7cc,$7bc,$6cc,$7bc,$7cc,$7bc,$7cc
        dc.w    $6bc,$7bc,$6cc,$7cc,$6bc,$7bc,$6bc,$6bb
        dc.w    $6bc,$6bc,$7bc,$7bc,$6bb,$6bc,$6bb,$6bc
        dc.w    $6bb,$6bc,$6ab,$6bb,$6bb,$5ab,$5bc,$5bb
        dc.w    $5ab,$5bb,$4ac,$4bb,$4ac,$4bb,$4ab,$4ab
        dc.w    $4ac,$4bb,$4ab,$4ab,$4ab,$4ab,$3ab,$4ab
        dc.w    $4ab,$4ab,$3ab,$4ab,$4ab,$3ab,$4ab,$3ab
        dc.w    $39a,$3ab,$3aa,$3ab,$3aa,$39b,$3aa,$39b
        dc.w    $39b,$3aa,$39a,$3ab,$29a,$39a,$29a,$39a
        dc.w    $39a,$29a,$29a,$09a,$09a,$09a,$09a,$09a
        dc.w    $09a,$09a,$09a,$09a,$09a

; https://gradient-blaster-grahambates.vercel.app/?points=000@0,719@64,fff@255&steps=256&blendMode=oklab&ditherMode=shuffle&target=amigaOcs&shuffleCount=2
sth_bar_gradient:
        dc.w    $000,$000,$000,$000,$000,$000,$000,$000
        dc.w    $000,$000,$101,$000,$101,$001,$101,$001
        dc.w    $102,$101,$102,$101,$102,$101,$203,$102
        dc.w    $203,$202,$203,$202,$203,$304,$203,$304
        dc.w    $204,$304,$204,$405,$304,$405,$304,$405
        dc.w    $304,$405,$405,$406,$405,$516,$406,$516
        dc.w    $406,$517,$506,$517,$507,$517,$507,$608
        dc.w    $618,$608,$618,$608,$709,$608,$719,$709
        dc.w    $709,$719,$719,$729,$719,$729,$719,$82a
        dc.w    $719,$82a,$729,$82a,$729,$83a,$73a,$83a
        dc.w    $83a,$83a,$83a,$83a,$83a,$83a,$83a,$84a
        dc.w    $83a,$84a,$83a,$84a,$83a,$84a,$84a,$84a
        dc.w    $84a,$95a,$84a,$95a,$84b,$95a,$84b,$95b
        dc.w    $95a,$95b,$95a,$95b,$95a,$95b,$95b,$96b
        dc.w    $95b,$96b,$95b,$96b,$95b,$96b,$96b,$a6b
        dc.w    $96b,$a6b,$96b,$a6b,$96b,$a6b,$a6b,$a7c
        dc.w    $a6b,$a7c,$a7b,$a7c,$a7b,$a7c,$a7b,$a7c
        dc.w    $a7c,$a7c,$a7c,$b8c,$a7c,$b8c,$a7c,$b8c
        dc.w    $a7c,$a8c,$b8c,$b8c,$b8c,$b8c,$b8c,$b8c
        dc.w    $b8c,$b8c,$b8c,$b9d,$b8c,$b9d,$b8c,$b9d
        dc.w    $b8c,$b9d,$b9d,$b9d,$b9c,$b9d,$c9d,$cad
        dc.w    $c9d,$cad,$c9d,$cad,$c9d,$cad,$cad,$cad
        dc.w    $cad,$cad,$cad,$cad,$cad,$cad,$cad,$dbd
        dc.w    $cad,$dbd,$cad,$dbe,$cad,$dbe,$dbd,$dbe
        dc.w    $dbd,$dbe,$dbe,$dce,$dbe,$dce,$dbe,$dce
        dc.w    $dbe,$dce,$dce,$dce,$dce,$dce,$dce,$dce
        dc.w    $dce,$dce,$ece,$dce,$ede,$ece,$ede,$dce
        dc.w    $ede,$dce,$ede,$ede,$edf,$ede,$edf,$ede
        dc.w    $edf,$ede,$edf,$eef,$edf,$eef,$edf,$eef
        dc.w    $edf,$eef,$fef,$eef,$fef,$fef,$fef,$fef
        dc.w    $fff,$fef,$fff,$fef,$fff,$fef,$fff,$fff
        dc.w    $fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff

        blk.w   180,$fff

sth_midbar_gradient:
; https://gradient-blaster-grahambates.vercel.app/?points=000@0,578@35,fff@43,984@52,000@128&steps=256&blendMode=oklab&ditherMode=blueNoise&target=amigaOcs&ditherAmount=82
        dc.w    $000,$000,$000,$000,$000,$000,$010,$001
        dc.w    $011,$011,$011,$112,$111,$122,$122,$223
        dc.w    $222,$233,$233,$234,$243,$234,$334,$245
        dc.w    $344,$345,$355,$455,$356,$466,$457,$567
        dc.w    $467,$568,$567,$578,$789,$79a,$8aa,$acc
        dc.w    $bcc,$cde,$efe,$fff,$efe,$edd,$ddb,$dcb
        dc.w    $cb9,$cb8,$a96,$a95,$984,$984,$984,$983
        dc.w    $874,$884,$873,$883,$873,$773,$863,$774
        dc.w    $763,$773,$663,$763,$763,$662,$662,$653
        dc.w    $652,$663,$553,$653,$652,$652,$542,$652
        dc.w    $542,$542,$541,$542,$541,$442,$432,$442
        dc.w    $431,$431,$431,$431,$321,$331,$331,$331
        dc.w    $221,$321,$320,$221,$321,$220,$220,$221
        dc.w    $211,$111,$210,$211,$110,$110,$110,$110
        dc.w    $100,$111,$100,$100,$010,$000,$000,$100
        dc.w    $000,$000,$000,$000,$000,$000,$000,$000

sth_sprite_xpos:
        ; XPos
        dc.b    77,74,70,68,64,62,60,58,56,53,52,50,49,48,46,45
        dc.b    44,43,42,41,39,39,38,37,36,35,34,33,33,32,32,31
        dc.b    30,30,29,29,28,27,27,26,26,25,25,24,24,23,23,22
        dc.b    22,22,21,21,21,20,20,20,19,19,19,19,18,18,18,18
        dc.b    18,17,17,17,17,17,17,16,16,16,16,16,16,16,16,16
        dc.b    16,16,16,16,15,16,16,16,16,16,16,16,16,16,16,16
        dc.b    17,17,17,17,17,17,18,18,18,19,19,19,19,20,20,21
        dc.b    21,22,22,23,23,24,24,25,25,26,27,27,28,29,29,30
        dc.b    31,31,32,33,34,35,36,37,38,39,40,42,43,44,45,46
        dc.b    48,49,50,52,54,55,56,57,60,62,63,65,67,68,71,73
        dc.b    75,77,80,82,84,86,88,90,93,96,99,101,104,107,110,113
        dc.b    116,119,122,125,128

sth_sprite_widths:
        ; Width (49 at 90, 81 at 144)
        dc.b    32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32     ;  0
        dc.b    32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,33     ; 16
        dc.b    33,33,33,33,34,34,34,34,34,35,35,35,35,35,36,36     ; 32
        dc.b    36,36,37,37,37,37,38,38,38,38,38,39,39,39,40,40     ; 48
        dc.b    40,40,41,41,41,42,42,42,42,43,43,43,44,44,44,45     ; 64
        dc.b    45,45,46,46,46,47,47,47,48,48,48,49,49,50,50,50     ; 80
        dc.b    51,51,52,52,52,53,53,54,54,55,55,56,56,57,57,58     ; 96
        dc.b    58,59,59,60,60,61,61,62,62,63,64,64,65,66,66,67     ; 112
        dc.b    68,68,69,69,70,71,72,72,73,74,75,76,76,77,78,79     ; 128
        dc.b    80,81,82,83,84,85,86,87,88,89,90,91,92,93,95,96     ; 144
        dc.b    97,98,100,101,102,104,105,106,107,109,111,112,114,116,117,119
        dc.b    121,123,125,126,128

sth_sprite_y_offsets:
        dc.w    0       ; 16
        dc.w    0       ; 32
        dc.w    31      ; 48
        dc.w    90      ; 64
        dc.w    124     ; 80
        dc.w    144     ; 96
        dc.w    160     ; 112
        dc.w    172     ; 128

sth_font_data:
        ; Font
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11202022
        dc.l    $33226266,$7766e6ee,$776eeeee,$776eeeee,$776eeeee,$776eeeee,$574eeeee,$556eaaaa,$466e2a2a,$6666222a,$6666224c,$6666204c,$6666444c,$6664444c,$6644444c,$4444444c
        dc.l    $4444444c,$44444488,$44444888,$44448888,$44088888,$44088888,$00088888,$00088888,$00088800,$00088000,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $776644ee,$7744ccee,$754cccee,$754cccee,$754c8cee,$75088cee,$31088cee,$31088cee,$31088eee,$3108aeee,$332aaeee,$322aaeee,$222aaeee,$222aeeee,$222aeecc,$626eeecc
        dc.l    $666ecccc,$464cccc8,$444ccc88,$444ccc88,$444ccc88,$444c8888,$444c8888,$44008888,$00000808,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00202220,$32222222,$32222266,$33226666,$33666666,$33666666
        dc.l    $77666666,$77466666,$554446ee,$554446aa,$55440aaa,$55008aaa,$55008aaa,$51008aaa,$11088aaa,$00088aaa,$00088a88,$00088888,$00088888,$00088888,$40088888,$40088888
        dc.l    $44488888,$444c8888,$444c8888,$44488888,$44008888,$44000888,$40000008,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $776646ee,$7744ceee,$554cceee,$554cceaa,$554c8aaa,$55088aaa,$11088aaa,$11088aaa,$11088aaa,$1108aaaa,$1008aaaa,$100aaaaa,$002aaaaa,$222aaaaa,$222aaaec,$622aeecc
        dc.l    $666eeecc,$666ecccc,$666ccccc,$664ccccc,$444ccccc,$4444cc88,$44440888,$00000008,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $776646ee,$7744ceee,$754cceee,$754cceee,$754c8eee,$75088eee,$31088eee,$31088eee,$31088eee,$31088eee,$31088eee,$31088eee,$00088eee,$00088e88,$00088888,$00088888
        dc.l    $00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $776646ee,$7744ceee,$754cceee,$754cceee,$754c8eee,$75088eee,$31088eee,$31088e66,$31080666,$31000666,$31000666,$11000666,$11000622,$11000222,$11000222,$11000222
        dc.l    $00000222,$00000200,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00202220,$32222222,$32222266,$33226666,$33666666,$33666666
        dc.l    $77666666,$7746666e,$554446ee,$554446aa,$55440aaa,$55008aaa,$55008aaa,$51008aaa,$11008aaa,$11088aaa,$000888cc,$0008cccc,$0008cccc,$0008cccc,$0008cccc,$0008cccc
        dc.l    $0008cccc,$404ccccc,$444ccccc,$444ccccc,$44cccccc,$44cccc88,$44cc8888,$44888888,$00888888,$00888800,$00880000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$22666666,$66666644
        dc.l    $666644cc,$6644cccc,$664ccccc,$664ccccc,$664ccccc,$6608cccc,$2208cccc,$2208cc44,$22084444,$33004444,$33004466,$33006666,$33226666,$33226666,$33226666,$33226666
        dc.l    $22666666,$66666644,$666644cc,$6644cccc,$444ccccc,$444ccc88,$444c8888,$44088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11000022,$11000022,$11000022,$11000022,$11000022,$11000022
        dc.l    $11000022,$110000a2,$1100aaa2,$112aaaa2,$332aaaa2,$332aaae6,$332aeee6,$336eeee6,$776eeee6,$776eccee,$774cccee,$554cccee,$554cccaa,$554c88aa,$550888aa,$110888aa
        dc.l    $000888a2,$00088880,$00088880,$00088880,$00088880,$00088880,$00088880,$00088880,$00088880,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00400000,$44400000
        dc.l    $44400008,$44400088,$44400888,$44408888,$44408888,$44008888,$44088888,$40088888,$00188888,$11188888,$111888aa,$1118aaaa,$113aaaaa,$333aaaaa,$333aaaee,$332aeeee
        dc.l    $626eeeee,$666eeecc,$666ecccc,$664ccccc,$444ccccc,$444ccc88,$44448888,$44000888,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$22666666,$66666644
        dc.l    $666644cc,$6644cccc,$644ccccc,$666ccccc,$666eeccc,$666eeeec,$766eeeee,$376eee66,$332e6666,$33226666,$33266666,$33666666,$15466666,$55444666,$5544440a,$45444488
        dc.l    $44440888,$44448888,$44088888,$44088888,$00088888,$00088888,$00088800,$00088800,$00080000,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$22666666,$66666644
        dc.l    $666644cc,$6644cccc,$444ccccc,$444ccc88,$444c8888,$44088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888
        dc.l    $40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$40088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $764466ee,$4466eeee,$446eee88,$666eaa88,$662a888c,$222888cc,$3208cc44,$31286666,$33666666,$37666666,$37666666,$37666666,$15446626,$15222222,$33222222,$33222266
        dc.l    $22226666,$22666644,$66664444,$664444cc,$4444cccc,$444ccc88,$444c8888,$44088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$32666666,$66666666
        dc.l    $666666ee,$6666eeec,$666eeecc,$666eeecc,$666ea8cc,$662a8ccc,$222acccc,$2228cc44,$220c4444,$22444444,$31444444,$15444466,$55446666,$55666662,$7766662a,$776666ee
        dc.l    $666666ee,$66666ecc,$6666cccc,$6644cccc,$444ccccc,$444ccc88,$444c8888,$44088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00202220,$32222222,$32222266,$33226666,$33666666,$37666666
        dc.l    $77666666,$7746666e,$554446ee,$554446aa,$55440aaa,$55008aaa,$55008aaa,$51008aaa,$11088aaa,$1108aaaa,$1008aaaa,$100aaaaa,$002aaaaa,$222aaaaa,$222aaaec,$622aeecc
        dc.l    $666eeecc,$666ecccc,$666ccccc,$664ccccc,$4444cccc,$44444c88,$44440008,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $776644ee,$7744ccee,$55ccccee,$55ccccee,$55ccccee,$5588ccee,$1188ccee,$1188cc66,$11884466,$11004466,$11004666,$11006666,$30226666,$32226666,$22226666,$22226666
        dc.l    $22226644,$22226644,$22220444,$22000444,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00202220,$32222222,$32222266,$33226666,$33666666,$37666666
        dc.l    $77666666,$774666ee,$554446ee,$55444eaa,$55448aaa,$55008aaa,$55008aaa,$51088aaa,$11088aaa,$1108aaaa,$1008aaaa,$100aaaaa,$002aaaaa,$222aaaaa,$222aaaec,$622aeecc
        dc.l    $666eeecc,$666ecccc,$666ccccc,$6644cccc,$4444cccc,$4444cc88,$444c8888,$04888888,$00888880,$08888800,$00088800,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666
        dc.l    $776644ee,$7744ccee,$554cccee,$554cccee,$554cccee,$5508ccee,$1108ccee,$1108cc66,$11084666,$11006666,$31266666,$32666666,$22666666,$26666666,$66666644,$6666664c
        dc.l    $666644cc,$66440ccc,$44448888,$44488888,$44088888,$40088888,$00088888,$00088880,$00088800,$00088000,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$10002222,$10222222,$13222222,$33222222,$33622222,$77622226
        dc.l    $7762222e,$776202ee,$776008ee,$774088ee,$774088ee,$770088ee,$730888ee,$330888ee,$330888ee,$220888ee,$220888cc,$220888cc,$220888cc,$220888cc,$22088ccc,$2008cccc
        dc.l    $604ccccc,$644ccccc,$444ccccc,$444ccccc,$444ccc88,$444ccc88,$44448888,$44000888,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11000222,$11000222,$11000222,$11000222,$11000222,$11000222,$11000222
        dc.l    $11000222,$11000222,$11002222,$11222222,$33222222,$33222266,$33226666,$33666666,$77666666,$776666ee,$7744eeee,$554ceeee,$554ceeaa,$554caaaa,$5508aaaa,$1108aaaa
        dc.l    $0008aa22,$00082200,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$33226666,$22666666,$26666644
        dc.l    $66664444,$6644444c,$444444cc,$44444488,$44440888,$44008888,$44008888,$40008888,$00088888,$11088888,$110888aa,$1108aaaa,$112aaaaa,$332aaaaa,$332aaaee,$732aeeee
        dc.l    $666eeeee,$666eeecc,$666ecccc,$664ccccc,$444ccccc,$4444cc88,$44440888,$04000008,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000002,$11000022,$11000222,$11002222,$11022222,$11222222,$32222222,$22222222
        dc.l    $22222244,$22222244,$22224444,$22244444,$22444444,$04444444,$44444444,$44444488,$54444088,$5564aaaa,$7762eaee,$776eeeee,$776eeeee,$776eeeee,$776eeeee,$776eeeee
        dc.l    $664ecece,$040c8888,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11002222,$11222222,$33222222,$33222266,$22226666,$22666644,$66664444
        dc.l    $664444cc,$4444cccc,$444ccc88,$444c8888,$642a8888,$626acccc,$666ecccc,$666ecccc,$666ecccc,$664ccccc,$3108cccc,$114c4466,$11446622,$55666622,$776622aa,$776222ee
        dc.l    $6622eeee,$626eeecc,$666ecccc,$664ccccc,$444ccccc,$444ccc88,$444c8888,$44088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$01000000,$11000000,$11000002,$11000022,$11000222,$11002222,$11022222,$10222222
        dc.l    $02222222,$22222220,$22222204,$666eeccc,$666ecccc,$666ccccc,$664ccccc,$766cecec,$776eeeee,$776eeeee,$33266666,$33666666,$33666666,$77666666,$47464606,$44444488
        dc.l    $44440088,$44448888,$44008888,$44088888,$00088888,$00088888,$00088800,$00088800,$00080000,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$01000000,$11000000,$11000002,$11000022,$11000222,$11002222,$11022222,$10222222,$02222222
        dc.l    $22222220,$22222204,$22222044,$22220444,$22204444,$22044444,$20444444,$04444444,$74646464,$776666ee,$7766eeee,$776eeeee,$776eeeee,$776eeeee,$776eeeee,$070e8e8e
        dc.l    $00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
        dc.l    $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$11000000,$11000022,$11000022,$11000022,$11000022,$11000022,$11000022,$510000aa
        dc.l    $554088aa,$554cc8aa,$554cccea,$754cccee,$776cccee,$776eecee,$776eeeee,$776eeeee,$376eeeee,$332eeeee,$332aaeee,$332aaaae,$132aaaaa,$110aaaaa,$00088aaa,$00088888
        dc.l    $00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088888,$00088800,$00080000,$00000000,$00000000,$00000000,$00000000,$00000000

;********************************************************************

;--------------------------------------------------------------------

        section "sth_copper",data,chip

sth_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$5281          ; window start
        COP_MOVE diwstop,$06c1          ; window stop
        COP_MOVE ddfstrt,$0038          ; bitplane start
sth_ddfstop:
        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00
sth_fmode:
        COP_MOVE fmode,$0000            ; fixes the aga modulo problem

        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon1,$0000
        COP_MOVE bplcon2,$0024          ; turn off all bitplanes, set scroll values to 0, sprites in front
        COP_MOVE bpl1mod,((STHAM_WIDTH*2)*STHAM_PLANES-STHAM_WIDTH)/8
        COP_MOVE bpl2mod,((STHAM_WIDTH*2)*STHAM_PLANES-STHAM_WIDTH)/8

sth_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

; Bitmap 1 (y offset = 30)
sth_scroller_shift_1_bitmap:
        dc.w    $0,$7fff,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$7f,$803f,$8000,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $380,$3fc3,$c000,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$403,$c1fc,$e000,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$80c,$1e3f,$3000,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$30,$e1c7,$d800,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $1043,$e39,$e400,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$84,$31ce,$7a00,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$108,$c633,$9d00,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $11,$18cc,$ee80,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $2222,$2333,$3300,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$4,$44cc,$ddc0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $40,$8933,$66e0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$409,$124c,$9b30,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $90,$2493,$64d8,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$2,$4924,$9b6c,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $4,$9249,$25b6,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $120,$492,$da4b,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$1,$2125,$25b5,$8000,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$808,$484a,$4a5a,$4000,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $42,$1290,$94a5,$a000,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$8425,$295a,$d000,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $210,$210a,$52a5,$2800,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $4,$850,$a54a,$d400,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $81,$285,$a95,$2a00,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$5028,$542a,$d500,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $20,$502,$a155,$2a80,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $a,$54,$aa8,$5540,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$a801,$5502,$aaa0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$2aa,$55,$5550,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$aaaa,$aaa8,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$5555,$5555,$5555,$5555,$0,$0,$0,$0
        dc.w    $0,$0,$2aaa,$aaaa,$8000,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $0,$aa,$8005,$5555,$4000,$0,$0,$0,$0,$2a00,$1550,$aaa,$a000,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$2,$8005,$402a,$a055,$5000,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$8,$50,$a81,$550a,$a800,$0,$0,$0
        dc.w    $0,$500,$a054,$aa5,$5400,$0,$0,$0,$20,$100a,$502,$a150,$aa00,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0,$0,$0,$0,$0,$4020,$5028,$542a,$5500,$0,$0,$0
        dc.w    $81,$81,$285,$a85,$a80,$0,$0,$0,$0,$204,$850,$a152,$a540,$0,$0,$0
        dc.w    $4,$810,$a102,$1428,$52a0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
        dc.w    $200,$2042,$428,$4285,$2850,$0,$0,$0,$0,$108,$1085,$852,$9528,$0,$0,$0
        dc.w    $10,$8000,$4210,$a528,$4294,$0,$0,$0,$0,$421,$842,$1085,$294a,$0,$0,$0
        dc.w    $0,$84,$2108,$4212,$94a5,$0,$0,$0,$2,$1000,$8421,$948,$4252,$8000,$0,$0
        dc.w    $40,$210,$1084,$2421,$2909,$4000,$0,$0,$0,$4002,$210,$9094,$84a4,$a000,$0,$0
        dc.w    $0,$40,$4042,$4242,$5252,$5000,$0,$0,$808,$808,$809,$909,$909,$800,$0,$0
        dc.w    $0,$101,$120,$2424,$24a4,$a400,$0,$0,$1,$20,$2404,$8090,$9212,$5200,$0,$0
        dc.w    $0,$2004,$90,$1242,$4849,$2900,$0,$0,$100,$400,$9002,$4809,$2124,$8480,$0,$0
        dc.w    $0,$90,$248,$124,$492,$5240,$0,$0,$20,$2,$4001,$2480,$9249,$920,$0,$0
        dc.w    $4,$0,$924,$12,$4924,$2490,$0,$0,$0,$9249,$2492,$9249,$2492,$4920,$0,$0
        dc.w    $0,$0,$0,$4924,$9249,$2492,$0,$0,$0,$0,$0,$2492,$4924,$9249,$0,$0
        dc.w    $0,$24,$9249,$0,$12,$4924,$8000,$0,$2,$4900,$124,$9248,$9249,$2449,$0,$0
        dc.w    $10,$0,$4800,$924,$124,$9204,$9000,$0,$0,$12,$12,$4002,$4802,$4922,$4800,$0
        dc.w    $80,$480,$2481,$2489,$2449,$2249,$1000,$0,$0,$2001,$48,$240,$1204,$9024,$8900,$0
        dc.w    $0,$8,$200,$9004,$8120,$4912,$4480,$0,$401,$40,$1004,$120,$4812,$481,$2040,$0
        dc.w    $0,$200,$8120,$4891,$2448,$9224,$4900,$0,$8,$1024,$812,$2448,$9122,$4891,$2240,$0
        dc.w    $0,$0,$4081,$204,$810,$2448,$9122,$0,$0,$8102,$408,$9122,$4448,$9122,$4448,$0
        dc.w    $40,$10,$2244,$891,$1224,$4488,$9122,$0,$0,$801,$20,$4408,$102,$2044,$891,$1000
        dc.w    $4,$80,$1102,$2044,$4889,$1112,$2244,$4000,$0,$4008,$8011,$1222,$2444,$4488,$8911,$1000
        dc.w    $0,$400,$888,$8111,$1122,$2222,$2444,$4400,$0,$44,$4440,$888,$8888,$9111,$1111,$1100
        dc.w    $0,$0,$4,$4444,$0,$888,$8888,$8888,$0,$0,$0,$0,$4444,$4444,$4444,$4444

        REPT    16
        dc.l    0
        ENDR

sth_scroller_shift_2_bitmap:
        ; Bitmap 2 (y offset = 157, x = 48, width = 80)
        dc.w    $0,$0,$9248,$0,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $1,$2480,$92,$4000,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $10,$90,$490,$2400,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $2,$81,$2048,$9220,$0
        dc.w    $0,$204,$102,$488,$0
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$81,$204,$891,$0
        dc.w    $0,$2000,$811,$2204,$4000
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$8010,$220,$4408,$8800
        dc.w    $0,$0,$8801,$1022,$2200
        dc.w    $0,$200,$44,$4088,$8880
        dc.w    $0,$11,$0,$222,$2220
        dc.w    $0,$0,$0,$0,$0
        dc.w    $0,$0,$0,$0,$0

        IFND    FW_DEMO_PART
sth_hamphrey_pic:
        incbin  "../data/stham/PLT_HAMph_path_2_test08b_ham.raw"
        ENDC

        END