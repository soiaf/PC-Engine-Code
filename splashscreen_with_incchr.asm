; in other sample code (e.g. tutorial7) we define all our background data as data within the source code
; itself. This can be useful when you want to make quick changes to some images. However this code loads
; the background data using a PNG image file, which is far more convenient when working with lots of 
; graphic data and/or have an artist producing your graphics.
; This program uses the file graphics.png

; Zero-page variables
	.zp
vsync_check:	.ds 1
_vreg:		  .ds 1

	.code
	.list
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

	lda #%00000101		  ;IRQ2, TIMER ints OFF
	sta $1402		;VDC INTS ON
	
	lda	#5
	sta	<_vreg
	sta	$0000
	
	lda #$CC
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$00
	sta $0003   ; Data port: higher 8bit/LSB

	; re-enable the interrupts
	cli
	
	lda   #bank(main)	; addressable memory
	tam   #page(main)
	
	JMP main
	
	
MY_VSYNC:
	; so every vsync, we set the value of this zero page variable to zero
	; we do this so we can check in code if a vsync has just occurred, in our code
	; we can set this to 1 and wait for it to become zero (as a result of this interrupt code)
	
	stz	<vsync_check

	rts
	
MY_HSYNC:   

	rts

;*************  INIT ROUTINES  ******************************
Init_VDC:
	lda	LOW_BYTE #vdc_table
	sta	LOW_BYTE <$20EE ; register table address in $20EE
	lda	HIGH_BYTE #vdc_table
	sta	HIGH_BYTE <$20EE

	cly
.l1:	
	lda   [$20EE],Y		; select the VDC register
	bmi	.init_end
	iny
	sta   <_vreg
	sta   $0000
	lda   [$20EE],Y		; send the 16-bit data
	iny
	sta   $0002
	lda   [$20EE],Y
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
	.db $09,$10,$00		; MWR   size of the virtual screen
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
	
	; $20F6 is the VDC status register
	lda	$0000
	sta	<$20F6
	
.hsync_test:
	; BBR is Branch on Bit Reset, with bbr2 being branch on bit 2 being clear
	bbr2	<$20F6,.vsync_test
	jsr	MY_HSYNC
;	inc	<$81
	bra	.exit
;--------
.vsync_test:
	bbr5	<$20F6,.exit
	jsr	MY_VSYNC
;	inc	<$80
.exit:
	; _vreg	the current selected VDC register
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
	 lda   #bank(importedtiles)	; addressable memory
	 tam   #page(importedtiles)
	 
	 lda   #bank(cgpal)	; addressable memory
	 tam   #page(cgpal)	 


	; set BAT to be 32x32 - we could do this in the Init_VDC code above, but we'll set it here to make it
	; clear what's happening

	lda #$09	;MWR Memory Access Width Register, used for setting the BAT size
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	   
	; setting $0000 results in the BAT size being set to 32x32
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$00
	sta $0003   ;Data port: upper 8bit/MSB + latch - command is activated on VDC
				
				


	; load our tiles into VRAM 


	ldy #0
	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	;   we're loading the graphic tiles into VRAM address $2000
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$20
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	; ok, we have set where we want this written, now lets write the actual data
	
	;iny ; next byte is the default palette to use, we are just skipping this
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta  <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port

	tia	importedtiles,$0002,$2000 ;Blast the imported tiles to VRAM

	; vsync to avoid snow - we are about to update the palette
	lda #1
	sta <vsync_check
.wl1:
	bbr0	<vsync_check,.wl2
	bra .wl1
.wl2:
	

	; fill palettes

	stz $0402
	stz $0403
	
	ldy #0
	ldx #64 ; 64 is 4x16 palettes
.lp1:
	lda cgpal,y
	sta $0404
	iny
	lda cgpal,y
	sta $0405
	iny	 
	
	dex
	bne .lp1
	


; blank the background

	lda #$00	;(MAWR) This register is used to set the VRAM write address
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port
	
	lda #$00
	sta $0002   ; Data port: lower 8bit/LSB
	lda #$00
	sta $0003	 ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
	
	lda #$02	;(VRR/VWR) Setting this register tells the VDC you are ready to
				;read/write to VRAM via the data port.
	sta <_vreg ; save this value so VDC interrupt does not overwrite
	sta $0000   ;Register select port


	tia	importedbatdata,$0002,$0780 ;Blast the imported BAT to VRAM

		
	 

   
.here:  bra	.here	; infinite loop :)

		;...

;北盵 USER DATA ]北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?

		.bank  $2
		.org   $6000

importedtiles:  


	.INCCHR "graphics.png"


	.bank  $3
	.org   $8000

;
; Simple palette entry
;
; DEFPAL  - Define a palette using RGB value
; There are 3 bits per color, so 0 to 7
;

cgpal:  

importedpalette1: .defpal  $000,$201,$420,$551,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
importedpalette2: .defpal  $000,$330,$551,$777,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
importedpalette3: .defpal  $000,$420,$551,$777,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
importedpalette4: .defpal  $000,$201,$551,$777,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000

; our imported BAT

importedbatdata:
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$01,$02,$02,$02,$03,$02,$04,$02
	.db $05,$02,$06,$02,$07,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$08,$02,$09,$02,$0A,$02,$0B,$02,$0C,$02,$0D,$02
	.db $0C,$02,$0E,$02,$0F,$02,$10,$02,$11,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$12,$02,$13,$02,$14,$02,$15,$02,$16,$02,$17,$02,$18,$02
	.db $19,$02,$1A,$02,$14,$02,$15,$02,$1B,$02,$1C,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $1D,$02,$1E,$02,$1F,$02,$20,$02,$21,$02,$22,$02,$23,$02,$24,$02
	.db $25,$02,$26,$02,$20,$02,$21,$02,$27,$02,$28,$02,$29,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $2A,$02,$1F,$02,$20,$02,$2B,$02,$2C,$02,$2D,$02,$23,$02,$2E,$02
	.db $2F,$02,$30,$02,$31,$02,$2B,$02,$21,$02,$27,$02,$32,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$33,$02
	.db $34,$02,$35,$02,$2B,$02,$36,$02,$37,$02,$22,$02,$24,$02,$38,$02
	.db $39,$02,$3A,$02,$3B,$02,$3C,$02,$3D,$02,$3E,$02,$3F,$02,$40,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$41,$02
	.db $42,$02,$43,$02,$44,$02,$45,$02,$46,$02,$47,$02,$39,$02,$48,$02
	.db $39,$02,$49,$02,$4A,$02,$4B,$02,$47,$02,$4C,$02,$4D,$02,$4E,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$4F,$02
	.db $50,$02,$51,$02,$52,$02,$52,$02,$52,$02,$52,$02,$52,$02,$52,$02
	.db $24,$02,$53,$02,$52,$02,$52,$02,$52,$02,$52,$02,$54,$02,$55,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$56,$02,$57,$02
	.db $58,$02,$59,$02,$51,$02,$5A,$02,$5B,$02,$24,$02,$5A,$02,$5C,$02
	.db $5D,$02,$5E,$02,$5A,$02,$5B,$02,$5F,$02,$60,$02,$61,$02,$55,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$62,$02,$63,$02
	.db $64,$02,$65,$02,$66,$02,$67,$02,$68,$02,$69,$02,$6A,$02,$6B,$02
	.db $6C,$02,$6D,$02,$6A,$02,$6E,$02,$6F,$02,$70,$02,$71,$02,$72,$02
	.db $73,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$74,$02,$75,$02
	.db $76,$02,$77,$02,$78,$02,$79,$02,$7A,$02,$7B,$02,$7C,$02,$7D,$02
	.db $7E,$02,$7F,$02,$80,$02,$81,$02,$82,$02,$83,$02,$84,$02,$85,$02
	.db $86,$02,$87,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$88,$02,$89,$02
	.db $8A,$02,$8B,$02,$8C,$02,$8D,$02,$8E,$02,$8F,$02,$90,$02,$91,$02
	.db $92,$02,$93,$02,$94,$02,$95,$02,$00,$02,$96,$02,$97,$02,$98,$02
	.db $99,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$9A,$02,$9B,$02
	.db $9C,$02,$9D,$02,$9E,$02,$9F,$02,$A0,$02,$A1,$02,$A2,$02,$A3,$02
	.db $A4,$02,$A5,$02,$A6,$02,$A7,$02,$A8,$02,$A9,$02,$AA,$02,$AB,$02
	.db $AC,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$AD,$02,$AE,$02,$AF,$02
	.db $B0,$02,$B1,$02,$B2,$02,$B3,$02,$B4,$02,$B5,$02,$B5,$02,$B6,$02
	.db $B7,$02,$B5,$02,$B5,$02,$B8,$02,$B9,$02,$BA,$02,$BB,$02,$BC,$02
	.db $BD,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $BE,$02,$BF,$02,$C0,$02,$C1,$02,$53,$02,$C2,$02,$53,$02,$5C,$02
	.db $C3,$02,$C4,$02,$C1,$02,$5C,$02,$BF,$02,$C0,$02,$C5,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $C6,$02,$43,$02,$C7,$02,$C8,$02,$C2,$02,$C9,$02,$C4,$02,$C9,$02
	.db $C4,$02,$5C,$02,$CA,$02,$53,$02,$CB,$02,$4C,$02,$CC,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $CD,$02,$CE,$02,$CF,$02,$D0,$02,$D1,$02,$D2,$02,$D3,$02,$D2,$02
	.db $D4,$02,$D2,$02,$C3,$02,$CF,$02,$D0,$02,$D5,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$D6,$02,$D7,$02,$D8,$02,$43,$02,$D9,$02,$D9,$02,$D9,$02
	.db $D9,$02,$D9,$02,$4C,$02,$D7,$02,$DA,$02,$DB,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$CD,$02,$DC,$02,$DD,$02,$DE,$02,$DF,$02,$DF,$02
	.db $DF,$02,$E0,$02,$E1,$02,$E2,$02,$E3,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$E4,$02,$E5,$02,$E6,$02,$E6,$02
	.db $E6,$02,$E7,$02,$E8,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
	.db $00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02
