; =============================================================================
; ZELDA-123 | src/world/z3_new.asm
; PART 3 — Original New World (LTTP-style top-down, new dungeons)
; Triforce assembled: Wisdom + Power + Courage
; =============================================================================

Z3_WORLD_W      = 16
Z3_WORLD_H      = 16        ; 16x16 = 256 rooms (larger than Z1)
Z3_DUNGEON_COUNT = 4        ; 4 new dungeons

; World zones
ZONE_LIGHT      = 0         ; familiar Hyrule remnants
ZONE_SHADOW     = 1         ; dark mirror world (Z3 original)
ZONE_SKY        = 2         ; floating islands
ZONE_ABYSS      = 3         ; final approach / Ganon's lair

.segment "BSS"
Z3_Active:      .res 1
Z3_Zone:        .res 1      ; current zone (0-3)
Z3_RoomID:      .res 2      ; 16-bit (256 rooms)
Z3_WorldFlags:  .res 32     ; 256 bits = 1 per room (visited/cleared)
Z3_BossDefeated:.res 1      ; bitmask: bit0-3 = dungeons 0-3 cleared
Z3_TriforceHeld:.res 1      ; bitmask: bit0=Wisdom, bit1=Power, bit2=Courage

.segment "ZEROPAGE"
Z3_RoomPtr:     .res 2

.segment "CODE"

Z3_Init:
    LDA #$01
    STA Z3_Active
    LDA #ZONE_LIGHT
    STA Z3_Zone
    REP #$20
    LDA #$0000
    STA Z3_RoomID
    SEP #$20
    STZ Z3_BossDefeated
    STZ Z3_TriforceHeld
    JSR Z3_LoadRoom
    RTS

Z3_LoadRoom:
    REP #$20
    LDA Z3_RoomID
    ASL A
    TAX
    LDA Z3_RoomPtrTable, X
    STA Z3_RoomPtr
    SEP #$20
    ; mark visited in WorldFlags bitfield
    JSR Z3_SetVisited
    JSR Z3_DMARoom
    ; check for zone-specific palette
    JSR Z3_LoadZonePalette
    RTS

Z3_Update:
    JSR Z3_CheckEdge
    JSR Z3_CheckEvents
    RTS

Z3_CheckEdge:
    ; same logic as OW_CheckEdge, 16x16 grid wrapping
    RTS

Z3_CheckEvents:
    ; trigger zone transitions, boss rooms, triforce pickups
    RTS

Z3_SetVisited:
    ; set bit in Z3_WorldFlags for current RoomID
    REP #$20
    LDA Z3_RoomID
    LSR A               ; byte index = RoomID / 8
    TAX
    SEP #$20
    LDA Z3_RoomID
    AND #$07            ; bit index = RoomID mod 8
    TAY
    LDA #$01
@shift:
    CPY #$00
    BEQ @done
    ASL A
    DEY
    BRA @shift
@done:
    ORA Z3_WorldFlags, X
    STA Z3_WorldFlags, X
    RTS

Z3_LoadZonePalette:
    ; select BG palette set based on Z3_Zone
    ; stub — palette data in data/palettes/
    RTS

Z3_DMARoom:
    RTS

; Triforce completion check — called after each dungeon clear
Z3_CheckTriforce:
    LDA Z3_TriforceHeld
    CMP #$07            ; all 3 pieces: bits 0+1+2
    BNE @notYet
    ; trigger ending sequence
    JSR Z3_TriggerEnding
@notYet:
    RTS

Z3_TriggerEnding:
    ; fade out, show triforce assembled, roll credits
    ; stub
    RTS

; 256-entry room pointer table stub
.segment "RODATA"
Z3_RoomPtrTable:
    .repeat 256
        .word $0000
    .endrepeat