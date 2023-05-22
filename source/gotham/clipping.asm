; QuickClip
;
; d0.w/d1.w = x1/y1
; d2.w/d3.w = y2/y2
; d4.w/d5.w = maxx/maxy

CLIPACCEPTCHECK MACRO
        tst.w   \2
        blt.s   .reject     ; xe < 0
        cmp.w   d4,\1
        bgt.s   .reject     ; xs > maxx
        tst.w   d3
        blt.s   .reject     ; ye < 0
        cmp.w   d5,d1
        bgt.s   .reject     ; ys > maxy
        ENDM

DOCLIPLOW MACRO
        tst.w   \1
        bge.s   .nocliplow\@ ; xs > 0
        ; if ((y0+=(xL-x0)*(y1-y0)/(x1-x0)) > yT) return
        sub.w   \2,\4       ; dy
        beq.s   .reject
        move.w  \3,d6
        sub.w   \1,d6       ; dx
        beq.s   .reject
        muls    \4,\1       ; dy*xs
        divs    d6,\1       ; (dy*xs)/dx
        bvs.s   .reject
        add.w   \2,\4       ; restore ye
        sub.w   \1,\2       ; ys += (dy*xs)/dx
        blt.s   .reject
        cmp.w   \5,\2
        bhi.s   .reject
        moveq.l #0,\1       ; xs = 0
.nocliplow\@
        ENDM

DOCLIPHIGH MACRO
        cmp.w   \3,\5
        bge.s   .nocliphigh\@
        ; y1 = y0 + (xR-x0)*(y1-y0)/(x1-x0); x1 = xR;
        sub.w   \1,\3       ; dx
        move.w  \4,d6
        sub.w   \2,d6       ; dy
        beq.s   .reject
        move.w  \5,\4       ; overwrites ye
        sub.w   \1,\4       ; maxx-xs
        beq.s   .reject
        muls    d6,\4       ; dy*(maxx-xs)
        divs    \3,\4       ; dy*(maxx-xs)/dx
        bvs.s   .reject
        add.w   \2,\4       ; y1 = y0 + dy*(maxx-xs)/dx
        cmp.w   \6,\4
        bhi.s   .reject
        move.w  \5,\3       ; xe = maxx
.nocliphigh\@
        ENDM

DOCLIPCHECK MACRO
        DOCLIPLOW d0,d1,d2,d3,d5
        DOCLIPLOW d1,d0,d3,d2,d4
        DOCLIPHIGH d0,d1,d2,d3,d4,d5
        DOCLIPHIGH d1,d0,d3,d2,d5,d4
        ENDM

gth_clip_line:
        cmp.w   d1,d3
        bge.s   .downward
        exg     d0,d2
        exg     d1,d3
.downward
        cmp.w   d0,d2
        bge.s   .rightward
        CLIPACCEPTCHECK d2,d0
        ; flip horizontally
        sub.w   d4,d0
        sub.w   d4,d2
        neg.w   d0
        neg.w   d2
        DOCLIPCHECK
        sub.w   d4,d0
        sub.w   d4,d2
        neg.w   d0
        neg.w   d2
        moveq.l #-1,d4
        rts
.reject
        moveq.l #0,d4
        rts
.rightward
        CLIPACCEPTCHECK d0,d2
        DOCLIPCHECK
        moveq.l #-1,d4
        rts
