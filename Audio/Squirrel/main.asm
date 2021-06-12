    .zp
    
_sourceaddr:    .ds 2
_vreg:          .ds 1	; the currently selected VDC register
_vsr:           .ds 1	; the VDC status register
vsync_check:    .ds 1   ; used to check if a vertical blank has just occurred
bataddresslo:   .ds 1   ; used when calculating the BAT address to modify for a given X, Y coord
bataddresshi:   .ds 1
_dh:            .ds 1
_al:            .ds 1
_ah:            .ds 1

    .bss
    
_TimerCnt:		.ds	2
_MainCnt:		.ds	2
_SubCnt:		.ds	2    

;---------------------------------------------------------------------------------------
; This block defines standard system variables in the zero-page.
;---------------------------------------------------------------------------------------
; do NOT change these variable names. They are used by HuC startup code.
;........................................................................................

				.org	$20e6
				
psg_irqflag	 	.ds		1		; $e6 = flag to indicate psg interrupt already being serviced.

;........................................................................................
; library.asm, line 1380 is the psg_init routine (which gets called during hardware setup).
; it sets psg_inhibit to 1! so, IF we are going to use inhibit to turn the psg on/off,
; then bit 7 = 0 means the psg is OFF, and bit 7 = 1 means the psg is ON.
;

psgFlags
psg_inhibit		.ds		1		; $e7 = flag bits that control indicate the psg state.
								;       bit 0 : 0 = use timer irq,   1 = use vsync irq
                                ;       bit 7 : 0 = psg not ready,   1 = psg ready.
								
psgPtr1			.ds		2		; $e8-$e9 = temp pointer1 for psg  (was _tmpptr)
psgPtr2 	    				; $ea-$eb = temp pointer2 for psg  (was _tmpptr1 )
psgTemp1		.ds     1
psgTemp2		.ds		1

;---------------------------------------------------------------------------------------
; This block defines data used by (original) psg MML player routine.
; this is the "shared" data, common to both main and sub tracks.
;.......................................................................................
;
;		.org			$22d0

		.include 		"main\common.inc"

;---------------------------------------------------------------------------------------
; this is the data used by ONLY the main track.
;.......................................................................................
;
;		.org			$22ee

		.include 		"main\main.inc"

;---------------------------------------------------------------------------------------
; this is the data used by ONLY the sub-track.
;
;		.org			$248b
		.include		"sub\sub.inc"
        

; ----
; PSG (Programmable Sound Generator)

psgport		.equ $0800
psg_ch		.equ psgport
psg_mainvol	.equ psgport+1
psg_freqlo	.equ psgport+2
psg_freqhi	.equ psgport+3
psg_ctrl	.equ psgport+4
psg_pan		.equ psgport+5
psg_wavebuf	.equ psgport+6
psg_noise	.equ psgport+7
psg_lfofreq	.equ psgport+8
psg_lfoctrl	.equ psgport+9

; TIMER
timerport	.equ $0C00
timer_cnt	.equ timerport
timer_ctrl	.equ timerport+1

; ----
; IRQ ports

irqport		.equ $1400
irq_disable	.equ irqport+2
irq_status	.equ irqport+3



PSGF_ON			.equ	$00
PSGF_OFF		.equ    $01
PSGF_INIT		.equ	$02
PSGF_BANK		.equ    $03			; already defined 
PSGF_TRACK  		.equ    $04
PSGF_WAVE		.equ    $05
PSGF_ENV		.equ    $06
PSGF_FM			.equ    $07
PSGF_PE			.equ    $08
PSGF_PC			.equ    $09
PSGF_TEMPO		.equ	$10
PSGF_PLAY		.equ	$0B
PSGF_MSTAT		.equ	$0c
PSGF_SSTAT		.equ	$0D
PSGF_MSTOP		.equ	$0E
PSGF_SSTOP		.equ    $0F

PSGF_ASTOP		.equ    $10
PSGF_MVOFF 		.equ    $11
PSGF_CONT    	.equ	$12
PSGF_FDOUT		.equ	$13
PSGF_DCNT		.equ	$14

;---------------------------------------------------------------------------
; fields for psgFlags / psg_inhibt

PSG_INHIBIT =	$80
PSG_IRQ		=   $01

;---------------------------------------------------------------------------
; song initialized bit

PSG_SNG_NEED_INIT		= $80

;---------------------------------------------------------------------------
; Track control fields

PSG_TRK_MAINPAUSE =	$80
PSG_TRK_SUBPAUSE =	$40

;...................................

PSG_DDA =	$40

;---------------------------------------------------------------------------
; system numbers

PSGSYS_MAIN_ONLY		= 0
PSGSYS_SUB_ONLY			= 1
PSGSYS_BOTH_60			= 2
PSGSYS_BOTH_120			= 3
PSGSYS_BOTH_240			= 4
PSGSYS_BOTH_300			= 5

; --------
; useful macros:
;

ENV_RLS	.macro
	 .db $fb
	 .dw \1
	.endm

ENV_LEV	.macro
	 .db $fc
	 .dw \1
	.endm

ENV_DLY	.macro
	 .db \1
	 .dw \2
	.endm

ENV_END	.macro
	 .db $ff
	.endm


    .list 
    .code
	.bank $0
	
    
	.org $fff6
	.dw my_rti
	.dw vdc_int
	.dw _timer
	.dw my_rti
	.dw RESET    

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
	lda #%00000001          ;IRQ2 interrupt is set OFF
	sta $1402		        ;VDC (IRQ1) and TIMER interrupt set ON
    
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
    
;    lda #bank(sounddriver)
;    tam #page(sounddriver)

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
 

_timer:
	pha
	phx
	phy

	sta   irq_status	; acknowledge interrupt

	;--------------------------------------------------------------------------
	; is psg irq already being serviced ?
	;--------------------------------------------------------------------------
	
	lda   <psg_irqflag
	bne   .timer_exit

	inc   <psg_irqflag	; mark IRQ as being serviced
	cli					; but allow other interrupts to be processed		

	;--------------------------------------------------------------------------
	; if psg not running, skip driver call.
	
	lda		<psg_inhibit
	and		#$80			; check bit 7
	beq		.timer_clear	; skip if not running
	
;	bbr7	<psg_inhibit, .exit2		; bit 7 indicates psg running
										;     1 means psg ready
										; so, if psg not turned on, skip it
	
	;--------------------------------------------------------------------------
	; are we running on timer irq ?

	lda		<psg_inhibit
	and		#PSG_IRQ					; which interrupt are we using ?
	bne		.timer_clear				; if vsync (0), ignore
	
;	bbs0   <psg_inhibit, .exit2			; bit 0 indicates irq
										; 0 is timer
										; so this is "if we're on VSync, skip it"
	
	;--------------------------------------------------------------------------
	;	irq just started being serviced, psg ready, and psg running. call driver
	
	inc		_TimerCnt					; count interrupt
	jsr		psg_driver					; do all sound-related stuff
	
.timer_clear:	
	stz   <psg_irqflag	; mark psg IRQ as having been processed
	
.timer_exit:
	ply
	plx
	pla
	rti

;------------------------------------------------------------------------------------------
; this is the system portion of the psg driver routine. It is responsible for mapping in
; the actual psg driver, calling the drivers, and restoring the original memory map.
; I assume this was done in this manner so the actual driver routine could be larger then
; the space left in the system code page(s).
;------------------------------------------------------------------------------------------

psg_driver:


    ;-----------------------------------------------------------------------------
	; this maps the driver code into memory.
	
	tma   #page(psgMainDrive)		; map out whatever is in 'our' code segment
	pha								; save old code page number
	lda   #bank(psgMainDrive)		; load 'our' page number
	tam   #page(psgMainDrive)		; and map it into memory

    ;-----------------------------------------------------------------------------
	; this maps in the music data.
	
	tma   #4				; get page for bank 4 = $8000
	pha						; save whatever was there
	lda   psgDataBankLow	; map song data low
	tam   #4
	
	tma   #5				; get page for bank 5 = $A000
	pha						; save whatever was there
	lda   psgDataBankHigh
	tam   #5

;.............................................................................
; _al = 0 	-> main track only; 60Hz
; 		1	-> sub track only; 60Hz
; 		2	-> both tracks; 60Hz
; 		3	-> both tracks; 120Hz
; 		4	-> both tracks; 240Hz
; 		5	-> both tracks; 300Hz
;.............................................................................


    ;-----------------------------------------------------------------------------
	; and finally, we can call the actual driver, with everything in the proper place
    ;-----------------------------------------------------------------------------
	
	lda		psgSystemNo			; get system number
	cmp		#1					; sub-track only ?
	beq		.doSub				; yes, skip main
	
	inc		_MainCnt
	jsr		psgMainDrive		; do main tracks

	cmp		#0					; still playing ??
	bne		.doSub				; yes, skip pausing it
	
	lda		psgTrackCtrl		; get control byte
	ora		#$80				; main track pause bit
	sta		psgTrackCtrl
	
.doSub
	lda		psgSystemNo			; get system number
	cmp		#0					; main tracks only ?
	beq		.sndDone			; yes, skip main track

	inc		_SubCnt
	jsr   	psgSubDrive			; handle sub track
	
	cmp		#0					; still playing ?
	bne		.sndDone			; yes, skip pausing it
	
	lda		psgTrackCtrl		; get track control bit
	ora		#$40				; main-track pause bit
	sta		psgTrackCtrl
	
.sndDone
	
    ;-----------------------------------------------------------------------------
	; this has to do with delaying the correct amount, so tempos work right
	; tempo appears to be how much time is between timer interrupts.
	
	lda		psg_inhibit			; get inhibit flag
	and		#1					; get irq type
	bne		.noreset			; not timer (0), skip re-set
	
	lda   psgTimerCount			; check timer count
	bmi   .noreset				; if it's already been set, skip it

	sta   timer_cnt				; update timer count
	ora   #$80					; mark as set
	sta   psgTimerCount			; save for next time

    ;-----------------------------------------------------------------------------
	; now that the driver is done, we need to restore the things we mapped out.
	; music data is first
	
.noreset:

	pla				; restore high data banks
	tam   #5
	pla				; restore low data bank
	tam   #4

    ;-----------------------------------------------------------------------------
	; followed by the driver code that we mapped in.
	
	pla
	tam   #page(psgMainDrive)	; restore code bank
	rts

    

timer_int:
	sta $1403	;ACK TIMER
	stz $0c01	;Turn off timer
my_rti:	rti

    ; put the driver system number you want in _al and call this
psgInit_Interface:
    lda		#PSGF_INIT
    sta		<_dh

    jsr		psg_bios
    rts
    
    ; put the IRQ to use in _al - 1 is vsync, 0 is timer
psgOn_Interface:

	lda		#PSGF_ON
    sta		<_dh

    jsr	psg_bios
    rts
    
    ; put track to play in _al
psgPlay_Interface:

	lda		#PSGF_PLAY
	sta		<_dh
	
    stz     _ah

	jsr 	psg_bios
    rts
    
    ; put amount of delay in _al
psgDelay_Interface:

	lda		#PSGF_DCNT
    sta		<_dh          ; set function number
    
    jsr		psg_bios   
    rts
    

    

.include	"sound.asm"



    

	.code
    .bank $1
    .org  $4000

main:   	
    ; map in the memory bank
	 lda   #bank(ourgraphicsdata)	; addressable memory
	 tam   #page(ourgraphicsdata) 
     
     
    ; fill palette #0
    
    ; vsync to avoid snow - we are about to update the palette
    lda #1
    sta <vsync_check
.wl1:
    bbr0    <vsync_check,.wl2
    bra .wl1
.wl2:
         
    ; 0 into both $0402 and $0403 - we're updating the colors in palette 0 of the background color palettes
    stz $0402
    stz $0403
    
    ldy #0
    ldx #16     ; 16 colors per palette
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
     
     
    lda #$00    ;(MAWR - Memory Address Write Register) This register is used to set the VRAM write address
    sta  <_vreg    ; save this value so VDC interrupt does not overwrite
    sta $0000   ;Register select port
    
    ; here is where we set the address in VRAM we wish to load the graphics into - $1000
    lda #$00
    sta $0002   ; Data port: lower 8bit/LSB
    lda #$10
    sta $0003     ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
    
    ; ok, we have set where we want this written, now lets write the actual data
    
    lda #$02    ;(VRR/VWR) Setting this register tells the VDC you are ready to
                ;read/write to VRAM via the data port.
    sta  <_vreg ; save this value so VDC interrupt does not overwrite
    sta $0000   ;Register select port

    tia	ourgraphicsdata,$0002,$0040 ;Blast the imported tiles to VRAM    
    
     
    ; now lets load the blank character into each part of our 32x32 BAT
    
    lda #$00    ;(MAWR) This register is used to set the VRAM write address
    sta <_vreg ; save this value so VDC interrupt does not overwrite
    sta $0000   ;Register select port
    
    ; BAT always starts at VRAM address $0000
    lda #$00
    sta $0002   ; Data port: lower 8bit/LSB
    lda #$00
    sta $0003     ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
    
    lda #$02    ;(VRR/VWR) Setting this register tells the VDC you are ready to
                ;read/write to VRAM via the data port.
    sta <_vreg ; save this value so VDC interrupt does not overwrite
    sta $0000   ;Register select port


    lda   #32               ; size 32 lines tall
.cs1:    
    ldx   #32               ; size 32 chars wide
    pha
.cs2:    
    cly

	; Fill each BAT map position with a pointer to the blank character
    ; the blank character is at $1010
    ; to get its pointer address shift right 4 times - we get $0101
    ; the left most (MSB) value is the palette to use, in this case 0
    ; is the correct value - so use $0101 as value to put in each BAT word position


    lda #$01    ; lsb    
    sta $0002
    lda #$01    ; msb
    sta $0003
        
    dex                     ; next block
    bne   .cs2
    pla
    dec   A                 ; next line
    bne   .cs1
    
    
    ; Now we write our graphic on-screen. How do we know the VRAM address to write to?
    ; We use a routine that, given an X and Y value, returns the correct address 
    ; This assumes a 32x32 BAT and routine would need to be modified if a different BAT
    ; size is used
    
    ldx #6
    ldy #12
    JSR CalculateBATAddress
    
    
    lda #$00    ;(MAWR) This register is used to set the VRAM write address
    sta <_vreg ; save this value so VDC interrupt does not overwrite
    sta $0000   ;Register select port
    

    lda bataddresslo
    sta $0002   ; Data port: lower 8bit/LSB
    lda bataddresshi
    sta $0003     ;Data port: upper 8bit/MSB + latch - command is activated on VDC 
    
    lda #$02    ;(VRR/VWR) Setting this register tells the VDC you are ready to
                ;read/write to VRAM via the data port.
    sta <_vreg ; save this value so VDC interrupt does not overwrite
    sta $0000   ;Register select port    

    lda #$00    ; lsb    
    sta $0002
    lda #$01    ; msb
    sta $0003  
    
    ; Now lets play some music
    
    lda #5
    sta <_al
    jsr psgInit_Interface
    
    lda #0  ; 0 use timer
    sta <_al
    jsr psgOn_Interface
    
    lda #0
    sta <_al
    jsr psgPlay_Interface
    
    
;-----------------
; set bank values 
;
	lda 	#$03
	sta	<_dh
	lda	#BANK(_sngBank1)
	sta	<_al
	stz	<_ah
	jsr	psg_bios

;--------------------------------
; set track index table location 
;
	lda    #$04
	sta    <_dh
	lda	#LOW(TRACK_IX)
	sta	<_al
	lda	#HIGH(TRACK_IX)
	sta	<_ah
	jsr	psg_bios

;--------------------
; register modulation 
;
	lda	#7
	sta	<_dh

	lda	#LOW(MODU_IX)
	sta	<_al
	lda	#HIGH(MODU_IX)
	sta	<_ah
	jsr	psg_bios

;--------------------
; register percussion 
;
	lda	#9
	sta	<_dh

	lda	#LOW(DRUM_TAB)
	sta	<_al
	lda	#HIGH(DRUM_TAB)
	sta	<_ah
	jsr	psg_bios

;--------------------
; Set Tempo 
;
	lda	#10
	sta	<_dh

	lda	#70
	sta	<_al
	jsr	psg_bios
    
    
    lda #0
    sta <_al
    jsr psgDelay_Interface
    
    
    
    
    
    
  
  
.here:  bra    .here    ; infinite loop!


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
ourchar:     .defchr $1000,0,\
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
		$777,$777,$777,$777,\
		$777,$777,$777,$777,\
		$777,$777,$777,$777
        
        
    .data
    .bank   9
    .org    $8000
_sngBank1:
    .include  "gnop.asm"

    .code        
    