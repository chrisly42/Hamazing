; TODOs:
; - fix stray unfilled pixels in text panel gfx?
; - fix bugs in outro (top line, right hand side diagonal line problem)
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
FW_SCRIPTING_SUPPORT        = 0 ; enable simple timed scripting functions
FW_SINETABLE_SUPPORT        = 1 ; enable creation of 1024 entries sin/cos table
FW_PALETTE_LERP_SUPPORT     = 1 ; enable basic palette fading functions
FW_YIELD_FROM_MAIN_TOO      = 0 ; adds additional code that copes with Yield being called from main code instead of task
FW_VBL_IRQ_SUPPORT          = 1 ; enable custom VBL IRQ routine
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

KNIGHTS_WIDTH   = 320
KNIGHTS_HEIGHT  = 180
KNIGHTS_BPLSIZE = (KNIGHTS_WIDTH*KNIGHTS_HEIGHT)/8
KNIGHTS_SLICE_WIDTH = 32

KNIGHTS_MOD       = (2*KNIGHTS_WIDTH)/8
KNIGHTS_BUF_WIDTH = 8*KNIGHTS_WIDTH
KNIGHTS_BUF_MOD   = (KNIGHTS_BUF_WIDTH/8)

KNIGHTS_TMP_BUFFER_SIZE = 3*(KNIGHTS_SLICE_WIDTH/8)*KNIGHTS_HEIGHT

NUM_LAMP_ROTATIONS = 41

LAMP_WIDTH  = 48
LAMP_HEIGHT = 32
LAMP_PLANES = 4

TITLETEXT_WIDTH = 128
TITLETEXT_HEIGHT = 80
TITLETEXT_PLANES = 2

TITLETEXT_Y_POS = 88
TITLETEXT_X_POS = 96

BQ_SIZE         = 6000

NUM_BQ_AHEAD_BUFFERS = 12

SWING_FRAMES    = 256
PAINT_FRAMES    = 258

ALL_SWING_FRAMES    = SWING_FRAMES+48
ALL_PAINT_FRAMES    = PAINT_FRAMES+48

COP_PREAMBLE_INST   = 16 ; bplptrs
COP_POST_INST       = 16 ; wait
COP_INST_PER_LINE   = 1+4+1 ; wait, 4 colors, aux
COP_LIST_SIZE       = (COP_PREAMBLE_INST+COP_INST_PER_LINE*KNIGHTS_HEIGHT+COP_POST_INST)*4

CHIPMEM_SIZE = (KNIGHTS_BPLSIZE*16)+COP_LIST_SIZE*2+KNIGHTS_TMP_BUFFER_SIZE+NUM_BQ_AHEAD_BUFFERS*(KNIGHTS_HEIGHT*4*2)+NUM_LAMP_ROTATIONS*(LAMP_WIDTH/8)*(LAMP_HEIGHT+2)*LAMP_PLANES+(TITLETEXT_WIDTH/8)*(TITLETEXT_HEIGHT+1)*TITLETEXT_PLANES*2
FASTMEM_SIZE = KNIGHTS_WIDTH*KNIGHTS_HEIGHT*2+NUM_BQ_AHEAD_BUFFERS*BQ_SIZE+(ALL_SWING_FRAMES+ALL_PAINT_FRAMES+PAINT_FRAMES)*4+4096*2

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"


; Memory use:
;   - CHIP DATA: 320 x  180 x 6      =  43200 (6 original, planar, scrambled as 4+2)
;   - CHIP DATA: 128 x   65 x 2 x  2 =   4160 (text sprites)
;
;   - CHIP BSS : 320 x  180 x 8 x  2 = 115200 (4x2 db / 2x2 db, 2 draw, 2 fill, interleaved)
;   - CHIP BSS :   2 x  180 x 4 x  2 =   2880 (4 line colors, db)
;   - CHIP BSS :  48 x   34 x 4 x 41 =  33456 (lamp rotations)
;
; Total: 202 KB
;
; Fast memory use:
;   - FAST DATA:  48 x   32 x 8      =   1536 (lamp chunky)
;
;   - FAST BSS : 320 x  180 x 2      = 115200 (True color buffer)
;   - FAST BSS :           6000 x  8 =  48000 (Blitterqueues)
;
; Algorithm:
; - mark all blocks as darkest
; - restore left hand side color via blitter
; - for both line pairs lines:
;   - draw blitter lines in single bitplane
;   - fill stripes according to stripe information to separate bitplanes
;   - clear blitter lines in single bitplane
; - redraw dirty stripes
;   - mode:
;     - plain: just copy (darkest only needs 2 planes copy + 1-2 planes black)
;     - darkest/dark: copy directly with mask (may overlap dark/bright)
;     - dark/bright: copy directly with mask
;     - darkest/dark/bright: copy with mask from existing background
; - draw blitter line in lower four bitplanes with color pattern
;   - stops at left hand side edge
; - call precalculated line color copying
;   - if left hand side edge is reached, continues to overwrite left hand side color
;   - draw blitter line in upper two bitplanes with zero to make index color
; - blit colors with shifting into copperlists
;
; Memory layout:
; a1-b1-a2-b2-a3-b3-a4-b4 = 8*320*180 = 57600
; a5-b5-a6-b6-d1-f1-d2-f2 = 8*320*180 = 57600
; p1-p2-p3-p4             = 4*320*180 = 28800
; p5-p6                   = 2*320*180 = 14400
;
; Per frame:
; 4+2+4 lines, 9-12 fill blits, 130-200 paint blits

    STRUCTURE   RayData,0
        UWORD   rd_StartY12
        UWORD   rd_StartX1
        UWORD   rd_EndY1
        UWORD   rd_EndX1
        UWORD   rd_StartX2
        UWORD   rd_EndY2
        UWORD   rd_EndX2
        LABEL   rd_SIZEOF

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrDbPlanesP1234Ptr
        APTR    pd_CurrDbPlanesP56Ptr
        APTR    pd_LastDbPlanesP1234Ptr
        APTR    pd_LastDbPlanesP56Ptr
        APTR    pd_CurrLineColorsPtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        APTR    pd_CurrTextSpritesPtr
        APTR    pd_LastTextSpritesPtr
        APTR    pd_SpriteDataPtr
        UBYTE   pd_DbToggle
        UBYTE   pd_AsyncDbToggle
        ALIGNWORD

        UWORD   pd_PartCountDown
        BOOL    pd_LampIsOn

        UWORD   pd_CopperLinesFixupOffset
        UWORD   pd_CopperLogoColorOffset
        UWORD   pd_SwingFrameNum
        UWORD   pd_PaintFrameNum
        UWORD   pd_LampFrameNum
        UWORD   pd_PullDownYPos
        UWORD   pd_NextQueueTriggerFrame
        UWORD   pd_CurrBlitSize

        UWORD   pd_LampYOffset
        BOOL    pd_PrecalcDone

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        APTR    pd_DbBufferP1234
        APTR    pd_DbBufferP56
        APTR    pd_OriginalBufferP1234
        APTR    pd_OriginalBufferP56
        APTR    pd_MiddleMaskBuffer
        APTR    pd_RightMaskBuffer
        APTR    pd_BothLinesMaskBuffer

        APTR    pd_LineColorsBuffer
        APTR    pd_LampSpriteBuffer
        APTR    pd_TextSpriteBuffer

        APTR    pd_BqBuffer
        APTR    pd_BqDataReadPtr
        APTR    pd_BqDataWritePtr
        APTR    pd_BqDataEndPtr
        UWORD   pd_PrecalculatedFrames

        LABEL   pd_LampChunkyBuffer
        APTR    pd_TrueColorImage
        APTR    pd_SwingDataPtr
        APTR    pd_TextPaintDataPtr
        APTR    pd_TextPanelsPtr
        APTR    pd_SourcePanelPtr
        UWORD   pd_SourcePanelNum

        APTR    pd_FillBrightBuffer
        APTR    pd_FillDarkBuffer
        APTR    pd_DrawBrightBuffer
        APTR    pd_DrawDarkBuffer

        APTR    pd_SwingScriptFramesPtrs
        APTR    pd_PaintScriptFramesPtrs
        APTR    pd_TextPaintScriptFramesPtrs

        APTR    pd_ShadeTableXor

        STRUCT  pd_LampSprites,8*4
        STRUCT  pd_TextSprites,2*(TITLETEXT_WIDTH/16)*4

        STRUCT  pd_XSheer1,LAMP_HEIGHT
        STRUCT  pd_XSheer2,LAMP_HEIGHT
        STRUCT  pd_YSheer,LAMP_WIDTH

        STRUCT  pd_LampPalette,15*cl_SIZEOF
        STRUCT  pd_KnightsPalette,16*2
        STRUCT  pd_PreparationTask,ft_SIZEOF

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        bsr.s   blb_init

        move.w  #DMAF_SETCLR|DMAF_SPRITE,dmacon(a5) ; enable sprite dma

        lea     blb_copperlist,a0
        CALLFW  SetCopper

        bsr     blb_intro
        bsr     blb_main
        bsr     blb_brighten
        bsr     blb_outro

        CALLFW  SetBaseCopper

        rts

;--------------------------------------------------------------------

blb_init:
        bsr     blb_init_vars
        bsr     blb_init_lamp_sprite_pointers

        bsr     blb_rearrange_buffers
        bsr     blb_clear_mask_buffers

        bsr     blb_init_colors

        lea     .backgroundtasks(pc),a0
        lea     pd_PreparationTask(a6),a1
        CALLFW  AddTask
        rts

.backgroundtasks
        bsr     blb_do_lamp_rotations
        bsr     blb_calc_true_color_image
        bsr     blb_calc_scene_pointers
        st      pd_PrecalcDone(a6)
        bsr     blb_init_shade_table
        rts

;--------------------------------------------------------------------

blb_init_vars:
        tst.w   fw_AgaChipset(a6)
        beq.s   .noaga
        move.w  #$00a0,blb_ddfstop+2        ; FIXME
        move.w  #$0003,blb_fmode+2
.noaga
        lea     blb_text_panels(pc),a0
        move.l  a0,pd_TextPanelsPtr(a6)

        move.l  #(COP_LIST_SIZE*2),d0
        CALLFW  AllocChip

        PUTMSG  10,<"Copperlist 1 %p">,a0
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)
        lea     COP_LIST_SIZE(a0),a0
        PUTMSG  10,<"Copperlist 2 %p">,a0
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        move.l  #(KNIGHTS_BPLSIZE*16),d0
        CALLFW  AllocChip
        PUTMSG  10,<"DbBufferP1234 %p">,a0
        move.l  a0,pd_DbBufferP1234(a6)
        move.l  a0,pd_CurrDbPlanesP1234Ptr(a6)
        lea     1*KNIGHTS_WIDTH/8(a0),a1
        move.l  a1,pd_LastDbPlanesP1234Ptr(a6)

        adda.l  #8*KNIGHTS_BPLSIZE,a0
        PUTMSG  10,<"DbBufferP56 %p">,a0
        move.l  a0,pd_DbBufferP56(a6)
        move.l  a0,pd_CurrDbPlanesP56Ptr(a6)
        lea     1*KNIGHTS_WIDTH/8(a0),a1
        move.l  a1,pd_LastDbPlanesP56Ptr(a6)

        lea     4*KNIGHTS_WIDTH/8(a0),a0
        move.l  a0,pd_DrawBrightBuffer(a6)
        lea     1*KNIGHTS_WIDTH/8(a0),a0
        move.l  a0,pd_FillBrightBuffer(a6)
        lea     1*KNIGHTS_WIDTH/8(a0),a0
        move.l  a0,pd_DrawDarkBuffer(a6)
        lea     1*KNIGHTS_WIDTH/8(a0),a0
        move.l  a0,pd_FillDarkBuffer(a6)

        lea     blb_bulb_pic,a0
        move.l  a0,pd_OriginalBufferP1234(a6)
        PUTMSG  10,<"OriginalBufferP1234 %p">,a0
        lea     4*KNIGHTS_BPLSIZE(a0),a0
        PUTMSG  10,<"OriginalBufferP56 %p">,a0
        move.l  a0,pd_OriginalBufferP56(a6)

        move.l  #KNIGHTS_TMP_BUFFER_SIZE,d0
        CALLFW  AllocChip
        move.l  a0,pd_MiddleMaskBuffer(a6)
        lea     (KNIGHTS_SLICE_WIDTH/8)*KNIGHTS_HEIGHT(a0),a0
        move.l  a0,pd_RightMaskBuffer(a6)
        lea     (KNIGHTS_SLICE_WIDTH/8)*KNIGHTS_HEIGHT(a0),a0
        move.l  a0,pd_BothLinesMaskBuffer(a6)

        move.l  #NUM_LAMP_ROTATIONS*(LAMP_WIDTH/8)*(LAMP_HEIGHT+2)*LAMP_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"LampSpriteBuffer %p">,a0
        move.l  a0,pd_LampSpriteBuffer(a6)

        move.l  #(TITLETEXT_WIDTH/8)*(TITLETEXT_HEIGHT+1)*TITLETEXT_PLANES*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"TextSpriteBuffer %p">,a0
        move.l  a0,pd_TextSpriteBuffer(a6)
        lea     pd_TextSprites(a6),a1
        move.l  a1,pd_CurrTextSpritesPtr(a6)
        moveq.l #2*(TITLETEXT_WIDTH/16)-1,d7
.tsprloop
        move.l  a0,(a1)+
        clr.l   TITLETEXT_HEIGHT*2*TITLETEXT_PLANES(a0)
        lea     (TITLETEXT_HEIGHT+1)*2*TITLETEXT_PLANES(a0),a0
        dbra    d7,.tsprloop

        move.l  #NUM_BQ_AHEAD_BUFFERS*KNIGHTS_HEIGHT*4*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"LineColorsBuffer %p">,a0
        move.l  a0,pd_LineColorsBuffer(a6)
        move.l  a0,pd_CurrLineColorsPtr(a6)

        move.l  #(KNIGHTS_WIDTH*KNIGHTS_HEIGHT*2),d0
        CALLFW  AllocFast
        PUTMSG  10,<"TrueColorImage %p">,a0
        move.l  a0,pd_TrueColorImage(a6)

        move.l  #NUM_BQ_AHEAD_BUFFERS*BQ_SIZE,d0
        CALLFW  AllocFast
        PUTMSG  10,<"BqBuffers %p">,a0
        addq.l  #4,a0       ; extra longwords for blitsize & lamp on
        move.l  a0,pd_BqDataReadPtr(a6)
        move.l  a0,pd_BqDataWritePtr(a6)
        move.l  a0,pd_BqBuffer(a6)
        add.l   #NUM_BQ_AHEAD_BUFFERS*BQ_SIZE,a0
        move.l  a0,pd_BqDataEndPtr(a6)

        move.l  #(ALL_SWING_FRAMES+ALL_PAINT_FRAMES+PAINT_FRAMES)*4,d0
        CALLFW  AllocFast
        PUTMSG  10,<"ScriptFramesPtrs %p">,a0
        move.l  a0,pd_SwingScriptFramesPtrs(a6)
        lea     ALL_SWING_FRAMES*4(a0),a0
        move.l  a0,pd_PaintScriptFramesPtrs(a6)
        lea     ALL_PAINT_FRAMES*4(a0),a0
        move.l  a0,pd_TextPaintScriptFramesPtrs(a6)

        move.l  #4096*2,d0
        CALLFW  AllocFast
        move.l  a0,pd_ShadeTableXor(a6)
        PUTMSG  10,<"ShadeTableXor %p">,a0

        rts

;--------------------------------------------------------------------

blb_init_lamp_sprite_pointers:
        lea     blb_coppersprites+2,a0
        lea     fw_EmptySprite(a6),a1
        moveq.l #8-1,d7
.sprloop
        move.w  (a1),(a0)
        move.w  2(a1),4(a0)
        addq.w  #8,a0
        dbra    d7,.sprloop
        rts

;--------------------------------------------------------------------

blb_init_colors:
        lea     color(a5),a1
        lea     blb_bulb_palette_expanded(pc),a0
        moveq.l #(16/2)-1,d7
.ploop
        move.l  (a0)+,(a1)+
        dbra    d7,.ploop

        addq.w  #2,a1
        lea     blb_lamp_off_palette(pc),a0
        moveq.l #15-1,d7
.palloop
        move.w  (a0)+,(a1)+
        dbra    d7,.palloop

        moveq.l #15,d0
        lea     blb_lamp_off_palette(pc),a0
        lea     pd_LampPalette(a6),a1
        CALLFW  InitPaletteLerp

        rts

;--------------------------------------------------------------------

blb_init_shade_table:
        move.l  pd_ShadeTableXor(a6),a0
        PUTMSG  10,<"%d: Init Shade Table %p">,fw_FrameCounterLong(a6),a0
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

        rts

;--------------------------------------------------------------------

blb_intro:
        bsr     blb_flip_db_frame
        bsr     blb_intro_fill_low_brightness
        bsr     blb_flip_db_frame
        bsr     blb_intro_fill_low_brightness
        move.w  #320,pd_LampFrameNum(a6)
        move.w  #-80,pd_LampYOffset(a6)
        IFD     FW_DEMO_PART
        CALLFW  StartMusic
        ENDC
.loop
        CALLFW  VSyncWithTask

        bsr     blb_flip_copper_frame
        bsr     blb_update_lamp_sprite
        move.w  pd_LampYOffset(a6),d0
        beq.s   .skipdown
        addq.w  #1,d0
        move.w  d0,pd_LampYOffset(a6)
.skipdown

        bsr     blb_create_intro_copperlist
        bsr     blb_update_copper_list_pointers

        tst.w   pd_LampYOffset(a6)
        bne.s   .loop

        tst.w   pd_PrecalcDone(a6)
        beq.s   .loop

        move.b  pd_AsyncDbToggle(a6),d0
        cmp.b   pd_DbToggle(a6),d0
        bne.s   .loop

        rts

;--------------------------------------------------------------------

blb_main:
        move.w  #5*256+32,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueMultiFrame

        move.w  #-1,pd_CurrBlitSize(a6)
        PUTMSG  10,<"%d: Main!">,fw_FrameCounterLong(a6)

        lea     .vblstuff(pc),a0
        move.l  a0,fw_VBlankIRQ(a6)

        bsr     blb_flip_db_frame
        bsr     blb_create_bulb_copperlist
        bsr     blb_patch_in_text_sprites_to_copperlist
        bsr     blb_update_copper_list_pointers

        CALLFW  VSyncWithTask

        PUTMSG  10,<"%d: Main 2">,fw_FrameCounterLong(a6)
        bsr     blb_flip_db_frame
        bsr     blb_create_bulb_copperlist
        bsr     blb_patch_in_text_sprites_to_copperlist
        bsr     blb_update_copper_list_pointers

.loop
        bsr     blb_flip_db_frame

        CALLFW  JoinBlitterQueue

        bsr     blb_swing_around
        move.l  pd_BqDataWritePtr(a6),a4

        move.l  -4(a1),-4(a4)

        move.w  #KNIGHTS_BUF_WIDTH/8,d4
        bsr     blb_blitter_line_init_bq

        bsr     blb_draw_rays

        bsr     blb_create_terminal_bq_node
        bsr     blb_add_branch_on_second_bq_node

        move.l  pd_DrawDarkBuffer(a6),a3
        move.l  pd_FillDarkBuffer(a6),a2
        bsr     blb_fill_rays

        move.l  pd_DrawBrightBuffer(a6),a3
        move.l  pd_FillBrightBuffer(a6),a2
        bsr     blb_fill_rays

        bsr     blb_do_bresenham_rays_color_fixup

        cmp.w   #17000,pd_CurrBlitSize(a6)
        blt.s   .donthog
        PUTMSG  20,<"Hogging frame %d">,pd_CurrBlitSize-2(a6)
        CALLFW  JoinBlitterQueue
.donthog

        bsr     blb_paint_around
        bsr     blb_paint_slices

        bsr     blb_draw_fixup_rays

        bsr     blb_paint_text_slices

        move.l  pd_BqDataWritePtr(a6),a0
        bsr     blb_add_execute_twice_bq_node

        bsr     blb_create_nop_bq_node
        ADD_TO_BLITTER_QUEUE a0,a2

        sub.l   pd_BqDataWritePtr(a6),a4
        PUTMSG  20,<"Queue size %ld">,a4

        TERMINATE_BLITTER_QUEUE

.waitforbqspaceloop
        move.l  pd_BqDataWritePtr(a6),a0
        move.l  pd_CurrLineColorsPtr(a6),a2
        lea     KNIGHTS_HEIGHT*4*2(a2),a2
        lea     BQ_SIZE(a0),a1
        cmp.l   pd_BqDataEndPtr(a6),a1
        bne.s   .nowrapbqwrite
        move.l  pd_BqBuffer(a6),a1
        move.l  pd_LineColorsBuffer(a6),a2
.nowrapbqwrite
        cmp.l   pd_BqDataReadPtr(a6),a1
        bne.s   .nowait
        PUTMSG  40,<"%d: Waiting for space Read: %p Write: %p">,fw_FrameCounterLong(a6),pd_BqDataReadPtr(a6),pd_BqDataWritePtr(a6)
        CALLFW  JoinBlitterQueue
        CALLFW  VSyncWithTask
        bra.s   .waitforbqspaceloop
.nowait
        move.l  a1,pd_BqDataWritePtr(a6)
        move.l  a2,pd_CurrLineColorsPtr(a6)
        PUTMSG  40,<"%d: Done a frame Read: %p Write: %p">,fw_FrameCounterLong(a6),pd_BqDataReadPtr(a6),pd_BqDataWritePtr(a6)

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

.vblstuff
        bsr     blb_update_lamp_sprite
        tst.b   pd_LampFrameNum+1(a6)
        bne.s   .nonextpanel
        move.l  pd_TextPanelsPtr(a6),a0
        move.l  (a0)+,pd_SourcePanelPtr(a6)
        move.l  a0,pd_TextPanelsPtr(a6)
        move.w  pd_SourcePanelNum(a6),d0
        bne.s   .notfirst
        move.w  d0,pd_CurrBlitSize(a6)
.notfirst
        addq.w  #1,d0
        move.w  d0,pd_SourcePanelNum(a6)
        subq.w  #4,d0
        beq.s   .insidelogo
        subq.w  #2,d0
        bne.s   .nonextpanel
        move.w  blb_lamp_palette+1*2(pc),d0
        bra.s   .fixcolor
.insidelogo
        move.w  #$f88,d0
.fixcolor
        move.l  pd_CurrCopListPtr(a6),a0
        add.w   pd_CopperLogoColorOffset(a6),a0
        move.w  d0,(a0)
        move.w  d0,COP_INST_PER_LINE*4(a0)
        move.l  pd_LastCopListPtr(a6),a0
        add.w   pd_CopperLogoColorOffset(a6),a0
        move.w  d0,(a0)
        move.w  d0,COP_INST_PER_LINE*4(a0)
.nonextpanel

        tst.w   pd_CurrBlitSize(a6)
        bne.s   .nop
        move.l  pd_BqDataReadPtr(a6),a0
        cmp.l   pd_BqDataWritePtr(a6),a0
        beq.s   .nop
        move.w  fw_FrameCounter(a6),d0
        cmp.w   pd_NextQueueTriggerFrame(a6),d0
        blt.s   .nop
        beq.s   .nodrop
        tst.w   pd_NextQueueTriggerFrame(a6)
        beq.s   .nodrop
        subq.w  #1,pd_LampFrameNum(a6)
        PUTMSG  10,<"%d: Framedrop %d vs %d!">,fw_FrameCounterLong(a6),pd_NextQueueTriggerFrame-2(a6),d0
.nodrop
        addq.w  #2,d0
        move.w  d0,pd_NextQueueTriggerFrame(a6)
        PUTMSG  20,<"%d: Triggering queue %p">,fw_FrameCounterLong(a6),a0
        move.w  -4(a0),pd_CurrBlitSize(a6)
        BLTWAIT
        CALLFW  TriggerCustomBlitterQueue
        rts
.nop
        PUTMSG  20,<"%d: Ignoring">,fw_FrameCounterLong(a6)
        rts

;--------------------------------------------------------------------

blb_brighten:
        move.w  #48,pd_PartCountDown(a6)

        moveq.l #15,d0
        move.w  #64,d1
        lea     blb_lamp_white_palette(pc),a0
        lea     pd_LampPalette(a6),a1
        CALLFW  FadePaletteTo

        PUTMSG  10,<"%d: Brighten!">,fw_FrameCounterLong(a6)

        move.w  #SWING_FRAMES*4,pd_SwingFrameNum(a6)
        move.w  #PAINT_FRAMES*4,pd_PaintFrameNum(a6)
.loop
        bsr     blb_flip_db_frame

        CALLFW  JoinBlitterQueue

        bsr     blb_swing_around_brighten
        move.l  pd_BqDataWritePtr(a6),a4

        move.l  -4(a1),-4(a4)

        move.w  #KNIGHTS_BUF_WIDTH/8,d4
        bsr     blb_blitter_line_init_bq

        bsr     blb_draw_rays

        bsr     blb_create_terminal_bq_node
        bsr     blb_add_branch_on_second_bq_node

        move.l  pd_DrawDarkBuffer(a6),a3
        move.l  pd_FillDarkBuffer(a6),a2
        bsr     blb_fill_rays

        move.l  pd_DrawBrightBuffer(a6),a3
        move.l  pd_FillBrightBuffer(a6),a2
        bsr     blb_fill_rays

        bsr     blb_do_bresenham_rays_color_fixup

        cmp.w   #17000,pd_CurrBlitSize(a6)
        blt.s   .donthog
        PUTMSG  20,<"Hogging frame %d">,pd_CurrBlitSize-2(a6)
        CALLFW  JoinBlitterQueue
.donthog

        bsr     blb_paint_around_brighten
        bsr     blb_paint_slices

        bsr     blb_draw_fixup_rays

        move.l  pd_BqDataWritePtr(a6),a0
        bsr     blb_add_execute_twice_bq_node

        bsr     blb_create_nop_bq_node
        ADD_TO_BLITTER_QUEUE a0,a2

        sub.l   pd_BqDataWritePtr(a6),a4
        PUTMSG  20,<"Queue size %ld">,a4

        TERMINATE_BLITTER_QUEUE

.waitforbqspaceloop
        move.l  pd_BqDataWritePtr(a6),a0
        move.l  pd_CurrLineColorsPtr(a6),a2
        lea     KNIGHTS_HEIGHT*4*2(a2),a2
        lea     BQ_SIZE(a0),a1
        cmp.l   pd_BqDataEndPtr(a6),a1
        bne.s   .nowrapbqwrite
        move.l  pd_BqBuffer(a6),a1
        move.l  pd_LineColorsBuffer(a6),a2
.nowrapbqwrite
        cmp.l   pd_BqDataReadPtr(a6),a1
        bne.s   .nowait
        PUTMSG  40,<"%d: Waiting for space Read: %p Write: %p">,fw_FrameCounterLong(a6),pd_BqDataReadPtr(a6),pd_BqDataWritePtr(a6)
        CALLFW  JoinBlitterQueue
        CALLFW  VSyncWithTask
        bra.s   .waitforbqspaceloop
.nowait
        move.l  a1,pd_BqDataWritePtr(a6)
        move.l  a2,pd_CurrLineColorsPtr(a6)
        PUTMSG  40,<"%d: Done a frame Read: %p Write: %p">,fw_FrameCounterLong(a6),pd_BqDataReadPtr(a6),pd_BqDataWritePtr(a6)

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

.waitloop

        CALLFW  JoinBlitterQueue
        CALLFW  VSyncWithTask
        move.l  pd_BqDataReadPtr(a6),a0
        cmp.l   pd_BqDataWritePtr(a6),a0
        bne.s   .waitloop

        clr.l   fw_VBlankIRQ(a6)

        CALLFW  JoinBlitterQueue
        CALLFW  VSyncWithTask

        rts

;--------------------------------------------------------------------

blb_outro:
        move.w  #16,pd_PartCountDown(a6)
        bsr     blb_prep_p5p6_mask

        lea     pd_KnightsPalette(a6),a1
        lea     blb_bulb_palette_expanded(pc),a0
        moveq.l #(16/2)-1,d7
.palloop
        move.l  (a0)+,(a1)+
        dbra    d7,.palloop

        lea     .vblstuff(pc),a0
        move.l  a0,fw_VBlankIRQ(a6)
.loop
        bsr     blb_flip_db_frame

        bsr     blb_fade_step_to_white

        bsr     blb_palette_fade_step_to_white

        bsr     blb_create_outro_copperlist
        bsr     blb_update_copper_list_pointers

        CALLFW  VSyncWithTask

        subq.w  #1,pd_PartCountDown(a6)
        bne     .loop

        rts

.vblstuff
        PUSHM   d4
        bsr     blb_update_lamp_sprite

        moveq.l #15,d0
        lea     pd_LampPalette(a6),a1
        CALLFW  DoFadePaletteStep
        BLTHOGON
        POPM
        rts

;--------------------------------------------------------------------

blb_flip_db_frame:
        move.l  pd_CurrDbPlanesP1234Ptr(a6),pd_LastDbPlanesP1234Ptr(a6)
        move.l  pd_CurrDbPlanesP56Ptr(a6),pd_LastDbPlanesP56Ptr(a6)
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        move.l  pd_CurrTextSpritesPtr(a6),pd_LastTextSpritesPtr(a6)

        move.l  pd_DbBufferP1234(a6),a0
        move.l  pd_DbBufferP56(a6),a1
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        lea     (KNIGHTS_WIDTH/8)(a0),a0
        lea     (KNIGHTS_WIDTH/8)(a1),a1
        move.l  a0,pd_CurrDbPlanesP1234Ptr(a6)
        move.l  a1,pd_CurrDbPlanesP56Ptr(a6)
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        lea     pd_TextSprites+(TITLETEXT_WIDTH/16)*4(a6),a0
        move.l  a0,pd_CurrTextSpritesPtr(a6)
        rts
.selb1
        move.l  a0,pd_CurrDbPlanesP1234Ptr(a6)
        move.l  a1,pd_CurrDbPlanesP56Ptr(a6)
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        lea     pd_TextSprites(a6),a0
        move.l  a0,pd_CurrTextSpritesPtr(a6)
        rts

blb_flip_copper_frame:
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        not.b   pd_AsyncDbToggle(a6)
        beq.s   .selb1
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        rts
.selb1
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        rts

blb_flip_async_db_frame:
        not.b   pd_AsyncDbToggle(a6)
        beq.s   .selb1
        move.l  pd_CopperList2(a6),a0
        move.w  pd_CopperList2(a6),blb_extra_copperlist_ptr+2
        move.w  a0,blb_extra_copperlist_ptr+6
        rts
.selb1
        move.l  pd_CopperList1(a6),a0
        move.w  pd_CopperList1(a6),blb_extra_copperlist_ptr+2
        move.w  a0,blb_extra_copperlist_ptr+6
        rts

;--------------------------------------------------------------------

blb_update_copper_list_pointers:
        lea     blb_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

blb_palette_fade_step_to_white:
        lea     pd_KnightsPalette(a6),a1
        move.l  pd_ShadeTableXor(a6),a0
        move.w  #$fff,d2
        moveq.l #16-1,d7
.loop   move.w  (a1),d0
        move.w  d0,d1
        eor.w   d2,d1
        add.w   d1,d1
        add.w   (a0,d1.w),d0
        move.w  d0,(a1)+
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

blb_calc_scene_pointers:
        lea     blb_swing_data,a1
        move.l  pd_SwingScriptFramesPtrs(a6),a0
        move.w  #ALL_SWING_FRAMES-1,d7
.swingloop
        move.l  a1,(a0)+
        addq.l  #4,a1
        lea     2*rd_SIZEOF(a1),a1

        bsr.s   blb_silent_fill_rays
        bsr.s   blb_silent_fill_rays
        dbra    d7,.swingloop

        lea     blb_paint_data,a1
        move.l  pd_PaintScriptFramesPtrs(a6),a0
        move.w  #ALL_PAINT_FRAMES-1,d7
.paintloop
        move.l  a1,(a0)+
        bsr.s   blb_silent_paint_slices
        dbra    d7,.paintloop

        lea     blb_textpaint_data,a1
        move.l  pd_TextPaintScriptFramesPtrs(a6),a0
        move.w  #PAINT_FRAMES-1,d7
.textpaintloop
        move.l  a1,(a0)+
.loop   tst.w   (a1)+
        beq.s   .finished
        addq.w  #6,a1
        bra.s   .loop
.finished
        dbra    d7,.textpaintloop

        rts

;--------------------------------------------------------------------

blb_silent_fill_rays:
blb_silent_paint_slices:
.loop
        tst.b   (a1)+
        beq.s   .finished
        addq.w  #3,a1
        bra.s   .loop
.finished
        addq.w  #1,a1
        rts

;--------------------------------------------------------------------

blb_swing_around:
        move.l  pd_SwingScriptFramesPtrs(a6),a0
        move.w  pd_SwingFrameNum(a6),d0
        move.l  (a0,d0.w),a1
        addq.l  #4,a1
        move.l  a1,pd_SwingDataPtr(a6)

        addq.w  #4,d0
        and.w   #(SWING_FRAMES-1)*4,d0
        move.w  d0,pd_SwingFrameNum(a6)
        rts

;--------------------------------------------------------------------

blb_swing_around_brighten:
        move.l  pd_SwingScriptFramesPtrs(a6),a0
        move.w  pd_SwingFrameNum(a6),d0
        move.l  (a0,d0.w),a1
        addq.l  #4,a1
        move.l  a1,pd_SwingDataPtr(a6)

        addq.w  #4,d0
        move.w  d0,pd_SwingFrameNum(a6)
        rts

;--------------------------------------------------------------------

blb_paint_around:
        move.l  pd_PaintScriptFramesPtrs(a6),a0
        move.l  pd_TextPaintScriptFramesPtrs(a6),a1
        move.w  pd_PaintFrameNum(a6),d0
        move.l  (a1,d0.w),pd_TextPaintDataPtr(a6)
        move.l  (a0,d0.w),a1
        addq.w  #4,d0
        cmp.w   #PAINT_FRAMES*4,d0
        bne.s   .noreset
        moveq.l #2*4,d0
.noreset
        move.w  d0,pd_PaintFrameNum(a6)
        rts

;--------------------------------------------------------------------

blb_paint_around_brighten:
        move.l  pd_PaintScriptFramesPtrs(a6),a0
        move.l  pd_TextPaintScriptFramesPtrs(a6),a1
        move.w  pd_PaintFrameNum(a6),d0
        move.l  (a0,d0.w),a1
        addq.w  #4,d0
        move.w  d0,pd_PaintFrameNum(a6)
        rts

;--------------------------------------------------------------------

blb_update_lamp_sprite:
        move.w  pd_LampFrameNum(a6),d2
        lea     blb_lamp_pos_table,a0
        adda.w  d2,a0
        adda.w  d2,a0
        moveq.l #0,d0
        moveq.l #0,d1
        move.b  (a0)+,d0
        move.b  (a0)+,d1

        lea     blb_lamp_angle_table,a0
        moveq.l #0,d3
        move.b  (a0,d2.w),d3
        add.b   #NUM_LAMP_ROTATIONS/2,d3
        addq.w  #1,d2
        and.w   #SWING_FRAMES*2-1,d2
        move.w  d2,pd_LampFrameNum(a6)

        mulu    #(LAMP_WIDTH/8)*(LAMP_HEIGHT+2)*LAMP_PLANES,d3
        move.l  pd_LampSpriteBuffer(a6),a0
        adda.l  d3,a0
        add.w   #128-(LAMP_WIDTH/2),d0
        add.w   #$52-(LAMP_HEIGHT/2),d1
        add.w   pd_LampYOffset(a6),d1
        move.w  d1,d2
        add.w   #LAMP_HEIGHT,d2
        moveq.l #0,d3

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d3,d3       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d3,d3       ; ev8
        lsr.w   #1,d0       ; sh8-sh1 in d0
        addx.w  d3,d3       ; sh0
        or.w    d2,d3       ; ev7-ev0, sv8, ev8, sh0 in d3
        or.w    d1,d0       ; sv7-sv0, sh8-sh1 in d0
        tas     d3          ; att TAS sets bit 7

        lea     blb_coppersprites+2,a1
        REPT    3
        move.l  a0,d1
        swap    d1
        move.w  d1,(a1)
        move.w  a0,4(a1)
        move.w  d0,(a0)+
        move.w  d3,(a0)+

        lea     (LAMP_HEIGHT+1)*LAMP_PLANES(a0),a0
        move.l  a0,d1
        addq.w  #8,a1
        swap    d1
        move.w  d1,(a1)
        move.w  a0,4(a1)
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        lea     (LAMP_HEIGHT+1)*LAMP_PLANES(a0),a0
        addq.w  #8,d0
        addq.w  #8,a1
        ENDR
        rts

;--------------------------------------------------------------------

blb_add_execute_twice_bq_node:
        ADD_TO_BLITTER_QUEUE a4,a2
        clr.l   (a4)+
        move.l  #.bq_rout,(a4)+
        clr.w   (a4)+   ; initial state
        move.l  a0,(a4)+
        rts
.bq_rout
        not.w   (a0)+
        beq.s   .secondtime
        move.l  (a0)+,fw_BlitterQueueReadPtr(a6)
        moveq.l #0,d0
.secondtime
        rts

blb_add_branch_on_second_bq_node:
        ADD_TO_BLITTER_QUEUE a4,a2
        clr.l   (a4)+
        move.l  #.bq_rout,(a4)+
        move.w  #-1,(a4)+   ; initial state
        move.l  a0,(a4)+
        rts
.bq_rout
        not.w   (a0)+
        beq.s   .secondtime
        move.l  (a0)+,fw_BlitterQueueReadPtr(a6)
        moveq.l #0,d0
.secondtime
        rts

blb_create_nop_bq_node:
        move.l  a4,a0
        clr.l   (a4)+
        move.l  #.bq_nop,(a4)+
        rts
.bq_nop
        moveq.l #0,d0
        rts

blb_create_terminal_bq_node:
        move.l  a4,a0
        clr.l   (a4)+
        move.l  #.bq_nop,(a4)+
        rts
.bq_nop
        PUTMSG  40,<"BQ terminated">
        PUSHM   d1-d4
        move.l  pd_BqDataReadPtr(a6),a0
        move.w  -2(a0),d0
        beq.s   .lampoff

        cmp.w   #2,d0
        bne.s   .noup
        subq.w  #1,pd_LampYOffset(a6)
.noup
        tst.w   pd_LampIsOn(a6)
        bne.s   .nochange

        move.w  d0,pd_LampIsOn(a6)
        moveq.l #15,d0
        lea     blb_lamp_palette(pc),a0
        lea     pd_LampPalette(a6),a1
        CALLFW  InitPaletteLerp
        bra.s   .reloada0

.lampoff
        tst.w   pd_LampIsOn(a6)
        beq.s   .nochange
        move.w  d0,pd_LampIsOn(a6)
        moveq.l #15,d0
        moveq.l #4,d1
        lea     blb_lamp_off_palette(pc),a0
        lea     pd_LampPalette(a6),a1
        CALLFW  FadePaletteTo
.reloada0
        move.l  pd_BqDataReadPtr(a6),a0
.nochange
        lea     BQ_SIZE(a0),a1

        cmp.l   pd_BqDataEndPtr(a6),a1
        bne.s   .nowrapbq
        move.l  pd_BqBuffer(a6),a1
.nowrapbq
        move.l  a1,pd_BqDataReadPtr(a6)

        moveq.l #15,d0
        lea     pd_LampPalette(a6),a1
        CALLFW  DoFadePaletteStep

        bsr     blb_flip_async_db_frame

        lea     pd_LampPalette(a6),a1
        moveq.l #15-1,d0
        addq.w  #2,a0
.cploop move.w  cl_Color(a1),(a0)
        addq.w  #4,a0
        lea     cl_SIZEOF(a1),a1
        dbra    d0,.cploop

        clr.w   pd_CurrBlitSize(a6)

        POPM
        rts

;--------------------------------------------------------------------

blb_clear_mask_buffers:
        BLTHOGON
        BLTWAIT

        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_MiddleMaskBuffer(a6),bltdpt(a5)
        move.w  #(KNIGHTS_SLICE_WIDTH>>4)|((KNIGHTS_HEIGHT*3)<<6),bltsize(a5)

        BLTWAIT
        move.l  pd_TextSpriteBuffer(a6),bltdpt(a5)
        move.w  #((TITLETEXT_WIDTH)>>4)|(((TITLETEXT_HEIGHT+1)*TITLETEXT_PLANES*2)<<6),bltsize(a5)

        ;NUM_LAMP_ROTATIONS*(LAMP_WIDTH/8)*(LAMP_HEIGHT+2)*LAMP_PLANES
        BLTWAIT
        move.l  pd_LampSpriteBuffer(a6),bltdpt(a5)
        move.w  #((NUM_LAMP_ROTATIONS*LAMP_WIDTH/2)>>4)|(((LAMP_HEIGHT+2)*LAMP_PLANES*2)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

blb_rearrange_buffers:
        moveq.l #-1,d2

        ; make a backup of picture to rearrange planes
        moveq.l #0,d0
        move.w  #((KNIGHTS_WIDTH*2)>>4)|((KNIGHTS_HEIGHT*3)<<6),d3

        BLTHOGON
        BLTWAIT

        BLTCON_SET AD,BLT_A,0,0
        move.l  d2,bltafwm(a5)      ; also fills bltalwm
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)

        move.l  #blb_bulb_pic,bltapt(a5)
        move.l  pd_DbBufferP1234(a6),bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.l  pd_DbBufferP1234(a6),a0
        move.l  pd_OriginalBufferP1234(a6),a1
        move.w  #(KNIGHTS_WIDTH*6-KNIGHTS_WIDTH)/8,d0
        move.w  #(KNIGHTS_WIDTH*4-KNIGHTS_WIDTH)/8,d1
        move.w  #((KNIGHTS_WIDTH)>>4)|((KNIGHTS_HEIGHT)<<6),d3

        BLTWAIT

        ; plane 1
        BLTCON_SET AD,BLT_A,0,0
        move.w  d0,bltamod(a5)
        move.w  d1,bltdmod(a5)

        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    3
        lea     KNIGHTS_WIDTH/8(a0),a0
        lea     KNIGHTS_WIDTH/8(a1),a1

        BLTWAIT

        ; plane 2/3/4
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR

        move.w  #(KNIGHTS_WIDTH*6-KNIGHTS_WIDTH)/8,d0
        move.w  #(KNIGHTS_WIDTH*2-KNIGHTS_WIDTH)/8,d1
        move.l  pd_OriginalBufferP56(a6),a1
        lea     KNIGHTS_WIDTH/8(a0),a0

        BLTWAIT

        ; plane 5
        move.w  d0,bltamod(a5)
        move.w  d1,bltdmod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     KNIGHTS_WIDTH/8(a0),a0
        lea     KNIGHTS_WIDTH/8(a1),a1

        BLTWAIT

        ; plane 6
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; clear all buffers
        moveq.l #0,d0
        move.w  #((KNIGHTS_WIDTH*2)>>4)|((KNIGHTS_HEIGHT*4)<<6),d3

        BLTWAIT
        BLTCON_SET D,BLT_C,0,0
        move.w  d0,bltcdat(a5)
        move.w  d0,bltdmod(a5)

        move.l  pd_DbBufferP1234(a6),bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.l  pd_OriginalBufferP56(a6),a0
        move.l  pd_DbBufferP56(a6),a1

        BLTWAIT
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.w  #(KNIGHTS_WIDTH*2-KNIGHTS_WIDTH)/8,d0
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8,d1
        move.w  #((KNIGHTS_WIDTH)>>4)|((KNIGHTS_HEIGHT)<<6),d3

        BLTWAIT

        ; Original to DB 5 (1)
        BLTCON_SET AD,BLT_A,0,0
        move.w  d0,bltamod(a5)
        move.w  d1,bltdmod(a5)

        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     KNIGHTS_WIDTH/8(a1),a1

        BLTWAIT

        ; Original to DB 5 (2)
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     KNIGHTS_WIDTH/8(a0),a0
        lea     KNIGHTS_WIDTH/8(a1),a1

        BLTWAIT

        ; Original to DB 6 (1)
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     KNIGHTS_WIDTH/8(a1),a1

        BLTWAIT
        BLTHOGOFF

        ; Original to DB 6 (2)
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        rts

;--------------------------------------------------------------------

blb_prep_p5p6_mask:
        move.l  pd_LastDbPlanesP56Ptr(a6),a0
        lea     KNIGHTS_MOD(a0),a1
        move.l  pd_DbBufferP56(a6),a2
        lea     2*KNIGHTS_MOD(a2),a2
        moveq.l #-1,d0
        move.l  #(((KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8)<<16)|((KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8),d1
        move.w  #(KNIGHTS_WIDTH>>4)|(KNIGHTS_HEIGHT<<6),d3

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

blb_fade_step_to_white:
        move.l  pd_LastDbPlanesP1234Ptr(a6),a0  ; source p1
        move.l  pd_CurrDbPlanesP1234Ptr(a6),a4
        move.l  pd_DbBufferP56(a6),a1
        lea     2*KNIGHTS_MOD(a1),a1            ; p5|p6 mask
        move.l  a1,d5
        lea     3*KNIGHTS_MOD(a4),a1
        move.l  a1,d4                           ; target p4 as temp mask
        lea     KNIGHTS_MOD(a0),a1              ; source p2
        lea     KNIGHTS_MOD(a1),a2              ; source p3
        lea     KNIGHTS_MOD(a2),a3              ; source p4

        moveq.l #-1,d0
        move.l  #(((KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8)<<16)|((KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8),d1
        move.w  #(KNIGHTS_WIDTH>>4)|(KNIGHTS_HEIGHT<<6),d3

        ; create mask -- all bits, that are NOT all 1s
        BLTHOGON
        BLTWAIT
        BLTCON_SET ABCD,~(BLT_A&BLT_B&BLT_C),0,0
        move.l  d0,bltafwm(a5)
        move.l  d1,bltcmod(a5)
        move.l  d1,bltamod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltbpt(a5)
        move.l  a2,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        BLTWAIT
        BLTCON0_SET ABCD,(~(~BLT_A&BLT_C))&BLT_B,0
        move.l  d4,bltapt(a5)
        move.l  d5,bltbpt(a5)
        move.l  a3,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 1: p1n = p1o ^ mask
        BLTWAIT
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; update mask: mask = p1o & mask
        BLTWAIT
        BLTCON0_SET ACD,BLT_A&BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 2: p2n = p2o ^ mask
        lea     KNIGHTS_MOD(a4),a4
        BLTWAIT
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a1,bltcpt(a5)
        move.l  a4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; update mask: mask = p2o & mask
        BLTWAIT
        BLTCON0_SET ACD,BLT_A&BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a1,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 3: p3n = p3o ^ mask
        lea     KNIGHTS_MOD(a4),a4
        BLTWAIT
        BLTCON0_SET ACD,BLT_A^BLT_C,0
        move.l  d4,bltapt(a5)
        move.l  a2,bltcpt(a5)
        move.l  a4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; plane 4: p4n = p4o ^ (p3o & mask)
        BLTWAIT
        BLTHOGOFF
        BLTCON0_SET ABCD,BLT_C^(BLT_A&BLT_B),0
        move.l  d4,bltapt(a5)
        move.l  a2,bltbpt(a5)
        move.l  a3,bltcpt(a5)
        move.l  d4,bltdpt(a5)
        move.w  d3,bltsize(a5)

        rts

;--------------------------------------------------------------------

blb_intro_fill_low_brightness:
        move.l  pd_OriginalBufferP1234(a6),a0
        lea     3*(KNIGHTS_WIDTH/8)(a0),a0
        move.l  pd_CurrDbPlanesP1234Ptr(a6),a1

        move.w  #(KNIGHTS_WIDTH*4-KNIGHTS_WIDTH)/8,d0
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8,d1
        move.w  #((KNIGHTS_WIDTH)>>4)|((KNIGHTS_HEIGHT)<<6),d3

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        ; Plane 4 to DB 1 (1)
        BLTCON_SET AD,BLT_A,0,0
        move.w  d0,bltamod(a5)
        move.w  d1,bltdmod(a5)

        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)
        rts

;--------------------------------------------------------------------

blb_create_intro_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0

        moveq.l #-2,d3
        COPIMOVE $6a00,bplcon0

        move.w  pd_PullDownYPos(a6),d0
        addq.w  #8,d0
        cmp.w   #KNIGHTS_HEIGHT,d0
        ble.s   .notrunc
        move.w  #KNIGHTS_HEIGHT,d0
.notrunc
        move.w  d0,pd_PullDownYPos(a6)
        move.w  #KNIGHTS_HEIGHT,d4
        sub.w   d0,d4
        moveq.l #$52,d5
        add.w   d0,d5
        mulu    #KNIGHTS_BUF_MOD,d4

        move.l  pd_CurrDbPlanesP1234Ptr(a6),d0
        add.l   d4,d0
        moveq.l #4-1,d7
        move.w  #bplpt,d1
        moveq.l #KNIGHTS_MOD,d2
.bplloop1234
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop1234

        move.l  pd_CurrDbPlanesP56Ptr(a6),d0
        add.l   d4,d0
        moveq.l #2-1,d7
.bplloop56
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop56

        lsl.w   #8,d5
        bcc.s   .no255
        move.w  #$ffdf,(a0)+
        move.w  d3,(a0)+
.no255
        move.b  #$07,d5

        move.w  d5,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $0200,bplcon0
        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

blb_create_outro_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0

        lea     pd_KnightsPalette(a6),a1
        moveq.l #16-1,d7
        move.w  #color,d0
.palloop
        move.w  d0,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d0
        dbra    d7,.palloop

        addq.w  #2,d0
        lea     pd_LampPalette(a6),a1
        moveq.l #15-1,d7
.cploop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        addq.w  #2,d0
        lea     cl_SIZEOF(a1),a1
        dbra    d7,.cploop

        moveq.l #-2,d3
        COPIMOVE $6a00,bplcon0

        move.l  pd_CurrDbPlanesP1234Ptr(a6),d0
        moveq.l #4-1,d7
        move.w  #bplpt,d1
        moveq.l #KNIGHTS_MOD,d2
.bplloop1234
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop1234

        move.l  pd_CurrDbPlanesP56Ptr(a6),d0
        moveq.l #2-1,d7
.bplloop56
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop56

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

blb_patch_in_text_sprites_to_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        adda.w  pd_CopperLinesFixupOffset(a6),a0
        lea     36*COP_INST_PER_LINE*4+4*4-2(a0),a0
        moveq.l #COP_INST_PER_LINE*4-4,d0
        move.l  pd_CurrTextSpritesPtr(a6),a1
        move.w  #sprpt+0*4+0,d4

        moveq.l #(TITLETEXT_WIDTH/16)-1,d7
.ptloop
        move.w  d4,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d4
        adda.l  d0,a0
        move.w  d4,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d4
        adda.l  d0,a0
        dbra    d7,.ptloop

        REPT    8
        move.l  #((spr+REPTN*sd_SIZEOF+sd_pos)<<16)|(($52+TITLETEXT_Y_POS)<<8)|((TITLETEXT_X_POS+128+REPTN*16)/2),(a0)+
        adda.l  d0,a0
        move.l  #((spr+REPTN*sd_SIZEOF+sd_ctl)<<16)|(($52+TITLETEXT_Y_POS+TITLETEXT_HEIGHT)<<8)|(1<<7),(a0)+
        adda.l  d0,a0
        ENDR

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #2,d1
        move.w  d1,pd_CopperLogoColorOffset(a6)

        lea     blb_lamp_palette(pc),a1
        COPRMOVE 1*2(a1),color+18*2
        adda.l  d0,a0
        COPRMOVE 7*2(a1),color+24*2
        adda.l  d0,a0
        COPIMOVE $0d00,color+19*2
        adda.l  d0,a0
        COPIMOVE $0d00,color+28*2

        move.l  pd_CurrCopListPtr(a6),a0
        adda.w  pd_CopperLinesFixupOffset(a6),a0
        lea     175*COP_INST_PER_LINE*4+4*4-2(a0),a0
        COPRMOVE 1*2(a1),color+18*2
        adda.l  d0,a0
        COPRMOVE 7*2(a1),color+24*2
        adda.l  d0,a0
        COPRMOVE 2*2(a1),color+19*2
        adda.l  d0,a0
        COPRMOVE 11*2(a1),color+28*2
        rts

;--------------------------------------------------------------------

blb_create_bulb_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2

        lea     pd_LampPalette(a6),a1
        move.w  #color+17*2,d0
        moveq.l #15-1,d7
.blloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.blloop

        COPIMOVE $6a00,bplcon0
        move.l  pd_CurrDbPlanesP1234Ptr(a6),d0
        moveq.l #4-1,d7
        move.w  #bplpt,d1
        moveq.l #KNIGHTS_MOD,d2
.bplloop1234
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop1234

        move.l  pd_CurrDbPlanesP56Ptr(a6),d0
        moveq.l #2-1,d7
.bplloop56
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1

        add.l   d2,d0
        dbra    d7,.bplloop56

        move.l  pd_TrueColorImage(a6),a1
        moveq.l #-2,d3
        move.w  #$51d5,d0
        move.w  #KNIGHTS_HEIGHT-1,d7
        move.w  #$100,d2

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset(a6)
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.w  #(color+8*2),(a0)+
        addq.w  #2,a0
        move.w  #(color+10*2),(a0)+
        addq.w  #2,a0
        move.w  #(color+12*2),(a0)+
        addq.w  #2,a0
        move.w  #(color+14*2),(a0)+
        addq.w  #2,a0
        move.l  #$01fe0000,(a0)+

        add.w   d2,d0

        dbra    d7,.cprloop

        move.l  d3,(a0)+
        rts

;--------------------------------------------------------------------

blb_calc_true_color_image:
        move.l  pd_OriginalBufferP1234(a6),a0
        move.l  pd_OriginalBufferP56(a6),a3
        move.l  pd_TrueColorImage(a6),a1
        PUTMSG  10,<"TC Image %p">,a1
        lea     blb_bulb_palette_expanded(pc),a2
        move.w  #KNIGHTS_HEIGHT,-(sp)
.lineloop
        moveq.l #(KNIGHTS_WIDTH/16)-1,d7
        move.w  (a2),d6               ; background color
        swap    d6
.wordloop
        move.w  3*(KNIGHTS_WIDTH/8)(a0),d3
        move.w  2*(KNIGHTS_WIDTH/8)(a0),d2
        move.w  1*(KNIGHTS_WIDTH/8)(a0),d1
        move.w  (a0)+,d0
        move.w  1*(KNIGHTS_WIDTH/8)(a3),d5
        move.w  (a3)+,d4
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
        lea     3*(KNIGHTS_WIDTH/8)(a0),a0
        lea     1*(KNIGHTS_WIDTH/8)(a3),a3
        subq.w  #1,(sp)
        bne     .lineloop
        addq.w  #2,sp
        rts

;--------------------------------------------------------------------

blb_draw_rays:
        move.w  #KNIGHTS_BUF_WIDTH/8,d4
        move.w  #BLT_A&BLT_B^BLT_C,d5
        move.w  rd_EndY1(a1),d3
        cmp.w   #30,d3
        blt.s   .skipray1
        move.l  pd_DrawDarkBuffer(a6),a0
        move.w  rd_StartY12(a1),d1
        move.w  rd_StartX1(a1),d0
        move.w  rd_EndX1(a1),d2
        PUSHM   d1/d4/d5/a0/a1
        bsr     blb_draw_blitter_line_bq
        POPM
        move.w  rd_StartX2(a1),d0
        move.w  rd_EndX2(a1),d2
        move.w  rd_EndY2(a1),d3
        PUSHM   d1/d4/d5/a0/a1
        bsr     blb_draw_blitter_line_bq
        POPM

.skipray1
        lea     rd_SIZEOF(a1),a1
        move.w  rd_EndY1(a1),d3
        cmp.w   #30,d3
        blt.s   .skipray2
        move.l  pd_DrawBrightBuffer(a6),a0
        move.w  rd_StartY12(a1),d1

        move.w  rd_StartX1(a1),d0
        move.w  rd_EndX1(a1),d2
        PUSHM   d1/d4/d5/a0/a1
        bsr     blb_draw_blitter_line_bq
        POPM
        move.w  rd_StartX2(a1),d0
        move.w  rd_EndX2(a1),d2
        move.w  rd_EndY2(a1),d3
        PUSHM   d1/d4/d5/a0/a1
        bsr     blb_draw_blitter_line_bq
        POPM
.skipray2
        lea     rd_SIZEOF(a1),a1
        rts

;--------------------------------------------------------------------

blb_draw_fixup_rays:
        move.w  #KNIGHTS_BUF_WIDTH/8,d4
        bsr     blb_blitter_line_init_bq

        move.l  pd_SwingDataPtr(a6),a1
        move.w  #(BLT_A&BLT_B)|BLT_C,d5
        move.l  pd_CurrDbPlanesP1234Ptr(a6),a0
        lea     KNIGHTS_MOD*2(a0),a0

        cmp.w   #30,rd_EndY1(a1)
        blt.s   .skipray1
        move.w  rd_StartY12(a1),d1
        move.w  rd_StartX2(a1),d0
        move.w  rd_EndX2(a1),d2
        move.w  rd_EndY2(a1),d3

        PUSHM   d4/d5/a0/a1
        bsr     blb_draw_blitter_line_bq
        POPM

.skipray1
        lea     rd_SIZEOF(a1),a1

        cmp.w   #30,rd_EndY1(a1)
        blt.s   .skipray2
        move.w  rd_StartY12(a1),d1
        move.w  rd_StartX2(a1),d0
        move.w  rd_EndX2(a1),d2
        move.w  rd_EndY2(a1),d3
        bsr     blb_draw_blitter_line_bq
.skipray2

        rts

;--------------------------------------------------------------------

blb_do_bresenham_rays_color_fixup:
        move.l  pd_SwingDataPtr(a6),a2

        move.w  rd_StartY12(a2),d1
        move.w  rd_StartX1(a2),d0
        move.w  rd_EndX1(a2),d2
        move.w  rd_EndY1(a2),d3
        move.l  pd_CurrLineColorsPtr(a6),a1
        bsr     blb_bresenham_line_draw

        move.w  rd_StartY12(a2),d1
        move.w  rd_StartX2(a2),d0
        move.w  rd_EndX2(a2),d2
        move.w  rd_EndY2(a2),d3
        move.l  pd_CurrLineColorsPtr(a6),a1
        lea     3*KNIGHTS_HEIGHT*2(a1),a1
        bsr     blb_bresenham_line_draw

        lea     rd_SIZEOF(a2),a2

        move.w  rd_StartY12(a2),d1
        move.w  rd_StartX1(a2),d0
        move.w  rd_EndX1(a2),d2
        move.w  rd_EndY1(a2),d3
        move.l  pd_CurrLineColorsPtr(a6),a1
        lea     1*KNIGHTS_HEIGHT*2(a1),a1
        bsr     blb_bresenham_line_draw

        move.w  rd_StartY12(a2),d1
        move.w  rd_StartX2(a2),d0
        move.w  rd_EndX2(a2),d2
        move.w  rd_EndY2(a2),d3
        move.l  pd_CurrLineColorsPtr(a6),a1
        lea     2*KNIGHTS_HEIGHT*2(a1),a1
        bsr     blb_bresenham_line_draw

        PREP_ADD_TO_BLITTER_QUEUE a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_linecopy1,(a4)+
        move.l  pd_CurrLineColorsPtr(a6),(a4)+
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset(a6),a1
        move.l  a1,(a4)+

        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_linecopy2,(a4)+
        move.l  pd_CurrLineColorsPtr(a6),a1
        lea     2*KNIGHTS_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset(a6),a1
        lea     12(a1),a1
        move.l  a1,(a4)+

        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_linecopy3,(a4)+
        move.l  pd_CurrLineColorsPtr(a6),a1
        lea     3*KNIGHTS_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset(a6),a1
        addq.l  #8,a1
        move.l  a1,(a4)+

        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        clr.l   (a4)+
        move.l  #.bq_linecopy4,(a4)+
        move.l  pd_CurrLineColorsPtr(a6),a1
        lea     1*KNIGHTS_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset(a6),a1
        addq.l  #4,a1
        move.l  a1,(a4)+

        rts

.bq_linecopy1
        BLTCON_SET AD,BLT_A&BLT_C,1,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #COP_INST_PER_LINE*4-2,d0
        move.l  d0,bltamod(a5)
        move.w  #$777,bltcdat(a5)
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #(KNIGHTS_HEIGHT<<6)|1,bltsize(a5)
        rts

.bq_linecopy2
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #(KNIGHTS_HEIGHT<<6)|1,bltsize(a5)
        rts

.bq_linecopy3
        BLTCON_SET AD,BLT_A&BLT_C,2,0
        move.w  #$333,bltcdat(a5)
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #(KNIGHTS_HEIGHT<<6)|1,bltsize(a5)
        rts

.bq_linecopy4
        BLTCON_SET AD,BLT_A,0,0
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #(KNIGHTS_HEIGHT<<6)|1,bltsize(a5)
        rts

;--------------------------------------------------------------------

blb_fill_rays:
        tst.b   (a1)
        bne.s   .cont
        addq.l  #2,a1
        rts
.cont
        PREP_ADD_TO_BLITTER_QUEUE a0
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_fillinit,(a4)+

        moveq.l #0,d0
        moveq.l #10,d5
        move.l  #.bq_fill,d6
.loop
        moveq.l #0,d1
        move.b  (a1)+,d1
        beq.s   .finished
        moveq.l #0,d3
        move.b  (a1)+,d3
        move.w  (a1)+,d0    ; offset
        ;PUTMSG  10,<"Height %d, Offset %ld">,d3,d0
        move.l  a3,d2
        move.l  a2,d4
        add.l   d0,d2
        add.l   d0,d4
        lsl.w   #6,d3
        addq.w  #KNIGHTS_SLICE_WIDTH/16,d3  ; bltsize

        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.w  d1,(a4)+    ; bltcon1
        move.l  d2,(a4)+    ; bltapt
        move.l  d4,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize
        bra.s   .loop
.finished
        TERM_ADD_TO_BLITTER_QUEUE a0
        addq.l  #1,a1
        rts

.bq_fillinit
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8,d0
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        BLTHOGOFF
        moveq.l #0,d0
        rts
.bq_fill
        move.w  (a0)+,bltcon1(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

blb_paint_slices:
        tst.b   (a1)
        bne.s   .cont
        addq.l  #2,a1
        rts
.cont
        ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_paintinit,(a4)+

.loop
        moveq.l #0,d0   ; x pos
        move.b  (a1)+,d0
        beq.s   .finished

        moveq.l #7,d1
        and.b   d0,d1   ; control
        and.w   #$f8,d0 ; xpos * 4
        IF      KNIGHTS_SLICE_WIDTH == 32
        lsr.w   #1,d0
        ELSE
        lsr.w   #2,d0
        ENDC

        moveq.l #0,d3
        move.b  (a1)+,d3
        moveq.l #0,d2
        move.w  (a1)+,d2
        PUTMSG  40,<"%d: x=%d, yo=%lx, h=%d">,d1,d0,d2,d3
        lsl.w   #6,d3
        addq.w  #KNIGHTS_SLICE_WIDTH/16,d3

        move.l  pd_CurrDbPlanesP1234Ptr(a6),a2
        adda.l  d2,a2
        adda.w  d0,a2
        move.l  pd_CurrDbPlanesP56Ptr(a6),a3
        adda.l  d2,a3
        adda.w  d0,a3

        add.w   d1,d1
        move.w  .table(pc,d1.w),d1
        jmp     .table(pc,d1.w)
.finished
        addq.l  #1,a1
        rts

.table  dc.w    .nop-.table
        dc.w    .filldarkest-.table         ; 1
        dc.w    .filldark-.table            ; 2
        dc.w    .fillbright-.table          ; 3

        dc.w    .nop-.table
        dc.w    .darkestlinedark-.table     ; 5
        dc.w    .darklinebright-.table      ; 6
        dc.w    .bothmixedlines-.table      ; 7

.nop    bra.s   .loop
        ; fill darkest
.filldarkest
        move.l  pd_OriginalBufferP1234(a6),a0
        lsr.w   #1,d2
        lea     2*(KNIGHTS_WIDTH/8)(a0,d2.w),a0
        adda.w  d0,a0
        move.l  pd_OriginalBufferP56(a6),d4
        lsr.w   #1,d2
        add.l   d2,d4
        add.l   d0,d4

        moveq.l #KNIGHTS_WIDTH/8,d7
        move.l  a0,d2
        PREP_ADD_TO_BLITTER_QUEUE a0

        ; plane 1
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy1,(a4)+
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2
        lea     KNIGHTS_MOD(a2),a2

        ; plane 2
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy1f,(a4)+
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 5
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56,(a4)+
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a3),a3
        add.l   d7,d4

        ; plane 6
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56f,(a4)+
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        ; plane 3
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_clr1,(a4)+
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 4
        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_clr1f,(a4)+
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        bra     .loop

.darkestlinedark
        move.l  pd_DrawDarkBuffer(a6),d5
        add.l   d2,d5
        add.l   d0,d5
        move.l  pd_FillDarkBuffer(a6),d6
        add.l   d2,d6
        add.l   d0,d6
        move.l  pd_OriginalBufferP1234(a6),a0
        lsr.w   #1,d2
        lea     1*(KNIGHTS_WIDTH/8)(a0,d2.w),a0
        adda.w  d0,a0
        move.l  pd_OriginalBufferP56(a6),d4
        lsr.w   #1,d2
        add.l   d2,d4
        add.l   d0,d4

        moveq.l #KNIGHTS_WIDTH/8,d7
        move.l  a0,d2
        PREP_ADD_TO_BLITTER_QUEUE a0

        ; plane 1 dark
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy2,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)&~BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is, but not where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2
        move.l  #.bq_generic_abcd,d1

        ; plane 2 darkest
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&~BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is NOT and merge with existing (B)
        move.l  d6,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 2 dark
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)&~BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is, but not where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2

        ; plane 3 darkest
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&~BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is NOT and merge with existing (B)
        move.l  d6,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 3 dark
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)&~BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is, but not where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 4
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy3,(a4)+
        move.l  d5,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        ; plane 5
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56b,(a4)+
        move.l  d5,(a4)+    ; bltcpt
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a3),a3
        add.l   d7,d4

        ; plane 6
        ; copy (A) where line (B) is NOT
        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56bf,(a4)+
        move.l  d5,(a4)+    ; bltcpt
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        bra     .loop

.filldark
        move.l  pd_OriginalBufferP1234(a6),a0
        lsr.w   #1,d2
        lea     (KNIGHTS_WIDTH/8)(a0,d2.w),a0
        adda.w  d0,a0
        move.l  pd_OriginalBufferP56(a6),d4
        lsr.w   #1,d2
        add.l   d2,d4
        add.l   d0,d4

        moveq.l #KNIGHTS_WIDTH/8,d7

        move.l  a0,d2
        PREP_ADD_TO_BLITTER_QUEUE a0
        ; plane 1
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy1,(a4)+
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2
        lea     KNIGHTS_MOD(a2),a2

        ; plane 2
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy1f,(a4)+
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2
        lea     KNIGHTS_MOD(a2),a2

        ; plane 3
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy1f,(a4)+
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 5
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56,(a4)+
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a3),a3
        add.l   d7,d4

        ; plane 6
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56f,(a4)+
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        ; plane 4
        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_clr1,(a4)+
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        bra     .loop

.darklinebright
        move.l  pd_DrawBrightBuffer(a6),d5
        add.l   d2,d5
        add.l   d0,d5
        move.l  pd_FillBrightBuffer(a6),d6
        add.l   d2,d6
        add.l   d0,d6
        move.l  pd_OriginalBufferP1234(a6),a0
        lsr.w   #1,d2
        adda.w  d2,a0
        adda.w  d0,a0
        move.l  pd_OriginalBufferP56(a6),d4
        lsr.w   #1,d2
        add.l   d2,d4
        add.l   d0,d4

        moveq.l #KNIGHTS_WIDTH/8,d7
        move.l  a0,d2
        PREP_ADD_TO_BLITTER_QUEUE a0

        ; plane 1 bright
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy2,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)&~BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is, but not where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2
        move.l  #.bq_generic_abcd,d1

        ; plane 1 dark
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&~BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is NOT and merge with existing (B)
        move.l  d6,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 2 bright
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is OR where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2

        ; plane 2 dark
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&~BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is NOT and merge with existing (B)
        move.l  d6,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 3 bright
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)&~BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is, but not where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2

        ; plane 3 dark
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&~BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is NOT and merge with existing (B)
        move.l  d6,(a4)+    ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a2),a2

        ; plane 4 bright
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)|BLT_B)&$ff)),(a4)+ ; copy (A) where mask (C) is OR where line (B) is
        move.l  d6,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   d7,d2

        ; plane 5
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56b,(a4)+
        move.l  d5,(a4)+    ; bltcpt
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a3),a3
        add.l   d7,d4

        ; plane 6
        ; copy (A) where line (B) is NOT
        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56bf,(a4)+
        move.l  d5,(a4)+    ; bltcpt
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        bra     .loop

.fillbright
        move.l  pd_OriginalBufferP1234(a6),a0
        lsr.w   #1,d2
        adda.w  d2,a0
        adda.w  d0,a0
        move.l  pd_OriginalBufferP56(a6),d4
        lsr.w   #1,d2
        add.l   d2,d4
        add.l   d0,d4

        move.w  d3,d1
        lsl.w   #2,d1
        subq.w  #3*(KNIGHTS_SLICE_WIDTH/16),d1

        moveq.l #KNIGHTS_WIDTH/8,d7
        move.l  a0,d2
        PREP_ADD_TO_BLITTER_QUEUE a0

        ; plane 1-4
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy7,(a4)+
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d1,(a4)+    ; bltsize

        ; plane 5
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy7b,(a4)+
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a3),a3
        add.l   d7,d4

        ; plane 6
        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56f,(a4)+
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        bra     .loop

;    middleMaskNoL = (fillDark & ~fillBright) & ~drawDark (has no lines)
;    rightMaskNoL = fillBright & ~drawBright (has no lines)
;    bothLines = (drawDark || darkBright)
; 1: (origDarkest &~fillDark) || (origDark & middleMaskNoL) || (origBright & rightMaskNoL)
;    -> d = (origDarkest &~fillDark); d = d || (origDark & middleMaskNoL); d = d || (origBright & rightMaskNoL)
; 2: (origDarkest &~fillDark) || (origDark & middleMaskNoL) || (origBright & rightMaskNoL) || drawBright
;    -> d = (origDarkest &~fillDark) || drawBright; d = d || (origDark & middleMaskNoL); d = d || (origBright & rightMaskNoL)
; 3: (origDark & middleMaskNoL) || (origBright & rightMaskNoL)
;    -> d = (origDark & middleMaskNoL); d = d || (origBright & rightMaskNoL)
; 4: (origBright & rightMaskNoL) || bothLines
;    -> d = (origBright & rightMaskNoL) || bothLines
; 5: (orig & ~bothLines)
; 6: (orig & ~bothLines)

.bothmixedlines
        move.l  pd_DrawBrightBuffer(a6),d5
        add.l   d2,d5
        add.l   d0,d5
        move.l  pd_FillBrightBuffer(a6),d6
        add.l   d2,d6
        add.l   d0,d6
        move.l  pd_DrawDarkBuffer(a6),a0
        add.l   d2,a0
        add.l   d0,a0
        move.l  a0,-(sp)
        move.l  pd_FillDarkBuffer(a6),d7
        add.l   d2,d7
        add.l   d0,d7
        move.l  pd_OriginalBufferP1234(a6),a0
        lsr.w   #1,d2
        adda.w  d2,a0
        adda.w  d0,a0
        move.l  pd_OriginalBufferP56(a6),d4
        lsr.w   #1,d2
        add.l   d2,d4
        add.l   d0,d4

        move.l  a0,d2

        PREP_ADD_TO_BLITTER_QUEUE a0
        ; create MiddleMask: dark and NOT bright and not line
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_createmask1,(a4)+
        move.l  d6,(a4)+    ; bltcpt
        move.l  (sp),(a4)+  ; bltbpt
        move.l  d7,(a4)+    ; bltapt
        move.l  pd_MiddleMaskBuffer(a6),(a4)+   ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        ; create RightMask: dark and NOT bright and not line
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_createmask2,(a4)+
        move.l  d5,(a4)+    ; bltcpt
        move.l  d6,(a4)+    ; bltapt
        move.l  pd_RightMaskBuffer(a6),(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        ; create BothLines: dark and NOT bright and not line
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_createmask3,(a4)+
        move.l  d5,(a4)+    ; bltcpt
        move.l  (sp)+,(a4)+ ; bltapt
        move.l  pd_BothLinesMaskBuffer(a6),(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   #2*KNIGHTS_WIDTH/8,d2               ; p3

        ; plane 1
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy9,(a4)+
        move.l  d7,(a4)+    ; bltcpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        sub.l   #KNIGHTS_WIDTH/8,d2                 ; p2

        ; d = d || (origDark & middleMaskNoL)
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mixit1,(a4)+
        move.l  pd_MiddleMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        sub.l   #KNIGHTS_WIDTH/8,d2                 ; p1

        move.l  #.bq_generic_abcd,d1

        ; d = d || (origBright & rightMaskNoL)
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)|BLT_B)&$ff)),(a4)+ ; d = d || (origBright & rightMaskNoL)
        move.l  pd_RightMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   #3*KNIGHTS_WIDTH/8,d2               ; p4
        lea     KNIGHTS_MOD(a2),a2

        ; plane 2
        ; d = (origDarkest &~fillDark) || drawBright
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mixit2,(a4)+
        move.l  d7,(a4)+    ; bltcpt
        move.l  d5,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        sub.l   #KNIGHTS_WIDTH/8,d2                 ; p3

        ; d = d || (origDark & middleMaskNoL)
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mixit1,(a4)+
        move.l  pd_MiddleMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        sub.l   #KNIGHTS_WIDTH/8,d2                 ; p2

        ; d = d || (origBright & rightMaskNoL)
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)|BLT_B)&$ff)),(a4)+ ; d = d || (origBright & rightMaskNoL)
        move.l  pd_RightMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   #2*KNIGHTS_WIDTH/8,d2               ; p4
        lea     KNIGHTS_MOD(a2),a2

        ; plane 3
        ; d = (origDark & middleMaskNoL)
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mixit1b,(a4)+
        move.l  pd_MiddleMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        sub.l   #KNIGHTS_WIDTH/8,d2                 ; p3

        ; d = d || (origBright & rightMaskNoL)
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  d1,(a4)+
        move.w  #(BLTEN_ABCD+(((BLT_A&BLT_C)|BLT_B)&$ff)),(a4)+ ; d = d || (origBright & rightMaskNoL)
        move.l  pd_RightMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  a2,(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        add.l   #KNIGHTS_WIDTH/8,d2                 ; p4
        lea     KNIGHTS_MOD(a2),a2

        ; plane 4
        ; d = (origBright & rightMaskNoL) || bothLines
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mixit3,(a4)+
        move.l  pd_RightMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  pd_BothLinesMaskBuffer(a6),(a4)+    ; bltbpt
        move.l  d2,(a4)+    ; bltapt
        move.l  a2,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        ; plane 5
        ; copy (A) where both lines (B) are NOT
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56c,(a4)+
        move.l  pd_BothLinesMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        lea     KNIGHTS_MOD(a3),a3
        add.l   #KNIGHTS_WIDTH/8,d4

        ; plane 6
        ; copy (A) where both lines (B) are NOT
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_copy56bf,(a4)+
        move.l  pd_BothLinesMaskBuffer(a6),(a4)+   ; bltcpt
        move.l  d4,(a4)+    ; bltapt
        move.l  a3,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        LAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_restorecmod,(a4)+

        bra     .loop

.bq_paintinit
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8,d0
        lea     bltcmod(a5),a1
        move.w  d0,(a1)+        ; bltcmod
        move.w  d0,(a1)+        ; bltbmod
        move.w  d0,(a1)+        ; bltamod
        move.w  d0,(a1)+        ; bltdmod
        BLTHOGOFF
        moveq.l #0,d0
        move.w  d0,(a1)+        ; bltcdat
        rts

.bq_copy1
        BLTCON0_SET AD,BLT_A,0
        move.w  #(4*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltamod(a5)
.bq_copy1f
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy2
        move.w  #(4*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltamod(a5)
.bq_generic_abcd
        move.w  (a0)+,bltcon0(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy3
        BLTCON0_SET AD,BLT_A,0  ; copy line (A)
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltamod(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy56
        BLTCON0_SET AD,BLT_A,0
        move.w  #(2*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltamod(a5)
.bq_copy56f
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy56c
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltbmod(a5)
.bq_copy56b
        BLTCON0_SET ACD,BLT_A&~BLT_C,0 ; copy (A) where line (B) is NOT
        move.w  #(2*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltamod(a5)
.bq_copy56bf
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_clr1
        BLTCON0_SET D,0,0
.bq_clr1f
        move.l  (a0)+,bltdpt(a5)
        move.w  (a0)+,bltsize(a5)
        rts

.bq_copy7
        BLTCON0_SET AD,BLT_A,0
        move.l  #(((KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8)<<16)|((2*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8),bltamod(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy7b
        move.l  #(((2*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8)<<16)|((KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8),bltamod(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_createmask1
        BLTCON0_SET ABCD,(BLT_A&~BLT_C)&~BLT_B,0 ; create MiddleMask: dark and NOT bright and not line
        move.l  #((KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8)<<16,bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_createmask2
        BLTCON0_SET ACD,(BLT_A&~BLT_C),0        ; create RightMask: dark and NOT bright and not line
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_createmask3
        BLTCON0_SET ACD,(BLT_A|BLT_C),0         ; create BothLines: dark and NOT bright and not line
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_copy9
        BLTCON0_SET ACD,(BLT_A&~BLT_C),0        ; d = (origDarkest &~fillDark)
        move.l  #(((4*KNIGHTS_WIDTH-KNIGHTS_SLICE_WIDTH)/8)<<16)|((KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8),bltamod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_mixit1
        BLTCON0_SET ABCD,(BLT_A&BLT_C)|BLT_B,0  ; d = d || (origDark & middleMaskNoL)
        move.w  #0,bltcmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_mixit1b
        BLTCON0_SET ACD,(BLT_A&BLT_C),0 ; d = (origDark & middleMaskNoL)
        move.w  #0,bltcmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1           ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_mixit2
        BLTCON0_SET ABCD,(BLT_A&~BLT_C)|BLT_B,0 ; d = (origDarkest &~fillDark) || drawBright
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltcmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_mixit3
        BLTCON0_SET ABCD,(BLT_A&BLT_C)|BLT_B,0 ; d = (origBright & rightMaskNoL) || bothLines
        moveq.l #0,d0
        move.l  d0,bltcmod(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_restorecmod
        move.w  #(KNIGHTS_BUF_WIDTH-KNIGHTS_SLICE_WIDTH)/8,bltcmod(a5)
        moveq.l #0,d0
        rts

;--------------------------------------------------------------------

blb_paint_text_slices:
        move.l  pd_TextPaintDataPtr(a6),a1
        tst.w   (a1)
        bne.s   .cont
        rts
.cont
        PREP_ADD_TO_BLITTER_QUEUE a0
.loop
        move.w  (a1)+,d3
        beq.s   .finished

        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        ; sprite offset, source offset, mask offset
        movem.w (a1)+,d0-d2
        move.l  a1,d7
        move.l  pd_CurrTextSpritesPtr(a6),a1
        move.l  (a1),a1
        adda.w  d0,a1
        move.l  pd_SourcePanelPtr(a6),d4
        beq.s   .emptysource
        tst.w   d2
        beq.s   .plaincopy

        move.l  d4,a2
        adda.w  d1,a2
        move.l  pd_FillBrightBuffer(a6),a3
        lea     (KNIGHTS_BUF_WIDTH/8)*TITLETEXT_Y_POS(a3),a3
        adda.w  d2,a3

        ; plane 1
        move.l  #.bq_mask,(a4)+
        move.l  a3,(a4)+    ; bltcpt
        move.l  a1,(a4)+    ; bltbpt
        move.l  a2,(a4)+    ; bltapt
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        addq.w  #2,a1
        lea     (TITLETEXT_WIDTH/8)(a2),a2

        ; plane 2
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mask_more,(a4)+
        move.l  a3,(a4)+    ; bltcpt
        move.l  a1,(a4)+    ; bltbpt
        move.l  a2,(a4)+    ; bltapt
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        move.l  d7,a1
        bra.s   .loop

.plaincopy
        tst.w   d1
        beq.s   .dbcopy

        move.l  d4,a2
        adda.w  d1,a2
        move.l  #.bq_copy,(a4)+
        move.l  a2,(a4)+    ; bltapt
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        move.l  d7,a1
        bra.s   .loop

.dbcopy
        move.l  pd_LastTextSpritesPtr(a6),a2
        move.l  (a2),a2
        adda.w  d0,a2

        move.l  #.bq_dbcopy,(a4)+
        move.l  a2,(a4)+    ; bltapt
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        move.l  d7,a1
        bra     .loop

.emptysource
        tst.w   d2
        beq.s   .clearall

        move.l  pd_FillBrightBuffer(a6),a3
        lea     (KNIGHTS_BUF_WIDTH/8)*TITLETEXT_Y_POS(a3),a3
        adda.w  d2,a3

        ; plane 1
        move.l  #.bq_mask_clear,(a4)+
        move.l  a3,(a4)+    ; bltcpt
        move.l  a1,(a4)+    ; bltapt
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        addq.w  #2,a1
        lea     (TITLETEXT_WIDTH/8)(a2),a2

        ; plane 2
        FAST_ADD_TO_BLITTER_QUEUE a4,a0
        addq.l  #4,a4
        move.l  #.bq_mask_clear_more,(a4)+
        move.l  a3,(a4)+    ; bltcpt
        move.l  a1,(a4)+    ; bltapt
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        move.l  d7,a1
        bra     .loop

.clearall
        tst.w   d1
        beq.s   .dbcopy
        move.l  #.bq_clear,(a4)+
        move.l  a1,(a4)+    ; bltdpt
        move.w  d3,(a4)+    ; bltsize

        move.l  d7,a1
        bra     .loop

.finished
        ;clr.l   (a0)
        TERM_ADD_TO_BLITTER_QUEUE a0
        rts

.bq_mask
        BLTCON_SET ABCD,(BLT_A&BLT_C)|(BLT_B&~BLT_C),0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((KNIGHTS_BUF_WIDTH-16)/8)<<16)|(2),bltcmod(a5)
        move.l  #(((TITLETEXT_WIDTH*TITLETEXT_PLANES-16)/8)<<16)|(2),bltamod(a5)
.bq_mask_more
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_mask_clear
        BLTCON_SET ACD,(BLT_A&~BLT_C),0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.w  #((KNIGHTS_BUF_WIDTH-16)/8),bltcmod(a5)
        move.l  #((2)<<16)|(2),bltamod(a5)
.bq_mask_clear_more
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_clear
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  (a0)+,bltsize(a5)
        rts

.bq_copy
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((TITLETEXT_WIDTH-16)/8)<<16)|0,bltamod(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_dbcopy
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #0,d0
        move.l  d0,bltamod(a5)
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

; a0: linedraw buffer
; a1: line result buffer
; d0-d3: x1,y1 - x2,y2
; d7 high word not trashed
blb_bresenham_line_draw:
        adda.w  d1,a1
        adda.w  d1,a1

        move.l  pd_TrueColorImage(a6),a0
        move.w  d1,d4           ; offset in true color image
        mulu    #KNIGHTS_WIDTH*2,d4
        add.w   d0,d4
        add.w   d0,d4
        adda.l  d4,a0

        sub.w   d1,d3
        ;beq     .done

        sub.w   d0,d2
        beq     .straightdown
        bmi     .leftwards

.rightwards
        move.w  #KNIGHTS_WIDTH*2,d0

.rightwards_dy_greater_than_dx
        move.w  d3,d1       ; error term
        move.w  d3,d7
        add.w   d2,d2       ; dx * 2
        add.w   d3,d3       ; dy * 2

.lineloop1
        move.w  (a0),(a1)+
        adda.w  d0,a0
        sub.w   d2,d1
        dbmi    d7,.lineloop1
        add.w   d3,d1
        addq.w  #2,a0
        subq.w  #1,d7
        bpl.s   .lineloop1
.done1
        rts

.leftwards
        move.w  #KNIGHTS_WIDTH*2,d0

        neg.w   d2

.leftwards_dy_greater_than_dx
        move.w  d3,d1       ; error term
        move.w  d3,d7
        add.w   d2,d2       ; dx * 2
        add.w   d3,d3       ; dy * 2

.lineloop2
        move.w  (a0),(a1)+
        adda.w  d0,a0
        sub.w   d2,d1
        dbmi    d7,.lineloop2
        add.w   d3,d1
        subq.w  #2,a0
        subq.w  #1,d7
        bpl.s   .lineloop2
.done2
        rts

.straightdown
        move.w  #KNIGHTS_WIDTH*2,d0
.lineloopstd
        move.w  (a0),(a1)+
        adda.w  d0,a0
        dbra    d7,.lineloopstd
        rts

;--------------------------------------------------------------------

blb_do_lamp_rotations:
        move.l  pd_LampSpriteBuffer(a6),a4
        move.w  #NUM_LAMP_ROTATIONS-1,d7

        moveq.l #-NUM_LAMP_ROTATIONS/2,d1
.loop
        PUTMSG  40,<"%d: Rotation %d to %p">,fw_FrameCounterLong(a6),d1,a4

        PUSHM   d1/d7
        bsr     blb_calc_sheers
        bsr     blb_rotate_chunky

        PUTMSG  40,<"%d: C2P">,fw_FrameCounterLong(a6)
        lea     pd_LampSprites(a6),a3
        REPT    3
        move.l  a4,a1
        move.l  a1,(a3)+
        clr.l   (a1)+
        clr.l   2*2*LAMP_HEIGHT(a1)

        lea     2*2*(LAMP_HEIGHT+2)(a4),a2
        move.l  a2,(a3)+
        clr.l   (a2)+
        clr.l   2*2*LAMP_HEIGHT(a2)

        move.l  pd_LampChunkyBuffer(a6),a0
        lea     REPTN*16(a0),a0
        bsr     blb_c2p_line

        lea     2*2*2*(LAMP_HEIGHT+2)(a4),a4
        ENDR

        POPM
        addq.w  #1,d1
        dbra    d7,.loop

        rts

;--------------------------------------------------------------------

blb_calc_sheers:
        moveq.l #0,d0       ; tan increment
        moveq.l #0,d3       ; sin increment
        lea     blb_tan_table(pc),a1
        lea     blb_sin_table(pc),a2
        add.w   d1,d1
        bmi.s   .negtan
        move.w  (a1,d1.w),d0
        move.w  (a2,d1.w),d3
        neg.l   d3
        bra.s   .conttan
.negtan neg.w   d1
        move.w  (a1,d1.w),d0
        move.w  (a2,d1.w),d3
        neg.l   d0
.conttan
        lea     pd_XSheer1(a6),a0
        moveq.l #LAMP_HEIGHT/2,d1
        moveq.l #LAMP_HEIGHT,d2
        moveq.l #0,d4
        bsr     blb_calc_sheer

        lea     pd_XSheer2(a6),a0
        moveq.l #LAMP_HEIGHT/2,d1
        moveq.l #LAMP_HEIGHT,d2
        move.l  #$8000,d4
        bsr     blb_calc_sheer

        lea     pd_YSheer(a6),a0
        move.l  d3,d0
        moveq.l #LAMP_WIDTH/2,d1
        moveq.l #LAMP_WIDTH,d2
        move.l  #$8000,d4
        bsr     blb_calc_sheer
        rts

;--------------------------------------------------------------------

blb_rotate_chunky:
        PUSHM   a4
        move.l  pd_LampChunkyBuffer(a6),a0
        lea     blb_lamp_chunky(pc),a1
        lea     pd_XSheer1(a6),a2
        lea     pd_YSheer(a6),a3
        lea     pd_XSheer2(a6),a4
        moveq.l #LAMP_HEIGHT-1,d7
        moveq.l #0,d1           ; y
        moveq.l #0,d2           ; x2/saxy
.yloop
        move.b  (a2,d1.w),d2    ; x2 = saxy
        moveq.l #LAMP_WIDTH-1,d6
.xloop
        moveq.l #0,d0
        cmp.b   #LAMP_WIDTH,d1
        bhs.s   .skippix
        move.w  d1,d3
        add.b   (a3,d2.w),d3    ; y3 = y + say[x2]
        cmp.b   #LAMP_HEIGHT,d3
        bhs.s   .skippix
        move.w  d2,d4
        add.b   (a4,d3.w),d4    ; x3 = x2 + sax[y3]
        cmp.b   #LAMP_WIDTH,d4
        bhs.s   .skippix
        lsl.w   #4,d3
        add.w   d3,d4
        add.w   d3,d4
        add.w   d3,d4
        move.b  (a1,d4.w),d0
.skippix
        move.b  d0,(a0)+
        addq.b  #1,d2           ; x2
        dbra    d6,.xloop
        addq.b  #1,d1
        dbra    d7,.yloop
        POPM
        rts

;--------------------------------------------------------------------

; a0 = sheer table
; d0.l = increment
; d1.w = center
; d2.w = height
; d4.l = startoffset
blb_calc_sheer:
        PUTMSG  40,<"Calc Sheer %p, %lx, %d, %d">,a0,d0,d1,d2
        lea     (a0,d1.w),a0
        lea     1(a0),a1
        move.w  d1,d6
        move.w  d2,d7
        sub.w   d1,d7
        subq.w  #1,d7

        move.l  d4,d1
        move.l  d1,d2

.plusloop
        swap    d1
        move.b  d1,(a0)+
        swap    d1
        add.l   d0,d1
        dbra    d7,.plusloop

.minusloop
        swap    d2
        move.b  d2,-(a1)
        swap    d2
        sub.l   d0,d2
        dbra    d6,.minusloop
        rts

;--------------------------------------------------------------------

blb_c2p_line:
        move.l  #$55555555,d3
        move.l  #$33333333,d4
        move.l  #$00ff00ff,d5
        moveq.l #LAMP_HEIGHT-1,d7
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

        swap    d1
        move.l  d1,(a1)+
        swap    d0
        move.l  d0,(a2)+

        lea     LAMP_WIDTH-16(a0),a0
        dbra    d7,.loop
        rts

;--------------------------------------------------------------------

        include "blitterline_bq.asm"

;********************************************************************

blb_text_panels:
        dc.l    0
        dc.l    blb_text_1_data
        dc.l    0
        dc.l    blb_text_2_data
        dc.l    0
        dc.l    blb_text_3_data
        dc.l    blb_text_4_data
        dc.l    blb_text_5_data
        dc.l    0
        dc.l    0
        dc.l    0

blb_lamp_palette:
        incbin  "../data/bulb/lamp_64x32x16.PAL"

blb_lamp_off_palette:
        incbin  "../data/bulb/lamp_off_64x32x16.PAL"

blb_lamp_white_palette:
        REPT    15
        dc.w    $fff
        ENDR

blb_bulb_palette_expanded:
        dc.w    $0000,$0111,$0332,$0322,$0665,$0764,$0542,$0654
        dc.w    $0f0f,$0ddb,$0f0f,$0ec9,$0f0f,$0a85,$0f0f,$0cb8

blb_sin_table:
        include "sintable.asm"

blb_tan_table:
        include "tantable.asm"

blb_lamp_pos_table:
        include "lamppostable.asm"

blb_lamp_angle_table:
        include "langletable.asm"

blb_lamp_chunky:
        incbin  "../data/bulb/lamp_48x32x16.chk"

        section "blb_anim",data

blb_swing_data:
        include "swing2.asm"

blb_paint_data:
        include "paint2.asm"

blb_textpaint_data:
        include "textpaint.asm"

        IFND    FW_DEMO_PART
        dc.w    1 ; avoid hunk shortening that leaves dirty memory on kick 1.3
        ENDC

;********************************************************************

;--------------------------------------------------------------------

        section "blb_copper",data,chip

blb_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$5281          ; window start
        COP_MOVE diwstop,$06c1          ; window stop
        COP_MOVE ddfstrt,$0038          ; bitplane start
blb_ddfstop:
        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00
blb_fmode:
        COP_MOVE fmode,$0000            ; fixes the aga modulo problem

        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon1,$0000
        COP_MOVE bplcon2,$0024          ; turn off all bitplanes, set scroll values to 0, sprites in front
        COP_MOVE bpl1mod,(KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8
        COP_MOVE bpl2mod,(KNIGHTS_BUF_WIDTH-KNIGHTS_WIDTH)/8

blb_coppersprites:
        COP_MOVE sprpt,0
        COP_MOVE sprpt+2,0
        COP_MOVE sprpt+4,0
        COP_MOVE sprpt+6,0
        COP_MOVE sprpt+8,0
        COP_MOVE sprpt+10,0
        COP_MOVE sprpt+12,0
        COP_MOVE sprpt+14,0
        COP_MOVE sprpt+16,0
        COP_MOVE sprpt+18,0
        COP_MOVE sprpt+20,0
        COP_MOVE sprpt+22,0
        COP_MOVE sprpt+24,0
        COP_MOVE sprpt+26,0
        COP_MOVE sprpt+28,0
        COP_MOVE sprpt+30,0

blb_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

blb_bulb_pic:
        incbin  "../data/bulb/PLT_Lampscene_ham.raw"

blb_text_1_data:
        ;blk.b   2560,255
        incbin  "../data/bulb/text1.BPL"

blb_text_2_data:
        ;blk.b   2560,255
        incbin  "../data/bulb/text2.BPL"

blb_text_3_data:
        ;blk.b   2560,255
        incbin  "../data/bulb/text3.BPL"

blb_text_4_data:
        ;blk.b   2560,255
        incbin  "../data/bulb/text4.BPL"

blb_text_5_data:
        ;blk.b   2560,255
        incbin  "../data/bulb/text5.BPL"
        END