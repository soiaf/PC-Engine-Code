; Simple code to show setting up the reset interrupt, doing some core setup including mapping in the 
; hardware and RAM banks and then setting a palette color, which results in the screen background 
; changing color. The main screen area should display as red.
; This version does more of the proper setting up of the system (as compared to tutorial1), but does 
; not include everything, so this may not work on an actual device. 

	.bank $0
	.org $e000
	.code

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
	; it doesn't matter what value we write to $1403 (in our case its 7 from above), this just ensures the ACK
    
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




; We write to $0402 and $0403 to select a color entry, then define the new color for the palette entry by a 16 bit definition written to $0404 and $0405
; colors are written in format GGGRRRBBB
; Normally you wouldn't update palette colors without waiting for a vertical sync, but this is only a simple test!
; As the sprites and backgrounds have not been enabled, the system uses the first sprite color as the background color


	; we are updating color 0, of palette 0, for the sprite palettes - so %1_00000000
	lda #0
	sta $0402	;Palette address word
	lda #1
	sta $0403
    
	lda #%00111000      ; red
	sta $0404	;Palette data word
	lda #0
	sta $0405	


.next
	pha		;A short timing delay.
	pla
	pha
	pla

	bra .next


	.org $fffe
	.dw RESET