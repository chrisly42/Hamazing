; TODOs:
; - Fix bug with center line coloring being wrong
; - Fix one-pixel offset in pattern (when negative?)
; - Fix visual bugs (16 pixel wide stripe) when going back to fadeout mode
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
FW_VBL_IRQ_SUPPORT          = 1 ; enable custom VBL IRQ routine
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
PART_MUSIC_START_POS        = 10

        ENDC

STENCIL_WIDTH   = 64
STENCIL_HEIGHT  = 53 ; actually ((sqrt(3)/2))*64 = 55.425
LCOLBUF_HEIGHT  = 64
LCOL_NUM        = 10

KALEIDO_WIDTH   = 320
KALEIDO_HEIGHT  = STENCIL_HEIGHT
KALEIDO_VHEIGHT = 180
KALEIDO_PLANES  = 6
KALEIDO_BUF_WIDTH = 2*KALEIDO_WIDTH

INTRO_SPRITE_WIDTH = 2*STENCIL_WIDTH
INTRO_SPRITE_SHEIGHT = 2*STENCIL_HEIGHT-1
INTRO_SPRITE_HEIGHT = KALEIDO_VHEIGHT

LAST_SLICE_HEIGHT = KALEIDO_VHEIGHT-(STENCIL_HEIGHT*3-3)

KDSPAT_WIDTH    = 256
KDSPAT_HEIGHT   = 256
KDSPAT_THEIGHT  = 3*KDSPAT_HEIGHT

NOISE_WIDTH = 128
NOISE_HEIGHT = 1024+KALEIDO_VHEIGHT

SPLINE_TABLE_SIZE = 128

NUM_BACK_DUST = 80
NUM_FRONT_DUST = 80

FAIRY_WIDTH = 64
FAIRY_HEIGHT = 64
FAIRY_PLANES = 4

BODY_WIDTH = 48
BODY_HEIGHT = 51
BODY_PLANES = 4
BODY_XOFFSET = 0
BODY_YOFFSET = 5
NUM_BODY_FRAMES = 3

PUFF_WIDTH = 32
PUFF_HEIGHT = 15
PUFF_PLANES = 4
PUFF_XOFFSET = 32
PUFF_YOFFSET = 19
NUM_PUFF_FRAMES = 4

COP_PREAMBLE_INST   = 100 ; bplptrs
COP_POST_INST       = 16 ; wait
COP_INST_PER_LINE   = 1+10 ; wait, 10 colors
COP_INST_PER_INTRO_LINE = 1+3 ; wait, 3 colors
COP_INST_PER_PMAIN_LINE = 1+7+1+20 ; wait, 7 colors, 20 sprite pos
COP_LIST_SIZE       = (COP_PREAMBLE_INST+COP_INST_PER_PMAIN_LINE*KALEIDO_VHEIGHT+COP_POST_INST)*4

STENCILS_BUFFER_SIZE = ((STENCIL_WIDTH/8)*STENCIL_HEIGHT*KALEIDO_PLANES)*2+((STENCIL_WIDTH/8)*STENCIL_HEIGHT)*2
SPRITES_BUFFER_SIZE = (INTRO_SPRITE_WIDTH/16)*((INTRO_SPRITE_HEIGHT+2)*2*2)

CHIPMEM_SIZE = COP_LIST_SIZE*2+(KALEIDO_BUF_WIDTH/8)*KALEIDO_HEIGHT*KALEIDO_PLANES*2+STENCILS_BUFFER_SIZE+SPRITES_BUFFER_SIZE*2+4*LCOL_NUM*LCOLBUF_HEIGHT*2*2+NOISE_WIDTH/8*NOISE_HEIGHT+(BODY_WIDTH/8)*BODY_HEIGHT*BODY_PLANES*NUM_BODY_FRAMES+(PUFF_WIDTH/8)*PUFF_HEIGHT*PUFF_PLANES*NUM_PUFF_FRAMES+(FAIRY_WIDTH/8)*FAIRY_HEIGHT*FAIRY_PLANES
FASTMEM_SIZE = 2048*4+KDSPAT_WIDTH*KDSPAT_THEIGHT*2

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"

; Chip memory use:
;   - CHIP DATA: 256 x  256 x 6 x  3 = 147456 (Pattern/Texture)
;
;   - CHIP BSS : 320 x   53 x 6 x  2 =  25440 (6x2 db)
;   - CHIP BSS : 320 x   53 x 6 x  2 =  25440 (working space)
;   - CHIP BSS :   2 x  180 x10 x  2 =   7200 (10 line colors, db)
;   - CHIP BSS :  10 x  180 x      2 =  15840 (copperlists)
;
; Total: 207 KB
;
; Fast memory use:
;   - FAST BSS : 256 x  256     x  3 = 393216 (True color buffer)
;   - FAST BSS :           2000      =   2000 (Blitterqueues)
;
;          0)   1)         2)         3)         4)         5)
; Index = 000   -> 00 (I)  -> 00 (I)  -> 00 (I)  -> 00 (I)  -> 00 (I)
; Blue  = 101   -> 10 (R)  -> 01 (B)  -> 11 (G)  -> 10 (R)  -> 11 (G)
; Red   = 110   -> 01 (B)  -> 11 (G)  -> 10 (R)  -> 11 (G)  -> 01 (B)
; Green = 111   -> 11 (G)  -> 10 (R)  -> 01 (B)  -> 01 (B)  -> 10 (R)
;
; 0) RGB p5 := o5              ; p6 := o6
; 1) BGR p5 := o6              ; p6 := o5          -> Red   <-> Blue
; 2) GRB p5 := o5 ^ o6         ; p6 := o6          -> Red   <-> Green
; 3) RBG p5 := o5              ; p6 := o5 ^ o6     -> Green <-> Blue
; 4) GBR p5 := o5 ^ o6         ; p6 := o5          -> Red := Green, Green := Blue, Blue := Red
; 5) BRG p5 := o6              ; p6 := o5 ^ o6     -> Red := Blue , Green := Red , Blue := Green

; start out with 0000/0000, then 1010/1010, then 1010/4040, then 1010/4343, then 1012/4343, then 1012/4345
; original: 1 0 1 0
; combos  : GRB (2) xor|p6, BRG (5) p6|xor
; changes p5 for 24 after first mirror
; changes p6 for 43 after second mirror and p5 to o5 or o6 (for 4345)

; masks needed: 13, 4, 134, 3
; buffers needed: p5_xor, p6_xor, p5_org2, p6_xor2, p5_org3 (partial)
;

    STRUCTURE   FairyDust,0
        WORD    fd_Time
        ULONG   fd_PosY
        ULONG   fd_PosX
        ULONG   fd_SpeedY
        ULONG   fd_SpeedX
        LABEL   fd_SIZEOF

    STRUCTURE   HexagonPattern,0
        APTR    hp_CopListRoutine   ; to be called for every copperlist to update copperlist mirror pointers
        APTR    hp_DrawRoutine
        APTR    hp_FixupRoutine
        APTR    hp_Col2Routine
        APTR    hp_Col3Routine
        APTR    hp_Col4Routine
        APTR    hp_Pos1Routine
        APTR    hp_Pos2Routine
        STRUCT  hp_ColOffs,4*LCOL_NUM*2 ; four mirrors, first hexagon, second hexagon (plus border), third hexagon
        LABEL   hp_SIZEOF

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrPlanesPtr
        APTR    pd_LastPlanesPtr
        APTR    pd_CurrP5Xor6PlanePtr
        APTR    pd_CurrP6Xor5PlanePtr
        APTR    pd_CurrP5BonusPlanePtr
        APTR    pd_CurrP5BottomPlanePtr
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        APTR    pd_CurrTCLineColorsPtr
        APTR    pd_LastTCLineColorsPtr
        APTR    pd_CurrSpriteStencilPtr
        APTR    pd_CurrFairySprite
        UBYTE   pd_DbToggle
        ALIGNWORD

        UWORD   pd_PartCountDown
        UWORD   pd_TransitionHeight

        APTR    pd_CopperList1
        APTR    pd_CopperList2
        APTR    pd_DbBuffer

        UWORD   pd_CopperLinesFixupOffset1
        UWORD   pd_CopperLinesFixupOffset2
        UWORD   pd_CopperLinesFixupOffset3
        UWORD   pd_CopperLinesFixupOffset4
        UWORD   pd_CopperMirror1P5PtrOffset
        UWORD   pd_CopperMirror2P56PtrOffset
        UWORD   pd_CopperMirror3P5PtrOffset

        APTR    pd_OriginalPattern
        APTR    pd_StencilBuffer1
        APTR    pd_StencilBuffer2
        APTR    pd_StencilSprBuffer1
        APTR    pd_StencilSprBuffer2
        APTR    pd_TrueColorImage1
        APTR    pd_TrueColorImage2
        APTR    pd_TrueColorImage3
        APTR    pd_TCLineColors1
        APTR    pd_TCLineColors2
        APTR    pd_HexagonTopMaskPtr
        APTR    pd_HexagonBottomMaskPtr
        APTR    pd_Hexagon2MaskPtr
        APTR    pd_BonusGridPtr
        APTR    pd_P5Xor6Plane1Ptr
        APTR    pd_P5Xor6Plane2Ptr
        APTR    pd_P6Xor5Plane1Ptr
        APTR    pd_P6Xor5Plane2Ptr
        APTR    pd_P5BonusPlane1Ptr
        APTR    pd_P5BonusPlane2Ptr
        APTR    pd_P5BottomPlane1Ptr
        APTR    pd_P5BottomPlane2Ptr

        UWORD   pd_FairySpriteFrame
        UWORD   pd_PuffSpriteFrame
        UWORD   pd_SplinePos
        UWORD   pd_FairyPosX
        UWORD   pd_FairyPosY

        UWORD   pd_NextFrontDustOffset
        UWORD   pd_NextBackDustOffset

        ULONG   pd_NoiseValueA
        ULONG   pd_NoiseValueB

        APTR    pd_NoiseBuffer
        UWORD   pd_NoiseOffset
        BOOL    pd_EnableMirror1
        BOOL    pd_EnableMirror2
        BOOL    pd_EnableMirror3

        APTR    pd_BigSinCosTable

        WORD    pd_CopperlistUpdate
        UWORD   pd_PosBaseCounter
        WORD    pd_Distance1
        UWORD   pd_Angle1
        WORD    pd_Distance2

        BOOL    pd_InteractiveMode
        UBYTE   pd_OldMouseY
        UBYTE   pd_OldMouseX
        BYTE    pd_DeltaMouseY
        BYTE    pd_DeltaMouseX

        ULONG   pd_StencilOffset1
        ULONG   pd_StencilOffset2
        ULONG   pd_StencilOffset3
        ULONG   pd_StencilOffset6
        ULONG   pd_StencilOffset7
        ULONG   pd_StencilOffset8
        ULONG   pd_StencilTCOffset1
        ULONG   pd_StencilTCOffset2
        ULONG   pd_StencilTCOffset3
        ULONG   pd_StencilTCOffset6
        ULONG   pd_StencilTCOffset7
        ULONG   pd_StencilTCOffset8
        UWORD   pd_StencilShift1
        UWORD   pd_StencilShift2
        UWORD   pd_StencilShift3
        UWORD   pd_StencilShift6
        UWORD   pd_StencilShift7
        UWORD   pd_StencilShift8

        APTR    pd_FairyAnim1
        APTR    pd_FairyAnim2
        APTR    pd_FairyAnim3
        APTR    pd_FairyAnim4
        APTR    pd_FairyMask1
        APTR    pd_FairyMask2
        APTR    pd_FairyMask3
        APTR    pd_FairyMask4
        APTR    pd_PuffAnim1
        APTR    pd_PuffAnim2
        APTR    pd_PuffAnim3
        APTR    pd_PuffAnim4
        APTR    pd_PuffMask1
        APTR    pd_PuffMask2
        APTR    pd_PuffMask3
        APTR    pd_PuffMask4

        APTR    pd_SpriteCompoBuffer

        STRUCT  pd_PreparationTask,ft_SIZEOF
        STRUCT  pd_IntroPalette,8*cl_SIZEOF
        STRUCT  pd_PatternInfo,hp_SIZEOF
        STRUCT  pd_CompSprites1,8*4
        STRUCT  pd_CompSprites2,8*4
        STRUCT  pd_SpriteStencil1Ptrs,8*4
        STRUCT  pd_SpriteStencil2Ptrs,8*4
        STRUCT  pd_BQBuffer,2500
        STRUCT  pd_SMCLine1,(STENCIL_HEIGHT+2)*4
        STRUCT  pd_SMCLine2,(STENCIL_HEIGHT+2)*4
        STRUCT  pd_SMCLine3,(STENCIL_HEIGHT+2)*4
        STRUCT  pd_SMCLineUp1,(STENCIL_HEIGHT+2)*4
        STRUCT  pd_SMCLineUp2,(STENCIL_HEIGHT+2)*4
        STRUCT  pd_SMCLineUp3,(STENCIL_HEIGHT+2)*4

        STRUCT  pd_BackDust,NUM_BACK_DUST*fd_SIZEOF
        STRUCT  pd_FrontDust,NUM_FRONT_DUST*fd_SIZEOF

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        bsr.s   kds_init

        lea     kds_copperlist,a0
        CALLFW  SetCopper

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        move.l  #part_music_data,fw_MusicData(a6)
        move.l  #part_music_smp,fw_MusicSamples(a6)
        CALLFW  StartMusic
        IFD     PART_MUSIC_START_POS
        moveq.l #PART_MUSIC_START_POS,d0
        CALLFW  MusicSetPosition
        move.w  #3840,fw_MusicFrameCount(a6)
        ENDC
        ENDC
        ENDC

        IF      1
        bsr     kds_intro
        bsr     kds_transition
        bsr     kds_dissolve
        ELSE
        lea     pd_PreparationTask(a6),a1
        CALLFW  WaitUntilTaskFinished
        ENDC

        move.w  #$1fe,kds_extra_copperlist_ptr+8
        CALLFW  VSyncWithTask

        bsr     kds_pre_main
        bsr     kds_main
        bsr     kds_post_main

        CALLFW  SetBaseCopper
        rts

;--------------------------------------------------------------------

kds_init:
        bsr     kds_init_vars
        bsr     kds_init_colors
        bsr     kds_clear_sprites
        bsr     kds_init_sine_table
        bsr     kds_generate_stencils
        bsr     kds_generate_spr_stencils
        bsr     kds_generate_hexagonmasks

        lea     .backgroundtasks(pc),a0
        lea     pd_PreparationTask(a6),a1
        CALLFW  AddTask
        rts

.backgroundtasks
        bsr     kds_generate_smc_lines
        move.l  pd_OriginalPattern(a6),a0
        move.l  pd_TrueColorImage1(a6),a1
        bsr     kds_calc_true_color_image
        move.l  pd_TrueColorImage2(a6),a1
        bsr     kds_calc_true_color_image
        move.l  pd_TrueColorImage3(a6),a1
        bsr     kds_calc_true_color_image
        bsr     kds_fill_noise_buffer
        rts

;--------------------------------------------------------------------

kds_init_vars:
        lea     kds_kaleidoscope_pattern,a0
        move.l  a0,pd_OriginalPattern(a6)

        move.l  #kds_fairy_body1,pd_FairyAnim1(a6)
        move.l  #kds_fairy_body2,pd_FairyAnim2(a6)
        move.l  #kds_fairy_body3,pd_FairyAnim3(a6)
        move.l  #kds_fairy_body2,pd_FairyAnim4(a6)
        move.l  #kds_puff_sprite1,pd_PuffAnim1(a6)
        move.l  #kds_puff_sprite2,pd_PuffAnim2(a6)
        move.l  #kds_puff_sprite3,pd_PuffAnim3(a6)
        move.l  #kds_puff_sprite4,pd_PuffAnim4(a6)

        IFD     FW_DEMO_PART
        move.l  #(KDSPAT_WIDTH*KDSPAT_HEIGHT*2*2),d0
        CALLFW  AllocFast
        PUTMSG  10,<"TrueColorImage %p">,a0
        move.l  fw_GlobalUserData(a6),pd_TrueColorImage1(a6)
        move.l  a0,pd_TrueColorImage2(a6)
        add.l   #(KDSPAT_WIDTH*KDSPAT_HEIGHT)*2,a0
        move.l  a0,pd_TrueColorImage3(a6)
        ELSE
        move.l  #(KDSPAT_WIDTH*KDSPAT_THEIGHT*2),d0
        CALLFW  AllocFast
        PUTMSG  10,<"TrueColorImage %p">,a0
        move.l  a0,pd_TrueColorImage1(a6)
        add.l   #(KDSPAT_WIDTH*KDSPAT_HEIGHT)*2,a0
        move.l  a0,pd_TrueColorImage2(a6)
        add.l   #(KDSPAT_WIDTH*KDSPAT_HEIGHT)*2,a0
        move.l  a0,pd_TrueColorImage3(a6)
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

        move.l  #(KALEIDO_BUF_WIDTH/8)*KALEIDO_HEIGHT*KALEIDO_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"DbBuffer %p">,a0
        move.l  a0,pd_DbBuffer(a6)
        move.l  a0,pd_CurrPlanesPtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a1
        move.l  a1,pd_LastPlanesPtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a1

        move.l  #(KALEIDO_BUF_WIDTH/8)*KALEIDO_HEIGHT*KALEIDO_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"P5Xor6Plane1Ptr %p">,a0
        move.l  a0,pd_P5Xor6Plane1Ptr(a6)
        move.l  a0,pd_CurrP5Xor6PlanePtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0
        move.l  a0,pd_P5Xor6Plane2Ptr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0

        move.l  a0,pd_P6Xor5Plane1Ptr(a6)
        move.l  a0,pd_CurrP6Xor5PlanePtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0
        move.l  a0,pd_P6Xor5Plane2Ptr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0

        move.l  a0,pd_P5BonusPlane1Ptr(a6)
        move.l  a0,pd_CurrP5BonusPlanePtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0
        move.l  a0,pd_P5BonusPlane2Ptr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0

        move.l  a0,pd_P5BottomPlane1Ptr(a6)
        move.l  a0,pd_CurrP5BottomPlanePtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0
        move.l  a0,pd_P5BottomPlane2Ptr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0

        move.l  a0,pd_Hexagon2MaskPtr(a6)
        lea     (STENCIL_WIDTH/2)/8(a0),a1
        move.l  a1,pd_HexagonTopMaskPtr(a6)
        lea     1*KALEIDO_WIDTH/8(a0),a0
        move.l  a0,pd_HexagonBottomMaskPtr(a6)
        lea     (3*STENCIL_WIDTH)/8(a0),a1
        move.l  a1,pd_BonusGridPtr(a6)

        move.l  #((STENCIL_WIDTH/8)*STENCIL_HEIGHT*KALEIDO_PLANES)*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"Stencil %p">,a0
        move.l  a0,pd_StencilBuffer1(a6)
        lea     ((STENCIL_WIDTH/8)*STENCIL_HEIGHT*KALEIDO_PLANES)(a0),a0
        move.l  a0,pd_StencilBuffer2(a6)

        move.l  #((STENCIL_WIDTH/8)*STENCIL_HEIGHT)*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"Stencil Spr %p">,a0
        move.l  a0,pd_StencilSprBuffer1(a6)
        lea     ((STENCIL_WIDTH/8)*STENCIL_HEIGHT)(a0),a0
        move.l  a0,pd_StencilSprBuffer2(a6)

        move.l  #4*LCOL_NUM*LCOLBUF_HEIGHT*2*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"TCLineColors %p">,a0
        move.l  a0,pd_TCLineColors1(a6)
        move.l  a0,pd_CurrTCLineColorsPtr(a6)
        lea     4*LCOL_NUM*LCOLBUF_HEIGHT*2(a0),a0
        move.l  a0,pd_TCLineColors2(a6)
        move.l  a0,pd_LastTCLineColorsPtr(a6)

        move.l  #SPRITES_BUFFER_SIZE*2,d0
        CALLFW  AllocChip
        PUTMSG  10,<"SpriteStencilPtrs %p">,a0
        move.l  a0,d0
        lea     pd_SpriteStencil1Ptrs(a6),a1
        move.l  a1,pd_CurrSpriteStencilPtr(a6)
        REPT    (INTRO_SPRITE_WIDTH/16)
        move.l  a0,(a1)+
        lea     ((INTRO_SPRITE_HEIGHT+2)*2*2)(a0),a0
        ENDR
        REPT    (INTRO_SPRITE_WIDTH/16)
        move.l  a0,(a1)+
        lea     ((INTRO_SPRITE_HEIGHT+2)*2*2)(a0),a0
        ENDR

        move.l  d0,a0
        lea     pd_CompSprites1(a6),a1
        REPT    (FAIRY_WIDTH/16)*2
        move.l  a0,(a1)+
        lea     ((FAIRY_HEIGHT+2)*2*2)(a0),a0
        ENDR
        REPT    (FAIRY_WIDTH/16)*2
        move.l  a0,(a1)+
        lea     ((FAIRY_HEIGHT+2)*2*2)(a0),a0
        ENDR

        move.l  #(NOISE_WIDTH/8)*NOISE_HEIGHT,d0
        CALLFW  AllocChip
        PUTMSG  10,<"NoiseBuffer %p">,a0
        move.l  a0,pd_NoiseBuffer(a6)

        move.l  #2048*4,d0
        CALLFW  AllocFast
        move.l  a0,pd_BigSinCosTable(a6)

        move.l  #(BODY_WIDTH/8)*BODY_HEIGHT*BODY_PLANES*NUM_BODY_FRAMES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"FairyMasks %p">,a0
        move.l  a0,pd_FairyMask1(a6)
        lea     (BODY_WIDTH/8)*BODY_HEIGHT*BODY_PLANES(a0),a0
        move.l  a0,pd_FairyMask2(a6)
        move.l  a0,pd_FairyMask4(a6)
        lea     (BODY_WIDTH/8)*BODY_HEIGHT*BODY_PLANES(a0),a0
        move.l  a0,pd_FairyMask3(a6)

        move.l  #(PUFF_WIDTH/8)*PUFF_HEIGHT*PUFF_PLANES*NUM_PUFF_FRAMES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"PuffMasks %p">,a0
        move.l  a0,pd_PuffMask1(a6)
        lea     (PUFF_WIDTH/8)*PUFF_HEIGHT*PUFF_PLANES(a0),a0
        move.l  a0,pd_PuffMask2(a6)
        lea     (PUFF_WIDTH/8)*PUFF_HEIGHT*PUFF_PLANES(a0),a0
        move.l  a0,pd_PuffMask3(a6)
        lea     (PUFF_WIDTH/8)*PUFF_HEIGHT*PUFF_PLANES(a0),a0
        move.l  a0,pd_PuffMask4(a6)

        move.l  #(FAIRY_WIDTH/8)*FAIRY_HEIGHT*FAIRY_PLANES,d0
        CALLFW  AllocChip
        PUTMSG  10,<"SpriteCompoBuffer %p">,a0
        move.l  a0,pd_SpriteCompoBuffer(a6)

        lea     kds_setting_1(pc),a0
        bsr     kds_load_setting

        move.l  #$3eb2427c,pd_NoiseValueA(a6)
        move.l  #$a7f9d461,pd_NoiseValueB(a6)

        move.l  fw_SinTable(a6),a2
        move.l  fw_CosTable(a6),a3
        moveq.l #0,d2
        move.w  #256,d3
        move.w  #-420+96,d4
        lea     pd_FrontDust(a6),a1
        moveq.l #NUM_FRONT_DUST-1,d7
.dloop  move.w  (a2,d2.w),d0
        move.w  (a3,d2.w),d1
        add.w   #123*2,d2
        and.w   #1023*2,d2
        muls    d3,d0
        muls    d3,d1

        asr.l   #7,d0
        asr.l   #7,d1
        move.l  d0,fd_SpeedY(a1)
        move.l  d1,fd_SpeedX(a1)
        addq.w  #8,d3

        move.w  d4,fd_Time(a1)
        addq.w  #2,d4
        lea     fd_SIZEOF(a1),a1
        dbra    d7,.dloop

        rts

;--------------------------------------------------------------------

kds_init_sine_table:
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

kds_init_colors:
        lea     kds_fairy_sprite_palette(pc),a0
        lea     color+16*2(a5),a1
        moveq.l #16-1,d7
.sprpalloop
        move.w  (a0)+,(a1)+
        dbra    d7,.sprpalloop
        rts

;--------------------------------------------------------------------

kds_fill_noise_buffer:
        move.l  pd_NoiseBuffer(a6),a0
        move.l  pd_NoiseValueA(a6),d0
        move.l  pd_NoiseValueB(a6),d1
        move.w  #((NOISE_WIDTH/16)*NOISE_HEIGHT)-1,d7
        moveq.l #0,d4
.rloop
        moveq.l #16-1,d6
.wloop
        move.l  d1,d2
        swap    d2
        add.l   d0,d1
        add.l   d2,d0
        add.w   d3,d3
        lsr.w   #1,d2
        cmp.w   d4,d2
        bhi.s   .noadd1
        addq.w  #1,d3
.noadd1 dbra    d6,.wloop
        move.w  d3,(a0)+
        addq.w  #4,d4
        dbra    d7,.rloop
        move.l  d0,pd_NoiseValueA(a6)
        move.l  d1,pd_NoiseValueB(a6)

        rts

;--------------------------------------------------------------------

kds_intro:
        PUTMSG  10,<"%d: Intro part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #420,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueSingleFrame

        bsr     kds_prepare_intro_buffers
        bsr     kds_prepare_sprite_masks

        moveq.l #8,d0
        move.w  #$fff,d1
        lea     pd_IntroPalette(a6),a1
        CALLFW  InitPaletteLerpSameColor

        moveq.l #8,d0
        moveq.l #32,d1
        lea     kds_intro_palette(pc),a0
        lea     pd_IntroPalette(a6),a1
        CALLFW  FadePaletteTo

        bsr     kds_flip_db_frame
        bsr     kds_create_intro_copperlist

        bsr     kds_flip_db_frame
        bsr     kds_create_intro_copperlist

.waitloop
        CALLFW  VSyncWithTask
        cmp.w   #4032,fw_MusicFrameCount(a6)
        blt.s   .waitloop

        PUTMSG  10,<"%d: Intro part launching (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

.loop
        bsr     kds_flip_db_frame

        lea     pd_BQBuffer(a6),a4
        bsr     kds_draw_stencils_intro

        bsr     kds_clear_compobuffer

        bsr     kds_draw_dust

        bsr     kds_draw_fairy_body

        bsr     kds_draw_wand_heat

        bsr     kds_convert_compobuffer_to_sprites
        bsr     kds_calc_stencil_positions1_slow

        moveq.l #8,d0
        lea     pd_IntroPalette(a6),a1
        CALLFW  DoFadePaletteStep

        bsr     kds_calc_spline_pos
        bsr     kds_update_fairy_sprite
        bsr     kds_update_sprites_and_cols_in_copperlist

        CALLFW  JoinBlitterQueue

        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask

        subq.w  #1,pd_PartCountDown(a6)
        bne.s   .loop

        rts

;--------------------------------------------------------------------

kds_transition:
        PUTMSG  10,<"%d: Transition part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        move.w  #260,pd_PartCountDown(a6)
        CALLFW  SetBlitterQueueSingleFrame

        move.w  pd_FairyPosX(a6),d3
        move.w  pd_FairyPosY(a6),d4
        add.w   #45,d3
        add.w   #27,d4
        move.l  pd_NoiseValueA(a6),d0
        move.l  pd_NoiseValueB(a6),d1
        lea     pd_FrontDust(a6),a1
        moveq.l #32,d5
        moveq.l #NUM_FRONT_DUST-1,d7
.dloop
        move.w  d3,fd_PosX(a1)
        move.w  d4,fd_PosY(a1)

        move.l  d1,d2
        swap    d2
        add.l   d0,d1
        add.l   d2,d0
        moveq.l #15,d2
        and.w   d0,d2
        add.w   d5,d2
        move.w  d2,fd_Time(a1)

        lea     fd_SIZEOF(a1),a1
        dbra    d7,.dloop

        move.l  d0,pd_NoiseValueA(a6)
        move.l  d1,pd_NoiseValueB(a6)

.loop
        bsr     kds_flip_db_frame

        lea     pd_BQBuffer(a6),a4
        bsr     kds_draw_stencils_intro
        bsr     kds_draw_stencils_transition
        bsr     kds_clear_compobuffer

        bsr     kds_draw_dust
        bsr     kds_draw_fairy_body
        bsr     kds_draw_wand_blast

        bsr     kds_draw_puff
        bsr     kds_convert_compobuffer_to_sprites

        bsr     kds_calc_spline_pos
        bsr     kds_update_fairy_sprite
        bsr     kds_create_transition_copperlist

        bsr     kds_calc_stencil_fixup_lines_transition

        bsr     kds_calc_stencil_positions1_slow

        move.w  pd_TransitionHeight(a6),d0
        cmp.w   #STENCIL_HEIGHT*2-1,d0
        bge.s   .skipth
        addq.w  #1,d0
        move.w  d0,pd_TransitionHeight(a6)
.skipth

        CALLFW  JoinBlitterQueue

        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask

        subq.w  #1,pd_PartCountDown(a6)
        bne.s   .loop

        rts

;--------------------------------------------------------------------

kds_dissolve:
        PUTMSG  10,<"%d: Dissolve part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        CALLFW  SetBlitterQueueSingleFrame

        bsr     kds_clear_noise_sprite_buffer
        move.w  kds_intro_palette(pc),d0
        move.w  d0,color+17*2(a5)
        move.w  d0,color+21*2(a5)
        move.w  d0,color+25*2(a5)
        move.w  d0,color+29*2(a5)

.loop
        bsr     kds_flip_db_frame
        move.l  pd_CurrSpriteStencilPtr(a6),pd_CurrFairySprite(a6)

        TERMINATE_BLITTER_QUEUE
        lea     pd_BQBuffer(a6),a4
        bsr     kds_draw_stencils_intro
        bsr     kds_draw_stencils_transition
        bsr     kds_calc_stencil_fixup_lines_transition

        bsr     kds_calc_stencil_positions1_slow

        add.w   #110,pd_NoiseOffset(a6)
        moveq.l #INTRO_SPRITE_SHEIGHT,d0
        bsr     kds_convert_noise_to_sprites
        bsr     kds_update_stencil_sprite

        ;BLTHOGON
        ;BLTWAIT
        ;lea     pd_BQBuffer(a6),a0
        ;CALLFW  TriggerCustomBlitterQueue

        CALLFW  JoinBlitterQueue

        bsr     kds_update_sprites_in_copperlist
        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask

        cmp.w   #((NOISE_WIDTH/8)*(1024)),pd_NoiseOffset(a6)
        blt.s   .loop

        rts

;--------------------------------------------------------------------

kds_pre_main:
        PUTMSG  10,<"%d: Pre Main part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        CALLFW  SetBlitterQueueMultiFrame

        move.w  joy0dat(a5),pd_OldMouseY(a6)

        move.w  #(NOISE_WIDTH/8)*(NOISE_HEIGHT-KALEIDO_VHEIGHT),pd_NoiseOffset(a6)

        bsr     kds_prepare_buffers

        bsr     .prepare
        bsr     .prepare

        bsr     kds_calc_stencil_positions1_std
        bsr     kds_calc_stencil_positions2_std

.loop
        bsr     kds_flip_db_frame
        move.l  pd_CurrSpriteStencilPtr(a6),pd_CurrFairySprite(a6)

        lea     pd_BQBuffer(a6),a4

        bsr     kds_draw_stencils_col0000
        bsr     kds_draw_stencils_copy_edges
        bsr     kds_calc_stencil_fixup_lines_pre_main
        bsr     kds_calc_stencil_positions1_std
        bsr     kds_calc_stencil_positions2_std

        sub.w   #210,pd_NoiseOffset(a6)
        bmi.s   .exit
        move.w  #INTRO_SPRITE_HEIGHT,d0
        bsr     kds_convert_noise_to_sprites
        bsr     kds_update_stencil_pre_main_sprite

        CALLFW  JoinBlitterQueue

        bsr     kds_update_sprites_in_copperlist
        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask
        bra.s   .loop

.exit
        bsr     kds_kill_stencil_sprite

        CALLFW  JoinBlitterQueue

        bsr     kds_update_sprites_in_copperlist
        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask

        bsr.s   .restore

.restore
        bsr     kds_flip_db_frame
        bsr     kds_create_kaleidoscope_copperlist

        move.w  #DMAF_SPRITE,dmacon(a5)
        moveq.l #0,d0
        move.w  d0,spr+0*8+sd_dataa(a5)
        move.w  d0,spr+1*8+sd_dataa(a5)
        move.w  d0,spr+2*8+sd_dataa(a5)
        move.w  d0,spr+3*8+sd_dataa(a5)
        move.w  d0,spr+4*8+sd_dataa(a5)
        move.w  d0,spr+5*8+sd_dataa(a5)
        move.w  d0,spr+6*8+sd_dataa(a5)
        move.w  d0,spr+7*8+sd_dataa(a5)

        lea     pd_BQBuffer(a6),a4

        bsr     kds_draw_stencils_col0000
        bsr     kds_draw_stencils_copy_edges
        bsr     kds_calc_stencil_fixup_lines_generic
        bsr     kds_calc_stencil_positions1_std
        bsr     kds_calc_stencil_positions2_std

        CALLFW  JoinBlitterQueue

        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask
        rts

.prepare
        bsr     kds_flip_db_frame
        move.l  pd_CurrSpriteStencilPtr(a6),pd_CurrFairySprite(a6)

        TERMINATE_BLITTER_QUEUE
        lea     pd_BQBuffer(a6),a4
        bsr     kds_create_pre_main_copperlist
        move.w  #INTRO_SPRITE_HEIGHT,d0
        bsr     kds_convert_noise_to_sprites
        bsr     kds_update_stencil_pre_main_sprite

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        CALLFW  TriggerBlitterQueue

        CALLFW  JoinBlitterQueue

        bsr     kds_update_copper_list_pointers
        CALLFW  VSyncWithTask

        rts

;--------------------------------------------------------------------

kds_post_main:
        PUTMSG  10,<"%d: Post Main part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        bsr     .prepare
        bsr     .prepare

        PUTMSG  10,<"%d: Prep done">,fw_FrameCounterLong(a6)
.loop
        bsr     kds_flip_db_frame
        move.l  pd_CurrSpriteStencilPtr(a6),pd_CurrFairySprite(a6)

        lea     pd_BQBuffer(a6),a4

        bsr     kds_draw_stencils_col0000
        bsr     kds_draw_stencils_copy_edges
        bsr     kds_calc_stencil_fixup_lines_pre_main
        bsr     kds_calc_stencil_positions1_std
        bsr     kds_calc_stencil_positions2_std

        add.w   #164,pd_NoiseOffset(a6)
        cmp.w   #(NOISE_WIDTH/8)*(NOISE_HEIGHT-KALEIDO_VHEIGHT),pd_NoiseOffset(a6)
        bge.s   .exit
        move.w  #INTRO_SPRITE_HEIGHT,d0
        bsr     kds_convert_noise_to_sprites
        bsr     kds_update_stencil_pre_main_sprite

        CALLFW  JoinBlitterQueue

        bsr     kds_update_sprites_in_copperlist
        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask
        bra.s   .loop

.exit
        CALLFW  JoinBlitterQueue

        clr.l   fw_VBlankIRQ(a6)

        bsr     kds_update_sprites_in_copperlist
        bsr     kds_update_copper_list_pointers
        CALLFW  VSyncWithTask

        PUTMSG  10,<"%d: Post Main finished (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)

        rts

.prepare
        bsr     kds_flip_db_frame
        move.l  pd_CurrSpriteStencilPtr(a6),pd_CurrFairySprite(a6)

        TERMINATE_BLITTER_QUEUE
        lea     pd_BQBuffer(a6),a4
        bsr     kds_create_pre_main_copperlist

        bsr     kds_draw_stencils_col0000
        bsr     kds_draw_stencils_copy_edges
        bsr     kds_calc_stencil_fixup_lines_pre_main
        bsr     kds_calc_stencil_positions1_std
        bsr     kds_calc_stencil_positions2_std
        bsr     kds_clear_bonus_stuff_for_col2

        CALLFW  JoinBlitterQueue

        bsr     kds_update_copper_list_pointers
        CALLFW  VSyncWithTask

        rts

;--------------------------------------------------------------------

kds_main:
        PUTMSG  10,<"%d: Main part started (%d music frames)">,fw_FrameCounterLong(a6),fw_MusicFrameCount-2(a6)
        CALLFW  SetBlitterQueueMultiFrame

        IF      0
        bsr     kds_prepare_buffers

        bsr     kds_flip_db_frame
        bsr     kds_create_kaleidoscope_copperlist
        bsr     kds_flip_db_frame
        bsr     kds_create_kaleidoscope_copperlist

        move.l  pd_PatternInfo+hp_Pos1Routine(a6),a0
        jsr     (a0)
        move.l  pd_PatternInfo+hp_Pos2Routine(a6),a0
        jsr     (a0)
        ENDC

        lea     .script(pc),a0
        CALLFW  InstallMusicScript

        lea     .vblstuff(pc),a0
        move.l  a0,fw_VBlankIRQ(a6)
.loop
        bsr     kds_flip_db_frame

        CALLFW  CheckMusicScript

        lea     pd_BQBuffer(a6),a4

        move.l  pd_PatternInfo+hp_DrawRoutine(a6),a0
        jsr     (a0)

        move.l  pd_PatternInfo+hp_FixupRoutine(a6),a0
        jsr     (a0)

        move.l  pd_PatternInfo+hp_Pos1Routine(a6),a0
        jsr     (a0)
        move.l  pd_PatternInfo+hp_Pos2Routine(a6),a0
        jsr     (a0)
        subq.w  #1,pd_CopperlistUpdate(a6)
        bmi.s   .nocoplistupdate
        move.l  pd_PatternInfo+hp_CopListRoutine(a6),a0
        jsr     (a0)
.nocoplistupdate
        ;lea     pd_BQBuffer(a6),a0
        ;sub.l   a0,a4
        ;PUTMSG  10,<"Queue size %ld">,a4

        CALLFW  JoinBlitterQueue

        bsr     kds_update_copper_list_pointers

        CALLFW  VSyncWithTask

        cmp.w   #6336,fw_MusicFrameCount(a6)
        blt.s   .loop

        bsr     .flash
        rts

.vblstuff
        PUSHM   d4
        moveq.l #1,d0
        lea     pd_IntroPalette(a6),a1
        CALLFW  DoFadePaletteStep
        move.w  pd_IntroPalette+cl_Color(a6),color(a5)
        POPM
        rts

.script
        dc.w    4800+192+24+0*48,.load_setting2-*
        dc.w    4800+192+24+1*48,.load_setting3-*
        dc.w    4800+192+24+2*48,.load_setting4-*
        dc.w    4800+192+24+3*48,.load_setting5-*
        dc.w    4800+192+24+4*48,.load_setting6-*

        dc.w    5184+28*6,.jump-*
        dc.w    5184+29*6,.jump-*
        dc.w    5184+30*6,.jump-*
        dc.w    5184+31*6,.jump-*

        dc.w    5568+28*6,.jump-*
        dc.w    5568+29*6,.jump-*
        dc.w    5568+30*6,.jump-*
        dc.w    5568+31*6,.jump-*

        dc.w    5952+28*6,.jump-*
        dc.w    5952+29*6,.jump-*
        dc.w    5952+30*6,.jump-*
        dc.w    5952+31*6,.jump-*

        dc.w    5952+192+24+0*48,.load_setting4-*
        dc.w    5952+192+24+1*48,.load_setting3-*
        dc.w    5952+192+24+2*48,.load_setting2-*
        dc.w    5952+192+24+3*48,.load_setting1-*
        dc.w    0

.jump   add.w   #58,pd_Angle1(a6)
        add.w   #550,pd_PosBaseCounter(a6)
        rts

.flash
        moveq.l #1,d0
        move.w  #$fff,d1
        lea     pd_IntroPalette(a6),a1
        CALLFW  InitPaletteLerpSameColor

        moveq.l #1,d0
        moveq.l #16,d1
        lea     kds_intro_palette(pc),a0
        lea     pd_IntroPalette(a6),a1
        CALLFW  FadePaletteTo
        rts

.load_setting1
        bsr     .flash
        lea     kds_setting_1(pc),a0
        bra     kds_load_setting

.load_setting2
        bsr     .flash
        lea     kds_setting_2(pc),a0
        bra     kds_load_setting

.load_setting3
        bsr     .flash
        lea     kds_setting_3(pc),a0
        bra     kds_load_setting

.load_setting4
        bsr     .flash
        lea     kds_setting_4(pc),a0
        bra     kds_load_setting

.load_setting5
        bsr     .flash
        lea     kds_setting_5(pc),a0
        bra     kds_load_setting

.load_setting6
        bsr     .flash
        lea     kds_setting_6(pc),a0
        bra     kds_load_setting


;--------------------------------------------------------------------

kds_flip_db_frame:
        move.l  pd_CurrPlanesPtr(a6),pd_LastPlanesPtr(a6)
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        move.l  pd_CurrTCLineColorsPtr(a6),pd_LastTCLineColorsPtr(a6)

        move.l  pd_DbBuffer(a6),a0
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        lea     (KALEIDO_WIDTH/8)(a0),a0
        move.l  a0,pd_CurrPlanesPtr(a6)
        move.l  pd_P5Xor6Plane2Ptr(a6),pd_CurrP5Xor6PlanePtr(a6)
        move.l  pd_P6Xor5Plane2Ptr(a6),pd_CurrP6Xor5PlanePtr(a6)
        move.l  pd_P5BonusPlane2Ptr(a6),pd_CurrP5BonusPlanePtr(a6)
        move.l  pd_P5BottomPlane2Ptr(a6),pd_CurrP5BottomPlanePtr(a6)
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        move.l  pd_TCLineColors2(a6),pd_CurrTCLineColorsPtr(a6)
        lea     pd_SpriteStencil2Ptrs(a6),a0
        move.l  a0,pd_CurrSpriteStencilPtr(a6)
        lea     pd_CompSprites2(a6),a0
        move.l  a0,pd_CurrFairySprite(a6)
        rts
.selb1
        move.l  a0,pd_CurrPlanesPtr(a6)
        move.l  pd_P5Xor6Plane1Ptr(a6),pd_CurrP5Xor6PlanePtr(a6)
        move.l  pd_P6Xor5Plane1Ptr(a6),pd_CurrP6Xor5PlanePtr(a6)
        move.l  pd_P5BonusPlane1Ptr(a6),pd_CurrP5BonusPlanePtr(a6)
        move.l  pd_P5BottomPlane1Ptr(a6),pd_CurrP5BottomPlanePtr(a6)
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        move.l  pd_TCLineColors1(a6),pd_CurrTCLineColorsPtr(a6)
        lea     pd_SpriteStencil1Ptrs(a6),a0
        move.l  a0,pd_CurrSpriteStencilPtr(a6)
        lea     pd_CompSprites1(a6),a0
        move.l  a0,pd_CurrFairySprite(a6)
        rts

;--------------------------------------------------------------------

kds_update_copper_list_pointers:
        lea     kds_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

kds_load_setting:
        lea     pd_PatternInfo(a6),a1
        moveq.l #(hp_SIZEOF/4)-1,d7
.scloop move.l  (a0)+,(a1)+
        dbra    d7,.scloop
        move.w  #2,pd_CopperlistUpdate(a6)

        rts

;--------------------------------------------------------------------

kds_generate_smc_lines:
        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        lea     pd_SMCLine1(a6),a0
        move.w  #KDSPAT_WIDTH*2,d4
        PUSHM   d0-d3
        bsr     kds_bresenham_smc_line_draw
        POPM
        lea     pd_SMCLineUp1(a6),a0
        neg.w   d4
        bsr     kds_bresenham_smc_line_draw

        moveq.l #STENCIL_WIDTH-1,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2),d2
        moveq.l #STENCIL_HEIGHT-1,d3
        lea     pd_SMCLine2(a6),a0
        neg.w   d4
        PUSHM   d0-d3
        bsr     kds_bresenham_smc_line_draw
        POPM
        lea     pd_SMCLineUp2(a6),a0
        neg.w   d4
        bsr     kds_bresenham_smc_line_draw

        moveq.l #(STENCIL_WIDTH/2),d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2),d2
        moveq.l #STENCIL_HEIGHT-1,d3
        lea     pd_SMCLine3(a6),a0
        neg.w   d4
        PUSHM   d0-d3
        bsr     kds_bresenham_smc_line_draw
        POPM
        lea     pd_SMCLineUp3(a6),a0
        neg.w   d4
        bsr     kds_bresenham_smc_line_draw

        CALLFW  FlushCaches
        rts

;--------------------------------------------------------------------

kds_clear_sprites:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_SpriteStencil1Ptrs(a6),bltdpt(a5)
        move.w  #((INTRO_SPRITE_WIDTH)>>4)|(((INTRO_SPRITE_HEIGHT+2)*2*2)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

kds_generate_stencils:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_StencilBuffer1(a6),bltdpt(a5)
        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES*2)<<6),bltsize(a5)

        moveq.l #(STENCIL_WIDTH/8)*KALEIDO_PLANES,d4
        bsr     kds_blitter_line_init

        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilBuffer1(a6),a0
        bsr     kds_draw_blitter_singledot_line

        moveq.l #(STENCIL_WIDTH/8)*KALEIDO_PLANES,d4
        moveq.l #STENCIL_WIDTH-2,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilBuffer1(a6),a0
        bsr     kds_draw_blitter_singledot_line

        moveq.l #(STENCIL_WIDTH/8)*KALEIDO_PLANES,d4
        moveq.l #(STENCIL_WIDTH/2)-1,d0
        moveq.l #0,d1
        moveq.l #0,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilBuffer2(a6),a0
        bsr     kds_draw_blitter_singledot_line

        moveq.l #(STENCIL_WIDTH/8)*KALEIDO_PLANES,d4
        moveq.l #(STENCIL_WIDTH/2)-1,d0
        moveq.l #0,d1
        moveq.l #STENCIL_WIDTH-2,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilBuffer2(a6),a0
        bsr     kds_draw_blitter_singledot_line

        move.l  pd_StencilBuffer1(a6),a0
        lea     (STENCIL_WIDTH/8)*(STENCIL_HEIGHT*2-1)*KALEIDO_PLANES+(STENCIL_WIDTH/8)-2(a0),a0
        moveq.l #(STENCIL_WIDTH/8)*(KALEIDO_PLANES-1),d0
        moveq.l #-1,d2
        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT*2)<<6),d3
        BLTWAIT
        BLTCON_SET_X AD,BLT_A,0,0,BLTCON1F_EFE|BLTCON1F_DESC
        move.l  d2,bltafwm(a5)      ; also fills bltalwm
        move.w  d0,bltamod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a0,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        move.l  pd_StencilBuffer1(a6),a0
        lea     (STENCIL_WIDTH/8)(a0),a1
        BLTWAIT
        BLTCON_SET AD,BLT_A,0,0
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        REPT    KALEIDO_PLANES-2
        lea     (STENCIL_WIDTH/8)(a1),a1
        BLTWAIT
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)
        ENDR
        rts

;--------------------------------------------------------------------

kds_generate_spr_stencils:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_StencilSprBuffer1(a6),bltdpt(a5)
        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT*2)<<6),bltsize(a5)

        moveq.l #(STENCIL_WIDTH/8),d4
        bsr     kds_blitter_line_init

        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilSprBuffer1(a6),a0
        bsr     kds_draw_blitter_singledot_line

        moveq.l #(STENCIL_WIDTH/8),d4
        moveq.l #STENCIL_WIDTH-2,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilSprBuffer1(a6),a0
        bsr     kds_draw_blitter_singledot_line

        moveq.l #(STENCIL_WIDTH/8),d4
        moveq.l #(STENCIL_WIDTH/2)-1,d0
        moveq.l #0,d1
        moveq.l #0,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilSprBuffer2(a6),a0
        bsr     kds_draw_blitter_singledot_line

        moveq.l #(STENCIL_WIDTH/8),d4
        moveq.l #(STENCIL_WIDTH/2)-1,d0
        moveq.l #0,d1
        moveq.l #STENCIL_WIDTH-2,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_StencilSprBuffer2(a6),a0
        bsr     kds_draw_blitter_singledot_line

        move.l  pd_StencilSprBuffer1(a6),a0
        lea     (STENCIL_WIDTH/8)*(STENCIL_HEIGHT*2-1)+(STENCIL_WIDTH/8)-2(a0),a0
        moveq.l #0,d0
        moveq.l #-1,d2
        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT*2)<<6),d3
        BLTWAIT
        BLTCON_SET_X AD,BLT_A,0,0,BLTCON1F_IFE|BLTCON1F_DESC
        move.l  d2,bltafwm(a5)      ; also fills bltalwm
        move.l  d0,bltamod(a5)      ; and bltdmod
        move.l  a0,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        BLTWAIT
        move.l  pd_StencilSprBuffer1(a6),a0
        bset    d0,(STENCIL_WIDTH/8)*(STENCIL_HEIGHT-1)+((STENCIL_WIDTH/2)/8)-1(a0)
        rts

;--------------------------------------------------------------------

kds_generate_hexagonmasks:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_P5Xor6Plane1Ptr(a6),bltdpt(a5)
        move.w  #((KALEIDO_BUF_WIDTH)>>4)|((KALEIDO_HEIGHT*KALEIDO_PLANES)<<6),bltsize(a5)

        moveq.l #-1,d2
        move.w  #((KALEIDO_BUF_WIDTH*KALEIDO_PLANES-STENCIL_WIDTH)/8),d0
        move.w  #((STENCIL_WIDTH*KALEIDO_PLANES-STENCIL_WIDTH)/8),d1
        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT)<<6),d3

        move.l  pd_StencilBuffer1(a6),a1
        move.l  pd_StencilBuffer2(a6),a2
        move.l  pd_HexagonTopMaskPtr(a6),a0
        BLTWAIT
        BLTCON_SET ACD,BLT_A|BLT_C,0,0
        move.l  d2,bltafwm(a5)      ; also fills bltalwm
        move.w  d1,bltamod(a5)
        move.w  d0,bltcmod(a5)
        move.w  d0,bltdmod(a5)
        move.l  a2,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        addq.l  #(STENCIL_WIDTH/2)/8,a0

        BLTWAIT
        move.l  a1,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        addq.l  #(STENCIL_WIDTH/2)/8,a0

        BLTWAIT
        move.l  a2,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        ; bottom
        move.l  pd_HexagonBottomMaskPtr(a6),a0

        BLTWAIT
        move.l  a1,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        addq.l  #(STENCIL_WIDTH/2)/8,a0

        BLTWAIT
        move.l  a2,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        addq.l  #(STENCIL_WIDTH/2)/8,a0

        BLTWAIT
        BLTHOGOFF
        move.l  a1,bltapt(a5)
        move.l  a0,bltcpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        rts

;--------------------------------------------------------------------

kds_clear_compobuffer:
        ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_clear,(a4)+

        rts
.bq_clear
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_SpriteCompoBuffer(a6),bltdpt(a5)
        move.w  #(FAIRY_WIDTH>>4)|((FAIRY_HEIGHT*FAIRY_PLANES)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

kds_draw_fairy_body:
        move.w  pd_FairySpriteFrame(a6),d0
        addq.w  #1*4,d0
        and.w   #3*(1*4),d0
        move.w  d0,pd_FairySpriteFrame(a6)
        lea     pd_FairyAnim1(a6),a0
        move.l  (a0,d0.w),a1
        move.l  pd_FairyMask1-pd_FairyAnim1(a0,d0.w),a2

        move.l  pd_SpriteCompoBuffer(a6),a0
        lea     (BODY_XOFFSET/8)+BODY_YOFFSET*(FAIRY_WIDTH/8)*FAIRY_PLANES(a0),a0
        ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_copy_body,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        rts

.bq_copy_body
        BLTCON_SET ABCD,(BLT_A&BLT_B)|(~BLT_A&BLT_C),0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #(FAIRY_WIDTH-BODY_WIDTH)/8,d0
        move.w  d0,bltcmod(a5)
        move.w  d0,bltdmod(a5)
        moveq.l #0,d0
        move.l  d0,bltbmod(a5)      ; and bltamod
        move.l  (a0)+,bltbpt(a5)
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,d0
        move.l  d0,bltcpt(a5)
        move.l  d0,bltdpt(a5)
        move.w  #(BODY_WIDTH>>4)|((BODY_HEIGHT*BODY_PLANES)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

kds_draw_puff:
        move.w  pd_PuffSpriteFrame(a6),d0
        addq.w  #1,d0
        move.w  d0,pd_PuffSpriteFrame(a6)
        cmp.w   #NUM_PUFF_FRAMES*4,d0
        blt.s   .cont
        rts
.cont
        and.w   #(NUM_PUFF_FRAMES-1)*4,d0
        PUTMSG  10,<"Puff %d">,d0
        lea     pd_PuffAnim1(a6),a0
        move.l  (a0,d0.w),a1
        move.l  pd_PuffMask1-pd_PuffAnim1(a0,d0.w),a2

        move.l  pd_SpriteCompoBuffer(a6),a0
        lea     (PUFF_XOFFSET/8)+PUFF_YOFFSET*(FAIRY_WIDTH/8)*FAIRY_PLANES(a0),a0
        ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_copy_body,(a4)+
        move.l  a1,(a4)+
        move.l  a2,(a4)+
        move.l  a0,(a4)+
        rts

.bq_copy_body
        BLTCON_SET ABCD,(BLT_A&BLT_B)|(~BLT_A&BLT_C),0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        moveq.l #(FAIRY_WIDTH-PUFF_WIDTH)/8,d0
        move.w  d0,bltcmod(a5)
        move.w  d0,bltdmod(a5)
        moveq.l #0,d0
        move.l  d0,bltbmod(a5)      ; and bltamod
        move.l  (a0)+,bltbpt(a5)
        move.l  (a0)+,bltapt(a5)
        move.l  (a0)+,d0
        move.l  d0,bltcpt(a5)
        move.l  d0,bltdpt(a5)
        move.w  #(PUFF_WIDTH>>4)|((PUFF_HEIGHT*PUFF_PLANES)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

kds_draw_dust:
        lea     pd_BackDust(a6),a0
        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_draw,(a4)+
        move.l  a0,(a4)+
        move.w  #NUM_BACK_DUST,(a4)+
        rts

.bq_draw
        PUSHM   a2/d1-d7
        move.l  (a0)+,a1
        move.w  (a0)+,d7
        move.l  pd_SpriteCompoBuffer(a6),a0
        move.w  pd_FairyPosY(a6),d4
        move.w  pd_FairyPosX(a6),d5
        move.w  #FAIRY_WIDTH,d6 ; or height
        lea     kds_dust_twinkle(pc),a2
        subq.w  #1,d7
.loop
        subq.w  #1,fd_Time(a1)
        bmi.s   .skip
        movem.l fd_PosY(a1),d0-d3
        add.l   #3000,d2
        add.l   d2,d0
        add.l   d3,d1
        movem.l d0-d2,fd_PosY(a1)
        swap    d0
        swap    d1
        sub.w   d4,d0
        sub.w   d5,d1
        PUTMSG  40,<"Pos %d,%d">,d1,d0
        cmp.w   d6,d1
        bhs.s   .skip
        cmp.w   d6,d0
        bhs.s   .skip
        move.w  d1,d2
        move.b  d0,-(sp)
        move.w  (sp)+,d0
        move.b  d1,d0
        lsr.w   #3,d0
        not.w   d2
        move.w  fd_Time(a1),d3
        move.b  (a2,d3.w),d3
        move.w  .table-2(pc,d3.w),d3
        jmp     .table(pc,d3.w)
.skip
        lea     fd_SIZEOF(a1),a1
        dbra    d7,.loop
        POPM
        moveq.l #0,d0
        rts
.table
        dc.w    .set1-.table
        dc.w    .set2-.table
        dc.w    .set3-.table
        dc.w    .set4-.table
        dc.w    .set5-.table
        dc.w    .set6-.table
.set1
        bset    d2,(a0,d0.w)
        bra.s   .skip

.set2
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set3
        bset    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set4
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set5
        bset    d2,(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set6
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

;--------------------------------------------------------------------

kds_draw_wand_heat:
        lea     pd_FrontDust(a6),a0
        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_draw,(a4)+
        move.l  a0,(a4)+
        move.w  #NUM_FRONT_DUST,(a4)+
        rts

.bq_draw
        PUSHM   a2/d1-d7
        move.l  (a0)+,a1
        move.w  (a0)+,d7
        move.l  pd_SpriteCompoBuffer(a6),a0
        moveq.l #45,d5
        moveq.l #27,d4
        move.w  #FAIRY_WIDTH,d6 ; or height
        lea     kds_dust_burst(pc),a2
        subq.w  #1,d7
.loop
        addq.w  #1,fd_Time(a1)
        bmi.s   .skip
        move.w  fd_SpeedX(a1),d1
        move.w  fd_SpeedY(a1),d0
        neg.w   d1
        neg.w   d0
        move.w  d1,fd_SpeedX(a1)
        move.w  d0,fd_SpeedY(a1)
        add.w   d4,d0
        add.w   d5,d1
        PUTMSG  30,<"Pos %d,%d %d">,d1,d0,fd_Time-2(a1)
        move.w  d1,d2
        move.b  d0,-(sp)
        move.w  (sp)+,d0
        move.b  d1,d0
        lsr.w   #3,d0
        not.w   d2
        move.w  fd_Time(a1),d3
        lsr.w   #2,d3
        move.b  (a2,d3.w),d3
        move.w  .table-2(pc,d3.w),d3
        jmp     .table(pc,d3.w)
.skip
        lea     fd_SIZEOF(a1),a1
        dbra    d7,.loop
        POPM
        moveq.l #0,d0
        rts

.table
        dc.w    .set1-.table
        dc.w    .set2-.table
        dc.w    .set3-.table
        dc.w    .set4-.table
        dc.w    .set5-.table
        dc.w    .set6-.table
        dc.w    .set7-.table

.set1   ; 1
        bset    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set2   ; 2
        bclr    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set3   ; 8
        bclr    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set4   ; 11
        bset    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set5   ; 12
        bclr    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set6   ; 13
        bset    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set7   ; 14
        bclr    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

;--------------------------------------------------------------------

kds_draw_wand_blast:
        lea     pd_FrontDust(a6),a0
        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_draw,(a4)+
        move.l  a0,(a4)+
        move.w  #NUM_FRONT_DUST,(a4)+
        rts

.bq_draw
        PUSHM   a2/d1-d7
        move.l  (a0)+,a1
        move.w  (a0)+,d7
        move.l  pd_SpriteCompoBuffer(a6),a0
        move.w  pd_FairyPosY(a6),d4
        move.w  pd_FairyPosX(a6),d5
        move.w  #FAIRY_WIDTH,d6 ; or height
        lea     kds_dust_burst(pc),a2
        subq.w  #1,d7
.loop
        subq.w  #1,fd_Time(a1)
        bmi.s   .skip
        movem.l fd_PosY(a1),d0-d3
        add.l   d2,d0
        add.l   d3,d1
        movem.l d0-d1,fd_PosY(a1)
        swap    d0
        swap    d1
        sub.w   d4,d0
        sub.w   d5,d1
        PUTMSG  30,<"Pos %d,%d">,d1,d0
        cmp.w   d6,d1
        bhs.s   .skip
        cmp.w   d6,d0
        bhs.s   .skip
        move.w  d1,d2
        move.b  d0,-(sp)
        move.w  (sp)+,d0
        move.b  d1,d0
        lsr.w   #3,d0
        not.w   d2
        move.w  fd_Time(a1),d3
        move.b  (a2,d3.w),d3
        move.w  .table-2(pc,d3.w),d3
        jmp     .table(pc,d3.w)
.skip
        lea     fd_SIZEOF(a1),a1
        dbra    d7,.loop
        POPM
        moveq.l #0,d0
        rts

.table
        dc.w    .set1-.table
        dc.w    .set2-.table
        dc.w    .set3-.table
        dc.w    .set4-.table
        dc.w    .set5-.table
        dc.w    .set6-.table
        dc.w    .set7-.table

.set1   ; 1
        bset    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set2   ; 2
        bclr    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set3   ; 8
        bclr    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set4   ; 11
        bset    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bclr    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set5   ; 12
        bclr    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set6   ; 13
        bset    d2,(a0,d0.w)
        bclr    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

.set7   ; 14
        bclr    d2,(a0,d0.w)
        bset    d2,1*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,2*(FAIRY_WIDTH/8)(a0,d0.w)
        bset    d2,3*(FAIRY_WIDTH/8)(a0,d0.w)
        bra.s   .skip

;--------------------------------------------------------------------

kds_convert_compobuffer_to_sprites:
        PREP_ADD_TO_BLITTER_QUEUE a3
        move.w  #(16>>4)|(FAIRY_HEIGHT<<6),d3
        move.l  #.bq_generic_ad_with_all,d4
        move.l  #.bq_generic_ad,d5
        move.l  pd_SpriteCompoBuffer(a6),a2
        move.l  pd_CurrFairySprite(a6),a0

        moveq.l #(FAIRY_WIDTH/16)-1,d7
.sprloop
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d4,(a4)+
        move.l  (a0)+,d0
        addq.l  #4,d0
        move.l  a2,(a4)+
        move.l  d0,(a4)+
        move.w  d3,(a4)+

        move.l  d5,d4

        lea     (FAIRY_WIDTH/8)(a2),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d4,(a4)+
        addq.l  #2,d0
        move.l  a1,(a4)+
        move.l  d0,(a4)+
        move.w  d3,(a4)+

        lea     (FAIRY_WIDTH/8)(a1),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d4,(a4)+
        move.l  (a0)+,d0
        addq.l  #4,d0
        move.l  a1,(a4)+
        move.l  d0,(a4)+
        move.w  d3,(a4)+

        lea     (FAIRY_WIDTH/8)(a1),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d4,(a4)+
        addq.l  #2,d0
        move.l  a1,(a4)+
        move.l  d0,(a4)+
        move.w  d3,(a4)+

        addq.w  #2,a2

        dbra    d7,.sprloop

        clr.l   (a3)
        TERM_ADD_TO_BLITTER_QUEUE a3
        rts

.bq_generic_ad_with_all
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((FAIRY_WIDTH*FAIRY_PLANES-16)/8)<<16)|2,bltamod(a5)
.bq_generic_ad
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_prepare_buffers:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_DbBuffer(a6),bltdpt(a5)
        move.w  #((KALEIDO_BUF_WIDTH)>>4)|((KALEIDO_HEIGHT*KALEIDO_PLANES)<<6),bltsize(a5)

        move.w  #(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES,d4
        bsr     kds_blitter_line_init

        ; line 1 -> 1: bp 1
        ; line 2 -> 3: bp 1 & 2
        ; line 3 -> 5: bp 1 & 3
        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_DbBuffer(a6),a0
        PUSHM   a0/d0-d4
        lea     1*(STENCIL_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     2*(STENCIL_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     3*(STENCIL_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     2*(STENCIL_WIDTH/8)+(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     3*(STENCIL_WIDTH/8)+2*(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        move.l  pd_BonusGridPtr(a6),a0
        lea     (STENCIL_WIDTH/2)/8(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM

        ; line 1 -> 2: bp 2
        ; line 2 -> 4: bp 3
        ; line 3 -> 6: bp 2 & 3
        moveq.l #STENCIL_WIDTH-1,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2),d2
        moveq.l #STENCIL_HEIGHT-1,d3
        PUSHM   a0/d0-d4
        lea     1*(STENCIL_WIDTH/8)+(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     2*(STENCIL_WIDTH/8)+2*(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     3*(STENCIL_WIDTH/8)+(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     3*(STENCIL_WIDTH/8)+2*(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        move.l  pd_BonusGridPtr(a6),a0
        lea     -(STENCIL_WIDTH/2)/8(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        move.l  pd_BonusGridPtr(a6),a0
        lea     (STENCIL_WIDTH/2)/8(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM

        moveq.l #-1,d2
        move.w  #((16)>>4)|((KALEIDO_HEIGHT)<<6),d3
        BLTHOGON
        BLTWAIT
        BLTCON_SET AD,BLT_A|BLT_C,0,0
        move.l  d2,bltafwm(a5)      ; also fills bltalwm
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-16)/8,bltamod(a5)
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-16)/8,bltdmod(a5)
        move.w  #$8000,bltcdat(a5)
        move.l  a0,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     (KALEIDO_BUF_WIDTH/8)(a0),a1
        BLTHOGON
        BLTWAIT
        move.l  a1,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     2*(KALEIDO_BUF_WIDTH/8)(a0),a1
        BLTHOGON
        BLTWAIT
        move.l  a1,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)

        lea     (KALEIDO_WIDTH/8)(a0),a1
        BLTHOGON
        BLTWAIT
        BLTCON_SET AD,BLT_A,0,0
        move.w  #(KALEIDO_WIDTH/8),bltamod(a5)
        move.w  #(KALEIDO_WIDTH/8),bltdmod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  #((KALEIDO_WIDTH)>>4)|((KALEIDO_HEIGHT*KALEIDO_PLANES)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

kds_prepare_sprite_masks:
        move.l  pd_FairyAnim1(a6),a0
        move.l  pd_FairyMask1(a6),a1
        moveq.l #BODY_WIDTH,d0
        moveq.l #BODY_HEIGHT,d1
        bsr     .makemask

        move.l  pd_FairyAnim2(a6),a0
        move.l  pd_FairyMask2(a6),a1
        moveq.l #BODY_WIDTH,d0
        moveq.l #BODY_HEIGHT,d1
        bsr     .makemask

        move.l  pd_FairyAnim3(a6),a0
        move.l  pd_FairyMask3(a6),a1
        moveq.l #BODY_WIDTH,d0
        moveq.l #BODY_HEIGHT,d1
        bsr     .makemask

        move.l  pd_PuffAnim1(a6),a0
        move.l  pd_PuffMask1(a6),a1
        moveq.l #PUFF_WIDTH,d0
        moveq.l #PUFF_HEIGHT,d1
        bsr     .makemask

        move.l  pd_PuffAnim2(a6),a0
        move.l  pd_PuffMask2(a6),a1
        moveq.l #PUFF_WIDTH,d0
        moveq.l #PUFF_HEIGHT,d1
        bsr     .makemask

        move.l  pd_PuffAnim3(a6),a0
        move.l  pd_PuffMask3(a6),a1
        moveq.l #PUFF_WIDTH,d0
        moveq.l #PUFF_HEIGHT,d1
        bsr     .makemask

        move.l  pd_PuffAnim4(a6),a0
        move.l  pd_PuffMask4(a6),a1
        moveq.l #PUFF_WIDTH,d0
        moveq.l #PUFF_HEIGHT,d1

.makemask
        lsr.w   #3,d0
        move.w  d0,d3
        lea     (a0,d0.w),a2
        lea     (a2,d0.w),a3
        lea     (a3,d0.w),a4
        lsr.w   #1,d0
        lsl.w   #6,d1
        add.w   d0,d1

        move.w  d3,d2
        add.w   d3,d3
        add.w   d2,d3   ; for four bitplanes, so modulo is three times

        add.w   d0,d0

        moveq.l #-1,d2
        BLTHOGON
        BLTWAIT
        BLTCON_SET ABCD,BLT_A|BLT_B|BLT_C,0,0
        move.l  d2,bltafwm(a5)
        move.w  d3,bltamod(a5)
        move.w  d3,bltbmod(a5)
        move.w  d3,bltcmod(a5)
        move.w  d3,bltdmod(a5)
        move.l  a0,bltapt(a5)
        move.l  a2,bltbpt(a5)
        move.l  a3,bltcpt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d1,bltsize(a5)

        BLTWAIT
        BLTCON0_SET ACD,BLT_A|BLT_C,0
        move.l  a4,bltapt(a5)
        move.l  a1,bltcpt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d1,bltsize(a5)

        lea     (a1,d0.w),a0
        BLTWAIT
        BLTCON0_SET AD,BLT_A,0
        move.l  a1,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d1,bltsize(a5)

        REPT    2
        lea     (a0,d0.w),a0
        BLTWAIT
        BLTCON0_SET AD,BLT_A,0
        move.l  a1,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d1,bltsize(a5)
        ENDR

        rts

;--------------------------------------------------------------------

kds_prepare_intro_buffers:
        BLTHOGON
        BLTWAIT
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_DbBuffer(a6),bltdpt(a5)
        move.w  #((KALEIDO_BUF_WIDTH)>>4)|((KALEIDO_HEIGHT*KALEIDO_PLANES)<<6),bltsize(a5)

        move.w  #(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES,d4
        bsr     kds_blitter_line_init

        ; line 1 -> 1: bp 1
        ; line 2 -> 3: bp 1 & 2
        ; line 3 -> 5: bp 1 & 3
        moveq.l #0,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2)-1,d2
        moveq.l #STENCIL_HEIGHT-1,d3
        move.l  pd_DbBuffer(a6),a0
        PUSHM   a0/d0-d4
        lea     (128+(STENCIL_WIDTH/2))/8+(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM

        ; line 1 -> 2: bp 2
        ; line 2 -> 4: bp 3
        ; line 3 -> 6: bp 2 & 3
        moveq.l #STENCIL_WIDTH-1,d0
        moveq.l #0,d1
        moveq.l #(STENCIL_WIDTH/2),d2
        moveq.l #STENCIL_HEIGHT-1,d3
        PUSHM   a0/d0-d4
        lea     ((128-(STENCIL_WIDTH/2))/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     ((128+(STENCIL_WIDTH/2))/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM
        PUSHM   a0/d0-d4
        lea     ((128+(STENCIL_WIDTH/2))/8)+1*(KALEIDO_BUF_WIDTH/8)(a0),a0
        bsr     kds_draw_blitter_normal_line
        POPM

        lea     (KALEIDO_WIDTH/8)(a0),a1
        BLTHOGON
        BLTWAIT
        BLTCON_SET AD,BLT_A,0,0
        move.w  #(KALEIDO_WIDTH/8),bltamod(a5)
        move.w  #(KALEIDO_WIDTH/8),bltdmod(a5)
        move.l  a0,bltapt(a5)
        move.l  a1,bltdpt(a5)
        move.w  #((KALEIDO_WIDTH)>>4)|((KALEIDO_HEIGHT*KALEIDO_PLANES)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

CALC_STENCIL_POS MACRO
        move.w  2(a2,d7.w),d0
        muls    d6,d0
        swap    d0
        move.w  (a2,d7.w),d1
        muls    d6,d1
        swap    d1

        PUTMSG  30,<"\1 %d,%d">,d0,d1
        add.w   #(KDSPAT_WIDTH/2)+(\2),d0
        ble.s   .clipxleft\@
        cmp.w   #KDSPAT_WIDTH-STENCIL_WIDTH-1,d0
        ble.s   .noclipx\@
        move.w   #KDSPAT_WIDTH-STENCIL_WIDTH-1,d0
        bra.s   .noclipx\@
.clipxleft\@
        moveq.l #1,d0
.noclipx\@
        ext.l   d0

        add.w   #(KDSPAT_HEIGHT/2)+(\3),d1
        ble.s   .clipytop\@
        cmp.w   #KDSPAT_HEIGHT-STENCIL_HEIGHT-1,d1
        ble.s   .noclipy\@
        move.w   #KDSPAT_HEIGHT-STENCIL_HEIGHT-1,d1
        bra.s   .noclipy\@
.clipytop\@
        moveq.l #1,d1
.noclipy\@
        ext.l   d1
        lsl.l   #8,d1       ; * KDSPAT_WIDTH
        move.l  d1,d2
        add.l   d2,d2       ; *2
        add.l   d1,d2       ; *3
        add.l   d2,d2       ; *6
        move.b  d0,d1
        add.l   d0,d2
        add.l   d1,d1
        move.l  d1,pd_StencilTCOffset\1(a6)

        subq.w  #1,d2
        asr.l   #4,d2
        add.l   d2,d2
        IFNE    \4
        add.l   #(\4)*KDSPAT_WIDTH*KALEIDO_PLANES/8,d2
        ENDC
        move.l  d2,pd_StencilOffset\1(a6)

        moveq.l #15,d2
        neg.w   d0
        and.w   d0,d2
        ror.w   #4,d2
        move.w  d2,pd_StencilShift\1(a6)
        ENDM

kds_calc_stencil_positions1_std:
        move.l  pd_BigSinCosTable(a6),a2
        bsr     kds_calc_mouse
        tst.w   pd_InteractiveMode(a6)
        beq.s   .automode
        move.w  pd_Distance1(a6),d6
        move.b  pd_DeltaMouseY(a6),d1
        ext.w   d1
        asr.w   #2,d1
        add.w   d1,d6
        bpl.s   .nolimit0
        moveq.l #0,d6
.nolimit0
        cmp.w   #1200/4,d6
        bls.s   .nolimit
        move.w  #1200/4,d6
.nolimit
        move.w  d6,pd_Distance1(a6)
        move.b  pd_DeltaMouseX(a6),d0
        ext.w   d0
        move.w  pd_Angle1(a6),d7
        add.w   d0,d7
        and.w   #2047*4,d7
        move.w  d7,pd_Angle1(a6)
        clr.w   pd_DeltaMouseY(a6)
        PUTMSG  30,<"%d (%d), %d (%d)">,d6,d1,d7,d0
        bra.s   .mancont
.automode
        move.w  pd_PosBaseCounter(a6),d6
        add.w   #18,d6
        move.w  d6,pd_PosBaseCounter(a6)
        and.w   #2047*4,d6
        move.w  (a2,d6.w),d6
        muls    #1080,d6
        swap    d6
        move.w  d6,pd_Distance1(a6)
        move.w  pd_Angle1(a6),d7
        add.w   #15*4,d7
        and.w   #2047*4,d7
        move.w  d7,pd_Angle1(a6)
.mancont
        ; first angle, from bottom/mid to top/left corner
        CALC_STENCIL_POS 1,-(STENCIL_WIDTH/2),-STENCIL_HEIGHT,1*KDSPAT_HEIGHT

        ; second angle, from bottom/left to top/left corner
        move.w  #(((-120)*2048+180)/360)*4,d7
        sub.w   pd_Angle1(a6),d7
        and.w   #2047*4,d7
        CALC_STENCIL_POS 6,0,-STENCIL_HEIGHT,2*KDSPAT_HEIGHT

        ; third angle, from bottom/right to top/left corner
        move.w  #(((120)*2048+180)/360)*4,d7
        sub.w   pd_Angle1(a6),d7
        and.w   #2047*4,d7
        CALC_STENCIL_POS 8,-STENCIL_WIDTH,-STENCIL_HEIGHT,0*KDSPAT_HEIGHT
        rts

kds_calc_stencil_positions1_slow:
        move.l  pd_BigSinCosTable(a6),a2
        move.w  pd_PosBaseCounter(a6),d6
        add.w   #9,d6
        move.w  d6,pd_PosBaseCounter(a6)
        and.w   #2047*4,d6
        move.w  (a2,d6.w),d6
        muls    #1080,d6
        swap    d6
        move.w  d6,pd_Distance1(a6)
        ;and.w   #$ff,d6
        move.w  pd_Angle1(a6),d7
        ;move.w  #2*256*4,d7
        sub.w   #6*4,d7
        and.w   #2047*4,d7
        move.w  d7,pd_Angle1(a6)

        ; first angle, from bottom/mid to top/left corner
        CALC_STENCIL_POS 1,-(STENCIL_WIDTH/2),-STENCIL_HEIGHT,1*KDSPAT_HEIGHT

        ; second angle, from bottom/left to top/left corner
        move.w  #(((-120)*2048+180)/360)*4,d7
        sub.w   pd_Angle1(a6),d7
        and.w   #2047*4,d7
        CALC_STENCIL_POS 6,0,-STENCIL_HEIGHT,2*KDSPAT_HEIGHT

        ; third angle, from bottom/right to top/left corner
        move.w  #(((120)*2048+180)/360)*4,d7
        sub.w   pd_Angle1(a6),d7
        and.w   #2047*4,d7
        CALC_STENCIL_POS 8,-STENCIL_WIDTH,-STENCIL_HEIGHT,0*KDSPAT_HEIGHT
        rts

kds_calc_stencil_positions2_std:
        move.w  pd_Distance1(a6),d6
        move.w  pd_Angle1(a6),d7

        ; first angle, from top/mid to top/left corner
        CALC_STENCIL_POS 7,-(STENCIL_WIDTH/2),0,1*KDSPAT_HEIGHT

        ; second angle, from top/right to top/left corner
        move.w  #(((120)*2048+180)/360)*4,d7
        sub.w   pd_Angle1(a6),d7
        and.w   #2047*4,d7
        CALC_STENCIL_POS 2,-STENCIL_WIDTH,0,0*KDSPAT_HEIGHT

        ; third angle, from top/left to top/left corner
        move.w  #(((-120)*2048+180)/360)*4,d7
        sub.w   pd_Angle1(a6),d7
        and.w   #2047*4,d7
        CALC_STENCIL_POS 3,0,0,2*KDSPAT_HEIGHT

        rts

;--------------------------------------------------------------------

kds_calc_mouse:
        move.w  joy0dat(a5),d1
        move.w  pd_OldMouseY(a6),d0
        move.w  d1,pd_OldMouseY(a6)
        sub.w   d0,d1
        add.w   d1,pd_DeltaMouseY(a6)
        cmp.b   #32,d1
        blt.s   .skip
        st      pd_InteractiveMode(a6)
.skip
        rts

;--------------------------------------------------------------------

kds_calc_stencil_fixup_lines_transition:
        move.w  pd_TransitionHeight(a6),d5
        bne.s   .cont
        rts
.cont
        PREP_ADD_TO_BLITTER_QUEUE a3
        move.l  #.bq_ad_copy,d6

        move.l  pd_CurrTCLineColorsPtr(a6),a2

        ; first hexagon, first line, color 6
        lea     0*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset8(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; first hexagon, second line, color 1
        lea     1*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset1(a6),a0
        jsr     pd_SMCLine1(a6)

        ; first hexagon, third line, color 2
        lea     2*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset6(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; now copy colors to copperlist for each mirror
        move.w  d5,d3
        cmp.w   #STENCIL_HEIGHT,d3
        blt.s   .nomax1
        moveq.l #STENCIL_HEIGHT,d3
.nomax1 lsl.w   #6,d3
        addq.w  #1,d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset1(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    2
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        move.w  d5,d3
        sub.w   #STENCIL_HEIGHT,d3
        ble.s   .skip

        ; ---------------------
        ; mirror 1
        lsl.w   #6,d3
        addq.w  #1,d3

        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset2(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    2
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

.skip
        clr.l   (a3)
        TERM_ADD_TO_BLITTER_QUEUE a3
        rts

.bq_ad_copy_all
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(0<<16)|((COP_INST_PER_INTRO_LINE*4)-2),bltamod(a5) ; and bltdmod
.bq_ad_copy
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_ad_copy_backwards
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(-4<<16)|((4*4)-2),bltamod(a5) ; and bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_calc_stencil_fixup_lines_pre_main:
        PREP_ADD_TO_BLITTER_QUEUE a3
        move.l  #.bq_ad_copy,d6

        move.w  #(1|(STENCIL_HEIGHT<<6)),d3
        move.l  pd_CurrTCLineColorsPtr(a6),a2

        ; first hexagon, first line, color 6
        lea     0*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset8(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; first hexagon, second line, color 1
        lea     1*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset1(a6),a0
        jsr     pd_SMCLine1(a6)

        ; first hexagon, third line, color 2
        lea     2*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset6(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; second hexagon, first line, color 3
        lea     3*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset2(a6),a0
        jsr     pd_SMCLineUp1(a6)

        ; second hexagon, second line, color 4
        lea     4*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset7(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLineUp2(a6)

        ; second hexagon, border line, color 7
        lea     5*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset7(a6),a0
        jsr     pd_SMCLineUp3(a6)

        ; second hexagon, third line, color 5
        lea     6*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset3(a6),a0
        jsr     pd_SMCLineUp1(a6)

        ; now copy colors to copperlist for each mirror
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset1(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; ---------------------
        ; mirror 1
        move.w  #(1|((STENCIL_HEIGHT-1)<<6)),d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset2(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; mirror 2
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset3(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+2*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+2*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; mirror 3
        move.w  #(1|((LAST_SLICE_HEIGHT)<<6)),d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset4(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+3*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+3*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        clr.l   (a3)
        TERM_ADD_TO_BLITTER_QUEUE a3

        rts

.bq_ad_copy_all
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(0<<16)|((COP_INST_PER_PMAIN_LINE*4)-2),bltamod(a5) ; and bltdmod
.bq_ad_copy
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_ad_copy_backwards
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(-4<<16)|((COP_INST_PER_PMAIN_LINE*4)-2),bltamod(a5) ; and bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_calc_stencil_fixup_lines_generic:
        PREP_ADD_TO_BLITTER_QUEUE a3
        move.l  #.bq_ad_copy,d6

        move.w  #(1|(STENCIL_HEIGHT<<6)),d3
        move.l  pd_CurrTCLineColorsPtr(a6),a2

        ; first hexagon, first line, color 6
        lea     0*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset8(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; first hexagon, second line, color 1
        lea     1*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset1(a6),a0
        jsr     pd_SMCLine1(a6)

        ; first hexagon, third line, color 2
        lea     2*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset6(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; second hexagon, first line, color 3
        lea     3*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset2(a6),a0
        jsr     pd_SMCLineUp1(a6)

        ; second hexagon, second line, color 4
        lea     4*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset7(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLineUp2(a6)

        ; second hexagon, border line, color 7
        lea     5*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset7(a6),a0
        jsr     pd_SMCLineUp3(a6)

        ; second hexagon, third line, color 5
        lea     6*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset3(a6),a0
        jsr     pd_SMCLineUp1(a6)

        ; now copy colors to copperlist for each mirror
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset1(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; ---------------------
        ; mirror 1
        move.w  #(1|((STENCIL_HEIGHT-1)<<6)),d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset2(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; mirror 2
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset3(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+2*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+2*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; mirror 3
        move.w  #(1|((LAST_SLICE_HEIGHT)<<6)),d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset4(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+3*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-4
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+3*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        clr.l   (a3)
        TERM_ADD_TO_BLITTER_QUEUE a3
        rts

.bq_ad_copy_all
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(0<<16)|((COP_INST_PER_LINE*4)-2),bltamod(a5) ; and bltdmod
.bq_ad_copy
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_ad_copy_backwards
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(-4<<16)|((COP_INST_PER_LINE*4)-2),bltamod(a5) ; and bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_calc_stencil_fixup_lines_bonus:
        PREP_ADD_TO_BLITTER_QUEUE a3
        move.l  #.bq_ad_copy,d6

        move.w  #(1|(STENCIL_HEIGHT<<6)),d3
        move.l  pd_CurrTCLineColorsPtr(a6),a2

        ; first hexagon, first line, color 6
        lea     0*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset8(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; first hexagon, second line, color 1
        lea     1*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset1(a6),a0
        jsr     pd_SMCLine1(a6)

        ; first hexagon, third line, color 2
        lea     2*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset6(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; second hexagon, first line, color 3
        lea     3*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset2(a6),a0
        jsr     pd_SMCLineUp1(a6)

        ; second hexagon, second line, color 4
        lea     4*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset7(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLineUp2(a6)

        ; second hexagon, border line, color 7
        lea     5*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset7(a6),a0
        jsr     pd_SMCLineUp3(a6)

        ; second hexagon, third line, color 5
        lea     6*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col3Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset3(a6),a0
        jsr     pd_SMCLineUp1(a6)

        IF      0
        ; third hexagon, first line, color 6
        lea     7*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage1(a6),a0
        add.l   pd_StencilTCOffset8(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)

        ; third hexagon, second line, color 9
        lea     8*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage2(a6),a0
        add.l   pd_StencilTCOffset1(a6),a0
        jsr     pd_SMCLine1(a6)

        ; third hexagon, third line, color 10
        lea     9*4*LCOLBUF_HEIGHT*2(a2),a1
        move.l  pd_PatternInfo+hp_Col2Routine(a6),a0
        jsr     (a0)
        move.l  pd_TrueColorImage3(a6),a0
        add.l   pd_StencilTCOffset6(a6),a0
        lea     -(STENCIL_WIDTH/2)*2(a0),a0
        jsr     pd_SMCLine2(a6)
        ENDC

        ; now copy colors to copperlist for each mirror
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset1(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-1
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+0*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; ---------------------
        ; mirror 1
        move.w  #(1|((STENCIL_HEIGHT-1)<<6)),d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset2(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-1
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+1*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; mirror 2
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset3(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+2*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_all,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-1
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+2*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        ; mirror 3
        move.w  #(1|((LAST_SLICE_HEIGHT)<<6)),d3
        move.l  pd_CurrCopListPtr(a6),a1
        adda.w  pd_CopperLinesFixupOffset4(a6),a1

        move.l  a1,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(0+3*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_backwards,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+

        REPT    LCOL_NUM-1
        addq.l  #4,d4
        move.l  a2,a1
        add.w   pd_PatternInfo+hp_ColOffs+(REPTN+1+3*LCOL_NUM)*2(a6),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  d6,(a4)+
        move.l  a1,(a4)+
        move.l  d4,(a4)+
        move.w  d3,(a4)+
        ENDR

        clr.l   (a3)
        TERM_ADD_TO_BLITTER_QUEUE a3

        rts

.bq_ad_copy_all
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(0<<16)|((COP_INST_PER_LINE*4)-2),bltamod(a5) ; and bltdmod
.bq_ad_copy
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_ad_copy_backwards
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)  ; bltafwm
        move.l  #(-4<<16)|((COP_INST_PER_LINE*4)-2),bltamod(a5) ; and bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_swap_rgb_to_bgr:
        ; R>>8|0G0
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_rgb_to_00r_or_0g0,(a4)+
        move.l  a1,(a4)+
        move.l  a1,(a4)+
        lea     3*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.w  d3,(a4)+

        ; B<<8|0GR
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_0gr_merge_with_b00,(a4)+
        lea     STENCIL_HEIGHT*2-2(a1),a1
        move.l  a1,(a4)+
        lea     -3*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.l  a1,(a4)+
        move.w  d3,(a4)+
        lea     -STENCIL_HEIGHT*2+2(a1),a1
        rts

.bq_acd_rgb_to_00r_or_0g0
        move.l  #((BLTEN_ACD+((BLT_A|(BLT_B&BLT_C))))<<16)|(8<<28),bltcon0(a5)
        move.l  #$0f000f00,bltafwm(a5)  ; bltafwm
        moveq.l #0,d0
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  d0,bltcmod(a5)
        move.w  #$0f0,bltbdat(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_acd_0gr_merge_with_b00
        move.l  #((BLTEN_ACD+(((BLT_A|BLT_C)))&$ff)<<16)|(8<<28)|BLTCON1F_DESC,bltcon0(a5)
        lea     bltafwm(a5),a1
        move.l  #$000f000f,(a1)+ ; bltafwm
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_swap_rgb_to_bgr_and_gbr:
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_gbr,(a4)+
        lea     STENCIL_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        subq.w  #2,a1
        move.l  a1,(a4)+
        lea     1*LCOLBUF_HEIGHT*2+2(a1),a1
        move.l  a1,(a4)+
        add.w   #1<<6,d3
        move.w  d3,(a4)+
        sub.w   #1<<6,d3

        lea     -(1*LCOLBUF_HEIGHT*2+STENCIL_HEIGHT*2)(a1),a1

        bra     kds_swap_rgb_to_bgr

.bq_acd_gbr
        lea     bltcon0(a5),a1
        move.l  #((BLTEN_ABD+((BLT_A|(BLT_B&BLT_C))))<<16)|(8<<28)|(4<<12)|BLTCON1F_DESC,(a1)+
        move.l  #$0f000f00,(a1)+    ; bltafwm/bltafwm
        moveq.l #0,d0
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  d0,bltbmod(a5)
        move.w  #$ff0,bltcdat(a5)
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_swap_rgb_to_rbg:
        ; G>>4|R00
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_rgb_to_00g_or_r00,(a4)+
        move.l  a1,(a4)+
        move.l  a1,(a4)+
        lea     3*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.w  d3,(a4)+

        ; B<<4|R0G
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_r0g_merge_with_0b0,(a4)+
        lea     STENCIL_HEIGHT*2-2(a1),a1
        move.l  a1,(a4)+
        lea     -3*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        lea     1*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.w  d3,(a4)+
        lea     -(1*LCOLBUF_HEIGHT*2+STENCIL_HEIGHT*2)+2(a1),a1

        rts

.bq_acd_rgb_to_00g_or_r00
        lea     bltcon0(a5),a1
        move.l  #((BLTEN_ACD+((BLT_A|(BLT_B&BLT_C))))<<16)|(4<<28),(a1)+
        move.l  #$00f000f0,(a1)+    ; bltafwm/bltafwm
        moveq.l #0,d0
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  d0,bltcmod(a5)
        move.w  #$f00,bltbdat(a5)
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_acd_r0g_merge_with_0b0
        lea     bltcon0(a5),a1
        move.l  #((BLTEN_ACD+(((BLT_A|BLT_C)))&$ff)<<16)|(4<<28)|BLTCON1F_DESC,(a1)+
        move.l  #$000f000f,(a1)+    ; bltafwm/bltafwm
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_swap_rgb_to_rbg_and_grb:
        bsr     kds_swap_rgb_to_rbg
        bra     kds_swap_rgb_to_grb

;--------------------------------------------------------------------

kds_swap_rgb_to_rbg_and_grb_and_brg:
        bsr     kds_swap_rgb_to_rbg
        bsr     kds_swap_rgb_to_grb

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_rgb_to_brg,(a4)+
        move.l  a1,(a4)+
        addq.w  #2,a1
        move.l  a1,(a4)+
        lea     3*LCOLBUF_HEIGHT*2-2(a1),a1
        move.l  a1,(a4)+
        move.w  d3,(a4)+

        lea     -(3*LCOLBUF_HEIGHT*2)(a1),a1

        rts

.bq_acd_rgb_to_brg
        ; (r<<8)|(bg>>4) -> (b<<8)|(rg>>4)
        move.l  #((BLTEN_ABD+((BLT_A|(BLT_B&BLT_C))))<<16)|(8<<28)|(4<<12),bltcon0(a5)
        move.l  #$000f000f,bltafwm(a5)  ; bltafwm
        moveq.l #0,d0
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  d0,bltbmod(a5)
        move.w  #$0ff,bltcdat(a5)
        lea     bltbpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_swap_rgb_to_grb:
        ; R>>4|00B
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_rgb_to_0r0_or_00b,(a4)+
        move.l  a1,(a4)+
        move.l  a1,(a4)+
        lea     3*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.w  d3,(a4)+

        ; G<<4|0RB
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_0rb_merge_with_g00,(a4)+
        lea     STENCIL_HEIGHT*2-2(a1),a1
        move.l  a1,(a4)+
        lea     -3*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        lea     2*LCOLBUF_HEIGHT*2(a1),a1
        move.l  a1,(a4)+
        move.w  d3,(a4)+
        lea     -(2*LCOLBUF_HEIGHT*2+STENCIL_HEIGHT*2)+2(a1),a1

        rts

.bq_acd_rgb_to_0r0_or_00b
        lea     bltcon0(a5),a1
        move.l  #((BLTEN_ACD+((BLT_A|(BLT_B&BLT_C))))<<16)|(4<<28),(a1)+
        move.l  #$0f000f00,(a1)+    ; bltafwm/bltafwm
        moveq.l #0,d0
        move.l  d0,bltamod(a5)  ; and bltdmod
        move.w  d0,bltcmod(a5)
        move.w  #$00f,bltbdat(a5)
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_acd_0rb_merge_with_g00
        lea     bltcon0(a5),a1
        move.l  #((BLTEN_ACD+(((BLT_A|BLT_C)))&$ff)<<16)|(4<<28)|BLTCON1F_DESC,(a1)+
        move.l  #$00f000f0,(a1)+    ; bltafwm/bltafwm
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------
; blit order: merge: 1 2 3 6 7 5b 8a, copy 3 to 0, copy 1 to 4
; \0/5\1/6\2/7\3/8\4/
; / \ / \ / \ / \ / \
;
kds_draw_stencils_col1010:
        move.w  #((STENCIL_WIDTH+16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KDSPAT_WIDTH-STENCIL_WIDTH-16)/8,d6
        move.w  #(KALEIDO_BUF_WIDTH-STENCIL_WIDTH-16)/8,d7

        ; first row
        move.l  pd_OriginalPattern(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer1(a6),a2
        subq.w  #2,a1
        subq.w  #2,a2

        addq.w  #STENCIL_WIDTH/8,a1

        FIRST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_all,(a4)+
        move.w  #BLTEN_ABCD+(((BLT_B&BLT_A)|(BLT_C&~BLT_A))&$ff),(a4)+
        move.l  #$0000ffff,(a4)+    ; bltafwm
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #-2,(a4)+           ; bltamod
        move.w  d7,(a4)+            ; bltdmod

        move.w  pd_StencilShift1(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset1(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; second row
        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer2(a6),a2
        lea     (STENCIL_WIDTH+STENCIL_WIDTH/2)/8-2(a1),a1
        subq.w  #2,a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift6(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset6(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #(((STENCIL_WIDTH/2)+16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KDSPAT_WIDTH-((STENCIL_WIDTH/2)+16))/8,d6
        move.w  #(KALEIDO_BUF_WIDTH-((STENCIL_WIDTH/2)+16))/8,d7

        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer2(a6),a2
        lea     (STENCIL_WIDTH)/8-2(a1),a1
        lea     (STENCIL_WIDTH/2)/8-2(a2),a2

        PUSHM   a0/a1
        BLTHOGON
        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue
        POPM

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_mods,(a4)+
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #((STENCIL_WIDTH/2)-16)/8,(a4)+ ; bltamod
        move.w  d7,(a4)+            ; bltdmod
        move.w  pd_StencilShift8(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset8(a6),d5
        addq.l  #(STENCIL_WIDTH/2)/8,d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        subq.w  #(STENCIL_WIDTH/2)/8,a0
        lea     (2*STENCIL_WIDTH+STENCIL_WIDTH/2)/8(a1),a1
        lea     -(STENCIL_WIDTH/2)/8(a2),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        subq.l  #(STENCIL_WIDTH/2)/8,d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; mirrored and swapped p5/p6
        addq.w  #(STENCIL_WIDTH/2)/8,a0
        move.w  #((STENCIL_WIDTH+16)>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(-KDSPAT_WIDTH*KALEIDO_PLANES-((STENCIL_WIDTH)+16))/8,d6
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-((STENCIL_WIDTH)+16))/8,d7

        move.l  pd_StencilBuffer1(a6),a2
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     2*(STENCIL_WIDTH/8)-2(a1),a1
        subq.w  #2,a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_mods,(a4)+
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #((STENCIL_WIDTH*KALEIDO_PLANES)-(STENCIL_WIDTH+16))/8,(a4)+ ; bltamod
        move.w  d7,(a4)+            ; bltdmod
        move.w  pd_StencilShift2(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset2(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        REPT    3
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        ENDR

        lea     2*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     -(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; next one
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*(STENCIL_WIDTH/8)-2(a1),a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift3(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset3(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        REPT    3
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        ENDR

        lea     2*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     -(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; next one
        move.l  pd_StencilBuffer2(a6),a2
        move.l  pd_CurrPlanesPtr(a6),a1
        subq.w  #2,a2
        lea     (STENCIL_WIDTH*2+STENCIL_WIDTH/2)/8-2(a1),a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift7(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset7(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        REPT    3
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        ENDR

        lea     2*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     -(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_generic_abcd_with_all
        BLTHOGOFF
        move.w  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltafwm(a5)
.bq_generic_abcd_with_mods
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
.bq_generic_abcd_with_bltcon1
        move.w  (a0)+,bltcon1(a5)
.bq_generic_abcd
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------
;--------------------------------------------------------------------
; blit order: merge: 1 2 3 6 7 5b 8a, copy 3 to 0, copy 1 to 4
; \0/5\1/6\2/7\3/8\4/
; / \ / \ / \ / \ / \
;
kds_draw_stencils_col0000:
        move.w  #((STENCIL_WIDTH+16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KDSPAT_WIDTH-STENCIL_WIDTH-16)/8,d6
        move.w  #(KALEIDO_BUF_WIDTH-STENCIL_WIDTH-16)/8,d7

        ; first row
        move.l  pd_OriginalPattern(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer1(a6),a2
        subq.w  #2,a1
        subq.w  #2,a2

        addq.w  #STENCIL_WIDTH/8,a1

        FIRST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_all,(a4)+
        move.w  #BLTEN_ABCD+(((BLT_B&BLT_A)|(BLT_C&~BLT_A))&$ff),(a4)+
        move.l  #$0000ffff,(a4)+    ; bltafwm
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #-2,(a4)+           ; bltamod
        move.w  d7,(a4)+            ; bltdmod

        move.w  pd_StencilShift1(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset1(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; second row
        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer2(a6),a2
        lea     (STENCIL_WIDTH+STENCIL_WIDTH/2)/8-2(a1),a1
        subq.w  #2,a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift6(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset6(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #(((STENCIL_WIDTH/2)+16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KDSPAT_WIDTH-((STENCIL_WIDTH/2)+16))/8,d6
        move.w  #(KALEIDO_BUF_WIDTH-((STENCIL_WIDTH/2)+16))/8,d7

        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer2(a6),a2
        lea     (STENCIL_WIDTH)/8-2(a1),a1
        lea     (STENCIL_WIDTH/2)/8-2(a2),a2

        PUSHM   a0/a1
        BLTHOGON
        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue
        POPM

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_mods,(a4)+
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #((STENCIL_WIDTH/2)-16)/8,(a4)+ ; bltamod
        move.w  d7,(a4)+            ; bltdmod
        move.w  pd_StencilShift8(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset8(a6),d5
        addq.l  #(STENCIL_WIDTH/2)/8,d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        subq.w  #(STENCIL_WIDTH/2)/8,a0
        lea     (2*STENCIL_WIDTH+STENCIL_WIDTH/2)/8(a1),a1
        lea     -(STENCIL_WIDTH/2)/8(a2),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        subq.l  #(STENCIL_WIDTH/2)/8,d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; mirrored and unswapped p5/p6
        addq.w  #(STENCIL_WIDTH/2)/8,a0
        move.w  #((STENCIL_WIDTH+16)>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(-KDSPAT_WIDTH*KALEIDO_PLANES-((STENCIL_WIDTH)+16))/8,d6
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-((STENCIL_WIDTH)+16))/8,d7

        move.l  pd_StencilBuffer1(a6),a2
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     2*(STENCIL_WIDTH/8)-2(a1),a1
        subq.w  #2,a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_mods,(a4)+
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #((STENCIL_WIDTH*KALEIDO_PLANES)-(STENCIL_WIDTH+16))/8,(a4)+ ; bltamod
        move.w  d7,(a4)+            ; bltdmod
        move.w  pd_StencilShift2(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset2(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        REPT    3
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        ENDR

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; next one
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*(STENCIL_WIDTH/8)-2(a1),a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift3(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset3(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        REPT    3
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        ENDR

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; next one
        move.l  pd_StencilBuffer2(a6),a2
        move.l  pd_CurrPlanesPtr(a6),a1
        subq.w  #2,a2
        lea     (STENCIL_WIDTH*2+STENCIL_WIDTH/2)/8-2(a1),a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift7(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset7(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        REPT    3
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        ENDR

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   #KDSPAT_WIDTH/8,d5
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_generic_abcd_with_all
        BLTHOGOFF
        move.w  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltafwm(a5)
.bq_generic_abcd_with_mods
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
.bq_generic_abcd_with_bltcon1
        move.w  (a0)+,bltcon1(a5)
.bq_generic_abcd
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_stencils_intro:
        move.w  #((STENCIL_WIDTH+16)>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(KDSPAT_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH+16))/8,d6
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH+16))/8,d7
        moveq.l #(KDSPAT_WIDTH/8),d4

        move.l  pd_OriginalPattern(a6),a0
        lea     2*(KDSPAT_WIDTH/8)(a0),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1

        ; second row
        move.l  pd_StencilSprBuffer2(a6),a2

        ; copy left part of triangle as background
        FIRST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_mask_only,(a4)+
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt

        ; copy right part of triangle as background
        lea     (STENCIL_WIDTH+STENCIL_WIDTH/2)/8(a1),a1
        addq.l  #(STENCIL_WIDTH/2)/8,a2
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_mask_only_more,(a4)+
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt

        ; fill center part
        subq.l  #(STENCIL_WIDTH)/8,a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_fill,(a4)+
        move.l  a1,(a4)+            ; bltdpt

        PUSHM   a0/a1
        BLTHOGON
        BLTWAIT
        lea     pd_BQBuffer(a6),a0
        CALLFW  TriggerCustomBlitterQueue
        POPM

        ; second row
        lea     1*(KALEIDO_BUF_WIDTH/8)+(STENCIL_WIDTH/2)/8-2(a1),a1
        subq.l  #(STENCIL_WIDTH/2)/8+2,a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_all,(a4)+
        move.w  #BLTEN_ABD+((BLT_B&BLT_A)),(a4)+
        move.l  #$0000ffff,(a4)+    ; bltafwm
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #-2,(a4)+           ; bltamod
        move.w  d7,(a4)+            ; bltdmod

        move.w  pd_StencilShift6(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset6(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   d4,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     -1*(KALEIDO_BUF_WIDTH/8)-(STENCIL_WIDTH)/8(a1),a1
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift8(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset8(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   d4,d5
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; first row
        move.l  pd_StencilSprBuffer1(a6),a2
        subq.w  #2,a2
        lea     -1*(KALEIDO_BUF_WIDTH/8)+(STENCIL_WIDTH/2)/8(a1),a1

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4

        move.l  #.bq_generic_abcd_with_bltcon01,(a4)+
        move.w  #BLTEN_ABCD+(((BLT_B&BLT_A)|(BLT_C&~BLT_A))&$ff),(a4)+
        move.w  pd_StencilShift1(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset1(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a1
        add.l   d4,d5
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_generic_abcd,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_mask_only
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((STENCIL_WIDTH-STENCIL_WIDTH/2)/8)<<16)|((KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH/2))/8),bltamod(a5)
.bq_mask_only_more
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  #((STENCIL_WIDTH/2)>>4)|((STENCIL_HEIGHT)<<6),(a1)+ ; bltsize
        rts

.bq_fill
        BLTCON0_SET D,255,0
        move.w  #((KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH))/8),bltdmod(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT)<<6),bltsize(a5)
        rts

.bq_generic_abcd_with_all
        move.w  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltafwm(a5)
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
.bq_generic_abcd_with_bltcon1
        move.w  (a0)+,bltcon1(a5)
.bq_generic_abcd
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

.bq_generic_abcd_with_bltcon01
        move.l  (a0)+,bltcon0(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_stencils_transition:
        move.w  #((STENCIL_WIDTH+16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KDSPAT_WIDTH-STENCIL_WIDTH-16)/8,d6
        move.w  #(KALEIDO_BUF_WIDTH-STENCIL_WIDTH-16)/8,d7

        ; first row
        move.l  pd_OriginalPattern(a6),a0
        move.l  pd_CurrPlanesPtr(a6),a1
        move.l  pd_StencilBuffer1(a6),a2
        lea     (128/8)-2(a1),a1
        subq.w  #2,a2

        addq.w  #(STENCIL_WIDTH/2)/8,a1

        SAFE_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_all,(a4)+
        move.w  #BLTEN_ABCD+(((BLT_B&BLT_A)|(BLT_C&~BLT_A))&$ff),(a4)+
        move.l  #$0000ffff,(a4)+    ; bltafwm
        move.w  d7,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  #-2,(a4)+           ; bltamod
        move.w  d7,(a4)+            ; bltdmod

        move.w  pd_StencilShift1(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset1(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        ; second row
        move.l  pd_StencilBuffer2(a6),a2
        lea     (STENCIL_WIDTH/2)/8(a1),a1
        subq.w  #2,a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift6(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset6(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     -(STENCIL_WIDTH)/8(a1),a1

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_generic_abcd_with_bltcon1,(a4)+
        move.w  pd_StencilShift8(a6),(a4)+ ; bltcon1
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,d5
        add.l   pd_StencilOffset8(a6),d5
        move.l  d5,(a4)+            ; bltbpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_generic_abcd_with_all
        BLTHOGOFF
        move.w  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltafwm(a5)
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
.bq_generic_abcd_with_bltcon1
        move.w  (a0)+,bltcon1(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_clear_noise_sprite_buffer:
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET D,0,0,0
        move.w  #0,bltdmod(a5)
        move.l  pd_SpriteStencil1Ptrs(a6),bltdpt(a5)
        move.w  #(INTRO_SPRITE_WIDTH>>4)|(((INTRO_SPRITE_HEIGHT+2)*2*2)<<6),bltsize(a5)
        rts

;--------------------------------------------------------------------

kds_convert_noise_to_sprites:
        move.w  d0,d3
        lsl.w   #6,d3
        addq.w  #1,d3
        move.l  pd_NoiseBuffer(a6),a2
        adda.w  pd_NoiseOffset(a6),a2

        move.l  #.bq_generic_ad_with_all,d4
        move.l  #.bq_generic_ad,d5
        move.l  pd_CurrSpriteStencilPtr(a6),a3
        moveq.l #8-1,d7
.sprloop
        move.l  a4,a0
        clr.l   (a4)+
        move.l  d4,(a4)+
        move.l  (a3)+,d0
        addq.w  #4,d0
        move.l  a2,(a4)+
        move.l  d0,(a4)+
        move.w  d3,(a4)+
        addq.w  #2,a2
        CALLFW  AddToBlitterQueue

        move.l  d5,d4
        dbra    d7,.sprloop

        rts

.bq_generic_ad_with_all
        move.l  #(BLTEN_AD+BLT_A)<<16,bltcon0(a5)
        moveq.l #-1,d0
        move.l  d0,bltafwm(a5)
        move.l  #(((NOISE_WIDTH-16)/8)<<16)|2,bltamod(a5)
.bq_generic_ad
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_stencils_copy_edges:
        ; copy stuff over
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*STENCIL_WIDTH/8(a1),a0
        move.w  #((16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH-16)/8,d6

        PREP_ADD_TO_BLITTER_QUEUE a3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_copy_without_left,(a4)+
        move.w  d6,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltcpt
        move.l  a0,(a4)+            ; bltbpt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        addq.w  #2,a1
        addq.w  #2,a0

        move.w  #((STENCIL_WIDTH-16)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH-(STENCIL_WIDTH-16))/8,d6

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_ad_copy_with_all,(a4)+
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a0,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        lea     (STENCIL_WIDTH/8)-2(a1),a1
        lea     (STENCIL_WIDTH/8)-2(a0),a0

        move.w  #((STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT*KALEIDO_PLANES)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH-(STENCIL_WIDTH))/8,d6

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_ad_copy_with_mods,(a4)+
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_acd_copy_without_left
        move.l  #(BLTEN_ACD+(((BLT_A&BLT_B)|(BLT_C&~BLT_B))&$ff))<<16,bltcon0(a5)
        move.l  (a0)+,bltcmod(a5) ; and bltbmod
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        moveq.l #-1,d0
        lea     bltafwm(a5),a1
        move.l  d0,(a1)+        ; bltafwm/bltalwm
        move.w  #$7fff,bltbdat(a5)
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_ad_copy_with_all
        move.w  #(BLTEN_AD+BLT_A),bltcon0(a5)
.bq_ad_copy_with_mods
        move.l  (a0)+,bltamod(a5) ; and bltdmod
.bq_ad_copy
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_bonus_stuff_for_col2:
        ; copy stuff over
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)+(3*STENCIL_WIDTH+(STENCIL_WIDTH/2))/8(a1),a1
        lea     1*(KALEIDO_BUF_WIDTH/8)(a1),a2

        move.w  #((STENCIL_WIDTH+(STENCIL_WIDTH/2))>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH+(STENCIL_WIDTH/2)))/8,d6

        PREP_ADD_TO_BLITTER_QUEUE a3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_abcd_xor,(a4)+
        move.w  d6,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  pd_HexagonTopMaskPtr(a6),(a4)+  ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*(KALEIDO_BUF_WIDTH/8)+(3*STENCIL_WIDTH+(STENCIL_WIDTH/2))/8(a1),a1
        move.l  pd_BonusGridPtr(a6),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_merge,(a4)+
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH/2)>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH/2))/8,d6

        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*(KALEIDO_BUF_WIDTH/8)+(STENCIL_WIDTH/2)/8(a1),a1
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_acd_clear,(a4)+
        move.w  d6,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_abcd_xor
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_ABCD+((BLT_A&(BLT_B^BLT_C)|(BLT_C&~BLT_A))&$ff))<<16,(a1)+
        move.l  (a0)+,bltcmod(a5) ; and bltbmod
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+        ; bltafwm/bltalwm
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_acd_merge
        move.l  #(BLTEN_ACD+((BLT_A|BLT_C)&$ff))<<16,bltcon0(a5)
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

.bq_acd_clear
        move.l  #(BLTEN_ACD+((~BLT_A&BLT_C)&$ff))<<16,bltcon0(a5)
        move.w  (a0)+,bltcmod(a5)
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        lea     bltcpt(a5),a1
        move.l  (a0)+,(a1)+     ; bltcpt
        addq.l  #4,a1
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_bonus_stuff_for_col5:
        ; copy stuff over
        move.l  pd_CurrP5BonusPlanePtr(a6),a1
        lea     (STENCIL_WIDTH/2)/8(a1),a1

        move.l  pd_CurrPlanesPtr(a6),a2
        lea     5*(KALEIDO_BUF_WIDTH/8)+(STENCIL_WIDTH/2)/8(a2),a2
        move.w  #((2*STENCIL_WIDTH)>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(2*STENCIL_WIDTH))/8,d6

        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_abcd_xor,(a4)+
        move.w  d6,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  pd_HexagonTopMaskPtr(a6),(a4)+  ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.l  pd_CurrPlanesPtr(a6),a2
        lea     5*(KALEIDO_BUF_WIDTH/8)(a2),a2  ; plane 6
        move.l  pd_CurrP5BottomPlanePtr(a6),a1
        move.l  pd_HexagonTopMaskPtr(a6),a0
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)+(STENCIL_WIDTH/2)/8(a1),a1
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)+(STENCIL_WIDTH/2)/8(a2),a2
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)(a0),a0

        move.w  #(2*STENCIL_WIDTH>>4)|((LAST_SLICE_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-2*STENCIL_WIDTH)/8,d6

        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_abcd_xor,(a4)+
        move.w  d6,(a4)+            ; bltcmod
        move.w  d6,(a4)+            ; bltbmod
        move.w  d6,(a4)+            ; bltamod
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  a0,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_abcd_xor
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_ABCD+(((BLT_A&BLT_B)|(BLT_C&~BLT_A))&$ff))<<16,(a1)+
        move.l  (a0)+,bltcmod(a5) ; and bltbmod
        move.l  (a0)+,bltamod(a5) ; and bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+        ; bltafwm/bltalwm
        move.l  (a0)+,(a1)+     ; bltcpt
        move.l  (a0)+,(a1)+     ; bltbpt
        move.l  (a0)+,(a1)+     ; bltapt
        move.l  (a0)+,(a1)+     ; bltdpt
        move.w  (a0)+,(a1)+     ; bltsize
        rts

;--------------------------------------------------------------------

kds_clear_bonus_stuff_for_col2:
        ; clear extra line stuff in bitplane 4 from col2/5
        move.w  #((STENCIL_WIDTH+(STENCIL_WIDTH/2))>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH+(STENCIL_WIDTH/2)))/8,d6

        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*(KALEIDO_BUF_WIDTH/8)+(3*STENCIL_WIDTH+(STENCIL_WIDTH/2))/8(a1),a1

        PREP_ADD_TO_BLITTER_QUEUE a3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_d_clear,(a4)+
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH/2)>>4)|((STENCIL_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH/2))/8,d6

        move.l  pd_CurrPlanesPtr(a6),a1
        lea     3*(KALEIDO_BUF_WIDTH/8)+(STENCIL_WIDTH/2)/8(a1),a1
        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        clr.l   (a4)+
        move.l  #.bq_d_clear,(a4)+
        move.w  d6,(a4)+            ; bltdmod
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_d_clear
        BLTCON_SET D,0,0,0
        move.w  (a0)+,bltdmod(a5)
        move.l  (a0)+,bltdpt(a5)
        move.w  (a0)+,bltsize(a5)
        rts

;--------------------------------------------------------------------

kds_draw_p5_flip13:
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)+(2*STENCIL_WIDTH)/8(a1),a1  ; plane 5
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a2    ; plane 6
        move.l  pd_CurrP5Xor6PlanePtr(a6),a0
        lea     (2*STENCIL_WIDTH/8)(a0),a0

        move.w  #((2*STENCIL_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-2*STENCIL_WIDTH)/8,d0

        PREP_ADD_TO_BLITTER_QUEUE a3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_abcd_with_all,(a4)+
        move.w  d0,(a4)+            ; bltcmod
        move.w  d0,(a4)+            ; bltbmod
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  pd_HexagonBottomMaskPtr(a6),(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-STENCIL_WIDTH)/8,d0
        lea     (2*STENCIL_WIDTH)/8(a1),a1
        lea     (2*STENCIL_WIDTH)/8(a0),a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_all,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((2*STENCIL_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-2*STENCIL_WIDTH)/8,d0
        lea     -(STENCIL_WIDTH)/8(a0),a0
        lea     -(3*STENCIL_WIDTH)/8(a0),a1

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_without_left,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a0,(a4)+            ; bltapt
        move.l  a1,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        rts

.bq_xor_abcd_with_all
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_ABCD+((BLT_C^(BLT_B&BLT_A))&$ff))<<16,(a1)+
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

.bq_copy_ad_with_all
        BLTCON0_SET AD,BLT_A,0
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

.bq_copy_ad_without_left
        BLTCON0_SET AD,BLT_A,0
        move.w  #$7fff,bltafwm(a5)
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_p5_flip134:
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)(a1),a1  ; plane 5
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a2    ; plane 6

        move.w  #((KALEIDO_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,d0

        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_abcd_with_all,(a4)+
        move.w  d0,(a4)+            ; bltcmod
        move.w  d0,(a4)+            ; bltbmod
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  pd_Hexagon2MaskPtr(a6),(a4)+    ; bltapt
        move.l  pd_CurrP5Xor6PlanePtr(a6),(a4)+ ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_xor_abcd_with_all
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_ABCD+(((BLT_A&BLT_C)|(~BLT_A&(BLT_C^BLT_B)))&$ff))<<16,(a1)+
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_p5_flip4_to_bonus:
        move.l  pd_CurrP5Xor6PlanePtr(a6),a1
        move.l  pd_CurrP5BonusPlanePtr(a6),a2

        move.w  #((KALEIDO_WIDTH-(STENCIL_WIDTH+STENCIL_WIDTH/2))>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(KALEIDO_WIDTH-(STENCIL_WIDTH+STENCIL_WIDTH/2)))/8,d0

        PREP_ADD_TO_BLITTER_QUEUE a3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_all,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltapt
        move.l  a2,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH+STENCIL_WIDTH/2)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH+STENCIL_WIDTH/2))/8,d0
        lea     (STENCIL_WIDTH/2)/8(a1),a1
        lea     (KALEIDO_WIDTH-(STENCIL_WIDTH+STENCIL_WIDTH/2))/8(a2),a2

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_all,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltapt
        move.l  a2,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        rts

.bq_copy_ad_with_all
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_AD+BLT_A)<<16,(a1)+
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        addq.l  #8,a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_p5_flip4_to_bottom:
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)(a1),a1  ; plane 5
        move.l  pd_CurrP5BottomPlanePtr(a6),a2
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)(a1),a1
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)(a2),a2

        move.w  #(KALEIDO_WIDTH>>4)|((LAST_SLICE_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,d0

        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_all,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltapt
        move.l  a2,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_copy_ad_with_all
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_AD+BLT_A)<<16,(a1)+
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        addq.l  #8,a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_p5_flip5_to_bottom:
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)(a1),a1  ; plane 5
        move.l  pd_CurrP5BottomPlanePtr(a6),a2
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)(a1),a1
        lea     (KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES*(KALEIDO_HEIGHT-LAST_SLICE_HEIGHT)(a2),a2

        move.w  #(KALEIDO_WIDTH>>4)|((LAST_SLICE_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,d0

        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_all,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltapt
        move.l  a2,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_copy_ad_with_all
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_AD+BLT_A)<<16,(a1)+
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        addq.l  #8,a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_p6_flip24:
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)+(STENCIL_WIDTH/2)/8(a1),a1  ; plane 5
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a2    ; plane 6
        move.l  pd_CurrP6Xor5PlanePtr(a6),a0
        lea     (STENCIL_WIDTH/2)/8(a0),a0

        move.w  #((2*STENCIL_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-2*STENCIL_WIDTH)/8,d0

        PREP_ADD_TO_BLITTER_QUEUE a3
        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_xor_abcd_with_all,(a4)+
        move.w  d0,(a4)+            ; bltcmod
        move.w  d0,(a4)+            ; bltbmod
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  pd_HexagonTopMaskPtr(a6),(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-STENCIL_WIDTH)/8,d0
        lea     (2*STENCIL_WIDTH)/8(a2),a2
        lea     (2*STENCIL_WIDTH)/8(a0),a0

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_all,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH+STENCIL_WIDTH/2)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-(STENCIL_WIDTH+STENCIL_WIDTH/2))/8,d0
        lea     (1*STENCIL_WIDTH)/8(a0),a0
        lea     -(3*STENCIL_WIDTH)/8(a0),a2

        FAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_with_mods,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        move.w  #((STENCIL_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-STENCIL_WIDTH)/8,d0
        lea     -(3*STENCIL_WIDTH+STENCIL_WIDTH/2)/8(a0),a0
        lea     (3*STENCIL_WIDTH)/8(a0),a2

        LAST_ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_copy_ad_without_left,(a4)+
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a2,(a4)+            ; bltapt
        move.l  a0,(a4)+            ; bltdpt
        move.w  d3,(a4)+            ; bltsize

        rts

.bq_xor_abcd_with_all
        lea     bltcon0(a5),a1
        move.l  #(BLTEN_ABCD+((BLT_B^(BLT_C&BLT_A))&$ff))<<16,(a1)+         ; bltcon0/1
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

.bq_copy_ad_with_all
        BLTCON0_SET AD,BLT_A,0
.bq_copy_ad_with_mods
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

.bq_copy_ad_without_left
        BLTCON0_SET AD,BLT_A,0
        move.w  #$7fff,bltafwm(a5)
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        lea     bltapt(a5),a1
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_draw_p6_flip2:
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     4*(KALEIDO_BUF_WIDTH/8)(a1),a1  ; plane 5
        lea     (KALEIDO_BUF_WIDTH/8)(a1),a2    ; plane 6

        move.w  #((KALEIDO_WIDTH)>>4)|((KALEIDO_HEIGHT)<<6),d3
        move.w  #(KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,d0

        ADD_TO_BLITTER_QUEUE a4,a3
        addq.l  #4,a4
        move.l  #.bq_generic_abcd_with_all,(a4)+
        move.l  #(BLTEN_ABCD+((BLT_B^(BLT_C&BLT_A))&$ff))<<16,(a4)+
        move.w  d0,(a4)+            ; bltcmod
        move.w  d0,(a4)+            ; bltbmod
        move.w  d0,(a4)+            ; bltamod
        move.w  d0,(a4)+            ; bltdmod

        move.l  a1,(a4)+            ; bltcpt
        move.l  a2,(a4)+            ; bltbpt
        move.l  pd_HexagonTopMaskPtr(a6),(a4)+   ; bltapt
        move.l  pd_CurrP6Xor5PlanePtr(a6),(a4)+ ; bltdpt
        move.w  d3,(a4)+            ; bltsize
        rts

.bq_generic_abcd_with_all
        lea     bltcon0(a5),a1
        move.l  (a0)+,(a1)+         ; bltcon0/1
        move.l  (a0)+,bltcmod(a5)   ; bltcmod/bltbmod
        move.l  (a0)+,bltamod(a5)   ; bltamod/bltdmod
        moveq.l #-1,d0
        move.l  d0,(a1)+            ; bltafwm/bltalwm
        move.l  (a0)+,(a1)+         ; bltcpt
        move.l  (a0)+,(a1)+         ; bltbpt
        move.l  (a0)+,(a1)+         ; bltapt
        move.l  (a0)+,(a1)+         ; bltdpt
        move.w  (a0)+,(a1)+         ; bltsize
        rts

;--------------------------------------------------------------------

kds_calc_spline_pos:
        move.w  pd_SplinePos(a6),d0
        addq.w  #2,d0
        move.w  d0,pd_SplinePos(a6)
        move.w  #(SPLINE_TABLE_SIZE-1)*2,d1
        and.w   d0,d1
        lea     kds_bernstein0(pc),a0
        adda.w  d1,a0

        lsr.w   #6,d0
        and.w   #-4,d0
        move.w  d0,d1
        add.w   d1,d1
        add.w   d0,d1   ; *12
        lea     kds_fairy_points(pc),a1
        movem.w (a1,d1.w),d0-d7
        PUTMSG  20,<"%d,%d %d,%d %d,%d %d,%d">,d0,d1,d2,d3,d4,d5,d6,d7
        mulu    (a0),d0
        mulu    (a0),d1
        mulu    kds_bernstein1-kds_bernstein0(a0),d2
        mulu    kds_bernstein1-kds_bernstein0(a0),d3
        add.l   d2,d0
        add.l   d3,d1
        move.w  kds_bernstein2-kds_bernstein0(a0),d2
        mulu    d2,d4
        mulu    d2,d5
        add.l   d4,d0
        add.l   d5,d1
        move.w  kds_bernstein3-kds_bernstein0(a0),d2
        mulu    d2,d6
        mulu    d2,d7
        add.l   d6,d0
        add.l   d7,d1
        move.l  #$8000,d2
        add.l   d2,d0
        add.l   d2,d1
        swap    d0
        swap    d1
        PUTMSG  20,<"XY %d,%d">,d0,d1
        sub.w   #KALEIDO_WIDTH/2,d0
        sub.w   #KALEIDO_VHEIGHT/2,d1
        move.w  d0,d3
        move.w  d1,d4
        move.w  d0,pd_FairyPosX(a6)
        move.w  d1,pd_FairyPosY(a6)

        bsr.s   .plant
        move.w  pd_FairyPosX(a6),d3
        move.w  pd_FairyPosY(a6),d4

.plant
        lea     pd_BackDust(a6),a1
        move.w  pd_NextBackDustOffset(a6),d2
        add.w   #fd_SIZEOF,d2
        cmp.w   #fd_SIZEOF*NUM_BACK_DUST,d2
        bne.s   .cont
        moveq.l #0,d2
.cont   move.w  d2,pd_NextBackDustOffset(a6)
        adda.w  d2,a1

        move.l  pd_NoiseValueA(a6),d0
        move.l  pd_NoiseValueB(a6),d1
        lea     kds_dust_pos(pc),a0
        moveq.l #15,d2
        and.w   d0,d2
        add.w   d2,d2
        PUTMSG  20,<"Dustpos %d">,d2
        add.w   (a0,d2.w),d3
        add.w   2*16(a0,d2.w),d4
        moveq.l #31,d2
        and.w   d1,d2
        add.w   #32,d2
        move.w  d2,fd_Time(a1)
        move.w  d3,fd_PosX(a1)
        move.w  d4,fd_PosY(a1)

        move.l  d1,d2
        swap    d2
        add.l   d0,d1
        add.l   d2,d0
        move.l  d0,pd_NoiseValueA(a6)
        move.l  d1,pd_NoiseValueB(a6)

        swap    d0
        swap    d1
        asr.w   #1,d0
        asr.w   #2,d1
        ext.l   d0
        ext.l   d1
        move.l  d0,fd_SpeedX(a1)
        move.l  d1,fd_SpeedY(a1)

        rts

;--------------------------------------------------------------------

kds_update_fairy_sprite:
        move.w  pd_FairyPosX(a6),d4
        move.w  pd_FairyPosY(a6),d1

        IF      0
        move.w  pd_FairySpriteFrame(a6),d0
        add.w   #8*4,d0
        and.w   #3*(8*4),d0
        move.w  d0,pd_FairySpriteFrame(a6)

        lea     pd_FairySprites1(a6),a2
        adda.w  d0,a2
        move.l  a2,pd_CurrFairySprite(a6)
        ENDC

        move.l  pd_CurrFairySprite(a6),a2
        add.w   #128-(FAIRY_WIDTH/2),d4
        add.w   #$52-(FAIRY_HEIGHT/2),d1
        ;add.w   #$52,d1

        move.w  d1,d2
        add.w   #FAIRY_HEIGHT,d2
        moveq.l #0,d0

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d0,d0       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d0,d0       ; ev8
        lsr.w   #1,d4       ; sh8-sh1 in d4
        addx.w  d0,d0       ; sh0
        or.w    d2,d0       ; ev7-ev0, sv8, ev8, sh0 in d0
        or.w    d1,d4       ; sv7-sv0, sh8-sh1 in d4
        tas     d0          ; att TAS sets bit 7
.filldata
        REPT    (FAIRY_WIDTH/16)
        move.l  (a2)+,a0
        move.l  (a2)+,a1
        move.w  d4,(a0)+
        move.w  d0,(a0)+
        move.w  d4,(a1)+
        move.w  d0,(a1)+
        addq.w  #8,d4
        ENDR
        rts

;--------------------------------------------------------------------

kds_update_stencil_sprite:
        move.l  pd_CurrSpriteStencilPtr(a6),a2
        move.w  #128+96,d0
        move.w  #$52+37,d1
        move.w  d1,d2
        add.w   #INTRO_SPRITE_SHEIGHT,d2
        moveq.l #0,d3

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d3,d3       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d3,d3       ; ev8
        lsr.w   #1,d0       ; sh8-sh1 in d0
        addx.w  d3,d3       ; sh0
        or.w    d2,d3       ; ev7-ev0, sv8, ev8, sh0 in d3
        or.w    d1,d0       ; sv7-sv0, sh8-sh1 in d0
        ;tas     d3          ; att TAS sets bit 7
.filldata
        REPT    8
        move.l  (a2)+,a0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        addq.w  #8,d0
        ENDR
        rts

;--------------------------------------------------------------------

kds_update_stencil_pre_main_sprite:
        move.l  pd_CurrSpriteStencilPtr(a6),a2
        move.w  #128,d0
        move.w  #$52,d1
        move.w  d1,d2
        add.w   #INTRO_SPRITE_HEIGHT,d2
        moveq.l #0,d3

        lsl.w   #8,d1       ; sv7-sv0 in d1
        addx.w  d3,d3       ; sv8
        lsl.w   #8,d2       ; ev7-ev0 in d2
        addx.w  d3,d3       ; ev8
        lsr.w   #1,d0       ; sh8-sh1 in d0
        addx.w  d3,d3       ; sh0
        or.w    d2,d3       ; ev7-ev0, sv8, ev8, sh0 in d3
        or.w    d1,d0       ; sv7-sv0, sh8-sh1 in d0
        ;tas     d3          ; att TAS sets bit 7
.filldata
        REPT    8
        move.l  (a2)+,a0
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        addq.w  #8,d0
        ENDR
        rts

;--------------------------------------------------------------------

kds_kill_stencil_sprite:
        move.l  pd_CurrSpriteStencilPtr(a6),a2
        moveq.l #0,d0
        REPT    8
        move.l  (a2)+,a0
        move.l  d0,(a0)
        ENDR
        rts

;--------------------------------------------------------------------

kds_update_sprites_and_cols_in_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  pd_CurrFairySprite(a6),a1
        move.w  #sprpt,d1
        moveq.l #(FAIRY_WIDTH/16)*4-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        lea     pd_IntroPalette(a6),a1
        REPT    8
        move.w  REPTN*cl_SIZEOF+cl_Color(a1),REPTN*4+2(a0)
        ENDR
        rts

;--------------------------------------------------------------------

kds_update_sprites_in_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  pd_CurrFairySprite(a6),a1
        move.w  #sprpt,d1
        moveq.l #(INTRO_SPRITE_WIDTH/16)*2-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop
        rts

;--------------------------------------------------------------------

kds_create_intro_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0

        move.l  pd_CurrFairySprite(a6),a1
        move.w  #sprpt,d1
        moveq.l #(FAIRY_WIDTH/16)*4-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        lea     pd_IntroPalette(a6),a1
        moveq.l #8-1,d7
        move.w  #color,d0
.blloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.blloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        ; screen width : 128 -> offset +96
        ; screen height: 53*2-1 = 105 -> offset +37
        COPIMOVE $3200,bplcon0
        COPIMOVE $0081+((($52+37)&$ff)<<8),diwstrt
        COPIMOVE $00c1+((($06-38)&$ff)<<8),diwstop
        COPIMOVE $0038+(96/2),ddfstrt
        COPIMOVE $00d0-(96/2),ddfstop

        move.l  pd_CurrPlanesPtr(a6),d0
        add.l   #1*(KALEIDO_BUF_WIDTH/8),d0 ; select p2/p3/p4
        moveq.l #KALEIDO_BUF_WIDTH/8,d2
        move.w  #bplpt,d1
        moveq.l #3-1,d7
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

        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod

        move.w  #$0037+((($51)&$ff)<<8),d0
        move.w  #$100,d2
        moveq.l #37+STENCIL_HEIGHT,d7
        bsr     .dolines

        move.w  #$07+((($51+37+STENCIL_HEIGHT)&$ff)<<8),(a0)+
        move.w  d3,(a0)+

        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod

        moveq.l #STENCIL_HEIGHT,d7
        bsr     .dolines

        move.l  d3,(a0)+
        rts
.dolines
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $0000,bpldat+2*2
        COPIMOVE $0000,bpldat+1*2
        COPIMOVE $0000,bpldat

        add.w   d2,d0
        dbra    d7,.cprloop
        rts

;--------------------------------------------------------------------

kds_create_transition_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2

        move.l  pd_CurrFairySprite(a6),a1
        move.w  #sprpt,d1
        moveq.l #(FAIRY_WIDTH/16)*4-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        ; screen width : 128 -> offset +96
        ; screen height: 53*2-1 = 105 -> offset +37
        COPIMOVE $0081+((($52+37)&$ff)<<8),diwstrt
        COPIMOVE $00c1+((($06-38)&$ff)<<8),diwstop
        COPIMOVE $0038+(96/2),ddfstrt
        COPIMOVE $00d0-(96/2),ddfstop

        move.w  pd_TransitionHeight(a6),d4
        beq.s   .noham
        move.l  pd_CurrPlanesPtr(a6),d0
        addq.l  #(128/8)/2,d0
        addq.l  #(128/8)/2,d0
        move.w  #$6a00,d3
        moveq.l #KALEIDO_PLANES-1,d7
        bra.s   .didham
.noham
        bsr     .dopal
        move.w  #$4200,d3
        moveq.l #4-1,d7
        move.l  pd_CurrPlanesPtr(a6),d0
.didham
        COPRMOVE d3,bplcon0
        moveq.l #KALEIDO_BUF_WIDTH/8,d2
        move.w  #bplpt,d1
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
        move.w  #$00d5+((($51+37)&$ff)<<8),d0
        move.w  #$100,d2

        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset1(a6)

        move.w  d4,d7
        beq.s   .skip1
        cmp.w   #STENCIL_HEIGHT,d7
        blt.s   .nomax1
        moveq.l #STENCIL_HEIGHT,d7
.nomax1 subq.w  #1,d7
        bsr     .dolines

        cmp.w   #STENCIL_HEIGHT,d4
        bgt.s   .skip1b
        blt.s   .normalskip
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128-128)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128-128)/8,bpl2mod
        bra.s   .matchskip
.normalskip
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128-128)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128-128)/8,bpl2mod
.matchskip
        move.w  d0,d1
        move.b  #$c1,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+

        COPIMOVE $4200,bplcon0

        cmp.w   #STENCIL_HEIGHT,d4
        bne.s   .normalskip2
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod
        bra.s   .matchskip2
.normalskip2
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod
.matchskip2
        bsr     .dopal

        cmp.w   #STENCIL_HEIGHT,d4
        beq.s   .modsset
.skip1
        move.w  #$07+((($51+37+STENCIL_HEIGHT)&$ff)<<8),(a0)+
        move.w  d3,(a0)+
.skip1b
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod
.modsset
        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset2(a6)

        move.w  d4,d7
        sub.w   #STENCIL_HEIGHT,d7
        ble.s   .skip2
        subq.w  #1,d7
        bsr     .dolines

        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128-128)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128-128)/8,bpl2mod
        move.w  d0,d1
        move.b  #$c1,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+

        COPIMOVE $4200,bplcon0
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-128)/8,bpl2mod

        bsr.s   .dopal
.skip2

        move.l  d3,(a0)+
        rts

.dolines
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $400,(color+1*2)
        COPIMOVE $080,(color+2*2)
        COPIMOVE $00c,(color+3*2)

        add.w   d2,d0
        dbra    d7,.cprloop
        rts

.dopal
        lea     kds_intro_palette(pc),a1
        moveq.l #8-1,d7
        move.w  #color,d0
.blloop
        move.w  d0,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #4,d0
        dbra    d7,.blloop
        rts

;--------------------------------------------------------------------

kds_create_pre_main_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        move.l  pd_CurrFairySprite(a6),a1
        move.w  #sprpt,d1
        moveq.l #(FAIRY_WIDTH/16)*4-1,d7
.sprloop
        move.w  d1,(a0)+
        move.w  (a1)+,(a0)+
        addq.w  #2,d1
        dbra    d7,.sprloop

        COPIMOVE DMAF_SETCLR|DMAF_SPRITE,dmacon ; enable sprite dma

        move.l  #$1fe0000,d4

        COPIMOVE $6a00,bplcon0
        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #KALEIDO_PLANES-1,d7
        move.w  #bplpt,d1
        moveq.l #KALEIDO_BUF_WIDTH/8,d2
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

        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset1(a6)

        moveq.l #STENCIL_HEIGHT-1,d7
        bsr     .dolines

        ;COPIMOVE $0200,bplcon0
        ;move.l  d3,(a0)+

        move.l  a0,d1
        sub.l   a2,d1
        move.w  d1,pd_CopperMirror1P5PtrOffset(a6)

        move.l  d4,(a0)+
        move.l  d4,(a0)+

        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset2(a6)

        moveq.l #STENCIL_HEIGHT-1-1,d7
        bsr     .dolines

        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset3(a6)

        moveq.l #STENCIL_HEIGHT-1-1,d7
        bsr     .dolines

        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset4(a6)

        moveq.l #(LAST_SLICE_HEIGHT)-1,d7
        bsr     .dolines

        move.l  d3,(a0)+
        rts

.dolines
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        add.w   d2,d0
        COPIMOVE $346,(color+6*2)
        COPIMOVE $346,(color+1*2)
        COPIMOVE $346,(color+2*2)
        COPIMOVE $346,(color+3*2)
        COPIMOVE $346,(color+4*2)
        COPIMOVE $346,(color+7*2)
        COPIMOVE $346,(color+5*2)

        move.w  d0,d1
        move.b  #$1b,d1
        move.w  d1,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $5240,spr+sd_pos+0*sd_SIZEOF
        COPIMOVE $5248,spr+sd_pos+1*sd_SIZEOF
        COPIMOVE $5250,spr+sd_pos+2*sd_SIZEOF
        COPIMOVE $5258,spr+sd_pos+3*sd_SIZEOF
        COPIMOVE $5260,spr+sd_pos+4*sd_SIZEOF
        COPIMOVE $5268,spr+sd_pos+5*sd_SIZEOF
        COPIMOVE $5270,spr+sd_pos+6*sd_SIZEOF
        COPIMOVE $5278,spr+sd_pos+7*sd_SIZEOF

        COPIMOVE $5280,spr+sd_pos+0*sd_SIZEOF
        COPIMOVE $5288,spr+sd_pos+1*sd_SIZEOF
        COPIMOVE $5290,spr+sd_pos+2*sd_SIZEOF
        COPIMOVE $5298,spr+sd_pos+3*sd_SIZEOF
        COPIMOVE $52a0,spr+sd_pos+4*sd_SIZEOF
        COPIMOVE $52a8,spr+sd_pos+5*sd_SIZEOF
        COPIMOVE $52b0,spr+sd_pos+6*sd_SIZEOF
        COPIMOVE $52b8,spr+sd_pos+7*sd_SIZEOF

        COPIMOVE $52c0,spr+sd_pos+0*sd_SIZEOF
        COPIMOVE $52c8,spr+sd_pos+1*sd_SIZEOF
        COPIMOVE $52d0,spr+sd_pos+2*sd_SIZEOF
        COPIMOVE $52d8,spr+sd_pos+3*sd_SIZEOF

        dbra    d7,.cprloop
        rts

;--------------------------------------------------------------------

kds_create_kaleidoscope_copperlist:
        move.l  pd_CurrCopListPtr(a6),a0
        move.l  a0,a2
        move.l  #$1fe0000,d4

        COPIMOVE DMAF_SPRITE,dmacon ; disable sprite dma

        COPIMOVE $6a00,bplcon0
        move.l  pd_CurrPlanesPtr(a6),d0
        moveq.l #KALEIDO_PLANES-1,d7
        move.w  #bplpt,d1
        moveq.l #KALEIDO_BUF_WIDTH/8,d2
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

        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset1(a6)

        moveq.l #STENCIL_HEIGHT-1,d7
        bsr     .dolines

        move.l  a0,d1
        sub.l   a2,d1
        move.w  d1,pd_CopperMirror1P5PtrOffset(a6)

        move.l  d4,(a0)+
        move.l  d4,(a0)+

        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset2(a6)

        moveq.l #STENCIL_HEIGHT-1-1,d7
        bsr     .dolines

        move.l  a0,d1
        sub.l   a2,d1
        move.w  d1,pd_CopperMirror2P56PtrOffset(a6)

        move.l  d4,(a0)+
        move.l  d4,(a0)+
        move.l  d4,(a0)+
        move.l  d4,(a0)+

        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset3(a6)

        moveq.l #STENCIL_HEIGHT-1-1,d7
        bsr     .dolines

        move.l  a0,d1
        sub.l   a2,d1
        move.w  d1,pd_CopperMirror3P5PtrOffset(a6)

        move.l  d4,(a0)+
        move.l  d4,(a0)+

        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl1mod
        COPIMOVE (-1*KALEIDO_BUF_WIDTH*KALEIDO_PLANES-KALEIDO_WIDTH)/8,bpl2mod

        move.l  a0,d1
        sub.l   a2,d1
        addq.w  #4+2,d1
        move.w  d1,pd_CopperLinesFixupOffset4(a6)

        moveq.l #(LAST_SLICE_HEIGHT)-1,d7
        bsr     .dolines

        move.l  d3,(a0)+
        rts
.dolines
.cprloop
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        COPIMOVE $346,(color+6*2)
        COPIMOVE $346,(color+1*2)
        COPIMOVE $346,(color+2*2)
        COPIMOVE $346,(color+3*2)
        COPIMOVE $346,(color+4*2)
        COPIMOVE $346,(color+7*2)
        COPIMOVE $346,(color+5*2)

        COPIMOVE $346,(color+14*2)
        COPIMOVE $346,(color+9*2)
        COPIMOVE $346,(color+10*2)

        add.w   d2,d0
        dbra    d7,.cprloop
        rts

;--------------------------------------------------------------------

kds_calc_true_color_image:
        PUTMSG  10,<"TC Image %p">,a1
        move.w  #KDSPAT_HEIGHT,-(sp)
.lineloop
        moveq.l #(KDSPAT_WIDTH/16)-1,d7
        move.w  (a2),d6               ; background color
        swap    d6
.wordloop
        move.w  5*(KDSPAT_WIDTH/8)(a0),d5
        move.w  4*(KDSPAT_WIDTH/8)(a0),d4
        move.w  3*(KDSPAT_WIDTH/8)(a0),d3
        move.w  2*(KDSPAT_WIDTH/8)(a0),d2
        move.w  1*(KDSPAT_WIDTH/8)(a0),d1
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
        bcc.s   .blue
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

.blue   add.w   d4,d4
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
        lea     5*(KDSPAT_WIDTH/8)(a0),a0
        subq.w  #1,(sp)
        bne     .lineloop
        addq.w  #2,sp
        rts

;--------------------------------------------------------------------

;--------------------------------------------------------------------

;--------------------------------------------------------------------
; a0: SMC buffer
; d0-d3: x1,y1 - x2,y2
; d4: lineinc
; d7 high word not trashed
kds_bresenham_smc_line_draw:
        PUTMSG  10,<"SMC Buffer %p">,a0
        moveq.l #2,d5
        sub.w   d1,d3
        sub.w   d0,d2
        bpl.s   .rightwards
        moveq.l #-2,d5
        neg.w   d2
.rightwards
        add.w   d0,d0

        move.w  d3,d1       ; error term
        move.w  d3,d7
        add.w   d2,d2       ; dx * 2
        add.w   d3,d3       ; dy * 2

.lineloop
        move.w  #$32e8,(a0)+    ; move.w x(a0),(a1)+
        move.w  d0,(a0)+
        add.w   d4,d0
        sub.w   d2,d1
        dble    d7,.lineloop
        add.w   d3,d1
        add.w   d5,d0
        subq.w  #1,d7
        bpl.s   .lineloop
.done1
        move.w  #$4e75,(a0)+    ; rts
        rts

kds_setting1_coplist:
kds_setting2_coplist:
        move.l  pd_CurrCopListPtr(a6),a2

        move.l  a2,a0
        move.w  #$1fe,d0
        adda.w  pd_CopperMirror1P5PtrOffset(a6),a0
        move.w  d0,(a0)
        move.w  d0,4(a0)

        move.l  a2,a0
        adda.w  pd_CopperMirror2P56PtrOffset(a6),a0
        move.w  d0,(a0)
        move.w  d0,4(a0)
        move.w  d0,8(a0)
        move.w  d0,12(a0)

        adda.w  pd_CopperMirror3P5PtrOffset(a6),a2
        move.w  d0,(a2)
        move.w  d0,4(a2)
        rts

kds_setting3_coplist:
        move.l  pd_CurrCopListPtr(a6),a2

        move.l  a2,a0
        adda.w  pd_CopperMirror1P5PtrOffset(a6),a0
        move.l  pd_CurrP5Xor6PlanePtr(a6),a1
        lea     (STENCIL_HEIGHT-1)*(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES(a1),a1
        move.l  a1,d0
        swap    d0
        move.w  #bplpt+4*4,(a0)+
        move.w  d0,(a0)+
        move.w  #bplpt+4*4+2,(a0)+
        move.w  a1,(a0)+

        move.w  #$1fe,d0
        move.l  a2,a0
        adda.w  pd_CopperMirror2P56PtrOffset(a6),a0
        move.w  d0,(a0)
        move.w  d0,4(a0)
        move.w  d0,8(a0)
        move.w  d0,12(a0)

        adda.w  pd_CopperMirror3P5PtrOffset(a6),a2
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     (STENCIL_HEIGHT-1)*(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES+4*(KALEIDO_BUF_WIDTH/8)(a1),a1
        move.l  a1,d0
        swap    d0
        move.w  #bplpt+4*4,(a2)+
        move.w  d0,(a2)+
        move.w  #bplpt+4*4+2,(a2)+
        move.w  a1,(a2)+
        rts

kds_setting4_coplist:
        move.l  pd_CurrCopListPtr(a6),a2

        move.l  a2,a0
        adda.w  pd_CopperMirror1P5PtrOffset(a6),a0
        move.l  pd_CurrP5Xor6PlanePtr(a6),a1
        lea     (STENCIL_HEIGHT-1)*(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES(a1),a1
        move.l  a1,d0
        swap    d0
        move.w  #bplpt+4*4,(a0)+
        move.w  d0,(a0)+
        move.w  #bplpt+4*4+2,(a0)+
        move.w  a1,(a0)+

        move.l  a2,a0
        adda.w  pd_CopperMirror2P56PtrOffset(a6),a0
        move.w  #bplpt+5*4,(a0)+
        move.w  pd_CurrP6Xor5PlanePtr(a6),(a0)+
        move.w  #bplpt+5*4+2,(a0)+
        move.w  pd_CurrP6Xor5PlanePtr+2(a6),(a0)+

        move.w  #$1fe,d0
        move.w  d0,(a0)
        move.w  d0,4(a0)

        adda.w  pd_CopperMirror3P5PtrOffset(a6),a2
        move.l  pd_CurrPlanesPtr(a6),a1
        lea     (STENCIL_HEIGHT-1)*(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES+4*(KALEIDO_BUF_WIDTH/8)(a1),a1
        move.l  a1,d0
        swap    d0
        move.w  #bplpt+4*4,(a2)+
        move.w  d0,(a2)+
        move.w  #bplpt+4*4+2,(a2)+
        move.w  a1,(a2)+
        rts

kds_setting5_coplist:
kds_setting6_coplist:
        move.l  pd_CurrCopListPtr(a6),a2

        move.l  a2,a0
        adda.w  pd_CopperMirror1P5PtrOffset(a6),a0
        move.l  pd_CurrP5Xor6PlanePtr(a6),a1
        lea     (STENCIL_HEIGHT-1)*(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES(a1),a1
        move.l  a1,d0
        swap    d0
        move.w  #bplpt+4*4,(a0)+
        move.w  d0,(a0)+
        move.w  #bplpt+4*4+2,(a0)+
        move.w  a1,(a0)+

        move.l  a2,a0
        adda.w  pd_CopperMirror2P56PtrOffset(a6),a0
        move.w  #bplpt+4*4,(a0)+
        move.w  pd_CurrP5BonusPlanePtr(a6),(a0)+
        move.w  #bplpt+4*4+2,(a0)+
        move.w  pd_CurrP5BonusPlanePtr+2(a6),(a0)+
        move.w  #bplpt+5*4,(a0)+
        move.w  pd_CurrP6Xor5PlanePtr(a6),(a0)+
        move.w  #bplpt+5*4+2,(a0)+
        move.w  pd_CurrP6Xor5PlanePtr+2(a6),(a0)+

        adda.w  pd_CopperMirror3P5PtrOffset(a6),a2
        move.l  pd_CurrP5BottomPlanePtr(a6),a1
        lea     (STENCIL_HEIGHT-1)*(KALEIDO_BUF_WIDTH/8)*KALEIDO_PLANES(a1),a1
        move.l  a1,d0
        swap    d0
        move.w  #bplpt+4*4,(a2)+
        move.w  d0,(a2)+
        move.w  #bplpt+4*4+2,(a2)+
        move.w  a1,(a2)+
        rts

kds_setting1_draw:
        bsr     kds_draw_stencils_col0000
        bra     kds_draw_stencils_copy_edges

kds_setting2_draw:
        bsr     kds_draw_stencils_col1010
        bra     kds_draw_stencils_copy_edges

kds_setting3_draw:
        bsr     kds_draw_stencils_col1010
        bsr     kds_draw_stencils_copy_edges
        bra     kds_draw_p5_flip13

kds_setting4_draw:
        bsr     kds_draw_stencils_col1010
        bsr     kds_draw_stencils_copy_edges
        bsr     kds_draw_p5_flip13
        bra     kds_draw_p6_flip24

kds_setting5_draw:
        pea     kds_draw_bonus_stuff_for_col2(pc)
        pea     kds_draw_p6_flip24(pc)
        pea     kds_draw_p5_flip4_to_bottom(pc)
        pea     kds_draw_p5_flip4_to_bonus(pc)
        pea     kds_draw_p5_flip134(pc)
        pea     kds_draw_stencils_copy_edges(pc)

        bra     kds_draw_stencils_col1010

kds_setting6_draw:
        pea     kds_draw_bonus_stuff_for_col5(pc)
        pea     kds_draw_bonus_stuff_for_col2(pc)
        pea     kds_draw_p6_flip24(pc)
        pea     kds_draw_p5_flip5_to_bottom(pc)
        pea     kds_draw_p5_flip4_to_bonus(pc)
        pea     kds_draw_p5_flip134(pc)
        pea     kds_draw_stencils_copy_edges(pc)

        bra     kds_draw_stencils_col1010

kds_setting_nop:
        rts

;--------------------------------------------------------------------

        include "blitterline_sync.asm"

;********************************************************************

LCOLDEF MACRO
        IF      \1==0
        dc.w    (\2)*LCOLBUF_HEIGHT*2
        dc.w    (\3)*LCOLBUF_HEIGHT*2
        dc.w    (\4)*LCOLBUF_HEIGHT*2
        dc.w    (\5)*LCOLBUF_HEIGHT*2
        dc.w    (\6)*LCOLBUF_HEIGHT*2
        dc.w    (\7)*LCOLBUF_HEIGHT*2
        dc.w    (\8)*LCOLBUF_HEIGHT*2
        dc.w    (\2)*LCOLBUF_HEIGHT*2
        dc.w    (\3)*LCOLBUF_HEIGHT*2
        dc.w    (\4)*LCOLBUF_HEIGHT*2
        ENDC
        IF      \1==1
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\2)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\3)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\4)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\5)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\6)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\7)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\8)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\2)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\3)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\4)*LCOLBUF_HEIGHT*2
        ENDC
        IF      \1==2
        dc.w    2+(\2)*LCOLBUF_HEIGHT*2
        dc.w    2+(\3)*LCOLBUF_HEIGHT*2
        dc.w    2+(\4)*LCOLBUF_HEIGHT*2
        dc.w    2+(\5)*LCOLBUF_HEIGHT*2
        dc.w    2+(\6)*LCOLBUF_HEIGHT*2
        dc.w    2+(\7)*LCOLBUF_HEIGHT*2
        dc.w    2+(\8)*LCOLBUF_HEIGHT*2
        dc.w    2+(\2)*LCOLBUF_HEIGHT*2
        dc.w    2+(\3)*LCOLBUF_HEIGHT*2
        dc.w    2+(\4)*LCOLBUF_HEIGHT*2
        ENDC
        ENDM

LCOLDEX MACRO
        IF      \1==0
        dc.w    (\2)*LCOLBUF_HEIGHT*2
        dc.w    (\3)*LCOLBUF_HEIGHT*2
        dc.w    (\4)*LCOLBUF_HEIGHT*2
        dc.w    (\5)*LCOLBUF_HEIGHT*2
        dc.w    (\6)*LCOLBUF_HEIGHT*2
        dc.w    (\7)*LCOLBUF_HEIGHT*2
        dc.w    (\8)*LCOLBUF_HEIGHT*2
        dc.w    (\9)*LCOLBUF_HEIGHT*2
        dc.w    (\a)*LCOLBUF_HEIGHT*2
        dc.w    (\b)*LCOLBUF_HEIGHT*2
        ENDC
        IF      \1==1
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\2)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\3)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\4)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\5)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\6)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\7)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\8)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\9)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\a)*LCOLBUF_HEIGHT*2
        dc.w    \1*((STENCIL_HEIGHT-1)*2-2)+(\b)*LCOLBUF_HEIGHT*2
        ENDC
        IF      \1==2
        dc.w    2+(\2)*LCOLBUF_HEIGHT*2
        dc.w    2+(\3)*LCOLBUF_HEIGHT*2
        dc.w    2+(\4)*LCOLBUF_HEIGHT*2
        dc.w    2+(\5)*LCOLBUF_HEIGHT*2
        dc.w    2+(\6)*LCOLBUF_HEIGHT*2
        dc.w    2+(\7)*LCOLBUF_HEIGHT*2
        dc.w    2+(\8)*LCOLBUF_HEIGHT*2
        dc.w    2+(\9)*LCOLBUF_HEIGHT*2
        dc.w    2+(\a)*LCOLBUF_HEIGHT*2
        dc.w    2+(\b)*LCOLBUF_HEIGHT*2
        ENDC

        ENDM

kds_setting_1:
        dc.l    kds_setting1_coplist
        dc.l    kds_setting1_draw
        dc.l    kds_calc_stencil_fixup_lines_bonus
        dc.l    kds_setting_nop,kds_setting_nop,kds_setting_nop
        dc.l    kds_calc_stencil_positions1_std,kds_calc_stencil_positions2_std
        LCOLDEF 0,0,4,8,12,16,20,24
        LCOLDEF 1,0,4,8,12,16,20,24
        LCOLDEF 2,0,4,8,12,16,20,24
        LCOLDEF 1,0,4,8,12,16,20,24

kds_setting_2:
        dc.l    kds_setting2_coplist
        dc.l    kds_setting2_draw
        dc.l    kds_calc_stencil_fixup_lines_bonus
        dc.l    kds_setting_nop,kds_swap_rgb_to_bgr,kds_setting_nop
        dc.l    kds_calc_stencil_positions1_std,kds_calc_stencil_positions2_std
        LCOLDEF 0,0,4,8,12,16,20,24
        LCOLDEF 1,0,4,8,12,16,20,24
        LCOLDEF 2,0,4,8,12,16,20,24
        LCOLDEF 1,0,4,8,12,16,20,24

kds_setting_3:
        dc.l    kds_setting3_coplist
        dc.l    kds_setting3_draw
        dc.l    kds_calc_stencil_fixup_lines_bonus
        dc.l    kds_setting_nop,kds_swap_rgb_to_bgr_and_gbr,kds_setting_nop
        dc.l    kds_calc_stencil_positions1_std,kds_calc_stencil_positions2_std
        LCOLDEF 0,0,4,8,12,16,20,24
        LCOLDEF 1,0,4,8,13,17,21,25
        LCOLDEF 2,0,4,8,13,17,21,25
        LCOLDEF 1,0,4,8,12,16,20,24

kds_setting_4:
        dc.l    kds_setting4_coplist
        dc.l    kds_setting4_draw
        dc.l    kds_calc_stencil_fixup_lines_bonus
        dc.l    kds_swap_rgb_to_rbg,kds_swap_rgb_to_bgr_and_gbr,kds_setting_nop
        dc.l    kds_calc_stencil_positions1_std,kds_calc_stencil_positions2_std
        LCOLDEF 0,0,4,8,12,16,20,24
        LCOLDEF 1,0,4,8,13,17,21,25
        LCOLDEF 2,1,5,9,13,17,21,25
        LCOLDEF 1,1,5,9,12,16,20,24

kds_setting_5:
        dc.l    kds_setting5_coplist
        dc.l    kds_setting5_draw
        dc.l    kds_calc_stencil_fixup_lines_bonus
        dc.l    kds_swap_rgb_to_rbg_and_grb,kds_swap_rgb_to_bgr_and_gbr,kds_setting_nop
        dc.l    kds_calc_stencil_positions1_std,kds_calc_stencil_positions2_std
        LCOLDEX 0,0,4,8,12,16,20,24,2,6,10
        LCOLDEX 1,0,4,8,13,17,21,25,2,6,10
        LCOLDEX 2,1,5,9,13,17,21,25,1,5,9
        LCOLDEX 1,1,5,9,12,16,20,24,1,5,9

kds_setting_6:
        dc.l    kds_setting6_coplist
        dc.l    kds_setting6_draw
        dc.l    kds_calc_stencil_fixup_lines_bonus
        dc.l    kds_swap_rgb_to_rbg_and_grb_and_brg,kds_swap_rgb_to_bgr_and_gbr,kds_setting_nop
        dc.l    kds_calc_stencil_positions1_std,kds_calc_stencil_positions2_std
        LCOLDEX 0,0,4,8,12,16,20,24,2,6,10
        LCOLDEX 1,0,4,8,13,17,21,25,2,6,10
        LCOLDEX 2,3,7,11,13,17,21,25,1,5,9
        LCOLDEX 1,3,7,11,12,16,20,24,1,5,9

;********************************************************************

kds_intro_palette:
        dc.w    $346,$458,$89b,$89b,$bbe,$bbe,$9ac,$9ac

kds_bright_transition_palette:
        dc.w    $68c,$68c,$9f4,$9f4,$fff,$fff,$ffc,$ffc

kds_fairy_sprite_palette:
        incbin  "../data/kaleidoscope/fairy1_48x51x16.PAL"

        ; Points
kds_fairy_points:
        dc.w    129,239,183,208,225,103,203,117,181,131,317,140,308,161,299,182
        dc.w    283,141,280,169,277,197,257,189,294,205,331,221,361,137,445,172
        dc.w    529,207,635,136,577,184

        ; 16 X and 16 Y coords
kds_dust_pos:
        dc.w    31,22,18,20,21,22,23,25,25,23,22,30,30,29,26,26
        dc.w    6,8,7,12,15,18,22,24,29,33,38,35,39,44,51,54

kds_dust_twinkle:
        dc.b    6*2,6*2,5*2,6*2,6*2,6*2,6*2,5*2,6*2,6*2,5*2 ;,4*2,6*2,6*2,5*2,4*2
        dc.b    6*2,5*2,5*2,6*2,5*2,5*2,4*2,5*2,5*2,6*2,5*2 ;,4*2,4*2,5*2,5*2,5*2
        dc.b    5*2,4*2,4*2,5*2,5*2,4*2,3*2,5*2,4*2,3*2,5*2 ;,4*2,3*2,4*2,3*2,3*2
        dc.b    5*2,4*2,3*2,4*2,4*2,3*2,4*2,3*2,2*2,5*2,4*2 ;,3*2,3*2,4*2,4*2,3*2
        dc.b    2*2,4*2,3*2,3*2,2*2,4*2,4*2,3*2,4*2,3*2,2*2 ;,4*2,3*2,2*2,1*2,1*2
        dc.b    1*2,3*2,2*2,2*2,1*2,3*2,2*2,1*2,2*2,3*2,2*2 ;,1*2,2*2,3*2,2*2,1*2

kds_dust_burst:
        dc.b    7*2,7*2,7*2,7*2,7*2,7*2,6*2,7*2
        dc.b    6*2,6*2,7*2,6*2,6*2,6*2,5*2,6*2
        dc.b    5*2,5*2,6*2,5*2,5*2,5*2,4*2,5*2
        dc.b    4*2,4*2,5*2,4*2,4*2,4*2,3*2,4*2
        dc.b    3*2,3*2,4*2,3*2,3*2,3*2,2*2,3*2
        dc.b    2*2,2*2,3*2,2*2,2*2,2*2,1*2,2*2
        dc.b    1*2,1*2,2*2,1*2,1*2,1*2,1*2,1*2
        dc.b    1*2,1*2,2*2,1*2,1*2,1*2,1*2,1*2
        dc.b    1*2,1*2,2*2,1*2,1*2,1*2,1*2,1*2

kds_bernstein0:
        ; Bernstein 0
        dc.w    $ffff,$fa0c,$f430,$ee6b,$e8be,$e328,$dda9,$d841,$d2f0,$cdb5,$c891,$c382,$be8a,$b9a7,$b4da,$b023
        dc.w    $ab80,$a6f2,$a27a,$9e16,$99c6,$958b,$9163,$8d50,$8950,$8564,$818b,$7dc5,$7a12,$7672,$72e4,$6f69
        dc.w    $6c00,$68a9,$6564,$6230,$5f0e,$5bfd,$58fd,$560e,$5330,$5062,$4da5,$4af7,$485a,$45cc,$434e,$40e0
        dc.w    $3e80,$3c2f,$39ee,$37bb,$3596,$3380,$3177,$2f7d,$2d90,$2bb1,$29df,$281a,$2662,$24b7,$2318,$2186
        dc.w    $2000,$1e86,$1d18,$1bb5,$1a5e,$1912,$17d1,$169b,$1570,$144f,$1339,$122c,$112a,$1031,$0f42,$0e5d
        dc.w    $0d80,$0cac,$0be2,$0b20,$0a66,$09b5,$090b,$086a,$07d0,$073e,$06b3,$062f,$05b2,$053c,$04cc,$0463
        dc.w    $0400,$03a3,$034c,$02fa,$02ae,$0267,$0225,$01e8,$01b0,$017c,$014d,$0121,$00fa,$00d6,$00b6,$009a
        dc.w    $0080,$0069,$0056,$0045,$0036,$002a,$001f,$0017,$0010,$000b,$0007,$0004,$0002,$0001,$0000,$0000

kds_bernstein1:
        ; Bernstein 1
        dc.w    $0000,$05e8,$0ba1,$112b,$1686,$1bb4,$20b4,$2588,$2a30,$2eac,$32fe,$3725,$3b22,$3ef6,$42a1,$4624
        dc.w    $4980,$4cb5,$4fc3,$52ab,$556e,$580c,$5a86,$5cdd,$5f10,$6121,$6310,$64dd,$668a,$6816,$6983,$6ad1
        dc.w    $6c00,$6d11,$6e05,$6edc,$6f96,$7035,$70b8,$7121,$7170,$71a5,$71c2,$71c6,$71b2,$7187,$7145,$70ed
        dc.w    $7080,$6ffe,$6f67,$6ebc,$6dfe,$6d2d,$6c4a,$6b56,$6a50,$693a,$6814,$66de,$659a,$6447,$62e7,$617a
        dc.w    $6000,$5e7a,$5ce9,$5b4d,$59a6,$57f6,$563c,$547a,$52b0,$50de,$4f06,$4d27,$4b42,$4958,$4769,$4576
        dc.w    $4380,$4187,$3f8b,$3d8d,$3b8e,$398e,$378e,$358f,$3390,$3193,$2f98,$2d9f,$2baa,$29b8,$27cb,$25e3
        dc.w    $2400,$2223,$204d,$1e7e,$1cb6,$1af7,$1940,$1793,$15f0,$1457,$12ca,$1148,$0fd2,$0e69,$0d0d,$0bbf
        dc.w    $0a80,$0950,$082f,$071e,$061e,$052f,$0452,$0388,$02d0,$022c,$019c,$0120,$00ba,$0069,$002f,$000c

kds_bernstein2:
        ; Bernstein 2
        dc.w    $0000,$000c,$002f,$0069,$00ba,$0120,$019c,$022c,$02d0,$0388,$0452,$052f,$061e,$071e,$082f,$0950
        dc.w    $0a80,$0bbf,$0d0d,$0e69,$0fd2,$1148,$12ca,$1457,$15f0,$1793,$1940,$1af7,$1cb6,$1e7e,$204d,$2223
        dc.w    $2400,$25e3,$27cb,$29b8,$2baa,$2d9f,$2f98,$3193,$3390,$358f,$378e,$398e,$3b8e,$3d8d,$3f8b,$4187
        dc.w    $4380,$4576,$4769,$4958,$4b42,$4d27,$4f06,$50de,$52b0,$547a,$563c,$57f6,$59a6,$5b4d,$5ce9,$5e7a
        dc.w    $6000,$617a,$62e7,$6447,$659a,$66de,$6814,$693a,$6a50,$6b56,$6c4a,$6d2d,$6dfe,$6ebc,$6f67,$6ffe
        dc.w    $7080,$70ed,$7145,$7187,$71b2,$71c6,$71c2,$71a5,$7170,$7121,$70b8,$7035,$6f96,$6edc,$6e05,$6d11
        dc.w    $6c00,$6ad1,$6983,$6816,$668a,$64dd,$6310,$6121,$5f10,$5cdd,$5a86,$580c,$556e,$52ab,$4fc3,$4cb5
        dc.w    $4980,$4624,$42a1,$3ef6,$3b22,$3725,$32fe,$2eac,$2a30,$2588,$20b4,$1bb4,$1686,$112b,$0ba1,$05e8

kds_bernstein3:
        ; Bernstein 3
        dc.w    $0000,$0000,$0000,$0001,$0002,$0004,$0007,$000b,$0010,$0017,$001f,$002a,$0036,$0045,$0056,$0069
        dc.w    $0080,$009a,$00b6,$00d6,$00fa,$0121,$014d,$017c,$01b0,$01e8,$0225,$0267,$02ae,$02fa,$034c,$03a3
        dc.w    $0400,$0463,$04cc,$053c,$05b2,$062f,$06b3,$073e,$07d0,$086a,$090b,$09b5,$0a66,$0b20,$0be2,$0cac
        dc.w    $0d80,$0e5d,$0f42,$1031,$112a,$122c,$1339,$144f,$1570,$169b,$17d1,$1912,$1a5e,$1bb5,$1d18,$1e86
        dc.w    $2000,$2186,$2318,$24b7,$2662,$281a,$29df,$2bb1,$2d90,$2f7d,$3177,$3380,$3596,$37bb,$39ee,$3c2f
        dc.w    $3e80,$40e0,$434e,$45cc,$485a,$4af7,$4da5,$5062,$5330,$560e,$58fd,$5bfd,$5f0e,$6230,$6564,$68a9
        dc.w    $6c00,$6f69,$72e4,$7672,$7a12,$7dc5,$818b,$8564,$8950,$8d50,$9163,$958b,$99c6,$9e16,$a27a,$a6f2
        dc.w    $ab80,$b023,$b4da,$b9a7,$be8a,$c382,$c891,$cdb5,$d2f0,$d841,$dda9,$e328,$e8be,$ee6b,$f430,$fa0c

;--------------------------------------------------------------------

        section "kds_copper",data,chip

kds_copperlist:
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

kds_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

kds_fairy_body1:
        incbin  "../data/kaleidoscope/fairy1_48x51x16.BPL"
kds_fairy_body2:
        incbin  "../data/kaleidoscope/fairy2_48x51x16.BPL"
kds_fairy_body3:
        incbin  "../data/kaleidoscope/fairy3_48x51x16.BPL"
kds_puff_sprite1:
        incbin  "../data/kaleidoscope/puff1_32x15x16.BPL"
kds_puff_sprite2:
        incbin  "../data/kaleidoscope/puff2_32x15x16.BPL"
kds_puff_sprite3:
        incbin  "../data/kaleidoscope/puff3_32x15x16.BPL"
kds_puff_sprite4:
        incbin  "../data/kaleidoscope/puff4_32x15x16.BPL"

kds_kaleidoscope_pattern:
        incbin  "../data/kaleidoscope/plt_neuro2_ham.raw"

blitter_temp_output_word:
        dc.w    0

        IFND    FW_DEMO_PART
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