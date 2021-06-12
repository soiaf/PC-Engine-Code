; Simple code to show setting up the reset interrupt, doing some core setup including mapping in the 
; hardware and RAM banks and then setting a palette color, which results in the screen background 
; changing color - in this case screen color is green.
; This version does more of the proper setting up of the system (as compared to tutorial2), 
; but again may not display correctly on a real PC Engine 

	.zp
    
_sourceaddr:    .ds 2
_vreg:          .ds 1	; the currently selected VDC register
_vsr:           .ds 1	; the VDC status register

	.code
	.bank $0
	.org $e000


RESET:
	sei        ; Disable interrupts
	csh     ; set CPU clock speed to high
	cld     ;Clear Decimal flag 
    
	lda #$ff	;map in I/O
	tam #0
	lda #$f8	;map in RAM
	tam #1

	ldx #$ff
	txs         ; set the stack pointer
    
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
    
	lda #$05    ; the VDC control register
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
	lda #%00000101          ;IRQ2 and TIMER interrupts are set OFF
	sta $1402		        ;VDC (IRQ1) interrupt set ON
    
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




; We write to $0402 and $0403 to select a color entry, then define the new color for the palette entry by a 16 bit definition written to $0404 and $0405
; colors are written in format GGGRRRBBB
; As the sprites and backgrounds have now been enabled, the system uses the first color of the first palette from the background colors as the background color
; we'll use a green background this time

	; we are updating color 0, of palette 0, for the background palettes - so %0_00000000
	lda #0
	sta $0402	;Palette address word
	sta $0403
    
	lda #%11000000      ; green
	sta $0404	;Palette data word
	lda #1
	sta $0405	


.next
	pha		;A short timing delay.
	pla
	pha
	pla

	bra .next


	; we will use this to run code that we want to run during vertical blank
MY_VSYNC:

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
 ;	.db $05,$00,$00		; CR    control register
	.db $06,$00,$00		; RCR   scanline interrupt counter
	.db $07,$00,$00		; BXR   background horizontal scroll offset
	.db $08,$00,$00		; BYR        "     vertical     "      "
	.db $09,$00,$00		; MWR   size of the virtual screen
	.db $0A,$02,$02		; HSR +                 [$02,$02]
	.db $0B,$1F,$04		; HDR | display size    [$1F,$04]
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
	bbr2    <_vsr,.vsync_test
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