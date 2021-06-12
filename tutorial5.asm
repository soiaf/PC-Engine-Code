; This simple code shows how to read from the joypads. In this code we  move a background graphic around
; the screen (instead of using sprites). This code also includes a routine called ReadFromController1 which shows
; how you could adapt the code from your NES game into a PC Engine game.


	.zp
	
_sourceaddr:		.ds 2
_vreg:			.ds 1	; the currently selected VDC register
_vsr:			.ds 1	; the VDC status register
vsync_check:		.ds 1   ; used to check if a vertical blank has just occurred
bataddresslo:		.ds 1   ; used when calculating the BAT address to modify for a given X, Y coord
bataddresshi:		.ds 1
currentX:		.ds 1
currentY:		.ds 1
controllertemp1:	.ds 1
controllertemp2:	.ds 1 
buttonspressed:		.ds 1
delayframeTimer:	.ds 1

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
	; map in the memory bank
	 lda   #bank(ourgraphicsdata)	; addressable memory
	 tam   #page(ourgraphicsdata) 
	 
	 
	; fill palette #0
	
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
	 
	 
	; load the graphics into VRAM
	 
	 
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

	tia	ourgraphicsdata,$0002,$0040 ;Blast the imported tiles to VRAM	
	
	 
	; now lets load the blank character into each part of our 32x32 BAT
	
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
	; the blank character is at $1010
	; to get its pointer address shift right 4 times - we get $0101
	; the left most (MSB) value is the palette to use, in this case 0
	; is the correct value - so use $0101 as value to put in each BAT word position


	lda #$01	; lsb	
	sta $0002
	lda #$01	; msb
	sta $0003
		
	dex					 ; next block
	bne   .cs2
	pla
	dec   A				 ; next line
	bne   .cs1
	
	
	; Now we write our graphic on-screen. How do we know the VRAM address to write to?
	; We use a routine that, given an X and Y value, returns the correct address 
	; This assumes a 32x32 BAT and routine would need to be modified if a different BAT
	; size is used
	
	ldx #6
	stx currentX
	ldy #12
	sty currentY
	JSR CalculateBATAddress
	
	
	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	

	lda bataddresslo
	sta $0002   ; Data port: lower 8bit/LSB
	lda bataddresshi
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port	

	lda #$00	; lsb	
	sta $0002
	lda #$01	; msb
	sta $0003  
  
  
infloop:
	JSR ResetJoypads
	JSR ReadController1
	JSR ReadController2
	
	; store controllertemp2 in buttonspressed if you want to try using joypad 2 to control the graphic
	lda <controllertemp1
	sta <buttonspressed
	; PC Engine is Left,Down,Right,Up, Run,Start,B,A
checkleft:	
	bbs7	<buttonspressed,checkright
	JSR MoveLeft
	
checkright:	
	bbs5	<buttonspressed,checkup
	JSR MoveRight

checkup:
	bbs4	<buttonspressed,checkdown
	JSR MoveUp
	
checkdown:
	bbs6	<buttonspressed,endcheck
	JSR MoveDown	

endcheck:

	jmp infloop
	
MoveLeft:
	lda <currentX
	cmp #0
	beq ml1
	
	ldx <currentX
	ldy <currentY
	jsr WriteBlankSquare
	
	dex
	stx <currentX

	ldy <currentY
	jsr WriteGraphicSquare  

	ldx #6
	JSR ActualDelay
	
	
ml1:
	RTS
	
MoveRight:
	lda <currentX
	cmp #31
	beq mr1
	
	ldx <currentX
	ldy <currentY
	jsr WriteBlankSquare
	
	inx
	stx <currentX

	ldy <currentY
	jsr WriteGraphicSquare	
	
	ldx #6
	JSR ActualDelay
	
	
mr1:
	RTS	
	
MoveUp:
	lda <currentY
	cmp #0
	beq mu1
	
	ldx <currentX
	ldy <currentY
	jsr WriteBlankSquare
	
	dec <currentY
	ldy <currentY
	jsr WriteGraphicSquare	
	
	ldx #6
	JSR ActualDelay
	
	
mu1:
	RTS   

MoveDown:
	lda <currentY
	cmp #29	 ; so we really only display 30 rows of data!
	beq mu1
	
	ldx <currentX
	ldy <currentY
	jsr WriteBlankSquare
	
	inc <currentY
	ldy <currentY
	jsr WriteGraphicSquare	
	
	ldx #6
	JSR ActualDelay
	
	
md1:
	RTS	  
	
	
; Write a blank character at the location specified
WriteBlankSquare:
	JSR CalculateBATAddress

	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	

	lda bataddresslo
	sta $0002   ; Data port: lower 8bit/LSB
	lda bataddresshi
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port	

	lda #$01	; lsb	
	sta $0002
	lda #$01	; msb
	sta $0003

	RTS

; Write a our graphic character at the location specified
	
WriteGraphicSquare:
	JSR CalculateBATAddress

	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	

	lda bataddresslo
	sta $0002   ; Data port: lower 8bit/LSB
	lda bataddresshi
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port	

	lda #$00	; lsb	
	sta $0002
	lda #$01	; msb
	sta $0003

	RTS	


; given an X, Y position, this works out the address in VRAM (within the BAT)
; result is stored in bataddresslo and bataddresshi
; Remember, that BAT always starts at VRAM memory location $0000
; in this code we are using a 32x32 BAT, so you would need to modify (or write a much better routine :) ) if
; you are using a different size BAT
; this clobbers A and Y  
CalculateBATAddress:

	; basically as there are 32 tiles per row, if value of Y (the row) is less than 8, then the memory location will be
	; less than 256, so high part of address will be 0. If Y is >=8, but less than 16, high part will be 1 etc.

	CPY #8
	BCC cba1
	CPY #16
	BCC cba2
	CPY #24
	BCC cba3
	JMP cba4
	
cba1:
	LDA #0
	STA bataddresshi
	JMP cba5
cba2:
	LDA #1
	STA bataddresshi
	TYA 
	SEC 
	SBC #8
	TAY
	JMP cba5
cba3:
	LDA #2
	STA bataddresshi
	TYA 
	SEC 
	SBC #16
	TAY	
	JMP cba5
cba4:
	LDA #3
	STA bataddresshi
	TYA 
	SEC 
	SBC #24
	TAY
cba5:
	; now calculate the low part of the address - y will always be less than 8 (based on the subtracts we did)
	; so multiply this by 32 and add the X value
	
	STX bataddresslo
	
cba6:
	CPY #0
	BEQ cba7
	LDA bataddresslo
	CLC
	ADC #32
	STA bataddresslo
	DEY
	JMP cba6
	
cba7:	


	RTS

; Every time you read from the joypads you have to reset the joypads
ResetJoypads:

	; reset the joypads
	lda   #$01		
	sta   $1000
	lda   #$03		
	sta   $1000
	
	RTS


ReadController1:

	; small amount of code to deliberately waste time
	pha
	pla
	nop
	nop

	; now lets read!

	lda #$01		
	sta $1000
	pha
	pla
	nop
	nop
	lda $1000	
	asl A			; shift it to 'high' position within byte
	asl A
	asl A
	asl A
	sta <controllertemp1
	
	lda #$00		
	sta $1000
	pha
	pla
	nop
	nop
	lda $1000 
	and #$0F
	ora <controllertemp1
	sta <controllertemp1
	
 
endreadcontroller1:
	RTS  
	
	
ReadController2:

	; small amount of code to deliberately waste time
	pha
	pla
	nop
	nop

	; now lets read!

	lda #$01		
	sta $1000
	pha
	pla
	nop
	nop
	lda $1000	
	asl A			; shift it to 'high' position within byte
	asl A
	asl A
	asl A
	sta <controllertemp2
	
	lda #$00		
	sta $1000
	pha
	pla
	nop
	nop
	lda $1000 
	and #$0F
	ora <controllertemp2
	sta <controllertemp2
	
 
endreadcontroller2:
	RTS  


;; Read from controller 1 and place result in buttonspressed

ReadFromController1:
	JSR ResetJoypads
	JSR ReadController1
	
	; now lets map the inputs to the way the NES works
	; NES is A, B, Select, Start, Up, Down, Left, Right.
	; PC Engine is Left,Down,Right,Up, Run,Select,B(II),A(I)
	; For PC Engine, having bit set to 1 means it has <not> been pressed
	
	STZ buttonspressed
	
	bbs7	<controllertemp1,rfc1   ; left
	LDA buttonspressed
	ORA #%00000010
	STA buttonspressed
rfc1:  
	bbs6	<controllertemp1,rfc2   ; down
	LDA buttonspressed
	ORA #%00000100
	STA buttonspressed
rfc2:	
	bbs5	<controllertemp1,rfc3   ; right
	LDA buttonspressed
	ORA #%00000001
	STA buttonspressed
rfc3:  
	bbs4	<controllertemp1,rfc4   ; up
	LDA buttonspressed
	ORA #%00001000
	STA buttonspressed
rfc4:   
	bbs3	<controllertemp1,rfc5   ; run (map to start)
	LDA buttonspressed
	ORA #%00010000
	STA buttonspressed
rfc5:
	bbs2	<controllertemp1,rfc6   ; select
	LDA buttonspressed
	ORA #%00100000
	STA buttonspressed
rfc6:  
	bbs1	<controllertemp1,rfc7   ; B (II)
	LDA buttonspressed
	ORA #%01000000
	STA buttonspressed
rfc7:
	bbs0	<controllertemp1,rfc8   ; A (I)
	LDA buttonspressed
	ORA #%10000000
	STA buttonspressed
rfc8:			 
 
	RTS	


ActualDelay:   
	LDA #0
	STA delayframeTimer

adloop1:
	CPX delayframeTimer
	BNE adloop1
	
	RTS	
  
	
; graphics data to display on screen 

		.bank  $2
		.org   $6000

; .defchr - Define a character tile (8x8 pixels). Operands are: VRAM
; address, default palette, and 8 rows of pixel data 
;

ourgraphicsdata:

;
; our character to display
;
ourchar:	 .defchr $1000,0,\
	  $00222220,\
	  $02000022,\
	  $03000103,\
	  $03001003,\
	  $03030003,\
	  $03300003,\
	  $00111110,\
	  $00000000
	  
; Blank char
;
blankchar:  .defchr $1010,0,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000,\
	  $00000000	  


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
	