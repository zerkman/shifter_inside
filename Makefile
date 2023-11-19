
#TARGETS=timing.mfm.xz
PROGS=shin.prg

AS=vasmm68k_mot
ASOPT=-m68000 -Ftos
CC=gcc
CFLAGS=-g -Wall

all: $(TARGETS) $(PROGS)

clean:
	rm -f $(TARGETS) $(PROGS) *.o

%.st: $(PROGS)
	hmsa $@ SS
	sudo mount -oloop -tmsdos $@ /mnt
	sudo cp $^ /mnt
	sudo umount /mnt

%.xz: %
	xz -f9 $<

%.mfm: %.st
	../../tools/st2mfm $< $@
	rm $<

%.prg: %.s
	$(AS) $(ASOPT) $< -o $@
