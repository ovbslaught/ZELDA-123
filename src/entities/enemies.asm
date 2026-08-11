; =============================================================================
; ZELDA-123 | src/entities/enemies.asm
; Enemy AI — Octorok, Moblin, Darknut, Wizzrobe, Patra (Z1)
;            Iron Knuckle, Wyvern (Z2 side-view)
;            Shadow Minion, Chaos Knight (Z3 original)
; Pooled entity system: 8 slots max per room
; =============================================================================

; ---------------------------------------------------------------------------
; CONSTANTS
; ---------------------------------------------------------------------------
MAX_ENEMIES     = 8
ENT_SIZE        = 16        ; bytes per entity slot

; Entity type IDs
ETYPE_NONE      = $00
ETYPE_OCTOROK   = $01
ETYPE_MOBLIN    = $02
ETYPE_DARKNUT   = $03
ETYPE_WIZZROBE  = $04
ETYPE_PATRA     = $05
ETYPE_IRONKNUX  = $06
ETYPE_WYVERN    = $07
ETYPE_SHADOWMIN = $08
ETYPE_CHAOSKNT  = $09

; Entity state IDs
EST_IDLE        = 0
EST_PATROL      = 1
EST_CHASE       = 2
EST_ATTACK      = 3
EST_HURT        = 4
EST_DEAD        = 5

; AI flag bits
EFLAG_FLYING    = %00000001
EFLAG_SHOOTER   = %00000010
EFLAG_ARMORED   = %00000100
EFLAG_BOSS      = %00001000

; ---------------------------------------------------------------------------
; ENTITY POOL — 8 slots x 16 bytes = 128 bytes WRAM
; Layout per slot:
;  +0  Type        +1  State       +2  Flags
;  +3  Dir         +4  HP          +5  MaxHP
;  +6  X lo        +7  X hi
;  +8  Y lo        +9  Y hi
;  +10 VelX(signed)+11 VelY(signed)
;  +12 Timer       +13 AnimFrame   +14 AnimTimer   +15 Scratch
; ---------------------------------------------------------------------------
.segment "BSS"
EnemyPool:      .res MAX_ENEMIES * ENT_SIZE

; Projectile pool: 4 enemy projectiles
PROJ_MAX        = 4
PROJ_SIZE       = 8         ; type, active, X lo/hi, Y lo/hi, dir, timer
ProjPool:       .res PROJ_MAX * PROJ_SIZE

; Scratch
ENT_TmpIdx:     .res 1      ; current entity index during update loop
ENT_TmpPtr:     .res 2      ; pointer to current entity slot

; ---------------------------------------------------------------------------
; MACROS
; ---------------------------------------------------------------------------
; ENT_FIELD base, field_offset — compute address of field in current slot
.macro ENT_ADDR base, offset
    .local addr
    addr = base + (ENT_TmpIdx * ENT_SIZE) + offset
.endmacro

; ---------------------------------------------------------------------------
; Enemies_ClearPool — zero all entity slots
; ---------------------------------------------------------------------------
.segment "CODE"
Enemies_ClearPool:
    REP #$20
    LDX #$00
@loop:
    STZ EnemyPool, X
    INX
    INX
    CPX #(MAX_ENEMIES * ENT_SIZE)
    BCC @loop
    SEP #$20
    RTS

; ---------------------------------------------------------------------------
; Enemies_SpawnAt — spawn enemy type A at (X=x, Y=y passed in WRAM scratch)
; Inputs: A=type, ENT_SpawnX/Y set before call
; ---------------------------------------------------------------------------
.segment "BSS"
ENT_SpawnX:     .res 2
ENT_SpawnY:     .res 2
ENT_SpawnType:  .res 1

.segment "CODE"
Enemies_SpawnAt:
    STA ENT_SpawnType
    ; find free slot (type == ETYPE_NONE)
    LDX #$00
@findSlot:
    LDA EnemyPool, X        ; type byte
    CMP #ETYPE_NONE
    BEQ @foundSlot
    TXA
    CLC
    ADC #ENT_SIZE
    TAX
    CPX #(MAX_ENEMIES * ENT_SIZE)
    BCC @findSlot
    RTS                     ; pool full, drop spawn
@foundSlot:
    STX ENT_TmpPtr          ; save slot base
    LDA ENT_SpawnType
    STA EnemyPool+0, X      ; type
    LDA #EST_PATROL
    STA EnemyPool+1, X      ; state
    ; set flags by type
    JSR ENT_SetDefaultFlags
    LDA #$00
    STA EnemyPool+3, X      ; dir=down
    ; HP by type
    JSR ENT_SetDefaultHP
    ; position
    REP #$20
    LDA ENT_SpawnX
    STA EnemyPool+6, X
    LDA ENT_SpawnY
    STA EnemyPool+8, X
    SEP #$20
    STZ EnemyPool+12, X     ; timer=0
    STZ EnemyPool+13, X     ; anim=0
    STZ EnemyPool+14, X
    STZ EnemyP