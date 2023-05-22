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

kds_blitter_line_init:
        moveq.l #-1,d0

        BLTHOGON
        BLTWAIT
        move.w  #BLTCON1F_LINE,bltcon1(a5)

        move.w  #$8000,bltadat(a5)
        move.l  d0,bltafwm(a5)
        move.w  d4,bltcmod(a5)
        move.w  d0,bltbdat(a5)
        rts

kds_draw_blitter_singledot_line:
        IF      1
        cmp.w   d1,d3
        bge.s   .downward
        exg     d0,d2
        exg     d1,d3
.downward
        ENDC

        move.w  d1,d5
        mulu    d4,d5
        add.l   d5,a0

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
        IF      0
        bpl.s   .positiveDY
        neg.w   d3
        addq.w  #2,d4
.positiveDY
        ENDC
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

        BLTWAIT

        move.l  d4,bltcon0(a5)
        move.w  d3,bltamod(a5)  ; 4 * (dy - dx)
        move.w  d0,bltbmod(a5)  ; 4 * dy
        move.w  d5,bltapt+2(a5) ; 4 * dy - 2 * dx

        move.l  a0,bltcpt(a5)
        ;move.l  #blitter_temp_output_word,bltdpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d2,bltsize(a5)

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

kds_draw_blitter_normal_line:
        IF      1
        cmp.w   d1,d3
        bge.s   .downward
        exg     d0,d2
        exg     d1,d3
.downward
        ENDC

        move.w  d1,d5
        mulu    d4,d5
        add.l   d5,a0

        moveq.l #-16,d4
        and.w   d0,d4
        lsr.w   #3,d4
        add.w   d4,a0

        moveq.l #15,d4
        and.w   d0,d4
        ror.w   #4,d4
        or.w    #BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|(BLT_A&BLT_B|BLT_C),d4
        swap    d4

        sub.w   d0,d2
        bpl.s   .positiveDX
        neg.w   d2
        addq.w  #1,d4
.positiveDX
        sub.w   d1,d3
        IF      0
        bpl.s   .positiveDY
        neg.w   d3
        addq.w  #2,d4
.positiveDY
        ENDC
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

        BLTWAIT

        move.l  d4,bltcon0(a5)
        move.w  d3,bltamod(a5)  ; 4 * (dy - dx)
        move.w  d0,bltbmod(a5)  ; 4 * dy
        move.w  d5,bltapt+2(a5) ; 4 * dy - 2 * dx

        move.l  a0,bltcpt(a5)
        ;move.l  #blitter_temp_output_word,bltdpt(a5)
        move.l  a0,bltdpt(a5)
        move.w  d2,bltsize(a5)

        rts

.octants
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD                                ; octant 7
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_AUL                   ; octant 4
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_SUL                   ; octant 0
        dc.b    BLTCON1F_LINE|BLTCON1F_SUD|BLTCON1F_SUL|BLTCON1F_AUL      ; octant 3
        dc.b    BLTCON1F_LINE|0                                           ; octant 6
        dc.b    BLTCON1F_LINE|BLTCON1F_SUL                                ; octant 5
        dc.b    BLTCON1F_LINE|BLTCON1F_AUL                                ; octant 1
        dc.b    BLTCON1F_LINE|BLTCON1F_SUL|BLTCON1F_AUL                   ; octant 2
