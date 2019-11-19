# 1x1 characterset editor
(c) 2017, Compyx/Focus


## Introduction

This is a very simple 1x1 characterset editor for the C64. I couldn't find any
editor that suited me (either joystick controlled or some weird keyboard control
that didn't make sense), so I wrote my own (again).

Right now it functions the way I want it. It does **not** have a disk menu, it
can't even load or save charactersets right now. If you need to load/save your
characterset, you have to do it manually, using either your cartridge's ML
monitor, or your emulator's monitor. The characterset is located at \$2000 at
the moment.


## Building

To build this editor, you need a fairly recent version (R1245 or later) of
[64tass](https://sourceforge.net/projects/tass64/). Either use `make` or run
64tass directly like this:
`64tass --ascii --case-sentitive --m6502 main.s -o 1x1editor.prg`


## Instructions

Use the following keys to control the editor:

| key(s)      | purpose |
| ----------- | ------- |
| Cursor keys | Move the cursor in the zoom area |
| Space       | Plot a pixel, in single color mode this inverts the current pixel, in multi color mode this plots the currently selected color |
| @, ;, /, :  | Move the cursor in the view area (on PC: [, ', /, ;) |
| 1-4         | Select color (only in multi color mode: 1=\$d021, 2=\$d022, 3=\$d800,4=\$d800+) |
| Shift + 1-4 | Increment color |
| b / B       | Copy to buffer / paste from buffer |
| c / C       | Clear current character / clear characterset |
| g / G       | Copy CHARGEN A (\$d000-\$d7ff) or CHARGEN B (\$d800-\$dfff) to character set |
| m / M       | Mirror character in X / Y direction |
| x / X       | Rotate character left / right |
| y / Y       | Rotate character up / down |
| F5          | Toggle multi color mode

Hold the *Commodore* key to display CHARGEN A in the view, and hold *Control* to
show CHARGEN B in the view. This can be useful when creating a custom charset
and figuring out where which character is in CHARGEN (I always forget).



