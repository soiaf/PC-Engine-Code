; this program demonstrates that it is possible to dynamically update the tiles used on the screen - this is to
; help show that you are not limited to the pre-defined graphics. This could be useful if you want to draw/show 3D
; objects on-screen, show plasma effects - draw fractals etc.!
; this code prints the words PC Engine on-screen, but draws it on-screen using lines

	.zp
	
_sourceaddr:		.ds 2
_vreg:			.ds 1	; the currently selected VDC register
_vsr:			.ds 1	; the VDC status register
vsync_check:		.ds 1   ; used to check if a vertical blank has just occurred
viewareaX:		.ds 1   ; this is the x co-ord within the viewarea that we want to modify
viewareaY:		.ds 1   ; this is the y co-ord within the viewarea that we want to modify
viewareaColor:		.ds 1   ; this is the color we want to change the indicated pixel to within the viewarea
getmodtemp:		.ds 1   ; used by GetModulo routine
viewareaPixelAddr:	.ds 2   ; starting address within viewarea buffer for pixel we are interested in, we work from offset of this
startingOffset:		.ds 1   ; starting offset from calculated address in viewarea buffer
viewareaBit:		.ds 1   ; the bit location within byte to set to 0 or 1
temp1:			.ds 1
battemp1:		.ds 1
bataddresslo:		.ds 1   ; used when calculating the BAT address to modify for a given X, Y coord
bataddresshi:		.ds 1
drawinginstr:		.ds 1   ; used by the routine that is drawing in the virtual screen (in the viewarea)
drawingX:		.ds 1   
drawingY:		.ds 1
drawingnumsteps:	.ds 1
random:			.ds 1   ; used by the random number generator
rnd2:			.ds 1
rnd3:			.ds 1
rnd4:			.ds 1


	.bss
viewareabuffer:		.ds 2048	; this is the buffer where we 'draw' our view area before displaying - this starts at address $2200	

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
	
	; Now that we have filled each BAT position with the blank character, lets load in the 'dynamic'
	; tiles (at start these are all blank too)
	
	JSR LoadViewArea
	
	; now we need to change our part so that part of it (an 8x8 tile section) points to the 'dynamic'
	; tile section
	; these tiles start at VRAM position $1020
	; our start position on screen is at tile (10,10)
	
	LDX #10
	LDY #10
	LDA #$02
	STA battemp1
.set1:
	phx
	phy
	JSR CalculateBATAddress
	ply
	plx
	
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
	
.set2:	
	lda battemp1	; lsb	
	sta $0002
	lda #$01	; msb
	sta $0003 

	INC battemp1
	INX
	CPX #18 ; end of line
	BNE .set2
	LDX #10
	INY
	CPY #18
	BNE .set1
	
 
	; BAT is now setup - let's draw!
	
	
	JSR InitRandom  ; need to initialize our random number generator

startdrawing:
	LDX #0
sd1: 
	JSR rnd		  ; pick a random color
	AND #%00001111   ;bitmask bits 0, 1, 2 and 3 
	CMP #0  ; don't want 0 as that is background color
	BEQ sd1
	STA viewareaColor
	
	LDA drawinginstructions,X
	STA drawinginstr
	INX
	LDA drawinginstructions,X
	STA drawingX
	INX  
	LDA drawinginstructions,X
	STA drawingY
	INX  
	LDA drawinginstructions,X
	STA drawingnumsteps
	INX
	LDA drawinginstr
	CMP #0
	BEQ drawsingle
	CMP #1
	BEQ drawright
	CMP #2
	BEQ drawleft
	CMP #3
	BEQ drawup
	CMP #4
	BEQ drawdown
	CMP #5
	BCS enddrawing
	
drawsingle:
	PHX
	JSR DrawPoint
	JMP sd2
drawleft:
	PHX
	JSR DrawLeftLine
	JMP sd2
drawright:
	PHX
	JSR DrawRightLine
	JMP sd2
drawup:
	PHX
	JSR DrawUpLine
	JMP sd2
drawdown:
	PHX
	JSR DrawDownLine
sd2:
	JSR LoadViewArea
	ldx #$ff
	JSR ActualDelay	 ; add delay so we can see the lines appear  
	PLX
	JMP sd1
	
	
	
	
	
enddrawing:	


.here:  bra	.here	; infinite loop! 


DrawPoint:
	LDX drawingX
	LDY drawingY
	STX viewareaX
	STY viewareaY	
	JSR ChangeViewAreaBufferPixel
	RTS

DrawLeftLine:
	LDA drawingnumsteps
	CMP #0
	BEQ dll2
dll1:
	LDX drawingX
	LDY drawingY
	STX viewareaX
	STY viewareaY	 

	JSR ChangeViewAreaBufferPixel
	DEC drawingnumsteps
	LDA drawingnumsteps
	CMP #0
	BEQ dll2
	DEC drawingX
	JMP dll1	
	
dll2:
	
	RTS

DrawRightLine:
	LDA drawingnumsteps
	CMP #0
	BEQ drl2
drl1:
	LDX drawingX
	LDY drawingY
	STX viewareaX
	STY viewareaY	 

	JSR ChangeViewAreaBufferPixel
	DEC drawingnumsteps
	LDA drawingnumsteps
	CMP #0
	BEQ drl2
	INC drawingX
	JMP drl1
	
drl2:
	
	RTS	
	
DrawUpLine:
	LDA drawingnumsteps
	CMP #0
	BEQ dul2
dul1:
	LDX drawingX
	LDY drawingY
	STX viewareaX
	STY viewareaY	 

	JSR ChangeViewAreaBufferPixel
	DEC drawingnumsteps
	LDA drawingnumsteps
	CMP #0
	BEQ dul2
	DEC drawingY
	JMP dul1	
	
dul2:
	
	RTS	  

DrawDownLine:
	LDA drawingnumsteps
	CMP #0
	BEQ ddl2
ddl1:
	LDX drawingX
	LDY drawingY
	STX viewareaX
	STY viewareaY	 

	JSR ChangeViewAreaBufferPixel
	DEC drawingnumsteps
	LDA drawingnumsteps
	CMP #0
	BEQ ddl2
	INC drawingY
	JMP ddl1	
	
ddl2:
	
	RTS  

ActualDelay:	

	LDY #$00
adloop1:
  
adloop2:
	LDA #$34	  ; just a number, really just something that takes time
  
	INY				 ; inside loop counter
	CPY #$00
	BNE adloop2	  ; run the inside loop 256 times before continuing down
  
	DEX
	CPX #$00
	BNE adloop1

	RTS
	
LoadViewArea:	
	
	; now we've modified our viewarea buffer, load into tiles
	lda #$00	;(MAWR - Memory Address Write Register) This register is used to set the VRAM write address
	sta  <_vreg	; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port	

	; here is where we set the address in VRAM we wish to load the graphics into - $1020
	lda #$20
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$10
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	; ok, we have set where we want this written, now lets write the actual data
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port

	tia	viewareabuffer,$0002,$0800 ;Blast the imported tiles to VRAM 

	RTS
   

; this routine changes a pixel in the viewarea buffer to the desired color
; 3 parameters
; viewareaX - x coord within viewarea
; viewareaY - y coord within viewarea
; viewareaColor - color within palette for pixel
; our viewarea has the same layout as graphic tile memory layout in VRAM; this is based
; on bitplanes, every pixel can have one of sixteen colors (2 to the power of 4) - so there
; are 4 bitplanes. Every tile takes up 32 bytes
; the pixels are laid out as follows - our tile is made up of 8 rows, each row has 8 pixels
; therefore each row is a byte
; layout in VRAM (in terms of bytes) is then
; row1bitplane1, row1bitplane2,row2bitplane1,row2bitplane2....row8bitplane1,row8bitplane2
; then immediately followed by
; row1bitplane3, row1bitplane4,row2bitplane3,row2bitplane4....row8bitplane3,row8bitplane4

ChangeViewAreaBufferPixel:

	; first we need to calculate the starting address within the viewarea buffer where we will find the 
	; pixel - our pixels will be an offset from this.
	
	LDA viewareaX
	LSR A
	LSR A
	LSR A   ; divide by 8
	STA temp1
	LDA viewareaY
	AND #%11111000

	CLC
	ADC temp1
	TAX
	
	LDA viewareabufferLo,X
	STA viewareaPixelAddr
	LDA viewareabufferHi,X
	STA viewareaPixelAddr+1	
	
	; from here we need to calculate the offset
	; first byte will be at offset (remainder(viewareaY/8) * 2)
	LDX viewareaY
	LDY #8
	JSR GetModulo
	ASL A
	STA startingOffset
	

	; now calculate the bit offset within the byte - as we want this to go from left to right, and bits go from right to left
	; we subtract the bit number from 7
	LDX viewareaX
	LDY #8
	JSR GetModulo
	STA viewareaBit	
	LDA #7
	SEC 
	SBC viewareaBit
	STA viewareaBit

	LDA startingOffset
	TAY
	
cvabp1:
	bbr0	<viewareaColor,cvabp2
	; bit is to be set to 1
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToOne
	LDA <temp1
	STA [viewareaPixelAddr],Y
	 
	bra cvabp3
cvabp2:	
	; bit is to be set to 0
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToZero
	LDA <temp1
	STA [viewareaPixelAddr],Y
cvabp3:
	; second bit to modify is one byte away
	INY

	bbr1	<viewareaColor,cvabp4
	; bit is to be set to 1
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToOne
	LDA <temp1
	STA [viewareaPixelAddr],Y
	 
	bra cvabp5
cvabp4:	
	; bit is to be set to 0
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToZero
	LDA <temp1
	STA [viewareaPixelAddr],Y
cvabp5: 
	; third bit is 16 bytes from the starting offset
	LDA startingOffset
	CLC
	ADC #16
	TAY
	
	bbr2	<viewareaColor,cvabp6
	; bit is to be set to 1
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToOne
	LDA <temp1
	STA [viewareaPixelAddr],Y
	 
	bra cvabp7
cvabp6:	
	; bit is to be set to 0
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToZero
	LDA <temp1
	STA [viewareaPixelAddr],Y	
 
cvabp7: 
	; fourth bit is again one byte on from offset
	
	INY 
	
	bbr3	<viewareaColor,cvabp8
	; bit is to be set to 1
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToOne
	LDA <temp1
	STA [viewareaPixelAddr],Y
	 
	bra cvabp9
cvabp8:	
	; bit is to be set to 0
	LDA [viewareaPixelAddr],Y
	STA <temp1
	LDX viewareaBit
	JSR SetBitToZero
	LDA <temp1
	STA [viewareaPixelAddr],Y	 
 
cvabp9:	

	RTS

; this routine sets a bit to 1
; byte being changed is in temp1
; bit position being changed is in X
SetBitToOne:

	CPX #0
	BEQ sbto0
	CPX #1
	BEQ sbto1
	CPX #2
	BEQ sbto2
	CPX #3
	BEQ sbto3
	CPX #4
	BEQ sbto4
	CPX #5
	BEQ sbto5
	CPX #6
	BEQ sbto6
	CPX #7
	BEQ sbto7	
	JMP sbto8

sbto0:
	SMB0 <temp1
	JMP sbto8
sbto1:
	SMB1 <temp1
	JMP sbto8
sbto2:
	SMB2 <temp1
	JMP sbto8
sbto3:
	SMB3 <temp1
	JMP sbto8
sbto4:
	SMB4 <temp1
	JMP sbto8
sbto5:
	SMB5 <temp1
	JMP sbto8
sbto6:
	SMB6 <temp1
	JMP sbto8
sbto7:
	SMB7 <temp1	
sbto8:	

	RTS
	
; this routine sets a bit to 0
; byte being changed is in temp1
; bit position being changed is in X
SetBitToZero:

	CPX #0
	BEQ sbtz0
	CPX #1
	BEQ sbtz1
	CPX #2
	BEQ sbtz2
	CPX #3
	BEQ sbtz3
	CPX #4
	BEQ sbtz4
	CPX #5
	BEQ sbtz5
	CPX #6
	BEQ sbtz6
	CPX #7
	BEQ sbtz7	
	JMP sbtz8

sbtz0:
	RMB0 <temp1
	JMP sbtz8
sbtz1:
	RMB1 <temp1
	JMP sbtz8
sbtz2:
	RMB2 <temp1
	JMP sbtz8
sbtz3:
	RMB3 <temp1
	JMP sbtz8
sbtz4:
	RMB4 <temp1
	JMP sbtz8
sbtz5:
	RMB5 <temp1
	JMP sbtz8
sbtz6:
	RMB6 <temp1
	JMP sbtz8
sbtz7:
	RMB7 <temp1	
sbtz8:	

	RTS	
	
; routine for calculating modulo - result will be in A 
; registers X and Y are also used
; X is number being divided, Y is divisor	
GetModulo:
	TXA
	STY getmodtemp
	SEC
gm1:
	SBC getmodtemp
	BCS gm1
	
	CLC
	ADC getmodtemp

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


; initialise the variables used by the random number generator
InitRandom:

	LDA #82
	STA random
	LDA #97
	STA rnd2
	LDA #120
	STA rnd3
	LDA #111
	STA rnd4
	
	RTS
	
; random number generator. Thanks to Drag for this code	
rnd
	TXA
	PHA
	LDA rnd4   ;3
	TAX ;2  5
	EOR rnd2   ;3  8
	STA rnd2   ;3  11
	LSR rnd4   ;5  16
	ROR A ;2  18
	LSR rnd4   ;5  23
	ROR A ;2  25
	PHA ;3  28
	TXA	  ;2  30
	EOR rnd4   ;3  33
	STA rnd4   ;3  36
	PLA ;4  40
	LSR rnd4   ;5  45
	ROR A ;2  47
	AND #$e0   ;2  49
	EOR rnd2   ;3  52
	PHA ;3  55
	LDA rnd4   ;3  58
	EOR rnd3   ;3  61
	STA rnd4   ;3  64
	PLA ;4  68
	STA rnd3   ;3  71
	LDA random   ;3  74
	STA rnd2   ;3  77
	TXA ;2  79
	STA random   ;3  82
	PLA
	TAX
	LDA random
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
; entry #0 = black
; DEFPAL  - Define a palette using RGB value
; There are 3 bits per color, so 0 to 7
;
bgpal1:  .defpal $000,$777,$007,$700,\
		$070,$111,$222,$333,\
		$444,$555,$666,$770,\
		$707,$077,$404,$044
		
; these are our lookup tables for the viewarea buffer. These tables are based on the buffer starting at memory $2100

viewareabufferLo: 
		.db $00,$20,$40,$60,$80,$A0,$C0,$E0,$00,$20,$40,$60,$80,$A0,$C0,$E0
		.db $00,$20,$40,$60,$80,$A0,$C0,$E0,$00,$20,$40,$60,$80,$A0,$C0,$E0
		.db $00,$20,$40,$60,$80,$A0,$C0,$E0,$00,$20,$40,$60,$80,$A0,$C0,$E0
		.db $00,$20,$40,$60,$80,$A0,$C0,$E0,$00,$20,$40,$60,$80,$A0,$C0,$E0
viewareabufferHi: 
		.db $22,$22,$22,$22,$22,$22,$22,$22
		.db $23,$23,$23,$23,$23,$23,$23,$23,$24,$24,$24,$24,$24,$24,$24,$24
		.db $25,$25,$25,$25,$25,$25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26
		.db $27,$27,$27,$27,$27,$27,$27,$27,$28,$28,$28,$28,$28,$28,$28,$28
		.db $29,$29,$29,$29,$29,$29,$29,$29

; first byte is instruction
; 0 - just draw point at position
; 1 - go right
; 2 - go left
; 3 - go up
; 4 - go down
; 5 - end routine
; second byte is start X, third byte is start Y
; fourth byte is number of steps to go (ignored when first value is 0 or 5)
; of course we don't really need both left and right (and up and down) but I've added
; them for completeness!
drawinginstructions:
	.db 1,2,2,9
	.db 4,2,2,22
	.db 4,10,2,9
	.db 1,2,10,9
	.db 1,13,2,9
	.db 4,13,2,22
	.db 1,13,23,9
	.db 1,2,26,8
	.db 4,2,26,22
	.db 1,2,47,8
	.db 1,2,37,6
	; small n
	.db 4,12,37,11
	.db 4,20,37,11
	.db 1,12,37,8
	; small g
	.db 4,23,37,11
	.db 1,23,37,8
	.db 1,23,47,8
	.db 4,30,37,20
	.db 2,30,56,8
	; small i
	.db 4,34,37,11
	.db 0,34,34,0
	; small n
	.db 4,38,37,11
	.db 4,46,37,11
	.db 1,38,37,8  
	; small e
	.db 1,50,37,8
	.db 4,50,37,11
	.db 1,50,47,8
	.db 1,50,41,8
	.db 3,57,41,5
		
	.db 5,0,0,0