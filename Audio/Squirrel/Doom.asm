Channel000:
		.db		$db
		.db		$50
		.db		$dc
		.db		$1f
		.db		$d0
		.db		$00
		.db		$f1
		.db		$ff
lead1:
		.db		$f0
		.db		LOW(Channel000)
		.db		HIGH(Channel000)
		.db		$d1
		.db		$dd
		.db		$f0
		.db		$e5
		.db		$11
		.db		$e6
		.db		$01
		.db		$e7
		.db		$00
		.db		$e8
		.db		$01
		.db		$ff
Lead2:
		.db		$f0
		.db		LOW(Channel000)
		.db		HIGH(Channel000)
		.db		$d1
		.db		$dd
		.db		$0f
		.db		$e5
		.db		$11
		.db		$e6
		.db		$01
		.db		$e7
		.db		$00
		.db		$e8
		.db		$01
		.db		$ff
BASS:
		.db		$f0
		.db		LOW(Channel000)
		.db		HIGH(Channel000)
		.db		$d1
		.db		$dd
		.db		$ff
		.db		$e5
		.db		$13
		.db		$e6
		.db		$01
		.db		$ff
drummage:
		.db		$f0
		.db		LOW(Channel000)
		.db		HIGH(Channel000)
		.db		$d3
		.db		$dd
		.db		$dd
		.db		$f8
		.db		$01
		.db		$ff
HiHatting:
		.db		$f0
		.db		LOW(Channel000)
		.db		HIGH(Channel000)
		.db		$d5
		.db		$dd
		.db		$00
		.db		$f8
		.db		$01
		.db		$ff
MODU_TAB:
wiggle2:					;0
	.db	$00
	.db	$00
	.db	$01
	.db	$02
	.db	$04
	.db	$08
	.db	$0c
	.db	$10
	.db	$14
	.db	$10
	.db	$0c
	.db	$08
	.db	$04
	.db	$02
	.db	$01
	.db	$00
	.db	$00
	.db	$ff
	.db	$fe
	.db	$fc
	.db	$f8
	.db	$f4
	.db	$f0
	.db	$ec
	.db	$f0
	.db	$f4
	.db	$f8
	.db	$fc
	.db	$fe
	.db	$ff
	.db	$00
	.db	$00
	.db	$80
;----- end wiggle2 ----
;----end MODU_TAB----

;--------percussion-----------
perc000:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc001:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc002:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc003:
	.db	$c0
	.db	$01
	.db	$e0
	.db	$00
	.db	$d0
	.db	$ee
	.db	$b3
	.db	$28
	.db	$b7
	.db	$10
	.db	$be
	.db	$e0
	.db	$b6
	.db	$b0
	.db	$b2
	.db	$68
	.db	$b5
	.db	$f0
	.db	$f0
perc004:
	.db	$c0
	.db	$01
	.db	$e0
	.db	$00
	.db	$d0
	.db	$0e
	.db	$b0
	.db	$c8
	.db	$b1
	.db	$90
	.db	$b3
	.db	$e8
	.db	$0f
	.db	$14
	.db	$bb
	.db	$b8
	.db	$bb
	.db	$58
	.db	$09
	.db	$0f
	.db	$f0
perc005:
	.db	$c0
	.db	$00
	.db	$e0
	.db	$00
	.db	$d0
	.db	$e0
	.db	$b0
	.db	$5a
	.db	$b0
	.db	$5a
	.db	$b0
	.db	$6e
	.db	$1f
	.db	$1e
	.db	$1e
	.db	$1d
	.db	$f0
perc006:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc007:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc008:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc009:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc010:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
perc011:
	.db	$c0
	.db	$11
	.db	$e0
	.db	$2d
	.db	$d0
	.db	$ff
	.db	$b3
	.db	$ac
	.db	$b0
	.db	$67
	.db	$1f
	.db	$1b
	.db	$1d
	.db	$1a
	.db	$f0
;--------end percussion-----------

PITCH_IX:		=		$0000
FREQ_IX:		=		$0000
MODU_IX:
		.db		LOW(wiggle2)
		.db		HIGH(wiggle2)
;----end MODU_IX----

DRUM_TAB:
		.db		LOW(perc003)
		.db		HIGH(perc003)
		.db		LOW(perc004)
		.db		HIGH(perc004)
		.db		LOW(perc005)
		.db		HIGH(perc005)
		.db		LOW(perc006)
		.db		HIGH(perc006)
		.db		LOW(perc007)
		.db		HIGH(perc007)
		.db		LOW(perc008)
		.db		HIGH(perc008)
		.db		LOW(perc009)
		.db		HIGH(perc009)
		.db		LOW(perc010)
		.db		HIGH(perc010)
		.db		LOW(perc011)
		.db		HIGH(perc011)
		.db		LOW(perc000)
		.db		HIGH(perc000)
		.db		LOW(perc001)
		.db		HIGH(perc001)
		.db		LOW(perc002)
		.db		HIGH(perc002)
TEMPO:			=		$0050
WAVE_BASE:		=		$0000
N_WAVES:		=		0

;--------Begin DOOM--------
DOOM:
		.db		$37
		.db		LOW(lead1)
		.db		HIGH(lead1)
		.db		LOW(Lead2)
		.db		HIGH(Lead2)
		.db		LOW(BASS)
		.db		HIGH(BASS)
		.db		LOW(drummage)
		.db		HIGH(drummage)
		.db		LOW(HiHatting)
		.db		HIGH(HiHatting)
;--------End DOOM--------

;-----------Track Index Table------------
TRACK_IX:
		.db		LOW(DOOM)
		.db		HIGH(DOOM)
;-----------End Track Index Table--------
