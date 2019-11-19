; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :

; Multiply accumulator by 8
;
; Result:       bit 0-7 in X, bit 8-15 in Y, A untouched
mul8 .proc
        pha
        clc
        rol
        rol
        rol
        pha
        and #$f8
        tax
        pla
        rol             ; one more to shift the last C in
        and #$07
        tay
        pla
        rts
.pend


; Get pointer to current character's data
;
; Result:       bit 0-7 in X, bit 8-15 in Y, clobbers A
get_char_ptr .proc
        lda data.view_index
        jsr mul8
        clc
        tya
        adc #>CHARSET
        tay
        rts
.pend



view_up .proc
        lda data.view_index
        sec
        sbc #$20
        sta data.view_index
        rts
.pend


view_right .proc

        tmp = zp

        lda data.view_index
        and #$e0
        sta tmp
        lda data.view_index
        clc
        adc #1
        and #$1f
        ora tmp
        sta data.view_index
        rts
.pend


view_down .proc
        lda data.view_index
        clc
        adc #$20
        sta data.view_index
        rts
.pend

view_left .proc
        tmp = zp

        lda data.view_index
        and #$e0
        sta tmp
        lda data.view_index
        sec
        sbc #1
        and #$1f
        ora tmp
        sta data.view_index
        rts
.pend


zoom_up .proc
        lda data.zoom_ypos
        beq +
        dec data.zoom_ypos
+       rts
.pend

zoom_right .proc
        lda data.mc_mode
        bne ++

        lda data.zoom_xpos
        cmp #7
        beq +
        inc data.zoom_xpos
+       rts

+
        lda data.zoom_xpos
        and #6
        cmp #6
        bne +
        rts
+
        lda data.zoom_xpos
        clc
        adc #2
        and #6
        sta data.zoom_xpos
        rts
.pend

zoom_down .proc
        lda data.zoom_ypos
        cmp #7
        beq +
        inc data.zoom_ypos
+       rts
.pend

zoom_left .proc
        lda data.mc_mode
        bne ++
        lda data.zoom_xpos
        beq +
        dec data.zoom_xpos
+       rts
+
        lda data.zoom_xpos
        and #6
        bne +
        rts
+
        sec
        sbc #2
        sta data.zoom_xpos
        rts

.pend


; Copy CHARGEN to charset
;
; Blocks IRQ and temporarily sets $01 to $33, enabled IRQ and set $01 to $37
; on exit.
;
; Input: C clear = $d000-$d7ff, C set $d800-$dfff
copy_chargen .proc

        chargen = zp
        charset = zp + 2

        lda #0
        ldx #$d0
        bcc +
        ldx #$d8
+       sta chargen
        stx chargen + 1
        sta charset
        lda #$20
        sta charset + 1
        sei
        lda #$33
        sta $01
        ldx #7
        ldy #0
-       lda (chargen),y
        sta (charset),y
        iny
        bne -
        inc chargen + 1
        inc charset + 1
        dex
        bpl -
        lda #$37
        sta $01
        cli
        rts
.pend


; Called from keyscan code: A contains keycode ('1'-'4')
set_color .proc
        sec
        sbc #1
        and #3
        sta data.color_index
        rts
.pend


; Called from keyscan code: A contains keycode ('1'-'4')
inc_color .proc
        sec
        sbc #1
        and #3
        tax
        lda data.colors,x
        clc
        adc #1
        and #15
        sta data.colors,x

        ; check color index
        cpx #3
        beq +
        rts
+
        ; update displayed colors
        lda data.col_fg
        ldx data.mc_mode
        beq +
        and #7
        sta data.col_fg
+       jsr zoom.update_view
        rts
.pend



; Switch between single and multi color mode
switch_mode .proc
        lda data.mc_mode
        and #$10
        eor #$10
        sta data.mc_mode
        jmp zoom.render_grid
.pend




; Plot or invert a pixel
;
; TODO: support multi-color
plot .proc
        lda data.mc_mode
        beq +
        jmp plot_multi_color
+       jmp plot_single_color
.pend


; Invert a single color pixel
plot_single_color .proc

        char = zp

        jsr edit.get_char_ptr
        stx char + 0
        sty char + 1

        ldy data.zoom_ypos
        ldx data.zoom_xpos
        lda (char),y
        eor data.single_color_bits,x
        sta (char),y
        rts
.pend


; Plot a multi-color pixel
plot_multi_color .proc
        char = zp
        tmp = zp + 2

        jsr edit.get_char_ptr
        stx char + 0
        sty char + 1

        ldy data.zoom_ypos
        lda data.zoom_xpos
        lsr
        tax
        stx tmp + 1
        lda (char),y
        and data.multi_mask,x
        sta tmp
        lda data.color_index
        beq +
        sec
        sbc #1
        clc
        asl
        asl
        adc tmp + 1
        tax
        lda tmp
        ora data.multi_d022,x
        sta (char),y
+       rts
.pend

; Clear currently selected character
clear_char .proc
        jsr get_char_ptr
        stx zp + 0
        sty zp + 1

        ldy #7
        lda #0
-       sta (zp),y
        dey
        bpl -
        rts
.pend


; Clear entire charset (prompts user)
clear_charset .proc

        lda #<data.text_clear_charset
        ldx #>data.text_clear_charset
        jsr prompt_yesno
        bcs +
        rts
+       lda #<CHARSET
        ldx #>CHARSET
        sta zp
        stx zp + 1
        ldx #7
        ldy #0
        tya
-       sta (zp),y
        iny
        bne -
        inc zp + 1
        dex
        bpl -
        rts
.pend



; Copy chargen A to charset (prompts user)
copy_chargen_A .proc
        lda #<data.text_copy_chargen_A
        ldx #>data.text_copy_chargen_A
        jsr prompt_yesno
        bcs +
        rts
+       clc
        jmp copy_chargen
.pend


; Copy chargen B to charset (prompts user)
copy_chargen_B .proc
        lda #<data.text_copy_chargen_B
        ldx #>data.text_copy_chargen_B
        jsr prompt_yesno
        bcs +
        rts
+       sec
        jmp copy_chargen
.pend


rotate_up .proc

        jsr edit.get_char_ptr
        sty zp + 1
        sty zp + 3
        stx zp + 0
        inx
        stx zp + 2

        ldy #0
        lda (zp),y
        pha

        ldy #0
-       lda (zp + 2),y
        sta (zp),y
        iny
        cpy #7
        bne -
        pla
        sta (zp),y

        rts
.pend


rotate_down .proc
        jsr edit.get_char_ptr
        sty zp + 1
        sty zp + 3
        stx zp + 0
        inx
        stx zp + 2

        ldy #7
        lda (zp),y
        pha

        dey
-       lda (zp),y
        sta (zp+ 2),y
        dey
        bpl -
        pla
        iny
        sta (zp),y
        rts
.pend

rotate_right .proc
        jsr get_char_ptr
        stx zp + 0
        sty zp + 1

        jsr rot_once
        lda data.mc_mode
        beq +
rot_once
        ldy #7
-       lda (zp),y
        pha
        and #1
        cmp #1
        ; C is either set or clear now
        pla
        ror
        sta (zp),y
        dey
        bpl -
+       rts

.pend

rotate_left .proc
        jsr get_char_ptr
        stx zp + 0
        sty zp + 1

        jsr rot_once
        lda data.mc_mode
        beq +
rot_once
        ldy #7
-       lda (zp),y
        pha
        and #$80
        cmp #$80
        pla
        rol
        sta (zp),y
        dey
        bpl -
+       rts
.pend


; Mirror character in X direction (along Y-axis)
mirror_x .proc

        char = zp
        tmp = zp + 2

        jsr get_char_ptr
        stx char + 0
        sty char + 1

        lda #0
        sta tmp + 1

        lda data.mc_mode
        bne mirror_mc

        ldy #7
-
        lda (char),y
        sta tmp
        ldx #0
        stx tmp + 1
-       lda tmp
        and data.single_color_bits,x
        beq +
        lda tmp + 1
        ora data.single_color_bits_inv,x
        sta tmp + 1
+       lda tmp
        and data.single_color_bits + 4,x
        beq +
        lda tmp + 1
        ora data.single_color_bits_inv + 4,x
        sta tmp + 1
+       inx
        cpx #4
        bne -
        lda tmp + 1
        sta (char),y
        dey
        bpl --
        rts
mirror_mc
        ldy #7
-
        lda (char),y
        sta tmp

        ; swap bit 7-6 with 1-0
        rol     ; C shifted in will be AND'ed out
        rol
        rol
        and #%00000011
        sta tmp + 1
        lda tmp
        ror     ; C shifted in will be AND'ed out
        ror
        ror
        and #%11000000
        ora tmp + 1
        sta tmp + 1

        ; swap bit 5-4 with 3-2
        lda tmp
        lsr
        lsr
        and #%00001100
        ora tmp + 1
        sta tmp + 1
        lda tmp
        asl
        asl
        and #%00110000
        ora tmp + 1

        sta (char),y

        dey
        bpl -
        rts
.pend


; Mirror current char in Y-direction (along X-axis)
mirror_y .proc
        jsr edit.get_char_ptr
        stx zp + 0
        sty zp + 1

        .for row = 0, row < 4, row += 1

        ldy #row
        lda (zp),y
        pha
        ldy #7 - row
        lda (zp),y
        ldy #row
        sta (zp),y
        pla
        ldy #7 - row
        sta (zp),y

        .next
        rts
.pend


buffer_copy .proc

        char = zp

        jsr get_char_ptr
        stx char + 0
        sty char + 1

        ldy #7
-       lda (char),y
        sta data.buffer,y
        dey
        bpl -
        rts
.pend


buffer_paste .proc

        char = zp

        jsr get_char_ptr
        stx char + 0
        sty char + 1

        ldy #7
-       lda data.buffer,y
        sta (char),y
        dey
        bpl -
        rts
.pend

