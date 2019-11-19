; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :

GRID_POS = $0400
VIEW_POS = $0400 + (17 * 40)

; Render grid for zoom area
render_grid .proc

        vidram = zp
        colram = zp + 2

        lda #<GRID_POS
        ldx #>GRID_POS
        sta vidram
        stx vidram + 1
        lda #<((GRID_POS & $03ff) + $d800)
        ldx #>((GRID_POS & $03ff) + $d800)
        sta colram
        stx colram + 1

        lda data.mc_mode
        beq grid_sc

        ; generate multi color grid
        ldx #7
-
        ldy #0
-       lda #$ef
        sta (vidram),y
        lda #$fa
        iny
        sta (vidram),y
        iny
        cpy #8
        bne -
        dey
        lda #0
-       sta (colram),y
        dey
        bpl -
        lda vidram
        clc
        adc #40
        sta vidram
        sta colram
        bcc +
        inc vidram + 1
        inc colram + 1
+       dex
        bpl ---
        rts

grid_sc
        ; generate single color grid
        ldx #7
-       ldy #7
-       lda #$fa
        sta (vidram),y
        lda #0
        sta (colram),y
        dey
        bpl -
        lda vidram
        clc
        adc #40
        sta vidram
        sta colram
        bcc +
        inc vidram + 1
        inc colram + 1
+       dex
        bpl --
        rts
.pend


; Render a 32*8 character grid for viewing the charset
render_view .proc
        vidram = zp

        ; render 32*8 chars
        lda #<(VIEW_POS + 4)
        ldx #>(VIEW_POS + 4)
        sta vidram
        stx vidram + 1

        ldx #0
-       ldy #0
        txa
        clc
        asl
        asl
        asl
        asl
        asl
-       sta (vidram),y
        adc #1
        iny
        cpy #32
        bne -
        lda vidram
        clc
        adc #40
        sta vidram
        bcc +
        inc vidram + 1
+       inx
        cpx #8
        bne --
        rts
.pend



update  .proc
        lda data.mc_mode
        bne +
        jmp zoom_single_color
+       jmp zoom_multi_color
.pend



update_view .proc

        colram = zp
        color = zp + 2

        lda #<((VIEW_POS & $03ff) + $d800)
        ldx #>((VIEW_POS & $03ff) + $d800)
        sta colram
        stx colram + 1

        lda data.col_fg
        ldx data.mc_mode
        beq +
        ora #8
+       sta color


        ldx #7
-
        ldy #39
        lda data.col_bg
-       sta (colram),y
        dey
        cpy #35
        bne -
        lda color
-       sta (colram),y
        dey
        cpy #3
        bne -
        lda data.col_bg
-       sta (colram),y
        dey
        bpl -

        lda colram
        clc
        adc #40
        sta colram
        bcc +
        inc colram + 1
+
        dex
        bpl ----
        rts
.pend



zoom_single_color .proc
        char = zp
        row = zp + 2


        jsr edit.get_char_ptr
        stx char + 0
        sty char + 1

        lda #0
        ldx #$d8
        sta vidram + 1
        stx vidram + 2

        ldy #0
        sty row
-
        lda (char),y

        ldy #7
-
        lsr
        pha
        ldx #0
        bcc +
        ldx #3
+       lda data.colors,x
vidram  sta $d800,y
        pla
        dey
        bpl -

        lda vidram + 1
        clc
        adc #40
        sta vidram + 1
        bcc +
        inc vidram + 2
+       inc row
        ldy row
        cpy #8
        bne --
        rts
.pend



zoom_multi_color .proc

        char = zp
        vidram = zp + 2
        row = zp + 4
        ctmp = zp + 5

        jsr edit.get_char_ptr
        stx char + 0
        sty char + 1

        lda #0
        ldx #$d8
        sta vidram
        stx vidram + 1

        ldy #0
        sty row
-
        lda (char),y
        sta ctmp

        ; %11000000
        clc
        rol
        rol
        rol
        and #3
        tax
        lda data.colors,x

        ldy #0
        sta (vidram),y
        iny
        sta (vidram),y
        iny

        ; % 00110000
        lda ctmp
        lsr
        lsr
        lsr
        lsr
        and #3
        tax
        lda data.colors,x
        sta (vidram),y
        iny
        sta (vidram),y
        iny

        ; % 00001100
        lda ctmp
        lsr
        lsr
        and #3
        tax
        lda data.colors,x
        sta (vidram),y
        iny
        sta (vidram),y
        iny

        lda ctmp
        and #3
        tax
        lda data.colors,x
        sta (vidram),y
        iny
        sta (vidram),y

        lda vidram
        clc
        adc #40
        sta vidram
        bcc +
        inc vidram + 1
+
        inc row
        ldy row
        cpy #8
        bne -
        rts
.pend

