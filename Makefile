# vim: set noet ts=8 sw=8 sts=8:
#
#
VPATH=src

ASM=64tass
ASM_FLAGS=--ascii --case-sensitive -Wall -Wno-implied-reg --m6502
ASM_LABELS=--vice-labels -l $(LABEL_FILE)

X64=x64sc
X64_FLAGS=


LABEL_FILE=labels.txt

KERNAL=/usr/local/lib64/vice/C64/kernal
KERNAL_PATCHED=kernal-quick-memtest


TARGET=1x1editor.prg
SOURCES=src/main.s src/data.s src/edit.s src/sprites.s src/zoom.s
DATA=

all: $(TARGET)


$(TARGET): $(SOURCES) $(DATA)
	$(ASM) $(ASM_FLAGS) -o $@ $<


$(KERNAL_PATCHED): $(KERNAL)
	cp $(KERNAL) $(KERNAL_PATCHED)
	echo '1d69: 9f' | xxd -r - $(KERNAL_PATCHED)


run: $(TARGET) $(KERNAL_PATCHED)
	$(X64) $(X64_FLAGS) -kernal $(KERNAL_PATCHED) \
		-autostartprgmode 1 -autostart-delay 1 \
		$(TARGET) 2>&1 >vice.log


# Remove generated files
.PHONY: clean
clean:
	rm -f $(TARGET) $(KERNAL_PATCHED)

# Generate a tar.bz file outside the project directory
.PHONY: srcdist
srcdist: clean
	cd .. && tar -cjf 1x1editor-`date +'%Y%m%d'`.tar.bz 1x1editor/

