; =============================================================================
; ZELDA-123 | src/world/dungeon.asm
; Dungeon Engine — room grid, door states, transitions
; =============================================================================

DNG_ROOMS_MAX   = 64
DOOR_N          = 0
DOOR_S          = 1
DOOR_W          = 2
DOOR_E          = 3

; Door type IDs
DTYPE_OPEN      = 0
DTYPE_WALL      = 1
DTYPE_LOCKED    = 2
DTYPE_BOSS      = 3
DTYPE_BOMBABLE  = 4

.segment "BSS"
DNG_RoomID:     .res 1
DNG_PrevRoom:   .res 1
DNG_DoorStates: .res 256    ; 4 doors * 64 rooms = 256 bytes
DNG_RoomFlags:  .res 64     ; bit0=visited, bit1=cleared, bit2=has_chest
DNG_TransDir:   .res 1
DNG_TransTimer: .res 1
DNG_Active:     .res 1      ; 1 = in dungeon mode, 0 = overworld

.segment "ZEROPAGE"
DNG_RoomPtr:    .res 2

.segment "CODE"

DNG_Init:
    LDA #$01
    STA DNG_Active
    LDA #$00
    STA DNG_RoomID
    STA DNG_TransTimer
    JSR DNG_LoadRoom
    RTS

DNG_LoadRoom:
    ; mark visited
    LDA DNG_RoomID
    TAX
    LDA DNG_RoomFlags, X
    ORA #$01
    STA DNG_RoomFlags, X
    ; load tile data (DMA stub)
    JSR DNG_DMARoom
    RTS

DNG_Update:
    LDA DNG_TransTimer
    BNE DNG_DoTransition
    JSR DNG_CheckDoorContact
    RTS

DNG_CheckDoorContact:
    ; compare Link_X/Y against door threshold per direction
    ; stub — wired to link.asm after positions confirmed
    RTS

DNG_DoTransition:
    DEC DNG_TransTimer
    BNE @scrolling
    ; transition complete
    LDA DNG_TransDir
    CMP #DOOR_N
    BEQ @goNorth
    CMP #DOOR_S
    BEQ @goSouth
    CMP #DOOR_W
    BEQ @goWest
    ; else East
    LDA DNG_RoomID
    CLC
    ADC #$01
    STA DNG_RoomID
    BRA @done
@goNorth:
    LDA DNG_RoomID
    SEC
    SBC #$08            ; dungeon row width = 8
    STA DNG_RoomID
    BRA @done
@goSouth:
    LDA DNG_RoomID
    CLC
    ADC #$08
    STA DNG_RoomID
    BRA @done
@goWest:
    LDA DNG_RoomID
    SEC
    SBC #$01
    STA DNG_RoomID
@done:
    JSR DNG_LoadRoom
    RTS
@scrolling:
    RTS

DNG_TriggerDoor:
    ; called by OW_CheckEdge equivalent for dungeons
    ; X = door direction (0-3)
    LDA #$10            ; 16-frame transition
    STA DNG_TransTimer
    TXA
    STA DNG_TransDir
    RTS

DNG_DMARoom:
    RTS