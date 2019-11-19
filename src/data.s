; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :

; Buffer for copy/paste
buffer          .fill 8, 0


mc_mode         .byte 0 ; either 0 (off), or $10 (on)

zoom_xpos       .byte 0 ; cursor X position in zoom
zoom_ypos       .byte 0 ; cursor Y position in zoom

view_index      .byte 0 ; currently selected char in view

; Colors
; XXX:  don't change the order of these values, they are used indexed as a
;       small table
colors
col_bg          .byte $0b
col_mc1         .byte $0c
col_mc2         .byte $0f
col_fg          .byte $01

; Currently selected color, index into the previous four colors
color_index     .byte 0


; Helper tables for single color bit manipulation
single_color_bits
        .byte 128, 64, 32, 16, 8, 4, 2, 1
single_color_bits_inv
        .byte 1, 2, 4, 8, 16, 32, 64, 128

; Helper tables for multi color bit manipulation
multi_mask
        .byte %00111111, %11001111, %11110011, %11111100
; XXX:  don't change the order of the following three tables, they belong
;       together
multi_d022
        .byte %01000000, %00010000, %00000100, %00000001
multi_d023
        .byte %10000000, %00100000, %00001000, %00000010
multi_d800
        .byte %11000000, %00110000, %00001100, %00000011


; Main/Help text
help_text
        .enc "none"
        .text $f1, "1x1 editor 1.0.1 - cpx/focus", $0d
        .text $f7, "cursor ", $ff, " move zoom cursor", $0d
        .text $f7, "@ ; / :", $ff, " move view cursor", $0d
        .text $f7, "space  ", $ff, " plot/remove pixel", $0d
        .text $f7, "1", $ff, "-", $f7, "4 ", $ff, "    select color", $0d
        .text $ff, "sh+", $f7, "1", $ff, "-", $f7, "4", $ff, "  change color", $0d
        .text $f7, "b", $ff, "/sh+", $f7, "b", $ff, "  copy to/paste from buf", $0d
        .text $f7, "c", $ff, "/sh+", $f7, "c", $ff, "  clear char/charset", $0d
        .text $f7, "g", $ff, "/sh+", $f7, "g", $ff, "  copy chargen A/B", $0d
        .text $f7, "m", $ff, "/sh+", $f7, "m", $ff, "  mirror char in X/Y dir", $0d
        .text $f7, "x", $ff, "/sh+", $f7, "x", $ff, "  rotate char in X dir", $0d
        .text $f7, "y", $ff, "/sh+", $f7, "y", $ff, "  rotate char in Y dir", $0d
        .text $f7, "f5", $ff, "      toggle multicolor", $0d
        .text $f7, "c=", $ff, "/", $f7, "ctrl", $ff, " show chargen A/B", $0d
        .byte 0

; Status display text, shows colors, currently select char (index and chargen
; look, memory location)
status_text
        .enc "screen"
        .text "d021: ", $ef, $fa
        .text "d022: ", $ef, $fa
        .text "d023: ", $ef, $fa
        .text "d800: ", $ef, $fa
        .text "chr: ' '"
        .text "idx: $ff"
        .text "mem:0123"

; Table with colors to flash the sprites
flash_table
        .byte 1,1,1,1,1,1,1,1,1,7,15,14,4,6,0,0,0,0,0,0,0,6,4,14,15,7,1,$ff


;
; Prompts for actions that work on the entire charset
;


text_clear_charset
        .text "really clear ", $f1, "charset", $ff, "?", 0

text_copy_chargen_A
        .text "copy ", $f1, "chargen a", $ff, " ($d000-$d7ff)?", 0

text_copy_chargen_B
        .text "copy ", $f1, "chargen b", $ff, " ($d800-$d700)?", 0



