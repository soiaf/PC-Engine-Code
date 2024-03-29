; this code demonstrates the fade in of a background image.
; screen starts in all black and then the image appears (but fades in rather than appearing all at once)

; Zero-page variables
	.zp
vsync_check:	.ds 1
_vreg:		.ds 1
paletteentry:	.ds 1
currentgreen:	.ds 1
targetred:	.ds 1
targetgreen:	.ds 1
targetblue:	.ds 1
delayframeTimer:.ds 1
	.bss
palettebuffer:	.ds 128 ; 4 palette, 16 colors, but 9 bits, so 2 bytes per color

	.list
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

	INC delayframeTimer

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

; load the background into BAT

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


	; now lets fade in the background image
	; we do this by fading red and green in one level, then fade blue in, repeat
	; palettebuffer starts with being all zero
	; colors are stored in GRB format, 3 bits per color - data is stored lsb, msb, lsb etc.

; we go through the big loop 8 times
	ldx #8
	phx

mainpaletteloop1:		
	
	ldy #0
	ldx #64
.incp1: 
	lda cgpal,y
	sta paletteentry
	
	LDA paletteentry
	and #%111000
	lsr A
	lsr A
	lsr A
	sta targetred

	LDA paletteentry
	and #%11000000
	lsr A
	lsr A
	lsr A
	lsr A
	lsr A
	lsr A	
	sta targetgreen	
	   
	iny   
	lda cgpal,y	 ; loading msb, 1 but for green
	dey
	
	and #1
	cmp #1
	bne .incp2

	lda targetgreen
	CLC
	ADC #4
	sta targetgreen
 
.incp2:	

	; first do r+g
	
	lda palettebuffer,y
	and #%111000
	lsr A
	lsr A
	lsr A

	cmp targetred
	bcs .incp3	  ; bcs is greater than or equal to
	
	; increase red
	lda palettebuffer,y
	clc
	adc #8
	sta palettebuffer,y
 
.incp3: 
	; figure out current green
	lda palettebuffer,y
	and #%11000000
	lsr A
	lsr A
	lsr A
	lsr A
	lsr A
	lsr A	
	sta currentgreen 

	iny
	lda palettebuffer,y
	sta paletteentry
	dey
	
	and #1
	cmp #1
	bne .incp4

	lda currentgreen
	CLC
	ADC #4
	sta currentgreen
	
.incp4:	

	lda currentgreen
	cmp targetgreen
	bcs .incp6
	
	; need to increase green
	; if green value is 3, then we need to switch palettebuffer+1 value to 1
	
	lda currentgreen
	cmp #3
	bne .incp5
	
	lda #1
	sta paletteentry
	
.incp5:  

	lda palettebuffer,y
	clc
	adc #64
	sta palettebuffer,y

.incp6: 

	iny
	lda paletteentry
	sta palettebuffer,y
	
	iny
	
	dex
	bne .incp7
	jmp .incp8
	
.incp7:
	jmp .incp1
	
.incp8:	
	JSR LoadPaletteFromBuffer
	; wait
	ldx #3
	jsr ActualDelay
  


	ldy #0
	ldx #64

.incb1:
  
	; now increase blue
	
	lda cgpal,y

	and #7  ; blue
	sta targetblue
	
	lda palettebuffer,y
	
	AND #7
	cmp targetblue
	bcs .incb2
	
	lda palettebuffer,y
	clc
	adc #1
	sta palettebuffer,y	
	
.incb2:  
	
	iny
	iny 
	
	dex
	bne .incb1
	
	JSR LoadPaletteFromBuffer
	
	; wait
	ldx #3
	jsr ActualDelay
	
	plx
	dex
	bne mainpaletteloop2
	jmp mainpaletteloop3
	
mainpaletteloop2:
	phx
	jmp mainpaletteloop1

mainpaletteloop3: 
	; finished


		
		
	  
	 

   
.here:  bra	.here	; infinite loop :)

; this waits a specified number of frames
ActualDelay:   
	LDA #0
	STA delayframeTimer

adloop1:
	CPX delayframeTimer
	BNE adloop1
	
	RTS

; this loads the palette data stored in palettebuffer into the VCE

LoadPaletteFromBuffer:
	pha
	phx
	phy
	
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
	lda palettebuffer,y
	sta $0404
	iny
	lda palettebuffer,y
	sta $0405
	iny	 
	
	dex
	bne .lp1

	ply
	plx
	pla
	
	RTS



;北盵 USER DATA ]北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?

		.bank  $2
		.org   $6000

; .defchr - Define a character tile (8x8 pixels). Operands are: VRAM
; address, default palette, and 8 rows of pixel data 
;

importedtiles:  


importedtileB0:	.defchr $2000,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB1:	.defchr $2010,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000012,\
	$00012333,\
	$01233333,\
	$23333332

importedtileB2:	.defchr $2020,0,\
	$00000000,\
	$00000000,\
	$00011223,\
	$12233333,\
	$33333333,\
	$33333321,\
	$33210111,\
	$11111122

importedtileB3:	.defchr $2030,0,\
	$00000000,\
	$12222233,\
	$33333333,\
	$33333333,\
	$33332211,\
	$11111111,\
	$12221101,\
	$33322110

importedtileB4:	.defchr $2040,0,\
	$00000000,\
	$33333333,\
	$33333333,\
	$33333333,\
	$11111111,\
	$12333211,\
	$01232101,\
	$01222110

importedtileB5:	.defchr $2050,0,\
	$00000000,\
	$33222221,\
	$33333333,\
	$33333333,\
	$12233333,\
	$11111111,\
	$01121221,\
	$11223332

importedtileB6:	.defchr $2060,0,\
	$00000000,\
	$00000000,\
	$33210000,\
	$33333210,\
	$33333333,\
	$23333333,\
	$01112333,\
	$11111112

importedtileB7:	.defchr $2070,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$21000000,\
	$33311000,\
	$33333200,\
	$33333332

importedtileB8:	.defchr $2080,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000002,\
	$00000033,\
	$00001333,\
	$00023333

importedtileB9:	.defchr $2090,0,\
	$00000123,\
	$00002333,\
	$00233333,\
	$12333331,\
	$33333201,\
	$33321111,\
	$33110111,\
	$31111122

importedtileB10:	.defchr $20A0,0,\
	$33332211,\
	$33211111,\
	$21110100,\
	$11111122,\
	$11011212,\
	$11111010,\
	$11010101,\
	$21101010

importedtileB11:	.defchr $20B0,0,\
	$11000112,\
	$10001111,\
	$00000111,\
	$33211110,\
	$23221100,\
	$10112110,\
	$01010111,\
	$11211011

importedtileB12:	.defchr $20C0,0,\
	$12122322,\
	$21101221,\
	$00000001,\
	$00101010,\
	$31000000,\
	$32102000,\
	$32023211,\
	$31123221

importedtileB13:	.defchr $20D0,0,\
	$01121100,\
	$11222111,\
	$01121111,\
	$11222111,\
	$11121102,\
	$11112113,\
	$21121113,\
	$31122133

importedtileB14:	.defchr $20E0,0,\
	$11000101,\
	$21100010,\
	$11100000,\
	$11111232,\
	$00012322,\
	$11211010,\
	$11110111,\
	$10112110

importedtileB15:	.defchr $20F0,0,\
	$02233333,\
	$11112333,\
	$01110113,\
	$21111111,\
	$12111111,\
	$10112111,\
	$01000111,\
	$10101122

importedtileB16:	.defchr $2100,0,\
	$32000000,\
	$33310000,\
	$33332100,\
	$33333320,\
	$01233333,\
	$11113333,\
	$11111233,\
	$21101123

importedtileB17:	.defchr $2110,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$31000000,\
	$33200000,\
	$33320000

importedtileB18:	.defchr $2120,0,\
	$00000000,\
	$00000000,\
	$00000001,\
	$00000012,\
	$00000123,\
	$00001233,\
	$00012333,\
	$00123331

importedtileB19:	.defchr $2130,0,\
	$00233331,\
	$02333311,\
	$23332101,\
	$33311122,\
	$33111222,\
	$31112221,\
	$11122211,\
	$11222110

importedtileB20:	.defchr $2140,0,\
	$01001333,\
	$11223333,\
	$12233222,\
	$22211110,\
	$11010000,\
	$11101010,\
	$00010101,\
	$00111121

importedtileB21:	.defchr $2150,0,\
	$33200101,\
	$33322111,\
	$22332211,\
	$11112222,\
	$00011112,\
	$10001111,\
	$01000001,\
	$11111010

importedtileB22:	.defchr $2160,0,\
	$13320101,\
	$12332111,\
	$00023101,\
	$11003210,\
	$01001310,\
	$10100232,\
	$01010022,\
	$10111022

importedtileB23:	.defchr $2170,0,\
	$01011210,\
	$11101110,\
	$00023321,\
	$00233321,\
	$12221001,\
	$22201121,\
	$11011102,\
	$10121001

importedtileB24:	.defchr $2180,0,\
	$00020000,\
	$01222000,\
	$02111101,\
	$21111211,\
	$11011211,\
	$21112121,\
	$11111111,\
	$11212121

importedtileB25:	.defchr $2190,0,\
	$12110101,\
	$11101111,\
	$23320001,\
	$12332000,\
	$00022210,\
	$21102222,\
	$01110112,\
	$00112012

importedtileB26:	.defchr $21A0,0,\
	$01013310,\
	$11133210,\
	$01330001,\
	$02300010,\
	$13100100,\
	$22001010,\
	$21010100,\
	$20111000

importedtileB27:	.defchr $21B0,0,\
	$23332100,\
	$12333210,\
	$01133321,\
	$21113332,\
	$22110333,\
	$22211133,\
	$12221102,\
	$11222211

importedtileB28:	.defchr $21C0,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$10000000,\
	$21000000,\
	$32100000,\
	$33210000,\
	$33321000

importedtileB29:	.defchr $21D0,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000002,\
	$00000022,\
	$00000123,\
	$00000132

importedtileB30:	.defchr $21E0,0,\
	$00133311,\
	$01333111,\
	$12231112,\
	$22321122,\
	$23211222,\
	$32112221,\
	$21122211,\
	$11222110

importedtileB31:	.defchr $21F0,0,\
	$12221100,\
	$22211010,\
	$22110101,\
	$21111121,\
	$11100112,\
	$11001122,\
	$00001212,\
	$10101122

importedtileB32:	.defchr $2200,0,\
	$01011212,\
	$11212222,\
	$12122222,\
	$21223232,\
	$22222222,\
	$22323232,\
	$22232222,\
	$32323232

importedtileB33:	.defchr $2210,0,\
	$11110100,\
	$22211110,\
	$12221111,\
	$22212121,\
	$22122212,\
	$22223222,\
	$22222222,\
	$32322222

importedtileB34:	.defchr $2220,0,\
	$00010002,\
	$11101001,\
	$11000101,\
	$21101110,\
	$12110100,\
	$32211010,\
	$22210001,\
	$32321011

importedtileB35:	.defchr $2230,0,\
	$01111111,\
	$11212121,\
	$01121111,\
	$11221121,\
	$01111111,\
	$11211111,\
	$01111111,\
	$11212111

importedtileB36:	.defchr $2240,0,\
	$11011101,\
	$11101111,\
	$11111111,\
	$11111111,\
	$01010111,\
	$11101110,\
	$11010011,\
	$10000011

importedtileB37:	.defchr $2250,0,\
	$01000012,\
	$11100012,\
	$11110021,\
	$20110120,\
	$11010110,\
	$21111210,\
	$12111200,\
	$11212110

importedtileB38:	.defchr $2260,0,\
	$00010000,\
	$10100010,\
	$01100101,\
	$11101111,\
	$01000111,\
	$10001121,\
	$00011222,\
	$10112222

importedtileB39:	.defchr $2270,0,\
	$01122211,\
	$10112221,\
	$00011222,\
	$10101122,\
	$11000112,\
	$21101112,\
	$11010111,\
	$21100011

importedtileB40:	.defchr $2280,0,\
	$02332000,\
	$11333200,\
	$21022220,\
	$22113231,\
	$22111322,\
	$22221132,\
	$12221123,\
	$11222112

importedtileB41:	.defchr $2290,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$20000000,\
	$21000000,\
	$32100000

importedtileB42:	.defchr $22A0,0,\
	$00001222,\
	$00002221,\
	$00012211,\
	$00112112,\
	$00122112,\
	$01221122,\
	$01221122,\
	$11211221

importedtileB43:	.defchr $22B0,0,\
	$22222322,\
	$32323232,\
	$23232223,\
	$32333232,\
	$23232322,\
	$33323232,\
	$23232323,\
	$32333332

importedtileB44:	.defchr $22C0,0,\
	$23222322,\
	$32323232,\
	$23222222,\
	$32323232,\
	$23222211,\
	$32322111,\
	$22211112,\
	$32112121

importedtileB45:	.defchr $22D0,0,\
	$22221101,\
	$32211011,\
	$22110101,\
	$21111011,\
	$01111001,\
	$21211000,\
	$12100001,\
	$21101011

importedtileB46:	.defchr $22E0,0,\
	$11111101,\
	$11101111,\
	$01000101,\
	$10111111,\
	$00013311,\
	$10112321,\
	$12120122,\
	$23322011

importedtileB47:	.defchr $22F0,0,\
	$11111201,\
	$21212100,\
	$11111101,\
	$21212110,\
	$11121101,\
	$11112110,\
	$01111111,\
	$11212111

importedtileB48:	.defchr $2300,0,\
	$00011222,\
	$10112222,\
	$00011112,\
	$10111121,\
	$00011111,\
	$10112221,\
	$00010112,\
	$10111011

importedtileB49:	.defchr $2310,0,\
	$22222323,\
	$22323232,\
	$12232223,\
	$22323232,\
	$12222322,\
	$11223232,\
	$11111223,\
	$21211122

importedtileB50:	.defchr $2320,0,\
	$22100000,\
	$22210000,\
	$02220000,\
	$11221000,\
	$21121100,\
	$21112100,\
	$22111110,\
	$22212120

importedtileB51:	.defchr $2330,0,\
	$00000000,\
	$00000001,\
	$00000001,\
	$00000011,\
	$00000011,\
	$00000011,\
	$00000111,\
	$00001121

importedtileB52:	.defchr $2340,0,\
	$12112211,\
	$22122211,\
	$21122111,\
	$21221111,\
	$11221001,\
	$11221001,\
	$12210001,\
	$22200011

importedtileB53:	.defchr $2350,0,\
	$11000112,\
	$10001122,\
	$10000122,\
	$10101122,\
	$11001112,\
	$21101122,\
	$11010112,\
	$21101122

importedtileB54:	.defchr $2360,0,\
	$23232322,\
	$33333221,\
	$23232212,\
	$32322123,\
	$23221232,\
	$32212322,\
	$22123212,\
	$31222223

importedtileB55:	.defchr $2370,0,\
	$11121112,\
	$12211121,\
	$22111210,\
	$21123101,\
	$11231001,\
	$22321012,\
	$33310123,\
	$33201232

importedtileB56:	.defchr $2380,0,\
	$23320101,\
	$23311121,\
	$12102223,\
	$21101333,\
	$11000233,\
	$10001022,\
	$00010002,\
	$00111011

importedtileB57:	.defchr $2390,0,\
	$11111201,\
	$11112211,\
	$11121211,\
	$21211121,\
	$21011111,\
	$21112121,\
	$22111112,\
	$21111112

importedtileB58:	.defchr $23A0,0,\
	$01011101,\
	$10112110,\
	$11122211,\
	$11223221,\
	$01122322,\
	$11223232,\
	$01122323,\
	$10223233

importedtileB59:	.defchr $23B0,0,\
	$11121111,\
	$12212221,\
	$01221122,\
	$10122112,\
	$11012312,\
	$21102332,\
	$21110233,\
	$32211123

importedtileB60:	.defchr $23C0,0,\
	$22222223,\
	$12323232,\
	$11222322,\
	$32123232,\
	$33211222,\
	$23321122,\
	$22232112,\
	$31222212

importedtileB61:	.defchr $23D0,0,\
	$22232222,\
	$32323222,\
	$22222222,\
	$22323222,\
	$22222212,\
	$32322222,\
	$22221222,\
	$32322221

importedtileB62:	.defchr $23E0,0,\
	$11000001,\
	$21101011,\
	$11110011,\
	$21101011,\
	$11000111,\
	$21101111,\
	$11000111,\
	$21101121

importedtileB63:	.defchr $23F0,0,\
	$12211111,\
	$11211121,\
	$01121111,\
	$11222111,\
	$00122111,\
	$00012111,\
	$00011211,\
	$10002221

importedtileB64:	.defchr $2400,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$10000000,\
	$11000000,\
	$21000000,\
	$11000000,\
	$11100000

importedtileB65:	.defchr $2410,0,\
	$00001111,\
	$00001111,\
	$00011111,\
	$00011112,\
	$00011112,\
	$00111112,\
	$00111123,\
	$00111232

importedtileB66:	.defchr $2420,0,\
	$12100112,\
	$22100111,\
	$22000000,\
	$21100010,\
	$11000111,\
	$33332111,\
	$23233311,\
	$32322232

importedtileB67:	.defchr $2430,0,\
	$12100112,\
	$22211111,\
	$02231001,\
	$00333111,\
	$00033200,\
	$00002220,\
	$01011211,\
	$21222222

importedtileB68:	.defchr $2440,0,\
	$22222322,\
	$22223221,\
	$12122211,\
	$11212112,\
	$01110112,\
	$00101021,\
	$01010112,\
	$21222221

importedtileB69:	.defchr $2450,0,\
	$12221113,\
	$22211133,\
	$22110223,\
	$21101232,\
	$11011221,\
	$21112210,\
	$11011201,\
	$10112112

importedtileB70:	.defchr $2460,0,\
	$32111223,\
	$21112233,\
	$10122323,\
	$10123233,\
	$01011222,\
	$10112121,\
	$01111111,\
	$22222222

importedtileB71:	.defchr $2470,0,\
	$23221111,\
	$33322121,\
	$23221111,\
	$32321121,\
	$22111211,\
	$21102111,\
	$11111112,\
	$22222222

importedtileB72:	.defchr $2480,0,\
	$01011100,\
	$11112110,\
	$01121101,\
	$11212110,\
	$01111100,\
	$10101010,\
	$01110101,\
	$22222222

importedtileB73:	.defchr $2490,0,\
	$11122323,\
	$20223233,\
	$11122323,\
	$21123233,\
	$12011222,\
	$21101121,\
	$11111111,\
	$21222222

importedtileB74:	.defchr $24A0,0,\
	$22210123,\
	$32322112,\
	$23221101,\
	$32322110,\
	$22221100,\
	$21211110,\
	$11111101,\
	$22222222

importedtileB75:	.defchr $24B0,0,\
	$32122211,\
	$32112221,\
	$32210222,\
	$22211122,\
	$02110112,\
	$01211011,\
	$01121112,\
	$22222222

importedtileB76:	.defchr $24C0,0,\
	$11000212,\
	$21002221,\
	$00133210,\
	$00333100,\
	$02231001,\
	$22210001,\
	$12110101,\
	$22222222

importedtileB77:	.defchr $24D0,0,\
	$11001211,\
	$21001221,\
	$00000221,\
	$10101122,\
	$11000112,\
	$21123222,\
	$12332323,\
	$32223221

importedtileB78:	.defchr $24E0,0,\
	$11100000,\
	$11110000,\
	$11110000,\
	$11111000,\
	$11111000,\
	$11111000,\
	$21111000,\
	$22111000

importedtileB79:	.defchr $24F0,0,\
	$00001212,\
	$00002122,\
	$00011122,\
	$00002122,\
	$00001112,\
	$00001010,\
	$00000000,\
	$00000000

importedtileB80:	.defchr $2500,0,\
	$33221122,\
	$33322112,\
	$23221101,\
	$22211011,\
	$12110001,\
	$11101001,\
	$00000000,\
	$00001100

importedtileB81:	.defchr $2510,0,\
	$11111111,\
	$11111111,\
	$11111111,\
	$11111111,\
	$01111101,\
	$00111110,\
	$10011111,\
	$11001111

importedtileB82:	.defchr $2520,0,\
	$11111111,\
	$11111111,\
	$12121212,\
	$21212121,\
	$01010101,\
	$10101010,\
	$11111111,\
	$11111111

importedtileB83:	.defchr $2530,0,\
	$10010111,\
	$11111110,\
	$01110101,\
	$11111111,\
	$11000101,\
	$11111111,\
	$01110101,\
	$11111011

importedtileB84:	.defchr $2540,0,\
	$22233322,\
	$22333332,\
	$12232322,\
	$11222221,\
	$01121100,\
	$11111000,\
	$01010001,\
	$10111111

importedtileB85:	.defchr $2550,0,\
	$11110100,\
	$10110000,\
	$11110110,\
	$10111000,\
	$01011010,\
	$11111100,\
	$11111010,\
	$20111110

importedtileB86:	.defchr $2560,0,\
	$00222221,\
	$01211122,\
	$02133333,\
	$13133333,\
	$22233333,\
	$31333333,\
	$22333333,\
	$00122222

importedtileB87:	.defchr $2570,0,\
	$11110000,\
	$22222221,\
	$21111233,\
	$33333210,\
	$33333333,\
	$33333333,\
	$33333333,\
	$22211122

importedtileB88:	.defchr $2580,0,\
	$00000001,\
	$00000000,\
	$32100000,\
	$22331000,\
	$21123310,\
	$33321233,\
	$33333212,\
	$33333331

importedtileB89:	.defchr $2590,0,\
	$01110111,\
	$11111111,\
	$00011101,\
	$00001111,\
	$00000111,\
	$00000011,\
	$31000001,\
	$13200000

importedtileB90:	.defchr $25A0,0,\
	$01010101,\
	$10101010,\
	$10010111,\
	$10112222,\
	$11022222,\
	$10123232,\
	$00122323,\
	$20223233

importedtileB91:	.defchr $25B0,0,\
	$01010101,\
	$10101010,\
	$11110111,\
	$21211111,\
	$22110111,\
	$32211021,\
	$22221012,\
	$32321121

importedtileB92:	.defchr $25C0,0,\
	$01010101,\
	$11102110,\
	$12121210,\
	$22212110,\
	$22111000,\
	$21200000,\
	$12100000,\
	$21100002

importedtileB93:	.defchr $25D0,0,\
	$00000001,\
	$00000000,\
	$00011000,\
	$00122100,\
	$01222210,\
	$02210321,\
	$23033032,\
	$31333313

importedtileB94:	.defchr $25E0,0,\
	$11111101,\
	$11111111,\
	$01111111,\
	$00111111,\
	$00011111,\
	$00001111,\
	$00000111,\
	$20001111

importedtileB95:	.defchr $25F0,0,\
	$01010101,\
	$10112112,\
	$01111212,\
	$10112220,\
	$01011100,\
	$10222000,\
	$01120000,\
	$22211000

importedtileB96:	.defchr $2600,0,\
	$11000000,\
	$20000000,\
	$00002300,\
	$00013320,\
	$00031032,\
	$00222303,\
	$02323330,\
	$23233333

importedtileB97:	.defchr $2610,0,\
	$00011211,\
	$00101110,\
	$00010101,\
	$00001111,\
	$00000000,\
	$20000012,\
	$22000002,\
	$03200010

importedtileB98:	.defchr $2620,0,\
	$11222333,\
	$00000000,\
	$00000000,\
	$00001000,\
	$00012200,\
	$00121320,\
	$01212131,\
	$12133213

importedtileB99:	.defchr $2630,0,\
	$32222222,\
	$00011123,\
	$00000011,\
	$00112321,\
	$00231122,\
	$01211333,\
	$01223333,\
	$22213333

importedtileB100:	.defchr $2640,0,\
	$11233333,\
	$32202333,\
	$22332123,\
	$01102311,\
	$21000122,\
	$21000002,\
	$22000000,\
	$22000000

importedtileB101:	.defchr $2650,0,\
	$20220000,\
	$33022000,\
	$33302200,\
	$33330220,\
	$03333022,\
	$21333312,\
	$21133322,\
	$02123331

importedtileB102:	.defchr $2660,0,\
	$00000001,\
	$00101100,\
	$00010000,\
	$00000000,\
	$00000001,\
	$10000002,\
	$20000012,\
	$21000021

importedtileB103:	.defchr $2670,0,\
	$11001222,\
	$00000121,\
	$00000010,\
	$00000000,\
	$21000000,\
	$32000000,\
	$03200000,\
	$12210001

importedtileB104:	.defchr $2680,0,\
	$12110001,\
	$00000000,\
	$00000000,\
	$00000000,\
	$01200000,\
	$12320000,\
	$22021000,\
	$21312100

importedtileB105:	.defchr $2690,0,\
	$00101000,\
	$01010000,\
	$10100000,\
	$01000001,\
	$00000123,\
	$00002320,\
	$00023112,\
	$00220233

importedtileB106:	.defchr $26A0,0,\
	$00022212,\
	$00012121,\
	$00001212,\
	$10000122,\
	$21000001,\
	$12100000,\
	$21210000,\
	$32121000

importedtileB107:	.defchr $26B0,0,\
	$11000023,\
	$20000220,\
	$01000212,\
	$11000121,\
	$10000022,\
	$10000232,\
	$00001223,\
	$00002102

importedtileB108:	.defchr $26C0,0,\
	$13333312,\
	$33333123,\
	$33332130,\
	$33322300,\
	$13313100,\
	$11122000,\
	$21120000,\
	$32310000

importedtileB109:	.defchr $26D0,0,\
	$30000100,\
	$10000000,\
	$00000000,\
	$00000011,\
	$00000122,\
	$00002320,\
	$00132123,\
	$02212333

importedtileB110:	.defchr $26E0,0,\
	$22110101,\
	$21211000,\
	$12110000,\
	$21000000,\
	$00000001,\
	$00000023,\
	$00002321,\
	$00132123

importedtileB111:	.defchr $26F0,0,\
	$11001100,\
	$00000000,\
	$00000000,\
	$11000000,\
	$23210000,\
	$10132100,\
	$23211122,\
	$33333211

importedtileB112:	.defchr $2700,0,\
	$22123332,\
	$12213333,\
	$01223333,\
	$01213333,\
	$00213333,\
	$00213333,\
	$20223333,\
	$12213333

importedtileB113:	.defchr $2710,0,\
	$21210000,\
	$22100000,\
	$12100000,\
	$12001000,\
	$12023200,\
	$12331220,\
	$13212122,\
	$10233312

importedtileB114:	.defchr $2720,0,\
	$10101000,\
	$11101000,\
	$01010000,\
	$00100001,\
	$00000012,\
	$00000121,\
	$00001212,\
	$20001213

importedtileB115:	.defchr $2730,0,\
	$00000000,\
	$12000000,\
	$23200000,\
	$20220000,\
	$12022000,\
	$23302200,\
	$33330220,\
	$33333122

importedtileB116:	.defchr $2740,0,\
	$01233321,\
	$02333332,\
	$12333333,\
	$01333333,\
	$01233333,\
	$11133333,\
	$02133333,\
	$02133333

importedtileB117:	.defchr $2750,0,\
	$21133333,\
	$23333333,\
	$22233333,\
	$12123333,\
	$21213333,\
	$20113333,\
	$20013333,\
	$20013333

importedtileB118:	.defchr $2760,0,\
	$22000000,\
	$21000000,\
	$22000000,\
	$22000000,\
	$21000000,\
	$21000000,\
	$21000000,\
	$22000000

importedtileB119:	.defchr $2770,0,\
	$01313333,\
	$00223333,\
	$00022333,\
	$00022333,\
	$00012233,\
	$00012233,\
	$00001233,\
	$00001233

importedtileB120:	.defchr $2780,0,\
	$12000121,\
	$12001213,\
	$31202133,\
	$32222133,\
	$33211233,\
	$33210223,\
	$33220213,\
	$33220122

importedtileB121:	.defchr $2790,0,\
	$33121012,\
	$33312221,\
	$33331123,\
	$33333333,\
	$33333111,\
	$33331232,\
	$33332202,\
	$33332201

importedtileB122:	.defchr $27A0,0,\
	$13331210,\
	$23333121,\
	$33333023,\
	$33331232,\
	$33312221,\
	$23221131,\
	$12220013,\
	$22300001

importedtileB123:	.defchr $27B0,0,\
	$02213333,\
	$22112123,\
	$20122221,\
	$11221122,\
	$22200002,\
	$02100001,\
	$21000001,\
	$32000000

importedtileB124:	.defchr $27C0,0,\
	$33212100,\
	$33320210,\
	$33333121,\
	$13333202,\
	$23333212,\
	$23333211,\
	$23333211,\
	$23333210

importedtileB125:	.defchr $27D0,0,\
	$00022131,\
	$00221333,\
	$12203333,\
	$11223333,\
	$00222333,\
	$00022333,\
	$00022333,\
	$00022333

importedtileB126:	.defchr $27E0,0,\
	$22000001,\
	$02210013,\
	$31221131,\
	$33122312,\
	$33222223,\
	$32211233,\
	$32210133,\
	$32210123

importedtileB127:	.defchr $27F0,0,\
	$22133333,\
	$21333333,\
	$23333211,\
	$33331222,\
	$33322202,\
	$33322101,\
	$33321001,\
	$33321001

importedtileB128:	.defchr $2800,0,\
	$33312100,\
	$33331211,\
	$23333212,\
	$13333320,\
	$23333321,\
	$13333321,\
	$13333321,\
	$13333321

importedtileB129:	.defchr $2810,0,\
	$12211333,\
	$22123333,\
	$21133333,\
	$21233332,\
	$11233332,\
	$01233332,\
	$01233332,\
	$01233332

importedtileB130:	.defchr $2820,0,\
	$33333333,\
	$33333333,\
	$21123331,\
	$12221121,\
	$21112212,\
	$10000122,\
	$00000000,\
	$00000000

importedtileB131:	.defchr $2830,0,\
	$01223333,\
	$21223333,\
	$20223333,\
	$20223333,\
	$10223333,\
	$00223333,\
	$00223333,\
	$00223333

importedtileB132:	.defchr $2840,0,\
	$33333331,\
	$33223333,\
	$31221333,\
	$23222233,\
	$22002133,\
	$22002233,\
	$22002133,\
	$22002133

importedtileB133:	.defchr $2850,0,\
	$23100122,\
	$21320022,\
	$33022021,\
	$33302221,\
	$33322021,\
	$33321021,\
	$33220021,\
	$33220021

importedtileB134:	.defchr $2860,0,\
	$33333122,\
	$33333222,\
	$33333321,\
	$33333333,\
	$33333333,\
	$33333333,\
	$33333211,\
	$33333222

importedtileB135:	.defchr $2870,0,\
	$22210000,\
	$22221000,\
	$12112000,\
	$33312000,\
	$33322000,\
	$33312000,\
	$11121000,\
	$22220000

importedtileB136:	.defchr $2880,0,\
	$02133333,\
	$02133333,\
	$02133333,\
	$02133333,\
	$02133333,\
	$02122222,\
	$02133333,\
	$02133333

importedtileB137:	.defchr $2890,0,\
	$20023333,\
	$20023333,\
	$20023332,\
	$20023331,\
	$20023322,\
	$20022222,\
	$20021231,\
	$20022320

importedtileB138:	.defchr $28A0,0,\
	$22000000,\
	$21000000,\
	$21000000,\
	$20000000,\
	$10000000,\
	$00000000,\
	$00000230,\
	$00000333

importedtileB139:	.defchr $28B0,0,\
	$00001233,\
	$00001133,\
	$00000133,\
	$00000133,\
	$00000133,\
	$00000122,\
	$00001123,\
	$00002123

importedtileB140:	.defchr $28C0,0,\
	$33220121,\
	$33210022,\
	$33210021,\
	$33210021,\
	$33210021,\
	$22210021,\
	$33220121,\
	$33230132

importedtileB141:	.defchr $28D0,0,\
	$33331200,\
	$33331200,\
	$33332200,\
	$33331200,\
	$33331200,\
	$22221200,\
	$33332200,\
	$33332300

importedtileB142:	.defchr $28E0,0,\
	$33000000,\
	$11000001,\
	$00000003,\
	$00000121,\
	$00001313,\
	$00001222,\
	$00002133,\
	$00002123

importedtileB143:	.defchr $28F0,0,\
	$23221001,\
	$21112221,\
	$13332012,\
	$33332232,\
	$33321300,\
	$22221001,\
	$33322000,\
	$33323001

importedtileB144:	.defchr $2900,0,\
	$23333210,\
	$13333210,\
	$13333210,\
	$23333210,\
	$23333210,\
	$22222110,\
	$23333210,\
	$23333210

importedtileB145:	.defchr $2910,0,\
	$00021333,\
	$00021333,\
	$00021333,\
	$00021333,\
	$00022333,\
	$00021222,\
	$00022333,\
	$00022333

importedtileB146:	.defchr $2920,0,\
	$31210123,\
	$31210123,\
	$32210123,\
	$32210123,\
	$31210123,\
	$21210122,\
	$31210123,\
	$32210123

importedtileB147:	.defchr $2930,0,\
	$33321001,\
	$33321001,\
	$33321001,\
	$33321001,\
	$33321001,\
	$22221001,\
	$33321101,\
	$33312101

importedtileB148:	.defchr $2940,0,\
	$13333221,\
	$13333321,\
	$13333321,\
	$13333121,\
	$13333121,\
	$12222221,\
	$13333121,\
	$13333321

importedtileB149:	.defchr $2950,0,\
	$01233332,\
	$01233332,\
	$01233332,\
	$01233332,\
	$01233332,\
	$01222222,\
	$01233332,\
	$01233332

importedtileB150:	.defchr $2960,0,\
	$00223333,\
	$00223333,\
	$00223333,\
	$00223333,\
	$00223333,\
	$00222222,\
	$00223333,\
	$00223333

importedtileB151:	.defchr $2970,0,\
	$12002133,\
	$22002133,\
	$12002133,\
	$12002133,\
	$12002133,\
	$12002122,\
	$22002233,\
	$13003233

importedtileB152:	.defchr $2980,0,\
	$33120021,\
	$33220021,\
	$33120021,\
	$33120021,\
	$33120021,\
	$22220021,\
	$33220021,\
	$33130032

importedtileB153:	.defchr $2990,0,\
	$33333200,\
	$33333200,\
	$33332200,\
	$33331200,\
	$33331200,\
	$22212100,\
	$33331200,\
	$33331200

importedtileB154:	.defchr $29A0,0,\
	$02122222,\
	$02123331,\
	$02122221,\
	$02112222,\
	$02111111,\
	$13101111,\
	$13100000,\
	$22100000

importedtileB155:	.defchr $29B0,0,\
	$21033200,\
	$23022000,\
	$23000000,\
	$12200000,\
	$11321000,\
	$10123222,\
	$00001233,\
	$00000000

importedtileB156:	.defchr $29C0,0,\
	$00001313,\
	$00003202,\
	$00132121,\
	$00230121,\
	$00033011,\
	$22112200,\
	$33211320,\
	$00002232

importedtileB157:	.defchr $29D0,0,\
	$00003122,\
	$30013023,\
	$32032122,\
	$03320221,\
	$00101101,\
	$10011013,\
	$00000132,\
	$00001320

importedtileB158:	.defchr $29E0,0,\
	$22220132,\
	$21210131,\
	$12200131,\
	$13100120,\
	$32001310,\
	$20002300,\
	$00001220,\
	$00000032

importedtileB159:	.defchr $29F0,0,\
	$22221300,\
	$33321300,\
	$22222200,\
	$22220220,\
	$11110132,\
	$11111023,\
	$00000002,\
	$00000000

importedtileB160:	.defchr $2A00,0,\
	$00001312,\
	$00002313,\
	$00002312,\
	$00002202,\
	$00001201,\
	$20001301,\
	$22001200,\
	$11001200

importedtileB161:	.defchr $2A10,0,\
	$22223001,\
	$33222001,\
	$22123001,\
	$22122001,\
	$11022001,\
	$11012101,\
	$00001211,\
	$00000121

importedtileB162:	.defchr $2A20,0,\
	$22222110,\
	$22332210,\
	$21222110,\
	$21221120,\
	$20111021,\
	$20111022,\
	$10000012,\
	$00000002

importedtileB163:	.defchr $2A30,0,\
	$00021222,\
	$00021233,\
	$00021122,\
	$00021022,\
	$00021011,\
	$00021011,\
	$10021000,\
	$20220000

importedtileB164:	.defchr $2A40,0,\
	$21210122,\
	$31210122,\
	$21210121,\
	$20310121,\
	$10310120,\
	$10210210,\
	$00121200,\
	$00022100

importedtileB165:	.defchr $2A50,0,\
	$22212101,\
	$33211101,\
	$22202101,\
	$22101101,\
	$11102101,\
	$11002202,\
	$00001232,\
	$00000122

importedtileB166:	.defchr $2A60,0,\
	$12222121,\
	$11333121,\
	$21222121,\
	$21222021,\
	$20111021,\
	$20111012,\
	$20000003,\
	$10000001

importedtileB167:	.defchr $2A70,0,\
	$02222222,\
	$02123322,\
	$02112211,\
	$02112210,\
	$23011110,\
	$22101111,\
	$21310000,\
	$30121000

importedtileB168:	.defchr $2A80,0,\
	$10000000,\
	$10000000,\
	$20000000,\
	$32000000,\
	$03200000,\
	$01232000,\
	$00012322,\
	$00000112

importedtileB169:	.defchr $2A90,0,\
	$00222222,\
	$00222333,\
	$00222222,\
	$01311222,\
	$13201111,\
	$23001111,\
	$23200000,\
	$30320000

importedtileB170:	.defchr $2AA0,0,\
	$12002222,\
	$13003223,\
	$12003222,\
	$13103212,\
	$02302201,\
	$00233201,\
	$00022200,\
	$00013200

importedtileB171:	.defchr $2AB0,0,\
	$22120022,\
	$33120032,\
	$22120032,\
	$22130032,\
	$11120022,\
	$11030230,\
	$00021220,\
	$00030121

importedtileB172:	.defchr $2AC0,0,\
	$22222200,\
	$23331200,\
	$12221300,\
	$12221200,\
	$01110200,\
	$01110110,\
	$00000011,\
	$00000001

importedtileB173:	.defchr $2AD0,0,\
	$00000000,\
	$00000001,\
	$00000012,\
	$00000121,\
	$00000233,\
	$00000122,\
	$00000000,\
	$00000000

importedtileB174:	.defchr $2AE0,0,\
	$32000000,\
	$31000000,\
	$20000000,\
	$00000000,\
	$33333333,\
	$22222222,\
	$00000000,\
	$00000000

importedtileB175:	.defchr $2AF0,0,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000001,\
	$33333333,\
	$22222222,\
	$00000000,\
	$00000000

importedtileB176:	.defchr $2B00,0,\
	$00023123,\
	$00231002,\
	$02310000,\
	$23100000,\
	$31000000,\
	$10000100,\
	$00000110,\
	$00001121

importedtileB177:	.defchr $2B10,0,\
	$10013200,\
	$30032000,\
	$22120000,\
	$12310000,\
	$01200001,\
	$00000011,\
	$00000111,\
	$00001221

importedtileB178:	.defchr $2B20,0,\
	$00000003,\
	$00100000,\
	$01110000,\
	$11112000,\
	$11011100,\
	$11112100,\
	$11111200,\
	$21112220

importedtileB179:	.defchr $2B30,0,\
	$20000001,\
	$32000013,\
	$13200032,\
	$02310320,\
	$00222200,\
	$00022000,\
	$00000000,\
	$00000000

importedtileB180:	.defchr $2B40,0,\
	$31001230,\
	$20000123,\
	$00000001,\
	$00000000,\
	$00010000,\
	$00111000,\
	$01120000,\
	$10211110

importedtileB181:	.defchr $2B50,0,\
	$00000023,\
	$20001320,\
	$32003200,\
	$13232000,\
	$01320000,\
	$00100000,\
	$00000001,\
	$00000011

importedtileB182:	.defchr $2B60,0,\
	$10320000,\
	$00232000,\
	$00012301,\
	$00001223,\
	$00000122,\
	$10000010,\
	$01000000,\
	$10100000

importedtileB183:	.defchr $2B70,0,\
	$00231120,\
	$03310012,\
	$32000001,\
	$20000000,\
	$00000000,\
	$00002000,\
	$00011100,\
	$00211120

importedtileB184:	.defchr $2B80,0,\
	$20013200,\
	$00001330,\
	$00000023,\
	$00000001,\
	$01100000,\
	$11210000,\
	$01120100,\
	$11211120

importedtileB185:	.defchr $2B90,0,\
	$00000023,\
	$00000230,\
	$10002300,\
	$31023000,\
	$13330000,\
	$01210000,\
	$00000001,\
	$00000011

importedtileB186:	.defchr $2BA0,0,\
	$10033000,\
	$00003300,\
	$00001320,\
	$00000131,\
	$01000023,\
	$11100003,\
	$11110000,\
	$11211000

importedtileB187:	.defchr $2BB0,0,\
	$00233200,\
	$01303200,\
	$03203200,\
	$23003200,\
	$31003201,\
	$20003203,\
	$00003232,\
	$00003330

importedtileB188:	.defchr $2BC0,0,\
	$00031013,\
	$00023001,\
	$00232000,\
	$03310000,\
	$33100000,\
	$20000000,\
	$00000000,\
	$00000000

importedtileB189:	.defchr $2BD0,0,\
	$10000000,\
	$31000000,\
	$13100011,\
	$02300130,\
	$00230310,\
	$00123200,\
	$00012000,\
	$00000000

importedtileB190:	.defchr $2BE0,0,\
	$01000112,\
	$11201111,\
	$11120101,\
	$11111011,\
	$11011001,\
	$11102100,\
	$11110200,\
	$11110120

importedtileB191:	.defchr $2BF0,0,\
	$11112222,\
	$22222222,\
	$12222222,\
	$12222222,\
	$12222222,\
	$11212222,\
	$01111112,\
	$10111122

importedtileB192:	.defchr $2C00,0,\
	$11011211,\
	$21101121,\
	$22110112,\
	$21101122,\
	$11110112,\
	$21111021,\
	$12110012,\
	$21101121

importedtileB193:	.defchr $2C10,0,\
	$10000101,\
	$21111111,\
	$11110101,\
	$10211111,\
	$01110100,\
	$00101110,\
	$00011111,\
	$00012120

importedtileB194:	.defchr $2C20,0,\
	$00000212,\
	$21223221,\
	$13332211,\
	$33322111,\
	$23221112,\
	$12211121,\
	$12111211,\
	$21112110

importedtileB195:	.defchr $2C30,0,\
	$12111101,\
	$11111111,\
	$11110112,\
	$11111011,\
	$11011101,\
	$10101110,\
	$00000111,\
	$00001121

importedtileB196:	.defchr $2C40,0,\
	$00000111,\
	$21223221,\
	$12122332,\
	$11212332,\
	$11011333,\
	$10112231,\
	$00021210,\
	$20111110

importedtileB197:	.defchr $2C50,0,\
	$00002300,\
	$20000000,\
	$01000000,\
	$10000000,\
	$00110101,\
	$00201111,\
	$02111111,\
	$21112110

importedtileB198:	.defchr $2C60,0,\
	$01111011,\
	$11111001,\
	$01011100,\
	$00111110,\
	$00010210,\
	$00011121,\
	$00001112,\
	$00001112

importedtileB199:	.defchr $2C70,0,\
	$11010111,\
	$10100021,\
	$00010211,\
	$11112110,\
	$12110000,\
	$21101010,\
	$11010002,\
	$11211022

importedtileB200:	.defchr $2C80,0,\
	$11011100,\
	$21101110,\
	$11010111,\
	$20111022,\
	$11010112,\
	$10111111,\
	$01110112,\
	$10101121

importedtileB201:	.defchr $2C90,0,\
	$11010111,\
	$10111110,\
	$01110101,\
	$11211110,\
	$01110111,\
	$21111021,\
	$11011102,\
	$20201111

importedtileB202:	.defchr $2CA0,0,\
	$11010111,\
	$00012210,\
	$11121100,\
	$21212001,\
	$11121002,\
	$11210122,\
	$00011211,\
	$21222121

importedtileB203:	.defchr $2CB0,0,\
	$11010111,\
	$11101010,\
	$02100000,\
	$11201121,\
	$11232211,\
	$21332111,\
	$11230001,\
	$22201121

importedtileB204:	.defchr $2CC0,0,\
	$11010111,\
	$10111110,\
	$01110100,\
	$11211010,\
	$12110100,\
	$21111000,\
	$11110000,\
	$11100000

importedtileB205:	.defchr $2CD0,0,\
	$00001101,\
	$00000111,\
	$00000011,\
	$00000001,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB206:	.defchr $2CE0,0,\
	$21011311,\
	$22211221,\
	$02210111,\
	$11221121,\
	$01021111,\
	$11113221,\
	$01111322,\
	$00111132

importedtileB207:	.defchr $2CF0,0,\
	$11001333,\
	$12103332,\
	$02232223,\
	$00322233,\
	$01211333,\
	$11212232,\
	$01111222,\
	$11212121

importedtileB208:	.defchr $2D00,0,\
	$33200211,\
	$32331111,\
	$22122112,\
	$32212221,\
	$22110211,\
	$32211120,\
	$12010111,\
	$10101121

importedtileB209:	.defchr $2D10,0,\
	$12110101,\
	$21101110,\
	$11011101,\
	$10111011,\
	$01110001,\
	$11111011,\
	$01110000,\
	$21210000

importedtileB210:	.defchr $2D20,0,\
	$01100110,\
	$11001011,\
	$10021001,\
	$00212110,\
	$01111211,\
	$11111111,\
	$00000000,\
	$21111121

importedtileB211:	.defchr $2D30,0,\
	$01133321,\
	$20123320,\
	$12000101,\
	$11333221,\
	$00133200,\
	$10000010,\
	$11110101,\
	$21212121

importedtileB212:	.defchr $2D40,0,\
	$12333200,\
	$01333101,\
	$11010112,\
	$11333221,\
	$00132100,\
	$10000000,\
	$01010112,\
	$21212121

importedtileB213:	.defchr $2D50,0,\
	$12111121,\
	$22102221,\
	$12012211,\
	$21112110,\
	$11121100,\
	$22311010,\
	$13111100,\
	$32101000

importedtileB214:	.defchr $2D60,0,\
	$00011113,\
	$00001111,\
	$00000111,\
	$00000011,\
	$00000001,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB215:	.defchr $2D70,0,\
	$21101101,\
	$32101010,\
	$22110101,\
	$11111121,\
	$11011101,\
	$11101110,\
	$01110001,\
	$00111011

importedtileB216:	.defchr $2D80,0,\
	$00010112,\
	$10111111,\
	$01111100,\
	$21211121,\
	$11010113,\
	$11100111,\
	$01000000,\
	$21101111

importedtileB217:	.defchr $2D90,0,\
	$11111111,\
	$11111111,\
	$00010101,\
	$10101010,\
	$11010101,\
	$21111111,\
	$11121111,\
	$22212122

importedtileB218:	.defchr $2DA0,0,\
	$00010112,\
	$10111111,\
	$01111221,\
	$21211111,\
	$11010111,\
	$11101110,\
	$01001100,\
	$21101000

importedtileB219:	.defchr $2DB0,0,\
	$11010000,\
	$11100000,\
	$11000000,\
	$10000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB220:	.defchr $2DC0,0,\
	$33321212,\
	$13333221,\
	$11133311,\
	$11113333,\
	$01111233,\
	$00011111,\
	$00001111,\
	$00000011

importedtileB221:	.defchr $2DD0,0,\
	$12210210,\
	$22211121,\
	$00010012,\
	$11211011,\
	$33100100,\
	$33332010,\
	$11333321,\
	$11113333

importedtileB222:	.defchr $2DE0,0,\
	$00011111,\
	$00101111,\
	$10010111,\
	$21001011,\
	$12100001,\
	$00211000,\
	$00011211,\
	$32100021

importedtileB223:	.defchr $2DF0,0,\
	$22121212,\
	$22212121,\
	$12221211,\
	$21212121,\
	$11111101,\
	$11111110,\
	$01010001,\
	$10111121

importedtileB224:	.defchr $2E00,0,\
	$11121100,\
	$21211000,\
	$11110002,\
	$11100022,\
	$01000211,\
	$10112110,\
	$01110001,\
	$21101133

importedtileB225:	.defchr $2E10,0,\
	$02001212,\
	$21102221,\
	$11010000,\
	$10101112,\
	$01001233,\
	$10123332,\
	$13333211,\
	$33321111

importedtileB226:	.defchr $2E20,0,\
	$12112332,\
	$21233321,\
	$03332111,\
	$33311111,\
	$32111100,\
	$11111000,\
	$11100000,\
	$10000000

importedtileB227:	.defchr $2E30,0,\
	$11110000,\
	$11100000,\
	$10000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB228:	.defchr $2E40,0,\
	$11111123,\
	$00111111,\
	$00001111,\
	$00000001,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB229:	.defchr $2E50,0,\
	$33332200,\
	$22333333,\
	$11122333,\
	$11111111,\
	$00111111,\
	$00000111,\
	$00000000,\
	$00000000

importedtileB230:	.defchr $2E60,0,\
	$11111111,\
	$11111111,\
	$33333333,\
	$33333333,\
	$11111111,\
	$11111111,\
	$11111111,\
	$00000000

importedtileB231:	.defchr $2E70,0,\
	$01233333,\
	$33333221,\
	$33221111,\
	$11111111,\
	$11111000,\
	$11000000,\
	$00000000,\
	$00000000

importedtileB232:	.defchr $2E80,0,\
	$32111110,\
	$11111000,\
	$11100000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000,\
	$00000000

importedtileB233:	.defchr $2E90,0,\
	$00233210,\
	$02311321,\
	$03123131,\
	$03131131,\
	$03123131,\
	$02311321,\
	$00233211,\
	$00011110

importedtileB234:	.defchr $2EA0,0,\
	$00233310,\
	$02311131,\
	$00110121,\
	$00003211,\
	$00032110,\
	$00321131,\
	$03333321,\
	$00111111

importedtileB235:	.defchr $2EB0,0,\
	$00233210,\
	$02312321,\
	$03113231,\
	$03122131,\
	$03231131,\
	$02321321,\
	$00233211,\
	$00011110

importedtileB236:	.defchr $2EC0,0,\
	$00021000,\
	$00231000,\
	$00031000,\
	$00031000,\
	$00031000,\
	$00031000,\
	$00333100,\
	$00011100

importedtileB237:	.defchr $2ED0,0,\
	$00233310,\
	$02211231,\
	$03100031,\
	$02200131,\
	$00233331,\
	$00011321,\
	$02333211,\
	$00111110

importedtileB238:	.defchr $2EE0,0,\
	$03333210,\
	$03111131,\
	$03100021,\
	$03333211,\
	$03111110,\
	$03100000,\
	$03100000,\
	$00100000

importedtileB239:	.defchr $2EF0,0,\
	$03333331,\
	$03111111,\
	$03100000,\
	$03333310,\
	$03111110,\
	$03100000,\
	$03333331,\
	$00111111

importedtileB240:	.defchr $2F00,0,\
	$03333310,\
	$00131110,\
	$00031000,\
	$00031000,\
	$00031000,\
	$00031000,\
	$00031000,\
	$00001000

importedtileB241:	.defchr $2F10,0,\
	$03333210,\
	$03111131,\
	$03100021,\
	$03333211,\
	$03112310,\
	$03100310,\
	$03100221,\
	$00100011

importedtileB242:	.defchr $2F20,0,\
	$03310331,\
	$03322331,\
	$03233231,\
	$03133131,\
	$03122131,\
	$03101131,\
	$03100031,\
	$00100001

importedtileB243:	.defchr $2F30,0,\
	$00233210,\
	$02211221,\
	$03110031,\
	$03100031,\
	$03103231,\
	$02310321,\
	$00233231,\
	$00011111

importedtileB244:	.defchr $2F40,0,\
	$00233210,\
	$02311321,\
	$03110011,\
	$03100000,\
	$03100000,\
	$02310321,\
	$00233211,\
	$00011110

importedtileB245:	.defchr $2F50,0,\
	$03100031,\
	$03100031,\
	$03100031,\
	$03100031,\
	$03100031,\
	$02310321,\
	$00233211,\
	$00011110

importedtileB246:	.defchr $2F60,0,\
	$00033310,\
	$00003110,\
	$00003100,\
	$00003100,\
	$00003100,\
	$00003100,\
	$00033310,\
	$00001110

importedtileB247:	.defchr $2F70,0,\
	$00310000,\
	$00310000,\
	$00310000,\
	$00310000,\
	$00310000,\
	$00310000,\
	$00333331,\
	$00011111

importedtileB248:	.defchr $2F80,0,\
	$00022100,\
	$00033100,\
	$00211210,\
	$00310310,\
	$02333321,\
	$03111131,\
	$03100031,\
	$00100001

importedtileB249:	.defchr $2F90,0,\
	$03310031,\
	$03321031,\
	$03231031,\
	$03123131,\
	$03103231,\
	$03100331,\
	$03100031,\
	$00100001

importedtileB250:	.defchr $2FA0,0,\
	$00333310,\
	$03211231,\
	$03110011,\
	$00333310,\
	$00011231,\
	$03100021,\
	$00333211,\
	$00011110

importedtileB251:	.defchr $2FB0,0,\
	$03333210,\
	$03111321,\
	$03100031,\
	$03100031,\
	$03100031,\
	$03100321,\
	$03333211,\
	$00111110

importedtileB252:	.defchr $2FC0,0,\
	$03333210,\
	$03111131,\
	$03100031,\
	$03333211,\
	$03111121,\
	$03100021,\
	$03333211,\
	$00111110

importedtileB253:	.defchr $2FD0,0,\
	$03212310,\
	$00313110,\
	$00313100,\
	$00232100,\
	$00031100,\
	$00031000,\
	$00031000,\
	$00001000

importedtileB254:	.defchr $2FE0,0,\
	$00233310,\
	$02311231,\
	$03110011,\
	$03103331,\
	$03100231,\
	$02310031,\
	$00233321,\
	$00011111

importedtileB255:	.defchr $2FF0,0,\
	$00233210,\
	$02311321,\
	$03110031,\
	$03100031,\
	$03100031,\
	$02310321,\
	$00233211,\
	$00011110


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
