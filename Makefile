# vim: set noet ts=8 sw=8 sts=8:
#
#
VPATH=src

ASM=64tass
ASM_FLAGS=--ascii --case-sensitive -Wall -Wno-implied-reg --m6502
ASM_LABELS=--vice-labels -l $(LABEL_FILE)

X64=x64sc
X64_FLAGS=

EXO=exomizer

LABEL_FILE=labels.txt

KERNAL=/usr/local/lib64/vice/C64/kernal
KERNAL_PATCHED=kernal-quick-memtest


TARGET = 1x1editor.prg
TARGET_EXO = 1x1editor-exo.prg
TARGET_ZIP = 1x1editor.zip

SOURCES = src/main.s src/data.s src/edit.s src/sprites.s src/zoom.s
DATA = data/prop-2000-22ff.prg

all: $(TARGET)


$(TARGET): $(SOURCES) $(DATA)
	$(ASM) $(ASM_FLAGS) -o $@ $<


# Remove generated files
.PHONY: clean
clean:
	rm -f $(TARGET)
	rm -f $(TARGET_EXO)


# Generate a tar.bz file outside the project directory
.PHONY: srcdist
srcdist: clean
	cd .. && tar -cjf 1x1editor-`date +'%Y%m%d'`.tar.bz 1x1editor/


# Generate an exomized binary
release: $(TARGET)
	$(EXO) sfx basic $(TARGET) -o $(TARGET_EXO)


# Generate an zipped version of the exomized prg since some forums won't
# accept .prg files
release-zip: release
	rm -f $(TARGET_ZIP)
	zip $(TARGET_ZIP) $(TARGET_EXO)
