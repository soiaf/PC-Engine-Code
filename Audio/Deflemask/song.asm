    .data
    .bank DMF_DATA_ROM_BANK+0
    .org (DMF_HEADER_MPR << 13)
Super_Sonic_STH2_Remix:
Super_Sonic_STH2_Remix.timeBase:        .db $00
Super_Sonic_STH2_Remix.timeTick:        .db $03, $03
Super_Sonic_STH2_Remix.patternRows:     .db $40
Super_Sonic_STH2_Remix.matrixRows:      .db $06
Super_Sonic_STH2_Remix.instrumentCount: .db $06
Super_Sonic_STH2_Remix.pointers:
    .dw Super_Sonic_STH2_Remix.wave
    .dw Super_Sonic_STH2_Remix.instruments
    .dw Super_Sonic_STH2_Remix.matrix
Super_Sonic_STH2_Remix.name:
  .db 22
  .db "Super Sonic STH2 Remix"
Super_Sonic_STH2_Remix.author:
  .db 13
  .db "littlelamp100"
Super_Sonic_STH2_Remix.wave:
Super_Sonic_STH2_Remix.wave_0000:
    .db $11,$15,$19,$1b,$1d,$1e,$1f,$1f,$1f,$1f,$1e,$1d,$1b,$19,$15,$11
    .db $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
Super_Sonic_STH2_Remix.wave_0001:
    .db $0f,$12,$15,$17,$19,$1b,$1d,$1e,$1e,$1d,$1b,$19,$17,$15,$12,$0f
    .db $00,$02,$04,$06,$08,$0a,$0c,$0e,$10,$12,$14,$16,$18,$1a,$1c,$1e
Super_Sonic_STH2_Remix.wave_0002:
    .db $00,$04,$06,$08,$09,$0a,$0b,$0b,$0c,$0d,$0d,$0e,$0e,$0f,$0f,$0f
    .db $10,$10,$10,$11,$11,$12,$12,$13,$14,$14,$15,$16,$17,$19,$1b,$1f
Super_Sonic_STH2_Remix.wave_0003:
    .db $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
    .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
Super_Sonic_STH2_Remix.instruments:
Super_Sonic_STH2_Remix.instruments.volume.size:
    .db $01,$01,$01,$10,$0b,$01
Super_Sonic_STH2_Remix.instruments.volume.loop:
    .db $ff,$ff,$ff,$ff,$ff,$ff
Super_Sonic_STH2_Remix.instruments.volume.lo:
    .dwl Super_Sonic_STH2_Remix.instruments.volume_0000
    .dwl Super_Sonic_STH2_Remix.instruments.volume_0001
    .dwl Super_Sonic_STH2_Remix.instruments.volume_0002
    .dwl Super_Sonic_STH2_Remix.instruments.volume_0003
    .dwl Super_Sonic_STH2_Remix.instruments.volume_0004
    .dwl Super_Sonic_STH2_Remix.instruments.volume_0005
Super_Sonic_STH2_Remix.instruments.volume.hi:
    .dwh Super_Sonic_STH2_Remix.instruments.volume_0000
    .dwh Super_Sonic_STH2_Remix.instruments.volume_0001
    .dwh Super_Sonic_STH2_Remix.instruments.volume_0002
    .dwh Super_Sonic_STH2_Remix.instruments.volume_0003
    .dwh Super_Sonic_STH2_Remix.instruments.volume_0004
    .dwh Super_Sonic_STH2_Remix.instruments.volume_0005
Super_Sonic_STH2_Remix.instruments.arpeggio.size:
    .db $00,$05,$00,$00,$0a,$00
Super_Sonic_STH2_Remix.instruments.arpeggio.loop:
    .db $00,$ff,$00,$00,$ff,$00
Super_Sonic_STH2_Remix.instruments.arpeggio.lo:
    .dwl Super_Sonic_STH2_Remix.instruments.arpeggio_0000
    .dwl Super_Sonic_STH2_Remix.instruments.arpeggio_0001
    .dwl Super_Sonic_STH2_Remix.instruments.arpeggio_0002
    .dwl Super_Sonic_STH2_Remix.instruments.arpeggio_0003
    .dwl Super_Sonic_STH2_Remix.instruments.arpeggio_0004
    .dwl Super_Sonic_STH2_Remix.instruments.arpeggio_0005
Super_Sonic_STH2_Remix.instruments.arpeggio.hi:
    .dwh Super_Sonic_STH2_Remix.instruments.arpeggio_0000
    .dwh Super_Sonic_STH2_Remix.instruments.arpeggio_0001
    .dwh Super_Sonic_STH2_Remix.instruments.arpeggio_0002
    .dwh Super_Sonic_STH2_Remix.instruments.arpeggio_0003
    .dwh Super_Sonic_STH2_Remix.instruments.arpeggio_0004
    .dwh Super_Sonic_STH2_Remix.instruments.arpeggio_0005
Super_Sonic_STH2_Remix.instruments.wave.size:
    .db $01,$01,$01,$00,$00,$01
Super_Sonic_STH2_Remix.instruments.wave.loop:
    .db $ff,$ff,$ff,$00,$00,$ff
Super_Sonic_STH2_Remix.instruments.wave.lo:
    .dwl Super_Sonic_STH2_Remix.instruments.wave_0000,Super_Sonic_STH2_Remix.instruments.wave_0001
    .dwl Super_Sonic_STH2_Remix.instruments.wave_0002,Super_Sonic_STH2_Remix.instruments.wave_0003
    .dwl Super_Sonic_STH2_Remix.instruments.wave_0004,Super_Sonic_STH2_Remix.instruments.wave_0005
Super_Sonic_STH2_Remix.instruments.wave.hi:
    .dwh Super_Sonic_STH2_Remix.instruments.wave_0000,Super_Sonic_STH2_Remix.instruments.wave_0001
    .dwh Super_Sonic_STH2_Remix.instruments.wave_0002,Super_Sonic_STH2_Remix.instruments.wave_0003
    .dwh Super_Sonic_STH2_Remix.instruments.wave_0004,Super_Sonic_STH2_Remix.instruments.wave_0005
Super_Sonic_STH2_Remix.instruments.flag:
    .db $00,$00,$00,$00,$00,$00
Super_Sonic_STH2_Remix.instruments.volume_0000:
    .db $7c
Super_Sonic_STH2_Remix.instruments.volume_0001:
    .db $7c
Super_Sonic_STH2_Remix.instruments.volume_0002:
    .db $7c
Super_Sonic_STH2_Remix.instruments.volume_0003:
    .db $7c,$4c,$78,$74,$70,$6c,$60,$5c,$54,$44,$3c,$34,$2c,$20,$14,$00
Super_Sonic_STH2_Remix.instruments.volume_0004:
    .db $7c,$58,$7c,$7c,$78,$68,$5c,$50,$40,$24,$00
Super_Sonic_STH2_Remix.instruments.volume_0005:
    .db $7c
Super_Sonic_STH2_Remix.instruments.arpeggio_0000:
Super_Sonic_STH2_Remix.instruments.arpeggio_0001:
    .db $18,$14,$10,$0b,$0c
Super_Sonic_STH2_Remix.instruments.arpeggio_0002:
Super_Sonic_STH2_Remix.instruments.arpeggio_0003:
Super_Sonic_STH2_Remix.instruments.arpeggio_0004:
    .db $0c,$0c,$0c,$0d,$0d,$0d,$0e,$0e,$0e,$0f
Super_Sonic_STH2_Remix.instruments.arpeggio_0005:
Super_Sonic_STH2_Remix.instruments.wave_0000:
    .db $00
Super_Sonic_STH2_Remix.instruments.wave_0001:
    .db $01
Super_Sonic_STH2_Remix.instruments.wave_0002:
    .db $02
Super_Sonic_STH2_Remix.instruments.wave_0003:
Super_Sonic_STH2_Remix.instruments.wave_0004:
Super_Sonic_STH2_Remix.instruments.wave_0005:
    .db $03
Super_Sonic_STH2_Remix.matrix:
Super_Sonic_STH2_Remix.matrix_0000.bank:
    .db bank(Super_Sonic_STH2_Remix.pattern_0000),bank(Super_Sonic_STH2_Remix.pattern_0001)
    .db bank(Super_Sonic_STH2_Remix.pattern_0001),bank(Super_Sonic_STH2_Remix.pattern_0002)
    .db bank(Super_Sonic_STH2_Remix.pattern_0002),bank(Super_Sonic_STH2_Remix.pattern_0003)
Super_Sonic_STH2_Remix.matrix_0000.lo:
    .dwl Super_Sonic_STH2_Remix.pattern_0000,Super_Sonic_STH2_Remix.pattern_0001
    .dwl Super_Sonic_STH2_Remix.pattern_0001,Super_Sonic_STH2_Remix.pattern_0002
    .dwl Super_Sonic_STH2_Remix.pattern_0002,Super_Sonic_STH2_Remix.pattern_0003
Super_Sonic_STH2_Remix.matrix_0000.hi:
    .dwh Super_Sonic_STH2_Remix.pattern_0000,Super_Sonic_STH2_Remix.pattern_0001
    .dwh Super_Sonic_STH2_Remix.pattern_0001,Super_Sonic_STH2_Remix.pattern_0002
    .dwh Super_Sonic_STH2_Remix.pattern_0002,Super_Sonic_STH2_Remix.pattern_0003
Super_Sonic_STH2_Remix.matrix_0001.bank:
    .db bank(Super_Sonic_STH2_Remix.pattern_0004),bank(Super_Sonic_STH2_Remix.pattern_0005)
    .db bank(Super_Sonic_STH2_Remix.pattern_0005),bank(Super_Sonic_STH2_Remix.pattern_0006)
    .db bank(Super_Sonic_STH2_Remix.pattern_0006),bank(Super_Sonic_STH2_Remix.pattern_0007)
Super_Sonic_STH2_Remix.matrix_0001.lo:
    .dwl Super_Sonic_STH2_Remix.pattern_0004,Super_Sonic_STH2_Remix.pattern_0005
    .dwl Super_Sonic_STH2_Remix.pattern_0005,Super_Sonic_STH2_Remix.pattern_0006
    .dwl Super_Sonic_STH2_Remix.pattern_0006,Super_Sonic_STH2_Remix.pattern_0007
Super_Sonic_STH2_Remix.matrix_0001.hi:
    .dwh Super_Sonic_STH2_Remix.pattern_0004,Super_Sonic_STH2_Remix.pattern_0005
    .dwh Super_Sonic_STH2_Remix.pattern_0005,Super_Sonic_STH2_Remix.pattern_0006
    .dwh Super_Sonic_STH2_Remix.pattern_0006,Super_Sonic_STH2_Remix.pattern_0007
Super_Sonic_STH2_Remix.matrix_0002.bank:
    .db bank(Super_Sonic_STH2_Remix.pattern_0008),bank(Super_Sonic_STH2_Remix.pattern_0009)
    .db bank(Super_Sonic_STH2_Remix.pattern_0009),bank(Super_Sonic_STH2_Remix.pattern_000a)
    .db bank(Super_Sonic_STH2_Remix.pattern_000b),bank(Super_Sonic_STH2_Remix.pattern_000c)
Super_Sonic_STH2_Remix.matrix_0002.lo:
    .dwl Super_Sonic_STH2_Remix.pattern_0008,Super_Sonic_STH2_Remix.pattern_0009
    .dwl Super_Sonic_STH2_Remix.pattern_0009,Super_Sonic_STH2_Remix.pattern_000a
    .dwl Super_Sonic_STH2_Remix.pattern_000b,Super_Sonic_STH2_Remix.pattern_000c
Super_Sonic_STH2_Remix.matrix_0002.hi:
    .dwh Super_Sonic_STH2_Remix.pattern_0008,Super_Sonic_STH2_Remix.pattern_0009
    .dwh Super_Sonic_STH2_Remix.pattern_0009,Super_Sonic_STH2_Remix.pattern_000a
    .dwh Super_Sonic_STH2_Remix.pattern_000b,Super_Sonic_STH2_Remix.pattern_000c
Super_Sonic_STH2_Remix.matrix_0003.bank:
    .db bank(Super_Sonic_STH2_Remix.pattern_000d),bank(Super_Sonic_STH2_Remix.pattern_000e)
    .db bank(Super_Sonic_STH2_Remix.pattern_000e),bank(Super_Sonic_STH2_Remix.pattern_000f)
    .db bank(Super_Sonic_STH2_Remix.pattern_0010),bank(Super_Sonic_STH2_Remix.pattern_0011)
Super_Sonic_STH2_Remix.matrix_0003.lo:
    .dwl Super_Sonic_STH2_Remix.pattern_000d,Super_Sonic_STH2_Remix.pattern_000e
    .dwl Super_Sonic_STH2_Remix.pattern_000e,Super_Sonic_STH2_Remix.pattern_000f
    .dwl Super_Sonic_STH2_Remix.pattern_0010,Super_Sonic_STH2_Remix.pattern_0011
Super_Sonic_STH2_Remix.matrix_0003.hi:
    .dwh Super_Sonic_STH2_Remix.pattern_000d,Super_Sonic_STH2_Remix.pattern_000e
    .dwh Super_Sonic_STH2_Remix.pattern_000e,Super_Sonic_STH2_Remix.pattern_000f
    .dwh Super_Sonic_STH2_Remix.pattern_0010,Super_Sonic_STH2_Remix.pattern_0011
Super_Sonic_STH2_Remix.matrix_0004.bank:
    .db bank(Super_Sonic_STH2_Remix.pattern_0012),bank(Super_Sonic_STH2_Remix.pattern_0013)
    .db bank(Super_Sonic_STH2_Remix.pattern_0013),bank(Super_Sonic_STH2_Remix.pattern_0014)
    .db bank(Super_Sonic_STH2_Remix.pattern_0014),bank(Super_Sonic_STH2_Remix.pattern_0015)
Super_Sonic_STH2_Remix.matrix_0004.lo:
    .dwl Super_Sonic_STH2_Remix.pattern_0012,Super_Sonic_STH2_Remix.pattern_0013
    .dwl Super_Sonic_STH2_Remix.pattern_0013,Super_Sonic_STH2_Remix.pattern_0014
    .dwl Super_Sonic_STH2_Remix.pattern_0014,Super_Sonic_STH2_Remix.pattern_0015
Super_Sonic_STH2_Remix.matrix_0004.hi:
    .dwh Super_Sonic_STH2_Remix.pattern_0012,Super_Sonic_STH2_Remix.pattern_0013
    .dwh Super_Sonic_STH2_Remix.pattern_0013,Super_Sonic_STH2_Remix.pattern_0014
    .dwh Super_Sonic_STH2_Remix.pattern_0014,Super_Sonic_STH2_Remix.pattern_0015
Super_Sonic_STH2_Remix.matrix_0005.bank:
    .db bank(Super_Sonic_STH2_Remix.pattern_0016),bank(Super_Sonic_STH2_Remix.pattern_0017)
    .db bank(Super_Sonic_STH2_Remix.pattern_0017),bank(Super_Sonic_STH2_Remix.pattern_0017)
    .db bank(Super_Sonic_STH2_Remix.pattern_0017),bank(Super_Sonic_STH2_Remix.pattern_0017)
Super_Sonic_STH2_Remix.matrix_0005.lo:
    .dwl Super_Sonic_STH2_Remix.pattern_0016,Super_Sonic_STH2_Remix.pattern_0017
    .dwl Super_Sonic_STH2_Remix.pattern_0017,Super_Sonic_STH2_Remix.pattern_0017
    .dwl Super_Sonic_STH2_Remix.pattern_0017,Super_Sonic_STH2_Remix.pattern_0017
Super_Sonic_STH2_Remix.matrix_0005.hi:
    .dwh Super_Sonic_STH2_Remix.pattern_0016,Super_Sonic_STH2_Remix.pattern_0017
    .dwh Super_Sonic_STH2_Remix.pattern_0017,Super_Sonic_STH2_Remix.pattern_0017
    .dwh Super_Sonic_STH2_Remix.pattern_0017,Super_Sonic_STH2_Remix.pattern_0017
    .data
    .bank DMF_DATA_ROM_BANK+1
    .org (DMF_DATA_MPR << 13)
Super_Sonic_STH2_Remix.pattern_0000:
    .db $1f,$3b,$1d,$74,$9e,$00,$44,$a0,$1f,$3c,$9e,$00,$44,$a0,$1f,$3d
    .db $9e,$00,$42,$a0,$1f,$3c,$9e,$00,$44,$a0,$1f,$3d,$9e,$00,$44,$a0
    .db $1f,$3e,$9e,$00,$42,$a0,$1f,$3d,$9e,$00,$44,$a0,$1f,$3e,$9e,$00
    .db $44,$a0,$1f,$3f,$9e,$00,$42,$a0,$1f,$3e,$9e,$00,$44,$a0,$1f,$3f
    .db $9e,$00,$44,$a0,$1f,$40,$9e,$00,$43,$ff
Super_Sonic_STH2_Remix.pattern_0001:
    .db $a0,$43,$1f,$3b,$1d,$7c,$9e,$02,$45,$a0,$41,$1f,$3b,$9e,$02,$43
    .db $1f,$3c,$9e,$02,$45,$1f,$3e,$9e,$02,$45,$1f,$40,$9e,$02,$43,$1f
    .db $3e,$9e,$02,$41,$a0,$41,$1f,$3e,$9e,$02,$41,$a0,$41,$1f,$3e,$9e
    .db $02,$41,$a0,$41,$1f,$3b,$9e,$02,$43,$1f,$3c,$9e,$02,$45,$1f,$39
    .db $9e,$02,$49,$ff
Super_Sonic_STH2_Remix.pattern_0002:
    .db $a0,$41,$1f,$47,$9e,$02,$45,$1f,$43,$9e,$02,$41,$a0,$41,$1f,$3e
    .db $9e,$02,$41,$a0,$41,$1f,$41,$9e,$02,$41,$a0,$41,$1f,$40,$9e,$02
    .db $41,$a0,$41,$1f,$41,$9e,$02,$41,$1f,$43,$9e,$02,$45,$a0,$41,$1f
    .db $47,$9e,$02,$45,$1f,$43,$9e,$02,$41,$a0,$41,$1f,$3e,$9e,$02,$41
    .db $a0,$41,$1f,$41,$9e,$02,$43,$1f,$25,$9e,$02,$41,$1f,$26,$9e,$02
    .db $41,$1f,$23,$9e,$02,$43,$1f,$1f,$9e,$02,$43,$ff
Super_Sonic_STH2_Remix.pattern_0003:
    .db $1f,$3c,$9e,$02,$4b,$1f,$39,$9e,$02,$41,$1f,$3c,$9e,$02,$41,$1f
    .db $40,$9e,$02,$4b,$1f,$3c,$9e,$02,$41,$1f,$40,$9e,$02,$41,$1f,$43
    .db $9e,$02,$5f,$ff
Super_Sonic_STH2_Remix.pattern_0004:
    .db $1f,$37,$1d,$74,$9e,$00,$44,$a0,$1f,$38,$9e,$00,$44,$a0,$1f,$39
    .db $9e,$00,$42,$a0,$1f,$38,$9e,$00,$44,$a0,$1f,$39,$9e,$00,$44,$a0
    .db $1f,$3a,$9e,$00,$42,$a0,$1f,$39,$9e,$00,$44,$a0,$1f,$3a,$9e,$00
    .db $44,$a0,$1f,$3b,$9e,$00,$42,$a0,$1f,$3a,$9e,$00,$44,$a0,$1f,$3b
    .db $9e,$00,$44,$a0,$1f,$3c,$9e,$00,$43,$ff
Super_Sonic_STH2_Remix.pattern_0005:
    .db $a0,$43,$1f,$3b,$1d,$7c,$1e,$02,$9a,$7c,$45,$a0,$41,$1f,$3b,$9e
    .db $02,$43,$1f,$3c,$9e,$02,$45,$1f,$3e,$1e,$02,$9a,$7f,$45,$1f,$40
    .db $1e,$02,$9a,$7c,$43,$1f,$3e,$1e,$02,$9a,$7f,$41,$a0,$41,$1f,$3e
    .db $9e,$02,$41,$a0,$41,$1f,$3e,$9e,$02,$41,$a0,$41,$1f,$3b,$1e,$02
    .db $9a,$7c,$43,$1f,$3c,$9e,$02,$45,$1f,$39,$1e,$02,$9a,$7f,$49,$ff
Super_Sonic_STH2_Remix.pattern_0006:
    .db $a0,$41,$1f,$47,$1e,$02,$9a,$7b,$45,$1f,$43,$9e,$02,$41,$a0,$41
    .db $1f,$3e,$9e,$02,$41,$a0,$41,$1f,$41,$9e,$02,$41,$a0,$41,$1f,$40
    .db $9e,$02,$41,$a0,$41,$1f,$41,$9e,$02,$41,$1f,$43,$9e,$02,$45,$a0
    .db $41,$1f,$47,$9e,$02,$45,$1f,$43,$9e,$02,$41,$a0,$41,$1f,$3e,$9e
    .db $02,$41,$a0,$41,$1f,$41,$9e,$02,$43,$a0,$4b,$ff
Super_Sonic_STH2_Remix.pattern_0007:
    .db $1f,$3c,$1e,$02,$9a,$7e,$4b,$a0,$43,$1f,$3c,$1e,$02,$9a,$80,$4b
    .db $a0,$43,$1f,$40,$9e,$02,$5f,$ff
Super_Sonic_STH2_Remix.pattern_0008:
    .db $3f,$40,$ff
Super_Sonic_STH2_Remix.pattern_0009:
    .db $1f,$3e,$1d,$70,$9e,$00,$41,$a0,$41,$1f,$3e,$9e,$00,$41,$a0,$41
    .db $1f,$3e,$9e,$00,$41,$a0,$41,$1f,$3e,$9e,$00,$41,$a0,$41,$1f,$40
    .db $9e,$00,$41,$a0,$41,$1f,$40,$9e,$00,$41,$20,$9e,$00,$41,$1f,$40
    .db $9e,$00,$41,$a0,$41,$1f,$40,$9e,$00,$41,$a0,$41,$1f,$3e,$9e,$00
    .db $41,$a0,$41,$1f,$3e,$9e,$00,$41,$a0,$41,$1f,$3e,$9e,$00,$41,$a0
    .db $41,$1f,$3e,$9e,$00,$41,$a0,$41,$1f,$3c,$9e,$00,$41,$a0,$41,$1f
    .db $3c,$9e,$00,$41,$a0,$41,$1f,$3c,$9e,$00,$41,$a0,$41,$1f,$3c,$9e
    .db $00,$41,$a0,$41,$ff
Super_Sonic_STH2_Remix.pattern_000a:
    .db $1f,$3b,$9e,$00,$45,$a0,$41,$1f,$3b,$9e,$00,$45,$a0,$41,$1f,$39
    .db $9e,$00,$45,$a0,$41,$1f,$39,$9e,$00,$45,$a0,$41,$1f,$3b,$9e,$00
    .db $41,$a0,$41,$1f,$3b,$9e,$00,$41,$a0,$41,$1f,$39,$9e,$00,$43,$1f
    .db $3b,$9e,$00,$41,$a0,$51,$ff
Super_Sonic_STH2_Remix.pattern_000b:
    .db $1f,$3e,$9e,$00,$45,$20,$9e,$00,$41,$1f,$3e,$9e,$00,$45,$a0,$41
    .db $1f,$3c,$9e,$00,$45,$a0,$41,$1f,$3c,$9e,$00,$45,$a0,$41,$1f,$3e
    .db $9e,$00,$41,$a0,$41,$1f,$3e,$9e,$00,$41,$a0,$41,$1f,$3c,$9e,$00
    .db $43,$1f,$3e,$9e,$00,$41,$a0,$51,$ff
Super_Sonic_STH2_Remix.pattern_000c:
    .db $48,$1f,$45,$1d,$70,$9e,$05,$1f,$44,$9e,$05,$1f,$43,$9e,$05,$1f
    .db $42,$9e,$05,$1f,$41,$9e,$05,$1f,$40,$9e,$05,$1f,$3f,$9e,$05,$1f
    .db $3e,$9e,$05,$20,$9e,$05,$47,$1f,$48,$9e,$05,$1f,$47,$9e,$05,$1f
    .db $46,$9e,$05,$1f,$45,$9e,$05,$1f,$44,$9e,$05,$1f,$43,$9e,$05,$1f
    .db $42,$9e,$05,$1f,$41,$9e,$05,$1f,$45,$9e,$05,$1f,$44,$9e,$05,$1f
    .db $43,$9e,$05,$1f,$42,$9e,$05,$1f,$41,$9e,$05,$1f,$40,$9e,$05,$1f
    .db $3f,$9e,$05,$1f,$3e,$9e,$05,$1f,$48,$9e,$05,$1f,$47,$9e,$05,$1f
    .db $46,$9e,$05,$1f,$45,$9e,$05,$1f,$44,$9e,$05,$1f,$43,$9e,$05,$1f
    .db $42,$9e,$05,$1f,$41,$9e,$05,$1f,$4c,$9e,$05,$1f,$4b,$9e,$05,$1f
    .db $4a,$9e,$05,$1f,$49,$9e,$05,$1f,$48,$9e,$05,$1f,$47,$9e,$05,$1f
    .db $46,$9e,$05,$1f,$45,$9e,$05,$1f,$44,$9e,$05,$1f,$43,$9e,$05,$1f
    .db $42,$9e,$05,$1f,$41,$9e,$05,$1f,$40,$9e,$05,$1f,$3f,$9e,$05,$1f
    .db $3e,$9e,$05,$1f,$3d,$9e,$05,$ff
Super_Sonic_STH2_Remix.pattern_000d:
    .db $3f,$40,$ff
Super_Sonic_STH2_Remix.pattern_000e:
    .db $1f,$3b,$1d,$70,$9e,$00,$41,$a0,$41,$1f,$3b,$9e,$00,$41,$a0,$41
    .db $1f,$3b,$9e,$00,$41,$a0,$41,$1f,$3b,$9e,$00,$41,$a0,$41,$1f,$3c
    .db $9e,$00,$41,$a0,$41,$1f,$3c,$9e,$00,$41,$a0,$41,$1f,$3c,$9e,$00
    .db $41,$a0,$41,$1f,$3c,$9e,$00,$41,$a0,$41,$1f,$3b,$9e,$00,$41,$a0
    .db $41,$1f,$3b,$9e,$00,$41,$a0,$41,$1f,$3b,$9e,$00,$41,$a0,$41,$1f
    .db $3b,$9e,$00,$41,$a0,$41,$1f,$39,$9e,$00,$41,$a0,$41,$1f,$39,$9e
    .db $00,$41,$a0,$41,$1f,$39,$9e,$00,$41,$a0,$41,$1f,$39,$9e,$00,$41
    .db $a0,$41,$ff
Super_Sonic_STH2_Remix.pattern_000f:
    .db $1f,$37,$9e,$00,$45,$a0,$41,$1f,$37,$9e,$00,$45,$a0,$41,$1f,$35
    .db $9e,$00,$45,$a0,$41,$1f,$35,$9e,$00,$45,$a0,$41,$1f,$37,$9e,$00
    .db $41,$a0,$41,$1f,$37,$9e,$00,$41,$a0,$41,$1f,$35,$9e,$00,$43,$1f
    .db $37,$9e,$00,$41,$a0,$51,$ff
Super_Sonic_STH2_Remix.pattern_0010:
    .db $1f,$3b,$9e,$00,$45,$a0,$41,$1f,$3b,$9e,$00,$45,$a0,$41,$1f,$39
    .db $9e,$00,$45,$a0,$41,$1f,$39,$9e,$00,$45,$a0,$41,$1f,$3b,$9e,$00
    .db $41,$a0,$41,$1f,$3b,$9e,$00,$41,$a0,$41,$1f,$39,$9e,$00,$43,$1f
    .db $3b,$9e,$00,$41,$a0,$51,$ff
Super_Sonic_STH2_Remix.pattern_0011:
    .db $3f,$40,$ff
Super_Sonic_STH2_Remix.pattern_0012:
    .db $1f,$19,$9e,$01,$44,$a0,$1f,$1a,$9e,$01,$44,$a0,$1f,$1b,$9e,$01
    .db $42,$a0,$1f,$1a,$9e,$01,$44,$a0,$1f,$1b,$9e,$01,$44,$a0,$1f,$1c
    .db $9e,$01,$42,$a0,$1f,$1b,$9e,$01,$44,$a0,$1f,$1c,$9e,$01,$44,$a0
    .db $1f,$1d,$9e,$01,$42,$a0,$1f,$1c,$9e,$01,$44,$a0,$1f,$1d,$9e,$01
    .db $44,$a0,$1f,$1e,$9e,$01,$43,$ff
Super_Sonic_STH2_Remix.pattern_0013:
    .db $1f,$2b,$9e,$01,$41,$a0,$41,$1f,$2b,$9e,$01,$43,$1f,$26,$9e,$01
    .db $41,$a0,$41,$1f,$26,$9e,$01,$43,$1f,$29,$9e,$01,$41,$a0,$41,$1f
    .db $29,$9e,$01,$43,$1f,$28,$9e,$01,$41,$20,$9e,$01,$41,$1f,$28,$9e
    .db $01,$43,$1f,$2b,$9e,$01,$41,$a0,$41,$1f,$2b,$9e,$01,$43,$1f,$26
    .db $9e,$01,$41,$a0,$41,$1f,$26,$9e,$01,$43,$1f,$29,$9e,$01,$41,$a0
    .db $41,$1f,$29,$9e,$01,$43,$1f,$28,$9e,$01,$41,$1f,$29,$9e,$01,$41
    .db $1f,$28,$9e,$01,$43,$ff
Super_Sonic_STH2_Remix.pattern_0014:
    .db $a0,$73,$1f,$22,$9e,$01,$41,$1f,$23,$9e,$01,$41,$1f,$1f,$9e,$01
    .db $43,$1f,$1d,$9e,$01,$43,$ff
Super_Sonic_STH2_Remix.pattern_0015:
    .db $1f,$29,$9e,$01,$47,$1f,$1d,$9e,$01,$47,$1f,$29,$9e,$01,$47,$1f
    .db $1d,$9e,$01,$47,$1f,$29,$9e,$01,$43,$1f,$1d,$9e,$01,$43,$1f,$29
    .db $9e,$01,$43,$1f,$1d,$9e,$01,$43,$1f,$29,$9e,$01,$43,$1f,$1d,$9e
    .db $01,$43,$1f,$29,$9e,$01,$43,$1f,$1d,$9e,$01,$43,$ff
Super_Sonic_STH2_Remix.pattern_0016:
    .db $1f,$2e,$1e,$03,$93,$01,$43,$1f,$28,$9e,$04,$41,$1f,$2e,$9e,$03
    .db $45,$1f,$28,$9e,$04,$43,$1f,$2e,$9e,$03,$43,$1f,$28,$9e,$04,$41
    .db $1f,$2e,$9e,$03,$45,$1f,$28,$9e,$04,$43,$1f,$2e,$9e,$03,$43,$1f
    .db $28,$9e,$04,$41,$1f,$2e,$9e,$03,$45,$1f,$28,$9e,$04,$43,$1f,$2e
    .db $9e,$03,$43,$1f,$28,$9e,$04,$41,$1f,$2e,$9e,$03,$43,$1f,$28,$9e
    .db $04,$41,$1f,$28,$9e,$04,$43,$ff
Super_Sonic_STH2_Remix.pattern_0017:
    .db $1f,$2e,$9e,$03,$43,$1f,$28,$9e,$04,$43,$1f,$2e,$9e,$03,$43,$1f
    .db $28,$9e,$04,$43,$1f,$2e,$9e,$03,$43,$1f,$28,$9e,$04,$43,$1f,$2e
    .db $9e,$03,$43,$1f,$28,$9e,$04,$43,$1f,$2e,$9e,$03,$43,$1f,$28,$9e
    .db $04,$43,$1f,$2e,$9e,$03,$43,$1f,$28,$9e,$04,$43,$1f,$2e,$9e,$03
    .db $43,$1f,$28,$9e,$04,$43,$1f,$2e,$9e,$03,$41,$1f,$28,$9e,$04,$41
    .db $1f,$28,$9e,$04,$43,$ff
