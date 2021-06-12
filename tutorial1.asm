; Simple code to show setting up the reset interrupt, doing some core setup including mapping in the 
; hardware and RAM banks and then setting a palette color, which results in the screen background 
; changing color
; This may not work on a real PC Engine (as it does not fully setup the system) but should work fine
; on an emulator


	.bank $0
	.org $e000
	.code

RESET:
	sei     ; lets prevent maskable interrupts
	csh     ; set the CPU to high speed
	cld     ; clear the decimal flag
    
	; map in the I/O (hardware) to MPR0
	lda #$ff	;map in I/O
	tam #0
    
	; map in RAM to MPR1
	lda #$f8	;map in RAM
	tam #1

	; set up the stack pointer
	ldx #$ff
	txs
    

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