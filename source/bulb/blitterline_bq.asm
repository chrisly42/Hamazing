;----------------------------------------------------------------------------------
; Draw regular blitter line
;
; The routine will exit with the blitter active
;
; in    d0.w    x0
;       d1.w    y0
;       d2.w    x1
;       d3.w    y1
;       d4.w    bytes per row in bitplane
;       a0      bitplane
;       a5      $dff000
; a0/d0-d5 trashed

blb_blitter_line_init_bq:
        ADD_TO_BLITTER_QUEUE a4,a0
        clr.l   (a4)+
        lea     .bq_init(pc),a0
        move.l  a0,(a4)+
        move.w  d4,(a4)+
        rts
.bq_init
        PUTMSG  50,<"Line Init">
        moveq.l #-1,d0
        move.w  #BLTCON1F_LINE,bltcon1(a5)
        move.w  #$8000,bltadat(a5)
        move.l  d0,bltafwm(a5)
        move.w  d0,bltbdat(a5)
        move.w  (a0)+,bltcmod(a5)
        BLTHOGON
        moveq.l #0,d0
        rts

;----------------------------------------------------------------------------------
; Draw regular blitter line to blitter queue
;
; in    d0.w    x0
;       d1.w    y0
;       d2.w    x1
;       d3.w    y1
;       d4.w    bytes per row in bitplane
;       a0      bitplane
;       a4      blitterqueue struct

blb_draw_blitter_line_bq:
        cmp.w   d1,d3
        bge.s   .downward
        exg     d0,d2
        exg     d1,d3
.downward

        mulu    d1,d4
        lea     (a0,d4.w),a1

        moveq.l #-16,d4
        and.w   d0,d4
        lsr.w   #3,d4
        adda.w  d4,a1

        moveq.l #15,d4
        and.w   d0,d4
        ror.w   #4,d4
        or.w    d5,d4
        or.w    #BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED,d4
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
        add.w   d2,d2       ; 2 * dx
        add.w   d2,d2       ; 4 * dx
        add.w   d3,d3       ; 4 * dy

        move.w  d3,d0
        sub.w   d2,d3       ; 4 * (dy - dx)

        addq.w  #4,d2       ; extra word height
        lsl.w   #4,d2
        addq.w  #2,d2       ; width == 2

        moveq.l #0,d1
        move.l  a4,a0

        move.l  d1,(a4)+
        move.l  #.bq_routine,(a4)+
        move.l  d4,(a4)+                        ; bql_BltCon01
        move.l  a1,(a4)+                        ; bql_BltCPt
        move.w  d0,(a4)+                        ; bql_BltBMod, 4 * dy
        move.w  d3,(a4)+                        ; bql_BltAMod, 4 * (dy - dx)
        move.w  d5,(a4)+                        ; bql_BltAPtLo, 4 * dy - 2 * dx
        ;move.l  #blitter_temp_output_word,(a4)+ ; bql_BltDPt
        move.l  a1,(a4)+ ; bql_BltDPt
        move.w  d2,(a4)+                        ; bql_BltSize
        CALLFW  AddToBlitterQueue
        rts

.octants
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD                              ; octant 7
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_AUL                 ; octant 4
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_SUL                 ; octant 0
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_SUL|BLTCON1F_AUL    ; octant 3
        dc.b    BLTCON1F_LINE|0                                         ; octant 6
        dc.b    BLTCON1F_LINE|BLTCON1F_SUL                              ; octant 5
        dc.b    BLTCON1F_LINE|BLTCON1F_AUL                              ; octant 1
        dc.b    BLTCON1F_LINE|BLTCON1F_SUL|BLTCON1F_AUL                 ; octant 2
        even

.bq_routine
        PUTMSG  50,<"LineDraw %p">,a0
        move.l  (a0)+,bltcon0(a5)
        move.l  (a0)+,bltcpt(a5)
        move.l  (a0)+,bltbmod(a5)
        move.l  (a0)+,bltapt+2(a5)
        move.l  (a0)+,bltdpt+2(a5)
        rts
