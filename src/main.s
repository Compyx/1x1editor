; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :
;
; Simple 1x1 charset editor
;
; No disk menu, so use VICE's monitor or a cart to save/load charset
; Written in 2016, so some 64tass code might be outdated.



        STATUS_TEXT_POS = $0540
        CHARSET = $2000

        PROMPT_POS = $0658

        ; flags for executing code after handling an input event
        UPDATE_STATUS = $100    ; update status text/colors
        UPDATE_ZOOM = $200      ; update zoom
        UPDATE_VIEW = $400      ; update view colors


        zp = $10

        * = $0801
        .word (+)
        .word 2016
        .null $9e, format("%d", init)
+       .word 0

; start of actual code ($080d)
        jmp init

data    .binclude "data.s"
edit    .binclude "edit.s"
sprites .binclude "sprites.s"
zoom    .binclude "zoom.s"

; Table of keys used. Each entry is a keyscan code as returned by GETIN with
; flags for doing things like updating the zoom or status display (bit 8-15)
; and a pointer to the subroutine to call
; The subroutine is called with the scanned key in A
keys
        ; SPACE - plot/invert pixel
        .word $20|UPDATE_ZOOM, edit.plot


        ; UP
        .word $91, edit.zoom_up
        ; RIGHT
        .word $1d, edit.zoom_right
        ; DOWN
        .word $11, edit.zoom_down
        ; LEFT
        .word $9d, edit.zoom_left

        ; @ or [ - move view cursor up one row
        .word $40|UPDATE_STATUS|UPDATE_ZOOM, edit.view_up
        ; ; or ' - move view cursor right one column
        .word $3b|UPDATE_STATUS|UPDATE_ZOOM, edit.view_right
        ; /      - move view cursor down one row
        .word $2f|UPDATE_STATUS|UPDATE_ZOOM, edit.view_down
        ; : or ; - move view cursor left one column
        .word $3a|UPDATE_STATUS|UPDATE_ZOOM, edit.view_left

        .word $87|UPDATE_ZOOM|UPDATE_VIEW, edit.switch_mode

        .word $31, edit.set_color
        .word $32, edit.set_color
        .word $33, edit.set_color
        .word $34, edit.set_color

        .word $21|UPDATE_STATUS|UPDATE_ZOOM, edit.inc_color
        .word $22|UPDATE_STATUS|UPDATE_ZOOM|UPDATE_VIEW, edit.inc_color
        .word $23|UPDATE_STATUS|UPDATE_ZOOM, edit.inc_color
        .word $24|UPDATE_STATUS|UPDATE_ZOOM, edit.inc_color

        ; 'c' - Clear currently select character
        .word $43|UPDATE_ZOOM, edit.clear_char
        ; 'C'  - Clear entire charset
        .word $c3|UPDATE_ZOOM, edit.clear_charset

        ; 'g' - copy CHARGEN A ($d000-$d7ff)
        .word $47|UPDATE_ZOOM, edit.copy_chargen_A
        ; 'G' - copy CHARGEN B ($d800-$dfff)
        .word $c7|UPDATE_ZOOM, edit.copy_chargen_B

        ; 'x' - rotate char left
        .word $58|UPDATE_ZOOM, edit.rotate_left
        ; 'X' - rotate char right
        .word $d8|UPDATE_ZOOM, edit.rotate_right

        ; 'y' - rotate char up
        .word $59|UPDATE_ZOOM, edit.rotate_up
        ; 'Y' - rotate char down
        .word $d9|UPDATE_ZOOM, edit.rotate_down

        ; 'm' - mirror character in x-direction
        .word $4d|UPDATE_ZOOM, edit.mirror_x
        ; 'M' - mirror character in y-direction
        .word $cd|UPDATE_ZOOM, edit.mirror_y

        ; 'b' - copy current character to buffer
        .word $42, edit.buffer_copy
        ; 'B' - paste buffer into current character
        .word $c2|UPDATE_ZOOM, edit.buffer_paste

keys_end

; Last key pressed
last_key_code   .byte 0
; Flags of last key pressed
last_key_flags  .byte 0
; Index in keys table for last key pressed
last_key_index  .byte 0


; Initialize editor
;
; Setup view and zoom, generate sprites, setup IRQ, start keyscan loop
;
init
        lda #$37
        sta $01
        jsr $fda3
        jsr $fd15
        jsr $ff5b

        ; remove when done testing
        ; clc
        ; jsr edit.copy_chargen

        sei
        lda #$7f
        sta $dc0d
        sta $dd0d
        ldx #0
        stx $dc0e
        stx $dc0f
        stx $dd0e
        stx $dd0f
        stx $3fff
        inx
        stx $d01a
        lda #$2c
        sta $d012
        lda #$1b
        sta $d011
        lda #<irq1
        ldx #>irq1
        sta $0314
        stx $0315
        ; Ack any pending IRQ's
        asl $d019
        lda $dc0d
        lda $dd0d
        cli
        lda #6
        sta $d020
        sta $d021
        lda #$0f
        ldx #0
-       sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $db00,x
        inx
        bne -

        jsr sprites.generate_sprites
        jsr zoom.render_grid
        jsr zoom.render_view
        jsr zoom.update_view
        jsr render_status_text
        jsr render_help_text
        jsr update_status_text
        jsr zoom.update

        ; keyboard scan loop
key_scan
        jsr $ffe4
        cmp #0
        beq key_scan
        ldx #0
-       cmp keys,x
        beq key_exec
        inx
        inx
        inx
        inx
        cpx #keys_end-keys
        bne -
        jmp key_scan
key_exec
        sta last_key_code
        stx last_key_index

        lda keys + 2,x
        sta key_jsr + 1
        lda keys + 3,x
        sta key_jsr + 2

        lda last_key_code
key_jsr
        jsr $fce2
        ; check for anything to do after the JSR
        ldx last_key_index
        lda keys + 1,x
        sta last_key_flags
        and #>UPDATE_STATUS
        beq +
        jsr update_status_text
+       lda last_key_flags
        and #>UPDATE_ZOOM
        beq +
        jsr zoom.update
+       lda last_key_flags
        and #>UPDATE_VIEW
        beq +
        jsr zoom.update_view
+


        jmp key_scan


irq1
        lda #$1b
        sta $d011
        lda #$14
        sta $d018
        lda #8
        sta $d016
        dec $d020
        inc $d020

        lda #$b9
        ldx #<irq2
        ldy #>irq2
do_irq
        sta $d012
        stx $0314
        sty $0315
        lda #1
        sta $d019
        jmp $ea81

irq2
        ldx #3
-       dex
        bne -
        lda data.col_bg
        sta $d020
        sta $d021
        lda #$08
        ora data.mc_mode
        sta $d016
irq_vidram
        lda #$18
        sta $d018
        lda data.col_mc1
        sta $d022
        lda data.col_mc2
        sta $d023

        lda #$f9
        ldx #<irq3
        ldy #>irq3
        jmp do_irq

irq3
        lda #$13
        sta $d011
        ldx #11
-       dex
        bne -
        lda #6
        sta $d020
        sta $d021
        lda #$14
        sta $d018
        lda #8
        sta $d016

        jsr sprites.update_sprites

        ldx #20
-       dex
        bne -
        lda #$1b
        sta $d011

        jsr handle_special_keys

        jsr sprites.flash_sprites

        lda #$2c
        ldx #<irq1
        ldy #>irq1
        sta $d012
        stx $0314
        sty $0315
        lda #1
        sta $d019
        jmp $ea31


; Render the main/help text on screen
render_help_text .proc
        txt = zp
        vidram = zp + 2
        colram = zp + 4
        offset = zp + 6
        color = zp + 7

        lda #<data.help_text
        ldx #>data.help_text
        sta txt
        stx txt + 1

        lda #$09
        ldx #$04
        ldy #$d8
        sta vidram
        stx vidram + 1
        sta colram
        sty colram + 1

        lda #15
        sta color
        lda #0
        sta offset
rht_more
        ldy #0
        lda (txt),y
        bne +
        rts     ; EOT
+       cmp #$f0
        bcc rht_check_cr
        and #$0f
        sta color
rht_txt_inc
        inc txt
        bne +
        inc txt + 1
+       jmp rht_more
rht_check_cr
        cmp #$0d
        bne rht_plot
        lda vidram
        clc
        adc #40
        sta vidram
        sta colram
        bcc +
        inc vidram + 1
        inc colram + 1
+       lda #0
        sta offset
        jmp rht_txt_inc
rht_plot
        ldy offset
        and #$3f
        sta (vidram),y
        lda color
        sta (colram),y
        inc offset
        jmp rht_txt_inc
.pend


; Render the 'status' display
render_status_text .proc
        ldx #7
-
        .for row = 0, row < 7, row += 1
        lda data.status_text + row * 8,x
        sta STATUS_TEXT_POS + row * 40,x
        lda #$0f
        sta ((STATUS_TEXT_POS & $03ff) + $d800) + row * 40,x
        .next
        dex
        bpl -
        rts
.pend


; Update the 'status' display
update_status_text .proc

        tmp = zp

        ; show current colors
        lda data.col_bg
        sta (STATUS_TEXT_POS & $03ff) + $d800 + 6
        sta (STATUS_TEXT_POS & $03ff) + $d800 + 7
        lda data.col_mc1
        sta (STATUS_TEXT_POS & $03ff) + $d828 + 6
        sta (STATUS_TEXT_POS & $03ff) + $d828 + 7
        lda data.col_mc2
        sta (STATUS_TEXT_POS & $03ff) + $d850 + 6
        sta (STATUS_TEXT_POS & $03ff) + $d850 + 7
        lda data.col_fg
        sta (STATUS_TEXT_POS & $03ff) + $d878 + 6
        sta (STATUS_TEXT_POS & $03ff) + $d878 + 7

        ; current char's CHARGEN equivalent and index in the charset
        lda data.view_index
        sta STATUS_TEXT_POS + (4 * 40) + 6
        jsr hexdigits
        sta STATUS_TEXT_POS + (5 * 40) + 6
        stx STATUS_TEXT_POS + (5 * 40) + 7


        lda data.view_index
        jsr edit.get_char_ptr
        stx tmp         ; LSB

        jsr hexdigits
        sta STATUS_TEXT_POS + (6 * 40) + 4
        stx STATUS_TEXT_POS + (6 * 40) + 5
        lda tmp
        jsr hexdigits
        sta STATUS_TEXT_POS + (6 * 40) + 6
        stx STATUS_TEXT_POS + (6 * 40) + 7

        colram = (STATUS_TEXT_POS & $03ff) + $d800

        lda #$01
        sta colram + (4 * 40) + 6
        sta colram + (5 * 40) + 6
        sta colram + (5 * 40) + 7
        ldx #3
-       sta colram + (6 * 40) + 4,x
        dex
        bpl-
        rts
.pend


hexdigits .proc
        pha
        and #$0f
        cmp #$0a
        bcc +
        sbc #$39
+       adc #$30
        tax
        pla
        lsr
        lsr
        lsr
        lsr
        cmp #$0a
        bcc +
        sbc #$39
+       adc #$30
        rts
.pend


; Handle 'special' keys: CBM to show CHARGEN A, CTRL to show CHARGEN B
handle_special_keys .proc

        lda #$18                ; user-editable charset
        sta irq_vidram + 1

        lda #$7f
        sta $dc00
        lda $dc01
        sta tmp + 1
        and #$20        ; CBM
        bne +
        lda #$14                ; CHARGEN A ($d000-$d7ff)
        sta irq_vidram + 1
        rts
tmp
+       lda #0
        and #$04
        bne +
        lda #$16                ; CHARGEN B ($d800-$dfff)
        sta irq_vidram + 1
+       rts
.pend


; Text display in case of a yes/no prompt
yesno_text
        .text $ff, "(", $f7, "y", $ff, "/", $f7, "n", $ff, ")", 0


; Clear prompt line and set colors to $0f
prompt_clear .proc

        ldx #39
-       lda #$20
        sta PROMPT_POS,x
        lda #$0f
        sta (PROMPT_POS & $03fff) + $d800,x
        dex
        bpl -
        rts
.pend

; Display yes/no prompt
;
; A = text LSB, X = text MSB
;
; return:       C = 0 -> No, C = 1 -> Yes
prompt_yesno .proc

        txt = zp
        col = zp + 2
        done = zp + 3

        sta txt
        stx txt + 1

        jsr prompt_clear

        lda #0
        sta done

        lda #$0f
        sta col

        ldx #0
        ldy #0
more
-       lda (txt),y
        beq print_yesno
        cmp #$f0
        bcc +
        and #$0f
        sta col
        iny
        bne -
+       sta PROMPT_POS,x
        lda col
        sta (PROMPT_POS & $03ff) + $d800,x

        inx
        iny
        bne -
print_yesno
        ldy done
        bne get_yesno
        inx
        lda #<yesno_text
        sta txt
        lda #>yesno_text
        sta txt + 1
        inc done
        ldy #0
        jmp more
get_yesno
        jsr $ffe4
        cmp #0
        beq get_yesno
        cmp #$59
        beq +
        jsr prompt_clear
        clc
        rts
+       jsr prompt_clear
        sec
        rts

.pend

