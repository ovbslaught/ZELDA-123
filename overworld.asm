; =============================================================================
; ZELDA-123 | src/world/overworld.asm
; Zelda 1 Overworld Engine — screen-by-screen scrolling, room ID system
; =============================================================================

; ---------------------------------------------------------------------------
; OVERWORLD CONSTANTS
; ---------------------------------------------------------------------------
OW_WIDTH        = 16        ; rooms wide
OW_HEIGHT       = 8         ; rooms tall
OW_TOTAL        = 128       ; 16x8 room grid
SCREEN_W        = 256       ; pixels
SCREEN_H        = 176       ; pixels (LTTP-style play area)
TILE_SIZE       = 16        ; 16x16 tiles (SNES LTTP scale)

; ---------------------------------------------------------------------------
; WRAM — Overworld State
; ---------------------------------------------------------------------------
.segment "BSS"
OW_RoomID:      .res 1      ; current room index (0-127)
OW_ScrollX:     .res 2      ; scroll pixel X (0-255 per screen)
OW_ScrollY:     .res 2      ; scroll pixel Y (0-175 per screen)
OW_TransDir:    .res 1      ; transition direction: 0=N 1=S 2=W 3=E
OW_TransTimer:  .res 1      ; scroll transition frame counter
OW_Flags:       .res 1      ; bit0=in_transition, bit1=dungeon_entrance

; ---------------------------------------------------------------------------
; ZEROPAGE — hot pointers
; ---------------------------------------------------------------------------
.segment "ZEROPAGE"
OW_MapPtr:      .res 2      ; pointer to current room tile data

; ---------------------------------------------------------------------------
; ROOM TRANSITION TABLE (direction → room offset)
; ---------------------------------------------------------------------------
.segment "RODATA"
TransOffsetTbl:
    .byte <-OW_WIDTH    ; North = -16
    .byte OW_WIDTH      ; South = +16
    .byte $FF           ; West  = -1
    .byte $01           ; East  = +1

; ---------------------------------------------------------------------------
; OW_Init — load overworld, set start room
; ---------------------------------------------------------------------------
.segment "CODE"
OW_Init:
    LDA #$00
    STA OW_RoomID
    STA OW_ScrollX
    STA OW_ScrollX+1
    STA OW_ScrollY
    STA OW_ScrollY+1
    STA OW_TransTimer
    STA OW_Flags
    JSR OW_LoadRoom
    RTS

; ---------------------------------------------------------------------------
; OW_LoadRoom — point MapPtr at room data, queue DMA to BG1
; ---------------------------------------------------------------------------
OW_LoadRoom:
    REP #$20
    LDA OW_RoomID
    ASL A               ; room * 2 (word index into room ptr table)
    TAX
    LDA RoomPtrTable, X
    STA OW_MapPtr
    SEP #$20
    JSR OW_DMARoom      ; push tile data to VRAM BG1
    RTS

; ---------------------------------------------------------------------------
; OW_Update — called each frame from MainLoop
; ---------------------------------------------------------------------------
OW_Update:
    LDA OW_Flags
    AND #$01
    BNE OW_DoTransition     ; mid-transition: keep scrolling
    JSR OW_CheckEdge        ; check if Link hit screen edge
    RTS

; ---------------------------------------------------------------------------
; OW_CheckEdge — read Link position, trigger transition if at border
; ---------------------------------------------------------------------------
OW_CheckEdge:
    ; stub — Link pos check wired in after link.asm
    ; sets OW_TransDir and OW_Flags bit0 when triggered
    RTS

; ---------------------------------------------------------------------------
; OW_DoTransition — slide-scroll to next screen (16px/frame)
; ---------------------------------------------------------------------------
OW_DoTransition:
    LDA OW_TransTimer
    CMP #$10            ; 16 frames = 256px / 16px per frame
    BEQ OW_TransitionDone
    INC OW_TransTimer

    ; shift BG scroll registers by 16px toward new room
    LDA OW_TransDir
    CMP #$02            ; West
    BEQ @scrollLeft
    CMP #$03            ; East
    BEQ @scrollRight
    CMP #$00            ; North
    BEQ @scrollUp
    ; else South
@scrollDown:
    REP #$20
    LDA OW_ScrollY
    CLC
    ADC #$10
    STA OW_ScrollY
    SEP #$20
    BRA @done
@scrollUp:
    REP #$20
    LDA OW_ScrollY
    SEC
    SBC #$10
    STA OW_ScrollY
    SEP #$20
    BRA @done
@scrollRight:
    REP #$20
    LDA OW_ScrollX
    CLC
    ADC #$10
    STA OW_ScrollX
    SEP #$20
    BRA @done
@scrollLeft:
    REP #$20
    LDA OW_ScrollX
    SEC
    SBC #$10
    STA OW_ScrollX
    SEP #$20
@done:
    JSR OW_SetScrollRegs
    RTS

OW_TransitionDone:
    ; finalize — update room ID, reset timer/flags
    LDA OW_TransDir
    TAX
    LDA TransOffsetTbl, X
    CLC
    ADC OW_RoomID
    STA OW_RoomID
    LDA #$00
    STA OW_TransTimer
    STA OW_Flags
    JSR OW_LoadRoom
    RTS

; ---------------------------------------------------------------------------
; OW_SetScrollRegs — push OW_ScrollX/Y to PPU BG1 scroll ($210D/$210E)
; ---------------------------------------------------------------------------
OW_SetScrollRegs:
    SEP #$20
    LDA OW_ScrollX
    STA $210D           ; BG1HOFS low
    LDA OW_ScrollX+1
    STA $210D           ; BG1HOFS high
    LDA OW_ScrollY
    STA $210E           ; BG1VOFS low
    LDA OW_ScrollY+1
    STA $210E           ; BG1VOFS high
    RTS

; ---------------------------------------------------------------------------
; OW_DMARoom — DMA room tile data to VRAM BG1 tilemap
; -------------------------------------------------------------------------