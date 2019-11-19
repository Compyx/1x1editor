; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :

SPRITES = $0340

data_view
        .byte %11111111, %11000000, 0
        .for row = 0, row < 8, row += 1
        .byte %10000000, %01000000, 0
        .next
        .byte %11111111, %11000000, 0
data_view_end

data_zoom_single
        .byte %11111111, 0, 0
        .byte %10000001, 0, 0
        .byte %10000001, 0, 0
        .byte %10000001, 0, 0
        .byte %10000001, 0, 0
        .byte %10000001, 0, 0
        .byte %10000001, 0, 0
        .byte %11111111, 0, 0
data_zoom_single_end

data_zoom_multi
        .byte %11111111, %11111111, 0
        .byte %10000000, %00000001, 0
        .byte %10000000, %00000001, 0
        .byte %10000000, %00000001, 0
        .byte %10000000, %00000001, 0
        .byte %10000000, %00000001, 0
        .byte %10000000, %00000001, 0
        .byte %11111111, %11111111, 0
data_zoom_multi_end




sprite_colors
        .byte 1,1,1,1,1,1,1,1

generate_sprites
        ; clear sprites
        ldx #0
        txa
-       sta SPRITES,x
        inx
        cpx #$c0
        bne -

        ; view sprite (used to indicate currently selected character)
        ldx #0
-       lda data_view,x
        sta SPRITES,x
        inx
        cpx #data_view_end - data_view
        bne -

        ; single color zoom
        ldx #0
-       lda data_zoom_single,x
        sta SPRITES + $40,x
        inx
        cpx #data_zoom_single_end - data_zoom_single
        bne -

        ; multi color zoom
        ldx #0
-       lda data_zoom_multi,x
        sta SPRITES + $80,x
        inx
        cpx #data_zoom_multi_end - data_zoom_multi
        bne -


        ; set all pointers
        ldx #(SPRITES / 64)
        stx $07f9
        inx
        stx $07f8
        inx
        stx $07fa
        rts


update_sprites .proc
        lda #%111
        sta $d015
        lda #0
        sta $d017
        sta $d01b
        sta $d010
        sta $d01d

        ldx #7
-       lda sprite_colors,x
        sta $d027,x
        dex
        bpl -

        lda data.zoom_xpos
        asl
        asl
        asl
        clc
        adc #$17
        sta $d000
        lda data.zoom_ypos
        asl
        asl
        asl
        clc
        adc #$31
        sta $d001

        lda data.view_index
        and #$1f
        asl
        asl
        asl
        clc
        adc #$37
        sta $d002
        bcc +
        lda $d010
        ora #2
        sta $d010
+       lda data.view_index
        lsr
        lsr
        and #$f8
        clc
        adc #$b9
        sta $d003

        lda data.color_index
        asl
        asl
        asl
        clc
        adc #$71
        sta $d005
        lda #$47
        sta $d004

        ldx #$0e
        lda data.mc_mode
        beq +
        ldx #$0f
+       stx $07f8
        rts
.pend


flash_sprites .proc
delay   lda #3
        beq +
        dec delay + 1
        rts
+       lda #3
        sta delay + 1
index   ldx #0
        lda data.flash_table,x
        cmp #$ff
        bne +
        ldx #0
        stx index + 1
        lda data.flash_table,x
+       ldx #7
-       sta sprite_colors,x
        dex
        bpl -
        inc index + 1
        rts
.pend
