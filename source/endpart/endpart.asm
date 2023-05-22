; TODOs:
; - Add copper fade for top and bottom (use Frustro copperlist sorting)
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
FW_LMB_EXIT_SUPPORT         = 0 ; allows abortion of intro with LMB
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

        ENDC

ENDP_WIDTH     = 320
ENDP_HEIGHT    = 180
ENDP_PLANES    = 6

SCREENSHOTS_WIDTH = 320
SCREENSHOTS_HEIGHT = 1620+1*180
SCREENSHOTS_PLANES = 2

SCT_WIDTH       = 320
SCT_HEIGHT      = 224
SCT_PLANES      = 2

FONT_WIDTH      = 8
FONT_HEIGHT     = 16
FONT_PLANES     = 2

COP_LIST_SIZE   = (200)*4

PERM_MUSIC_SAMPLES = $dd52+4

CHIPMEM_SIZE = (COP_LIST_SIZE*2)+((SCREENSHOTS_WIDTH/8)*SCREENSHOTS_HEIGHT)*SCREENSHOTS_PLANES+((SCT_WIDTH/8)*(SCT_HEIGHT+1)*2)
FASTMEM_SIZE = 4

        IFND    DEBUG_DETAIL
DEBUG_DETAIL    SET     10
        ENDC

NEWAGE_DEBUG    = 1

        include "../framework/framework.i"


; Memory use:
; Playfields:
; - 320 x 180 x 24     = 172800 (6x2 db, 2 draw, 2 fill, 6 original, 2 spare)

    STRUCTURE   PartData,fw_SIZEOF
        APTR    pd_CurrCopListPtr
        APTR    pd_LastCopListPtr
        UBYTE   pd_DbToggle
        ALIGNWORD

        BOOL    pd_PartDone

        BOOL    pd_LastLMB

        UWORD   pd_TextYPos
        UWORD   pd_ClearTextYPos
        UWORD   pd_NextLineWait
        APTR    pd_TextLinePtr
        UWORD   pd_ScrollScreenYPos
        UWORD   pd_ScrollerPause
        BOOL    pd_HalfspeedScrolling
        UWORD   pd_TextWrapYPos
        ULONG   pd_ScreenshotsYOffset
        UWORD   pd_ScreenshotsScrollWaitCount
        BOOL    pd_ScreenshotsLoaded
        ULONG   pd_CopyLastScreenYPos

        APTR    pd_ScreenshotsBuffer
        APTR    pd_ScreenshotsPackedFile
        APTR    pd_CopperList1              ; ds.b COP_LIST_SIZE
        APTR    pd_CopperList2              ; ds.b COP_LIST_SIZE
        APTR    pd_ScrollTextBuffer         ; ds.b ((SCT_WIDTH/8)*SCT_HEIGHT)*2
        STRUCT  pd_Palette,16*cl_SIZEOF

        LABEL   pd_SIZEOF

        IFND    FW_DEMO_PART
        include "../framework/framework.asm"
        ENDC

entrypoint:
        IFD     FW_DEMO_PART
        move.l  #pd_SIZEOF,d0
        CALLFW  InitPart
        ENDC

        bsr.s   enp_init

        lea     enp_copperlist,a0
        CALLFW  SetCopper

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        move.l  #part_music_data,fw_MusicData(a6)
        move.l  #part_music_smp,fw_MusicSamples(a6)
        CALLFW  StartMusic
        ENDC
        ELSE
        CALLFW  StartMusic
        ENDC

        bsr     enp_main

        CALLFW  SetBaseCopper

        rts

;--------------------------------------------------------------------

enp_init:
        bsr     enp_init_vars
        bsr     enp_clear_screen_buffers

        IFD     FW_DEMO_PART
        lea     .loadscreenshots(pc),a0
        move.l  fw_TrackloaderTask(a6),a1
        CALLFW  AddTask
        ELSE
        st      pd_ScreenshotsLoaded(a6)
        ENDC
        rts

        IFD     FW_DEMO_PART
.loadscreenshots
        lea     .screenshotfile(pc),a0
        CALLFW  LoadFile
        move.l  a0,pd_ScreenshotsPackedFile(a6)

        move.l  pd_ScreenshotsBuffer(a6),a1
        lea     (SCREENSHOTS_WIDTH/8)*ENDP_HEIGHT*SCREENSHOTS_PLANES(a1),a1
        CALLFW  DecompressZX0
        st      pd_ScreenshotsLoaded(a6)

        CALLFW  TrackloaderDiskMotorOff
        rts

.screenshotfile
        dc.b    "Screenshots.raw",0
        even
        ENDC

;--------------------------------------------------------------------

enp_init_vars:
        tst.w   fw_AgaChipset(a6)
        beq.s   .noaga
        move.w  #$00a0,enp_ddfstop+2        ; FIXME
        move.w  #$0003,enp_fmode+2
.noaga
        move.w  #11,pd_ScrollScreenYPos(a6)
        lea     enp_scrolltext(pc),a0
        move.l  a0,pd_TextLinePtr(a6)

        move.w  #ENDP_HEIGHT+12,pd_TextYPos(a6)
        move.w  #ENDP_HEIGHT+12+16,pd_ClearTextYPos(a6)
        move.w  #SCT_HEIGHT,pd_TextWrapYPos(a6)

        move.l  #(COP_LIST_SIZE*2),d0
        CALLFW  AllocChip
        PUTMSG  10,<"Copperlist 1 %p">,a0
        move.l  a0,pd_CopperList1(a6)
        move.l  a0,pd_CurrCopListPtr(a6)
        lea     COP_LIST_SIZE(a0),a0
        PUTMSG  10,<"Copperlist 2 %p">,a0
        move.l  a0,pd_CopperList2(a6)
        move.l  a0,pd_LastCopListPtr(a6)

        IFD     FW_DEMO_PART
        move.l  #((SCREENSHOTS_WIDTH/8)*SCREENSHOTS_HEIGHT)*SCREENSHOTS_PLANES,d0
        CALLFW  AllocChip
        move.l  a0,pd_ScreenshotsBuffer(a6)
        ELSE
        move.l  #enp_screenshots,pd_ScreenshotsBuffer(a6)
        ENDC

        move.l  #((SCT_WIDTH/8)*(SCT_HEIGHT+1)*SCT_PLANES),d0
        CALLFW  AllocChip
        move.l  a0,pd_ScrollTextBuffer(a6)

        rts

;--------------------------------------------------------------------

enp_main:
        moveq.l #16,d0
        moveq.l #0,d1
        lea     pd_Palette(a6),a1
        CALLFW  InitPaletteLerpSameColor

        moveq.l #16,d0
        move.w  #32,d1
        lea     enp_palette(pc),a0
        lea     pd_Palette(a6),a1
        CALLFW  FadePaletteTo

.loop
        CALLFW  VSyncWithTask

        bsr     enp_flip_db_frame

        CALLFW  CheckMusicScript

        bsr     enp_scroll_textscreen

        bsr     enp_scroll_screenshots

        moveq.l #16,d0
        lea     pd_Palette(a6),a1
        CALLFW  DoFadePaletteStep

        move.l  pd_CurrCopListPtr(a6),a0
        bsr     enp_create_dp_copperlist

        bsr     enp_update_copper_list_pointers

        tst.w   pd_PartDone(a6)
        bne.s   .quit
        btst    #2,potgor(a5)
        bne.s   .loop

.quit
        rts

;--------------------------------------------------------------------


enp_flip_db_frame:
        move.l  pd_CurrCopListPtr(a6),pd_LastCopListPtr(a6)
        not.b   pd_DbToggle(a6)
        beq.s   .selb1
        move.l  pd_CopperList2(a6),pd_CurrCopListPtr(a6)
        rts
.selb1
        move.l  pd_CopperList1(a6),pd_CurrCopListPtr(a6)
        rts

;--------------------------------------------------------------------

enp_update_copper_list_pointers:
        lea     enp_extra_copperlist_ptr+2,a0
        move.w  pd_CurrCopListPtr(a6),(a0)
        move.w  pd_CurrCopListPtr+2(a6),4(a0)
        move.w  #copjmp2,6(a0)
        rts

;--------------------------------------------------------------------

enp_clear_screen_buffers:
        move.l  pd_ScrollTextBuffer(a6),a0
        moveq.l #0,d0
        BLTHOGON
        BLTWAIT
        BLTHOGOFF

        BLTCON_SET D,0,0,0
        move.w  d0,bltdmod(a5)

        move.l  a0,bltdpt(a5)
        move.w  #(SCT_WIDTH>>4)|((SCT_HEIGHT+1)*2<<6),bltsize(a5)

        move.l  pd_ScreenshotsBuffer(a6),a0

        BLTHOGON
        BLTWAIT

        move.l  a0,bltdpt(a5)
        move.w  #(SCREENSHOTS_WIDTH>>4)|((ENDP_HEIGHT*SCREENSHOTS_PLANES)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

enp_scroll_screenshots:
        tst.w   pd_ScreenshotsLoaded(a6)
        bne.s   .cont
.skip   rts
.cont
        subq.w  #1,pd_ScreenshotsScrollWaitCount(a6)
        bpl.s   .skip
        move.w  #2,pd_ScreenshotsScrollWaitCount(a6)
        move.l  pd_ScreenshotsYOffset(a6),d0
        move.l  d0,d1
        moveq.l #(SCREENSHOTS_WIDTH/8)*SCREENSHOTS_PLANES,d2
        move.l  #(SCREENSHOTS_WIDTH/8)*SCREENSHOTS_PLANES*(SCREENSHOTS_HEIGHT-ENDP_HEIGHT),d3
        add.l   d2,d0
        cmp.l   d3,d0
        bne.s   .nowrap
        moveq.l #0,d0
.nowrap move.l  d0,pd_ScreenshotsYOffset(a6)
        move.l  pd_CopyLastScreenYPos(a6),d0
        cmp.l   #(SCREENSHOTS_WIDTH/8)*SCREENSHOTS_PLANES*ENDP_HEIGHT,d0
        beq.s   .skip
        tst.l   d1
        beq.s   .skip
        move.l  d1,pd_CopyLastScreenYPos(a6)

        move.l  pd_ScreenshotsBuffer(a6),a0
        sub.l   d2,d1
        adda.l  d1,a0
        lea     (a0,d3.l),a1

        moveq.l #-1,d2
        moveq.l #0,d0
        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        BLTCON_SET AD,BLT_A,0,0
        move.l  d2,bltafwm(a5)      ; also fills bltalwm
        move.l  d0,bltamod(a5)

        move.l  a1,bltapt(a5)
        move.l  a0,bltdpt(a5)
        move.w  #(SCREENSHOTS_WIDTH>>4)|((1*SCREENSHOTS_PLANES)<<6),bltsize(a5)

        rts

;--------------------------------------------------------------------

enp_scroll_textscreen:
        btst    #6,$bfe001
        beq.s   .skip
        sf      pd_LastLMB(a6)
        move.w  pd_ScrollerPause(a6),d0
        subq.w  #1,d0
        bmi.s   .notpaused
        move.w  d0,pd_ScrollerPause(a6)
        rts
.skip   tst.w   pd_LastLMB(a6)
        bne.s   .noclick
        st      pd_LastLMB(a6)
.noclick
        rts

.notpaused
        tst.w   pd_HalfspeedScrolling(a6)
        beq.s   .nohalfspeed
        move.w  #1,pd_ScrollerPause(a6)
.nohalfspeed
        move.w  pd_ScrollScreenYPos(a6),d0
        addq.w  #1,d0
        cmp.w   pd_TextWrapYPos(a6),d0
        bne.s   .nowrap
        moveq.l #0,d0
.nowrap move.w  d0,pd_ScrollScreenYPos(a6)

        move.l  pd_ScrollTextBuffer(a6),a1
        move.w  pd_ScrollScreenYPos(a6),d2
        subq.w  #2,d2
        bpl.s   .nogotobottom
        add.w   pd_TextWrapYPos(a6),d2
.nogotobottom
        lsl.w   #4,d2       ;*16
        adda.w  d2,a1
        lsl.w   #2,d2       ;*64
        adda.w  d2,a1

        BLTHOGON
        BLTWAIT
        BLTHOGOFF

        moveq.l #0,d0
        BLTCON_SET D,0,0,0
        move.w  d0,bltdmod(a5)

        move.l  a1,bltdpt(a5)
        move.w  #(SCT_WIDTH>>4)|((1*SCT_PLANES)<<6),bltsize(a5)
        ;rts

enp_write_textline:
        ;tst.w   pd_ScrollerPause(a6)
        ;bne.s   .paused
        subq.w  #1,pd_NextLineWait(a6)
        bmi.s   .nextline
.paused
        rts

.halfspeed
        eor.w   #1,pd_HalfspeedScrolling(a6)
        bra.s   .retrychar

.nextline

        PUTMSG  40,<"%d: NL">,fw_FrameCounterLong(a6)
        move.l  pd_TextLinePtr(a6),a0
.retrychar
        tst.b   (a0)
        bne.s   .nowrap
        st      pd_PartDone(a6)
        lea     enp_scrolltext(pc),a0
.nowrap bpl.s   .startcounting
        moveq.l #0,d0
        move.b  (a0)+,d0
        cmp.b   #$ff,d0
        beq.s   .halfspeed
        lsl.b   #1,d0
        lsl.w   #2,d0
        move.w  d0,pd_ScrollerPause(a6)
        bra.s   .retrychar

.startcounting
        move.l  a0,a1
        moveq.l #0,d0
        moveq.l #FONT_HEIGHT,d2

.countlinelength
        tst.b   (a1)
        beq.s   .done
        move.b  (a1)+,d1
        cmp.b   #10,d1
        beq.s   .done
        cmp.b   #5,d1
        beq.s   .halfdone
        addq.w  #1,d0
        bra.s   .countlinelength

.halfdone
        moveq.l #FONT_HEIGHT/2,d2
.done   move.l  a1,pd_TextLinePtr(a6)
        move.w  d0,d7
        beq.s   .skipline

        moveq.l #-1,d3
        BLTHOGON
        BLTWAIT
        BLTCON_SET A,0,0,0
        move.l  #$ff000000,bltafwm(a5)      ; also fills bltalwm
        move.w  d3,bltadat(a5)
        move.l  #(((SCT_WIDTH-16)/8-2)<<16)|(-2&$ffff),bltcmod(a5)
        move.w  #((SCT_WIDTH-16)/8-2),bltdmod(a5)

        move.w  #SCT_WIDTH/2,d1
        lsl.w   #2,d0
        sub.w   d0,d1
        PUTMSG  30,<"XPos %d">,d1

        move.l  pd_ScrollTextBuffer(a6),a3
        move.w  pd_TextYPos(a6),d3
        lsl.w   #4,d3       ;*16
        adda.w  d3,a3
        lsl.w   #2,d3       ;*64
        adda.w  d3,a3

        subq.w  #1,d7
.letterloop
        moveq.l #0,d0
        move.b  (a0)+,d0
        move.w  d1,d3
        lsr.w   #4,d3
        add.w   d3,d3
        lea     (a3,d3.w),a1
        bsr     enp_write_letter
        addq.w  #8,d1
        dbra    d7,.letterloop
.skipline
        move.w  d2,d0
        add.w   pd_TextYPos(a6),d2
        cmp.w   #SCT_HEIGHT-FONT_HEIGHT,d2
        ble.s   .noscrwrap
        move.w  d2,pd_TextWrapYPos(a6)
        moveq.l #0,d2
.noscrwrap
        move.w  d2,pd_TextYPos(a6)
        subq.w  #1,d0
        move.w  d0,pd_NextLineWait(a6)
        rts

; d0=letter, d1=xpos
enp_write_letter:
        sub.w   #' ',d0
        lsl.w   #6,d0       ; 2*FONT_HEIGHT*FONT_PLANES
        lea     enp_font_data,a2
        adda.w  d0,a2

        move.w  #(2)|((FONT_HEIGHT*FONT_PLANES)<<6),d3

        moveq.l #15,d5
        and.w   d1,d5
        ror.w   #4,d5

        move.w  #BLTEN_BCD|(((BLT_A&BLT_B)|(BLT_C&~BLT_A))&$ff),d4
        or.w    d5,d4
        swap    d4
        move.w  d5,d4

        BLTHOGON
        BLTWAIT
        BLTHOGOFF
        move.l  d4,bltcon0(a5)

        move.l  a2,bltbpt(a5)
        move.l  a1,bltcpt(a5)
        move.l  a1,bltdpt(a5)
        move.w  d3,bltsize(a5)
        rts

;--------------------------------------------------------------------

enp_create_dp_copperlist:
        COPIMOVE $4200,bplcon0
        move.l  #$5107fffe,(a0)+
        moveq.l #-2,d3

        move.w  #bplpt,d1
        move.l  pd_ScreenshotsBuffer(a6),d0
        add.l   pd_ScreenshotsYOffset(a6),d0
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #6,d1

        add.l   #(SCREENSHOTS_WIDTH/8),d0
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #6,d1

        move.w  #bplpt+4,d1

        move.w  pd_ScrollScreenYPos(a6),d2
        lsl.w   #4,d2   ; *16
        move.w  d2,d0
        lsl.w   #2,d2   ; *64
        add.w   d2,d0
        ext.l   d0
        add.l   pd_ScrollTextBuffer(a6),d0

        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #6,d1

        add.l   #(SCT_WIDTH/8),d0
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+
        addq.w  #2,d1
        move.w  d1,(a0)+
        swap    d0
        move.w  d0,(a0)+

        move.w  pd_TextWrapYPos(a6),d0
        move.w  d0,d1
        sub.w   #ENDP_HEIGHT,d0
        sub.w   pd_ScrollScreenYPos(a6),d0
        bpl.s   .skipwrap
        add.w   #$51+ENDP_HEIGHT,d0
        lsl.w   #8,d0
        bcc.s   .no255
        move.l  #$ffdffffe,(a0)+
.no255
        addq.w  #7,d0

        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.w  #bpl2mod,(a0)+
        mulu.w  #(SCT_WIDTH/8)*2,d1
        neg.w   d1
        add.w   #(SCT_WIDTH/8),d1
        move.w  d1,(a0)+
        add.w   #$100,d0
        bcc.s   .no255_2
        move.l  #$ffdffffe,(a0)+
.no255_2
        move.w  d0,(a0)+
        move.w  d3,(a0)+
        move.w  #bpl2mod,(a0)+
        move.w  #(SCT_WIDTH/8),(a0)+
.skipwrap

        lea     pd_Palette(a6),a1
        move.w  #color,d0
        moveq.l #16-1,d7
.palloop
        move.w  d0,(a0)+
        move.w  cl_Color(a1),(a0)+
        lea     cl_SIZEOF(a1),a1
        addq.w  #2,d0
        dbra    d7,.palloop

        move.l  d3,(a0)         ; COP_END
        rts

;********************************************************************

enp_scrolltext:
        dc.b    10
        dc.b    "This is the end of",10,5
        dc.b    "---===*** HAMAZING ***===---",10
        dc.b    "(post party version)",10
        dc.b    "A one-disk trackmo",10,5
        dc.b    "originally released at",10,5
        dc.b    "68k Inside 2023",10,5
        dc.b    "for OCS/ECS Amiga",10
        dc.b    "7 MHz 68000",10
        dc.b    "512 kb chip + 512 kb slow",10
        dc.b    $80+25
        dc.b    10,10,10,10
        dc.b    "* Graphics *",10,5
        dc.b    "Optic",10
        dc.b    10,5
        dc.b    "* Music *",10,5
        dc.b    "mA2E",10
        dc.b    10,5
        dc.b    "* Code *",10,5
        dc.b    "Platon",10,5
        dc.b    $80+25
        dc.b    10,10
        dc.b    "* HAM tech announcer *",10
        dc.b    "psenough",10
        dc.b    5
        dc.b    "* Additional graphics / photos *",10
        dc.b    "Platon",10
        dc.b    5
        dc.b    "* Additional code *",10
        dc.b    "Leonard / Oxygene (LightSpeedPlayer)",10
        dc.b    "Einar Saukas (ZX0 technology)",10
        dc.b    "Emmanuel Marty (orig. ZX0 decruncher)",10
        dc.b    "a/b (sine table routine)",10
        dc.b    5,$80+15,10
        dc.b    10,10,10
        dc.b    "'Hamazing' and 'Hamphrey' puns",10
        dc.b    "courtesy of Grip / Istari",10
        dc.b    10,10,10
        dc.b    10,10,10
        dc.b    "LMB pauses scroller",10
        dc.b    "RMB restarts demo!",10,10,10
        dc.b    10,10,10
        dc.b    10,10,10
        dc.b    10,10,10
        dc.b    10,10,10
        dc.b    $ff
        dc.b    "mA2E at the keyboard..."
        dc.b    10,10,10
        dc.b    "Thanks for watching the demo.",10
        dc.b    "Hope you like it. Greetings to all my",10
        dc.b    "friends in the demoscene, and also to my",10
        dc.b    "wife that let me sit hours after hours",10
        dc.b    "composing.",10,10
        dc.b    "Also I would like to say thanks to the",10
        dc.b    "whole Amiga community and their support",10
        dc.b    "and inspiration.",10,10
        dc.b    "Without you, I would have stopped making",10
        dc.b    "music many many years ago.",10,10
        dc.b    "Stay tuned for more intros and demos",10
        dc.b    "from us.",10,10
        dc.b    "Thats all from me. Enjoy the party.",10
        dc.b    "Until next time, keep on creating",10
        dc.b    "awesome stuff for the Amiga,",10
        dc.b    "which we all love.",10,10
        dc.b    "If you want to get in touch with me,",10
        dc.b    "drop me an email at stian-g@online.no",10
        dc.b    "or at Discord mA2E / dSr#1261."
        dc.b    10,10,10
        dc.b    "$%%&",10,10
        dc.b    "Optic on the keys.",10,10
        dc.b    "Seems time is eluding me as always. Been",10
        dc.b    "meaning to do a whole bunch of personal",10
        dc.b    "greets and messages, like the good old",10
        dc.b    "days, for many a scroller now",10
        dc.b    "$%%% %%% %%&",10,10
        dc.b    "Alas, it's not happening this time",10
        dc.b    "either... hugs and kisses to",10
        dc.b    "Planet.Jazz, Focus Design, Talent,",10
        dc.b    "Proxima, Desire, Nah, Resistance and so",10
        dc.b    "on and so forth $",10,10
        dc.b    "Thanks to Platon for bringing me onto",10
        dc.b    "this project, it's been fun. Had a great",10
        dc.b    "time producing true colour graphics with",10
        dc.b    "the wacom, as opposed to purely pushing",10
        dc.b    "pixels in DP. Most of the stuff here is",10
        dc.b    "WIP, as I am suffering some true colour",10
        dc.b    "ringrust. Hopefully there will be time",10
        dc.b    "to fix up some stuff post-party.",10,10
        dc.b    "Optic out.. Much love!"
        dc.b    10,10,10
        dc.b    "Platon at the keyboard..."
        dc.b    10,10,10
        dc.b    "This is the successor to",10,10
        dc.b    "*** Ham Eager *** ",10,10
        dc.b    "the demo that started the HAM madness",10
        dc.b    "two years ago.",10,10
        dc.b    "Unfortunately, it did not spark many",10
        dc.b    "new HAM effects by other people :-(",10,10
        dc.b    "This time we got some cool graphics",10
        dc.b    "from a real graphic artist and some",10
        dc.b    "really good music, too.",10
        dc.b    10
        dc.b    "Some will be disappointed about the",10
        dc.b    "reduced amount of coder colors...",10
        dc.b    10
        dc.b    "# ... you cannot please them all #",10
        dc.b    10,10,10
        dc.b    "Big big big thanks must go out to mA2E",10
        dc.b    "and Optic for their great work and that",10
        dc.b    "they are absolute reliable people.",10,10
        dc.b    "However, they seem to work best under",10
        dc.b    "pressure of the deadline...",10
        dc.b    10,10
        dc.b    "Also thanks to Virgill for feedback and",10
        dc.b    "testing some early effects.",10
        dc.b    10,10
        dc.b    "### Personal greetings ###",10,10
        dc.b    "4play, Accidental, Alex, Alis, Anders",10
        dc.b    "Arrakis, Axis, Bartman, Bifat, Bonefish",10
        dc.b    "Dan, Don Pu, Chellomere, Critikill",10
        dc.b    "Daddy Freddy, Dascon, Dexter, DJ H0ffman",10
        dc.b    "Evil, Facet, FloKi, Florist, Gasman",10
        dc.b    "Greippi, Grip, Ham, Hedning, Heike",10
        dc.b    "Jeenio, Jesko, Jonna, Johanna, Karla",10
        dc.b    "Kirsten, Krill, Lee, Leonard, LFT, Losso",10
        dc.b    "Leuat, MacMissAnn, Magic, Maze, Merry",10
        dc.b    "Mirrorbird, Mop, Mystra, No9, Nosferatu",10
        dc.b    "Nyingen, OhLi, Optic, Pellicus, Pestis",10
        dc.b    "Peter, Phreedh, Pink, Pit, psenough",10
        dc.b    "Prowler, RamonB5, Rakhee, Rapture, rez",10
        dc.b    "Rog_VF, Ronan, Serpent, Shoe",10
        dc.b    "Sir Garbagetruck, Slash, Soundy, spkr",10
        dc.b    "Starchaser, STC, Stinsen, Sudoism",10
        dc.b    "Superogue, TDK, Tezar, Tobi G.",10
        dc.b    "Toni Wilen, Virgill, XXX, Yoruq, Zoi",10
        dc.b    "Zoner",10,10,10
        dc.b    "... and to my beloved wife and kid",10
        dc.b    "who supported me while I spent many",10
        dc.b    "days and nights in front of the Amiga.",10
        dc.b    10,10,10
        dc.b    "We didn't manage to put all demogroups",10
        dc.b    "onto the graphics, but please feel",10
        dc.b    "our love nevertheless!"
        dc.b    10,10,10,10,10,10,10,10,10,10,10
        dc.b    "THE END",10,10
        dc.b    "(or, if you're interested, some",10
        dc.b    "tech tech coming up...)",10
        dc.b    10,10,$80+60
        dc.b    10,10,10,10,10,10,10,10,10,10,10,10
        dc.b    "* Trackloader / Framework *",10,10
        dc.b    "After Ham Eager, and several intros,",10
        dc.b    "I rewrote much of the framework that",10
        dc.b    "was originally based on Axis' work",10
        dc.b    "from Planet Rocklobster #",10,10
        dc.b    "Now both local variables of your part",10
        dc.b    "and those of the firmware are accessed",10
        dc.b    "through the same base register. Nice!",10,10
        dc.b    "The multitasking has been rewritten",10
        dc.b    "and now allows an arbitrary number of",10
        dc.b    "tasks with priorities and optional",10
        dc.b    "round robin.",10,10
        dc.b    "The framework comes with several new",10
        dc.b    "features such as blitter queues and",10
        dc.b    "blitter tasks, LSP and Pretracker",10
        dc.b    "playback, ZX0 decrunching, better",10
        dc.b    "memory management and so on...",10,10
        dc.b    "It's the things that you don't see, like",10
        dc.b    "calculating true color data or speedcode",10
        dc.b    "and loading more stuff from disk in the",10
        dc.b    "background that make this demo fancy.",10,10
        dc.b    "Once I have the time to document the",10
        dc.b    "stuff, I will make it public.",10,10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Gotham (1200 LOC) *",10,10
        dc.b    "As a nod to Batman Group's fantastic",10
        dc.b    "Batman Rises demo, I wanted to have",10
        dc.b    "an early loading screen, that slightly",10
        dc.b    "resembles their work. Little did I know",10
        dc.b    "that Losso had a similar idea with his",10
        dc.b    "winning demo at Revision.",10,10
        dc.b    "Anyway, the code uses the anti-aliased",10
        dc.b    "blitter line drawing from Frustro.",10,10
        dc.b    "The voice-over is from one of psenough's",10
        dc.b    "recent YouTube hype videos where he",10
        dc.b    "mentions Ham Eager and tries to explain",10
        dc.b    "what's special about it.",10,10
        dc.b    "Kudos for doing that! I just found it",10
        dc.b    "very cute how he was talking about",10
        dc.b    10,"* The HAM Technology *",10,10
        dc.b    "that I just had to make a little joke",10
        dc.b    "out of it. I hope you don't mind :)",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Bulb/Lamp/Sofa (3700 LOC) *",10,10
        dc.b    "I started coding this effect about a",10
        dc.b    "year ago, further exploring the",10
        dc.b    "possibilities of the mode one could call",10
        dc.b    "'extra-halfbright-HAM' (I recently saw",10
        dc.b    "a demo from a couple of years ago that",10
        dc.b    "uses a similar thing to blend in a HAM",10
        dc.b    "picture).",10,10
        dc.b    "The main problem was to reduce the",10
        dc.b    "required number of blits to do the",10
        dc.b    "compositing of the three shades to",10
        dc.b    "a minimum.",10,10
        dc.b    "Still it requires about 200 very unique",10
        dc.b    "blits for one new image.",10
        dc.b    "It was very hard to keep it running at",10
        dc.b    "a rate of constant 25 Hz.",10,10
        dc.b    "There is a lot of ahead-of-time blitter",10
        dc.b    "queue calculation here and you might",10
        dc.b    "notice how slow the disk keeps loading",10
        dc.b    "during the effect because, well, not",10
        dc.b    "much time left to do so.",10,10
        dc.b    "The lamp and the text are sprites, the",10
        dc.b    "rotations of the lamp are calculated",10
        dc.b    "at the beginning of the effect while",10
        dc.b    "the lamp is still off-screen.",10,10
        dc.b    "It's funny how a basic effect takes",10
        dc.b    "80 percent of your time and then",10
        dc.b    "designing stuff around it takes",10
        dc.b    "another 80 percent :)",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* STHam (1800 LOC) *",10,10
        dc.b    "Originally planned to be showing a",10
        dc.b    "sliced, temporal (spatial) dithered",10
        dc.b    "HAM picture with a scroller on top,",10
        dc.b    "the palette color switching had to",10
        dc.b    "go due to copper timing issues.",10,10
        dc.b    "What's left is a bent sprite scroller",10
        dc.b    "(inspired by the C64 demo",10
        dc.b    "The Shores of Reflection by Shape)",10
        dc.b    "that uses two blits to do a shearing",10
        dc.b    "operation -- this is a new approach",10
        dc.b    "to me. Fun!",10,10
        dc.b    "There was plenty of CPU time left to",10
        dc.b    "make the scroller reappear, but",10
        dc.b    "unfortunately, the motif didn't quite",10
        dc.b    "allow this.",10,10
        dc.b    "Okay, there is still this temporal",10
        dc.b    "dithering for extra smooth gradients.",10
        dc.b    "(Basically it's a 15 bits image.)",10,10
        dc.b    "The intro transition is a new thing,",10
        dc.b    "the sprite curtain is more or less",10
        dc.b    "taken from Ham Eager.",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Kaleidoscope (6400 LOC) *",10,10
        dc.b    "Ever since I watched Rule 30 by",10
        dc.b    "Andromeda, I thought: This kaleidoscope",10
        dc.b    "effect looks cool! But it should be",10
        dc.b    "possible to do it in HAM, right?",10,10
        dc.b    "So here you are: Not only running in",10
        dc.b    "constant 25 Hz in 320x180, but also",10
        dc.b    "flipping the graphics to six different",10
        dc.b    "gradients.",10,10
        dc.b    "The kaleidoscope uses three textures of",10
        dc.b    "256x256 pixels for three rotations each.",10,10
        dc.b    "Optic has somehow managed that the",10
        dc.b    "textures use over 4000 colors! Wow!",10,10
        dc.b    "Calculating the necessary true color",10
        dc.b    "representation takes a whopping 384 KB",10
        dc.b    "of slow ram. I had forgotten to multiply",10
        dc.b    "times two when I started designing the",10
        dc.b    "effect 8-O",10,10
        dc.b    "The intro/outro noise transition of the",10
        dc.b    "effect uses repeating sprite overlays.",10,10
        dc.b    "The party version was missing the fairy",10
        dc.b    "dust and wand effect as",10
        dc.b    "originally planned.",10,10
        dc.b    "The part is now interactive",10
        dc.b    "if you move your mouse.",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Hexagon (900 LOC) *",10,10
        dc.b    "After all free memory had been exhausted",10
        dc.b    "I needed a transition effect to preload",10
        dc.b    "the next part with the new music.",10,10
        dc.b    "I had this copper chunky thing lying",10
        dc.b    "around for a year or so -- so I thought",10
        dc.b    "I could do my first Amiga Rotozoomer.",10,10
        dc.b    "The kaleidoscope texture was still left",10
        dc.b    "in memory, so why not invert it (for",10
        dc.b    "free, 'cause Blitter!) and use that?",10,10
        dc.b    "The twist about this effect is that it",10
        dc.b    "uses extra-halfbright mode, but without",10
        dc.b    "any display DMA active!",10,10
        dc.b    "This means every second cycle is still",10
        dc.b    "available for the CPU or blitter.",10,10
        dc.b    "There are some things I want to explore",10
        dc.b    "further about this new mode with its",10
        dc.b    "own limitations, but it was time to get",10
        dc.b    "it out to see the light of day.",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Rubbercube (3000 LOC) *",10,10
        dc.b    "This is again a filler effect that was",10
        dc.b    "needed to get time music timing sync to",10
        dc.b    "the break and the cat cue.",10,10
        dc.b    "It is of course based on the G. Rowdy",10
        dc.b    "gouraud cube, but this one is smaller",10
        dc.b    "and uses 16 shades.",10,10
        dc.b    "It is smaller to fit in 264 KB of chip",10
        dc.b    "ram required to store 33 frames of",10
        dc.b    "animation to make it a rubbercube.",10,10
        dc.b    "The second palette is a nod to Variform",10
        dc.b    "(again).",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Virgillbars (3300 LOC) *",10,10
        dc.b    "The name came from Virgill telling me",10
        dc.b    "that he wanted to have a rotating bars",10
        dc.b    "effect in my next demo, like the ones in",10
        dc.b    "Interference by Sanity.",10,10
        dc.b    "Also, Nosferatu wrote in his tech",10
        dc.b    "write-up about his Fat Circuits intro",10
        dc.b    "that he would leave the HAM stuff to me",10
        dc.b    "and did EHB bars instead.",10,10
        dc.b    '"Hold my beer."',10,10
        dc.b    "The tricky thing is how to calculate",10
        dc.b    "a line of optimal HAM pixels fast",10
        dc.b    "enough and how to do the saturation and",10
        dc.b    "math involved.",10,10
        dc.b    "In Ramontic Getaway, I had a chunky",10
        dc.b    "copper display but used the blitter to",10
        dc.b    "perform 30 bit true color saturation",10
        dc.b    "and 12 bit result calculation.",10
        dc.b    "So I took it from there.",10,10
        dc.b    "As for the HAM pixel calculation:",10
        dc.b    "This is of course table-assisted but",10
        dc.b    "does use a few clever tricks or so.",10
        dc.b    "To be able to rotate the bars, the line",10
        dc.b    "has to be pretty wide.",10,10
        dc.b    "Next time: Full rotation",10,10
        dc.b    "Also: HAM. You need to fix the left",10
        dc.b    "border. If you see some shit there",10
        dc.b    "running in WinUAE emulation, you need",10
        dc.b    "to get the latest WinUAE 5.x.x version!",10,10
        dc.b    "The overlays texts are taken from",10
        dc.b    "'Addition of Light Divided'",10
        dc.b    "by Tori Amos.",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Blend (5800 LOC) *",10,10
        dc.b    "In Shuffling around the Christmas Tree",10
        dc.b    "I explored the possibilities of hacking",10
        dc.b    "HAM pictures into pieces without",10
        dc.b    "fringing. Taking some of the stuff I",10
        dc.b    "learned from there and applying it to",10
        dc.b    "some other shapes. The original main",10
        dc.b    "effect (a wavy line) didn't make it",10
        dc.b    "into the demo.",10,10
        dc.b    "Still you get some fading 'between' HAM",10
        dc.b    "images and transition effects that",10
        dc.b    "should not be possible.",10,10
        dc.b    "Does not use BresenHAM's circle drawing",10
        dc.b    "but the recently published method by",10
        dc.b    "C64 programmer Jesko, who invented a",10
        dc.b    "slightly faster drawing method in 1986.",10,10
        dc.b    "Main problem here is to keep five full",10
        dc.b    "screen buffers in memory (210 KB) plus",10
        dc.b    "the necessary true color data (337 KB)",10
        dc.b    "plus the generated speedcode, data and",10
        dc.b    "masks for the 47 circles.",10,10
        dc.b    "It's funny how many effects in this demo",10
        dc.b    "are actually quite memory-bound.",10,10
        dc.b    "As the logo graphics only turned up",10
        dc.b    "a day before the deadline, and I had",10
        dc.b    "assumed the logo to be a non-HAM gfx,",10
        dc.b    "the fading had to be removed at short",10
        dc.b    "notice. Now it's back again.",10
        dc.b    10,10,"----",10,10,10
        dc.b    "* Endpart (900 LOC) *",10,10
        dc.b    "Originally planned to be completely",10
        dc.b    "different, but the time just ran out.",10
        dc.b    "As there was still space left on the",10
        dc.b    "disk, the background images is just a",10
        dc.b    "huge bitmap of 128 KB.",10
        dc.b    10,10,10,10
        dc.b    10,10,10,10
        dc.b    "That's it. So many planned parts didn't",10
        dc.b    "make it into this demo, but we are",10
        dc.b    "still glad how it came out.",10,10,10
        dc.b    "We hope you enjoyed it as much",10
        dc.b    "as we did making it!",10
        dc.b    10,10,10,10
        dc.b    10,10,10,10
        dc.b    10,10,10,10
        dc.b    "Wrapping back to start in...",10,10
        dc.b    "3",10,10
        dc.b    "2",10,10
        dc.b    "1",10,10
        dc.b    0
        even

        ; bg playfield 0/2 (0,1,4,5), text playfield 1/3 (0,2,8,10)
enp_palette:
        dc.w    $345,$456,$fff,$fff,$567,$678,$fff,$fff
        dc.w    $acd,$bde,$000,$111,$cee,$def,$222,$333

;--------------------------------------------------------------------

        section "enp_copper",data,chip

enp_copperlist:
        COP_MOVE dmacon,DMAF_BLITHOG    ; disable blitter hogging to avoid interrupt latency
        COP_MOVE diwstrt,$5281          ; window start
        COP_MOVE diwstop,$06c1          ; window stop
        COP_MOVE ddfstrt,$0038          ; bitplane start
enp_ddfstop:
        COP_MOVE ddfstop,$00d0          ; bitplane stop

        COP_MOVE bplcon3,$0c00
enp_fmode:
        COP_MOVE fmode,$0000            ; fixes the aga modulo problem

        COP_MOVE bplcon0,$0200
        COP_MOVE bplcon1,$0000
        COP_MOVE bplcon2,$0044          ; sprites in front, playfield 2 has priority
        COP_MOVE bpl1mod,(SCREENSHOTS_WIDTH/8)*SCREENSHOTS_PLANES-(SCREENSHOTS_WIDTH/8)
        COP_MOVE bpl2mod,(SCT_WIDTH/8)*SCT_PLANES-(SCT_WIDTH/8)

enp_extra_copperlist_ptr:
        COP_MOVE cop2lc,0
        COP_MOVE cop2lc+2,0
        COP_MOVE $1fe,0
        COP_END

enp_font_data:
        incbin  "../data/endpart/PJZ_font_8x16x4.BPL"

        IFND    FW_DEMO_PART
        IFD     ENABLE_PART_MUSIC
        section "part_music_samples",data,chip      ; section for music playback
part_music_smp:
        incbin  "../data/music/desire_68k_tune3_v2.lsbank"
        section "part_music_data",data              ; section for music playback
part_music_data:
        incbin  "../data/music/desire_68k_tune3_v2.lsmusic"
        ENDC
        section "enp_screenshots",data,chip
enp_screenshots:
        ds.b    ((SCREENSHOTS_WIDTH/8)*ENDP_HEIGHT)*SCREENSHOTS_PLANES
        incbin  "../data/endpart/screenshots_320x1620.BPL"
        ENDC
        END