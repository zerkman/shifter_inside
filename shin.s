; shin.s - Shifter Inside - remove top and bottom borders in GEM desktop
;
; Copyright (c) 2023-2025 Francois Galea <fgalea at free.fr>
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

	opt	o+,p=68000

ADDSCR:	equ	(276*160-200*160+254)&$ffff00	; additional screen size in bytes

nops:	macro
	rept	\1/2
	or.l	d0,d0
	endr
	rept	\1%2
	nop
	endr
	endm

it_off:	macro
	bclr.b	#6,$fffffa15.w		; mask keyboard interrupt
	bclr.b	#5,$fffffa15.w		; mask Timer C (hz200) interrupt
	endm

it_on:	macro
	bset.b	#6,$fffffa15.w		; unmask keyboard interrupt
	bset.b	#5,$fffffa15.w		; unmask Timer C (hz200) interrupt
	endm


	section	text


begin:
	bra	install

	dc.b	'XBRA'
	dc.b	'shin'
oldvbl:	dc.l	0
vbl:
	clr.b	$fffffa1b.w	; timer B - stop
	move.b	#99,$fffffa21.w	; timer B - set counter
	move.b	#4,$fffffa1b.w	; timer B - delay mode,divide by 50
	move.l	#timer_b1,$120.w

	and.b	#$f0,$fffffa1d.w	; Timer D stop
	move.b	#88,$fffffa25.w	; timer D - set counter
	or.b	#4,$fffffa1d.w	; timer D - delay mode,divide by 50
	move	#$777,$ffff8240.w
	it_on
	clr.b	tb2cpt+1


	move.l	oldvbl(pc),-(sp)
	rts

timer_d:
	and.b	#$f0,$fffffa1d.w	; Timer D stop
	it_off
	bclr.b	#4,$fffffa11.w
	rte

timer_b1:
	clr.b	$fffffa1b.w	; timer B - stop
	move.b	#228,$fffffa21.w	; timer B - set counter
	move.b	#8,$fffffa1b.w	; timer B - event count mode
	move.l	#timer_b2,$120.w

	move	#$2100,sr
	stop	#$2100
	move	#$2700,sr
	nops	95

	move.b	#0,$ffff820a.w
	nops	9
	move.b	#2,$ffff820a.w
	move.b	#173,$fffffa25.w	; timer D - set counter
	or.b	#7,$fffffa1d.w	; timer D - delay mode,divide by 200
	it_on


	bclr.b	#0,$fffffa0f.w
hbl:	rte

timer_b2:
	clr.b	$fffffa1b.w	; timer B - stop
	movem.l	d0-d1,-(sp)
	move.b	$ffff8209.w,d0
tbwbc:
	move.b	$ffff8209.w,d1
	cmp.b	d0,d1
	beq.s	tbwbc
	sub.b	d1,d0
	lsr.l	d0,d0		; now we're on sync with display
	nops	51
	move.b	#44,$fffffa21.w	; timer B - set counter
	move.b	#8,$fffffa1b.w	; timer B - event count mode
	clr.b	$ffff820a.w
	nops	6
	move.b	#2,$ffff820a.w
	it_on
tb2cpt:	moveq	#0,d0
	bne.s	tb2_dont_td
	move.b	#58,$fffffa25.w	; timer D - set counter
	or.b	#6,$fffffa1d.w	; timer D - delay mode,divide by 100
	bra.s	tb2_do_td
tb2_dont_td:
	; this is line 308, close enough to next VBL
	it_off
tb2_do_td:
	addq.b	#1,tb2cpt+1
	movem.l	(sp)+,d0-d1

	bclr.b	#0,$fffffa0f.w
	rte

	dc.b	'XBRA'
	dc.b	'shin'
old_gem	dc.l	0
my_gem:
	cmp	#$73,d0		; VDI call ?
	bne.s	mgde		; no: back to system code

	move.l	d1,a0		; global array
	move.l	(a0),a0		; control array
	cmp	#1,(a0)		; v_opnwk() (control[0]==1) ?
	beq.s	v_opnwk
	cmp	#2,(a0)		; v_clswk() ?
	beq.s	v_clswk

mgde:	move.l	old_gem(pc),a0
	jmp	(a0)

v_clswk:
	move.l	d1,a0		; global array
	move.l	4(a0),a0	; intin array
	cmp	#2+2+1,(a0)	; if peripheral number too high (> 2+max res)
	bpl	mgde		; then it's not a standard screen mode
	tst	(a0)		; if too low
	ble	mgde		; no good either

	bclr	#0,$fffffa07.w	; deactivate timer B
	bclr	#0,$fffffa13.w	; mask timer B

	bclr	#4,$fffffa09.w	; disable Timer D
	bclr	#4,$fffffa15.w	; mask Timer D

	bra	mgde

v_opnwk:
	move.l	d1,a0		; global array
	move.l	4(a0),a0	; int_in array
	cmp	#2+2+1,(a0)	; if peripheral number too high (> 2+max res)
	bpl	mgde		; then it's not a standard screen mode
	tst	(a0)		; if too low
	ble	mgde		; no good either

	move.l	d1,a0		; global array
	move.l	12(a0),-(sp)	; int_out array

	pea	post_opnwk(pc)	; create a stack frame so return address from VDI comes back to our code
	move	sr,-(sp)	;
	bra	mgde

; Portion of code that is called after v_opnwk return
post_opnwk:
	move.l	(sp)+,a1	; int_out array

	;move.w	d0,(a1)		; max X coord (commented out to leave unchanged)
	move.w	#275,2(a1)	; max Y coord

	move.l	$44e.w,d0		; logical screen base (_v_bas_ad)
	sub.l	#ADDSCR,d0		; corrected screen address
	move.l	d0,$44e.w		; new logical screen base

	lsr.w	#8,d0
	move.l	d0,$ffff8200.w		; physical screen address

	bset	#0,$fffffa07.w	; activate timer B
	bset	#0,$fffffa13.w	; unmask timer B

	bset	#4,$fffffa09.w	; enable Timer D
	bset	#4,$fffffa15.w	; unmask Timer D

	dc.w	$a000

	;move	d1,2(a0)		; bytes/scanline
	;move	d1,-2(a0)		; bytes per screen line
	move	#276,-4(a0)		; vertical pixel resolution
	;move	ck_vwidth(pc),-12(a0)	; horizontal pixel resolution

	;move	d0,-44(a0)		; number of VT52 characters per line -1

	;move	-46(a0),d0		; text cell height (8 or 16)

	;move	d1,-40(a0)		; VT52 text line size in bytes
	move	#33,-42(a0)		; Number of VT52 text lines -1
	;move	d1,-692(a0)		; max X coord (width-1)
	move	#275,-690(a0)		; max Y coord (height-1)

	rte


end_resident:

install:
	lea	hello_txt(pc),a0
	bsr	cconws

	pea	install_super(pc)
	move	#38,-(sp)	; Supexec
	trap	#14
	addq.l	#6,sp

	tst	d0
	bne.s	noinstall

	clr	-(sp)
	move.l	#end_resident-begin+256,-(sp)
	move	#$31,-(sp)	; Ptermres
	trap	#1

; exit without installing
noinstall:
	lea	hires_txt(pc),a0
	bsr	cconws
	clr	-(sp)
	trap	#1

install_super:
	cmp.b	#2,$ffff8260.w
	bne.s	_is1		; don't install on high resolution
	moveq	#1,d0
	rts

_is1:	move	#$2700,sr

	bclr	#0,$fffffa07.w	; deactivate timer B
	bclr	#0,$fffffa13.w	; mask timer B

	clr.b	$fffffa1b.w	; timer B - stop

	and.b	#$f0,$fffffa1d.w	; Timer D stop
	move.l	#timer_d,$110.w	; Timer D vector
	bclr	#4,$fffffa09.w	; disable Timer D
	bclr	#4,$fffffa15.w	; mask Timer D

	move.l	#hbl,$68.w
	move.l	$70.w,oldvbl
	move.l	#vbl,$70.w

	move	#$2300,sr

	move.l	$88.w,old_gem
	move.l	#my_gem,$88.w	; AES/VDI (Trap #2) vector

	move.l	$436.w,a0	; _memtop
	move.l	a0,a3		; save old value
	sub.l	#ADDSCR,a0	; fix _memtop so it points before screen memory
	move.l	a0,$436.w

; Look for our program's MD (memory descriptor)
; To our knowledge, there is no known standard way to find the MPB (Memory
; Parameter Block) that has been initialised at boot.
; Hence we directly search for our MD by scanning the system memory.
	lea	begin-256(pc),a0	; basepage address
	sub.l	a0,a3		; current block size value
	lea	$2004.w,a1	; TOS internal variables
	move.l	$432.w,a2	; _membot
	sub.l	#12,a2		; remove size of MD
mdsearch_lp:
	cmp.l	(a1),a0		; Block address
	bne.s	.cont
	cmp.l	4(a1),a3	; Block size
	beq.s	mdsearch_found
.cont	addq.l	#2,a1
	cmp.l	a2,a1
	ble.s	mdsearch_lp
	bra.s	mdsearch_notfound

; Here we shrink the allocated buffer size for our program.
; Since we are now using a larger video memory buffer, we need to inform the
; system that a part of memory is not available anymore for allocation.
; Our program's memory has been allocated by Malloc, and the normal system
; behaviour is to allocate the largest available block of memory for any new
; program. When the program quits, the memory block will become a free block,
; so changing our program's memory descriptor will also affect the largest
; free block after program termination.
mdsearch_found:
	sub.l	#ADDSCR,4(a1)	; Shrink block size

; if not found (should not happen!), do nothing
mdsearch_notfound:
	moveq	#0,d0
	rts

cconws:
	move.l	a0,-(sp)
	move	#9,-(sp)		; Cconws
	trap	#1
	addq.l	#6,sp
	rts

	section data
hello_txt:	dc.b	13,10
		dc.b	27,"p- Shifter Inside v0.01 -",27,"q",13,10
		dc.b	"by zerkman / sector one",13,10,0
hires_txt	dc.b	"unsupported video mode",13,10,0
	even

