; This simple code shows how to define sprites and how to display/move them
; This sample moves a sprite from the left of the screen to the right

; Zero-page variables
	.zp
_sourceaddr:	.ds 2
_vreg:		  .ds 1	; the currently selected VDC register
_vsr:		   .ds 1	; the VDC status register	
vsync_check:	.ds 1
delayframeTimer:	.ds 1   ; used when we want to wait a certain number of frames for delay purposes

;Higher RAM variables - i.e. not zero page variables
	.bss
satb:		.ds 512	;Sprite Attribute Table Buffer (64 sprites, 8 bytes per entry)

	.code
	.bank $0
	.org $e000


RESET:
	sei		; Disable interrupts
	csh	 ; set CPU clock speed to high
	cld	 ;Clear Decimal flag 
	
	lda #$ff	;map in I/O
	tam #0
	lda #$f8	;map in RAM
	tam #1

	ldx #$ff
	txs		 ; set the stack pointer
	
	; $0000 is the VDC register latch, reading it returns a set of status flags of the VDC
	; reading also clears interrupts associated with the VDC
	
	lda $0000

	; $1402 is the interrupt mask. Setting a bit to 1 disables the associated interrupt call
	; 3 interrupts are controlled via this, IRQ2, IRQ1 and Timer, so setting %00000111 i.e. 7 
	; will disable all interrupts related to the mask
	; setting bit to 1 disables, setting to 0 enables

	lda #$07
	sta $1402	;IRQ mask, INTS OFF
	
	; now lets switch off the TIMER, 2 step process, send acknowledgement (ACK) to the TIMER, then disable
	; it doesn't matter what value we write to $1403, this just ensures the ACK
	
	sta $1403
	stz $0c01	;Turn off Timer
	
	; now we actually disable any interrupts the VDC could be generating
	
	lda #$05	; the VDC control register
	sta $0000   ;Register select port
	   
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$00
	sta $0003   ;Data port: upper 8bit/MSB + latch - command is activated on VDC
				

	; lets clear out the RAM
	; RAM starts at $2000 (we mapped this in above)
	; zero page maps to this address so zero page $00 is at $2000
	; STZ sets a byte to 0
	; the tii command copies from source to destination with the third parameter being number
	; of iterations, so the below would clear from $2000 to $3fff
	
	stz <$00
	tii $2000,$2001,$1fff
	
	bsr	Init_VDC

	; as per above setting a bit to 1 disables the corresponding interrupt. 
	lda #%00000101		  ;IRQ2 and TIMER interrupts are set OFF
	sta $1402				;VDC (IRQ1) interrupt set ON
	
	; 5 is the VDC control register, used for things like enabling background and sprites, which 
	; events you want interrupts generated for etc
	lda	#5
	sta	<_vreg  ; now that we have initialized the VDC, whenever we write to the register select port, we save the register we are using
	sta	$0000
	
	; $CC is 11001100 - this switches on sprites and background and asks interrupts to be sent when
	; vertical blank occurs or when a particular scanline is reached
	
	lda #$CC
	sta $0002   ; Data port: lower 8bit/LSB
	lda #00
	sta $0003   ; Data port: upper 8bit/LSB

	cli

	lda   #bank(main)	; addressable memory
	tam   #page(main)
	
	JMP main




	; we will use this to run code that we want to run during vertical blank
MY_VSYNC:

	; so every vsync, we set the value of this zero page variable to zero
	; we do this so we can check in code if a vsync has just occurred, in our code
	; we can set this to 1 and wait for it to become zero (as a result of this interrupt code)
	
	stz	<vsync_check
	
	INC delayframeTimer

	rts
	
	; this code can be called whenever a particular scanline is reached
MY_HSYNC:   

	rts

;*************  INIT ROUTINES  ******************************
Init_VDC:
	 lda	LOW_BYTE #vdc_table
	 sta	LOW_BYTE <_sourceaddr
	 lda	HIGH_BYTE #vdc_table
	 sta	HIGH_BYTE <_sourceaddr

	cly
.l1:	
	lda   [_sourceaddr],Y		; select the VDC register
	bmi	.init_end
	iny
	sta   <_vreg
	sta   $0000
	lda   [_sourceaddr],Y		; send the 16-bit data
	iny
	sta   $0002
	lda   [_sourceaddr],Y
	iny
	sta   $0003
	bra   .l1
.init_end:

	lda  #%00000100		;Low res, Colourburst shuffling
	sta  $0400		; set the pixel clock frequency
	rts

	; VDC register data
vdc_table:
 ;	.db $05,$00,$00		; CR	control register
	.db $06,$00,$00		; RCR   scanline interrupt counter
	.db $07,$00,$00		; BXR   background horizontal scroll offset
	.db $08,$00,$00		; BYR		"	 vertical	 "	  "
	.db $09,$00,$00		; MWR   size of the virtual screen
	.db $0A,$02,$02		; HSR +				 [$02,$02]
	.db $0B,$1F,$04		; HDR | display size	[$1F,$04]
	.db $0C,$07,$0D		; VPR |
	.db $0D,$DF,$00		; VDW |
	.db $0E,$03,$00		; VCR +
	.db $0F,$10,$00		; DCR   DMA control register
	.db $13,$00,$7F		; SATB  address of the SATB
	.db -1			; end of table!

;---------------------------------------------------------------





  
;!!!!!!!!!!!!!! INTERRUPT ROUTINES !!!!!!!!!!!!!!!!!!!!!!!!!!!

vdc_int:
	; save the registers
	pha
	phx
	phy

	; $0000 is the VDC register latch, reading it returns a set of status flags of the VDC
	; reading also clears interrupts associated with the VDC
	
	lda	$0000
	sta	<_vsr   ; the VDC status register
	
.hsync_test:
	; BBR is Branch on Bit Reset, with bbr2 being branch on bit 2 being clear
	bbr2	<_vsr,.vsync_test
	jsr	MY_HSYNC
	bra	.exit
;--------
.vsync_test:
	bbr5	<_vsr,.exit
	jsr	MY_VSYNC
.exit:
	lda	<_vreg
	sta	$0000
	
	; restore the registers
	ply
	plx
	pla
	rti	
	

timer_int:
	sta $1403	;ACK TIMER
	stz $0c01	;Turn off timer
my_rti:	rti


	.org $fff6
	.dw my_rti
	.dw vdc_int
	.dw timer_int
	.dw my_rti
	.dw RESET

	.code
	.bank $1
	.org  $C000

main:   	
	 
	; fill background palette #0
	
	; map in the memory bank used by the palette data
	lda   #bank(palettedata)	; addressable memory
	tam   #page(palettedata)
	
	; vsync to avoid snow - we are about to update the palette
	lda #1
	sta <vsync_check
.wl1:
	bbr0	<vsync_check,.wl2
	bra .wl1
.wl2:
		 
	; 0 into both $0402 and $0403 - we're updating the colors in palette 0 of the background color palettes
	stz $0402
	stz $0403
	
	ldy #0
	ldx #16	 ; 16 colors per palette
.lp1:
	lda bgpal1,y
	sta $0404
	iny
	lda bgpal1,y
	sta $0405
	iny	 
	
	dex
	bne .lp1
	 

	; fill sprite palette #0 (we already waited for vblank when we were updating the background 0 palette)
		 
	; We write 0 to $0402 and 1 to $0403 - we're updating the colors in palette 0 of the sprite color palettes
	stz $0402
	ldx #1
	stx $0403
	
	ldy #0
	ldx #16	 ; 16 colors per palette
.slp1:
	lda sprpal1,y
	sta $0404
	iny
	lda sprpal1,y
	sta $0405
	iny	 
	
	dex
	bne .slp1	 
	 
	; load the background graphics into VRAM
	
	; map in the memory bank used by the background graphics
	lda   #bank(backgroundgraphics)	; addressable memory
	tam   #page(backgroundgraphics)
	
	 
	lda #$00	;(MAWR - Memory Address Write Register) This register is used to set the VRAM write address
	sta  <_vreg	; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	; here is where we set the address in VRAM we wish to load the graphics into - $1000
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$10
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	; ok, we have set where we want this written, now lets write the actual data
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port

	tia	backgroundgraphics,$0002,$0020 ;Blast the imported tiles to VRAM	   
	 
	 
	 
		
	; now load the sprite graphics into VRAM
	
	; map in the memory bank used by the sprite graphics
	lda   #bank(spritegraphics)	; addressable memory
	tam   #page(spritegraphics)
	 
	lda #$00	;(MAWR - Memory Address Write Register) This register is used to set the VRAM write address
	sta  <_vreg	; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	; here is where we set the address in VRAM we wish to load the graphics into - $2000
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$20
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	; ok, we have set where we want this written, now lets write the actual data
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port

	tia	spritegraphics,$0002,$0080 ;Blast the imported tiles to VRAM	 


	; now that we have loaded the graphics into VRAM, lets fill the BAT with the blank character graphic 
	; we loaded - we load the blank character into each part of our 32x32 BAT

	
	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	; BAT always starts at VRAM address $0000
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$00
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port


	lda   #32			   ; size 32 lines tall
.cs1:	
	ldx   #32			   ; size 32 chars wide
	pha
.cs2:	
	cly

	; Fill each BAT map position with a pointer to the blank character
	; the blank character is at $1000
	; to get its pointer address shift right 4 times - we get $0100
	; the left most (MSB) value is the palette to use, in this case 0
	; is the correct value - so use $0100 as value to put in each BAT word position


	lda #$00	; lsb	
	sta $0002
	lda #$01	; msb
	sta $0003
		
	dex					 ; next block
	bne   .cs2
	pla
	dec   A				 ; next line
	bne   .cs1
	 
	 
	   


; draw our sprite on-screen

; zero out our backup sprite table (not really needed as we already cleared RAM earlier)  
	stz	satb	
	tii	satb,satb+1,511
	
	lda #$80	; y-pos
	sta satb
	lda #$00
	sta satb+1
	
	lda #$20 ; x-pos
	sta satb+2
	lda #$00
	sta satb+3

	lda #$00 ; sprite address - sprite data is in VRAM $2000 - you need to right shift this 5 times to get the address to use here
	sta satb+4
	lda #$01
	sta satb+5	
	
	lda #$80 ; attributes %0_0_00_0_00_0_1_000_0000 - 16x16 pixels sprite, no x or y flipping, show in foreground, sprite palette 0
	sta satb+6
	lda #$00
	sta satb+7  

; now we've updated our local sprite table, copy to VRAM

	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port

	; our VRAM SATB is located in VRAM memory location $7F00
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$7F
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC	 

	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	; tia writes bytes (in this case $0200 of them), alternating to a pair of addresses - Destination and Destination+1
	; in the below case, Destination being $0002 and Destination+1 being $0003
	
	tia	satb,$0002,$0200 ;Blast SATB to VRAM
	

; now lets move the sprite across the screen

	ldx #$20
.here:
	inx
	cpx #$ff
	bcc .movesprite
	bra .infloop
.movesprite:
	stx satb+2
	; wait for vsync
	lda #1
	sta <vsync_check
.ms1:
	bbr0	<vsync_check,.ms2
	bra .ms1
.ms2:
	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port

	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$7F
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC	 

	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	; tia writes bytes (in this case $0200 of them), alternating to a pair of addresses - Destination and Destination+1
	; in the below case, Destination being $0002 and Destination+1 being $0003
	
	tia	satb,$0002,$0200 ;Blast SATB to VRAM
	bra .here
	

.infloop:  bra	.infloop

		;...

; BACKGROUND GRAPHICS DATA

		.bank  $2
		.org   $6000

; .defchr - Define a character tile (8x8 pixels). Operands are: VRAM
; address, default palette, and 8 rows of pixel data 

backgroundgraphics:   
   
;
; Blank char
;
blankchar:  .defchr $1000,0,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000	
	  
 
; SPRITE GRAPHICS DATA
 
	.bank  $3
	.org   $6000

spritegraphics:

oursprite:   .defspr  $2000,$0,\
	  $00000000,$00000000,\
	  $00000000,$00000000,\
	  $00000000,$00000000,\
	  $00011111,$11111000,\
	  $00012000,$00031000,\
	  $00010200,$00301000,\
	  $00010020,$03001000,\
	  $00010002,$30001000,\
	  $00010003,$20001000,\
	  $00010030,$02001000,\
	  $00010300,$00201000,\
	  $00013000,$00021000,\
	  $00011111,$11111000,\
	  $00000000,$00000000,\
	  $00000000,$00000000,\
	  $00000000,$00000000	  


; PALETTE DATA
 
	.bank  $4
	.org   $6000

palettedata:

;
; Simple palette entry
;
; entry #0 = black, #1-#15 are all white
; DEFPAL  - Define a palette using RGB value
; There are 3 bits per color, so 0 to 7
;

bgpal1:  .defpal $000,$777,$007,$700,\
		$777,$777,$777,$777,\
		$777,$777,$777,$777,\
		$777,$777,$777,$777
		
sprpal1:  .defpal $000,$777,$007,$700,\
		$777,$777,$777,$777,\
		$777,$777,$777,$777,\
		$777,$777,$777,$777
		


