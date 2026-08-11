; =============================================================================
; ZELDA-123 | src/entities/link.asm
; Link — state machine, 8-directional movement, sword attack
; =============================================================================

; ---------------------------------------------------------------------------
; LINK CONSTANTS
; ---------------------------------------------------------------------------
LINK_SPEED      = 2         ; pixels per frame
LINK_SWORD_TIME = 12        ; sword swing duration frames

; Link state IDs
STATE_IDLE      = 0
STATE_WALK      = 1
STATE_SWORD     = 2
STATE_HURT      = 3
STATE_DEAD      = 4

; Facing direction IDs (matches OW transition dirs)
DIR_UP          = 0
DIR_DOWN        = 1
DIR_LEFT        = 2
DIR_RIGHT       = 3

; ---------------------------------------------------------------------------
; WRAM — Link State
; ---------------------------------------------------------------------------
.segment "BSS"
Link_X:         .res 2      ; world pixel X
Link_Y:         .res 2      ; world pixel Y
Link_State:     .res 1
Link_Dir:       .res 1
Link_HP:        .res 1      ; current hearts (half-hearts)
Link_MaxHP:     .res 1
Link_SwordTimer:.res 1
Link_HurtTimer: .res 1
Link_InvTimer:  .res 1      ; invincibility frames after hit
Link_AnimFrame: .res 1
Link_AnimTimer: .res 1

; ---------------------------------------------------------------------------
; Link_Init
; ---------------------------------------------------------------------------
.segment "CODE"
Link_Init:
    REP #$20
    LDA #$0080          ; start X = 128
    STA Link_X
    LDA #$0070          ; start Y = 112
    STA Link_Y
    SEP #$20
    LDA #STATE_IDLE
    STA Link_State
    LDA #DIR_DOWN
    STA Link_Dir
    LDA #$06
    STA Link_HP
    STA Link_MaxHP
    STZ Link_SwordTimer
    STZ Link_HurtTimer
    STZ Link_InvTimer
    STZ Link_AnimFrame
    STZ Link_AnimTimer
    RTS

; ---------------------------------------------------------------------------
; Link_Update — called each frame
; ---------------------------------------------------------------------------
Link_Update:
    LDA Link_State
    CMP #STATE_DEAD
    BEQ @skip
    JSR Link_StateMachine
    JSR Link_ClampToScreen
    JSR Link_UpdateSprite
@skip:
    RTS

; ---------------------------------------------------------------------------
; Link_StateMachine
; ---------------------------------------------------------------------------
Link_StateMachine:
    LDA Link_State
    CMP #STATE_SWORD
    BEQ @doSword
    CMP #STATE_HURT
    BEQ @doHurt

    ; --- IDLE / WALK: read input ---
    JSR Link_ReadMovement
    ; check sword button (B = attack)
    LDA JoyPress
    AND #<BTN_B
    BEQ @done
    ; trigger sword
    LDA #STATE_SWORD
    STA Link_State
    LDA #LINK_SWORD_TIME
    STA Link_SwordTimer
    BRA @done

@doSword:
    DEC Link_SwordTimer
    BNE @done
    LDA #STATE_IDLE
    STA Link_State
    BRA @done

@doHurt:
    DEC Link_HurtTimer
    BNE @done
    LDA #STATE_IDLE
    STA Link_State

@done:
    ; decrement invincibility timer
    LDA Link_InvTimer
    BEQ @exit
    DEC Link_InvTimer
@exit:
    RTS

; ---------------------------------------------------------------------------
; Link_ReadMovement — 8-directional movement from d-pad
; ---------------------------------------------------------------------------
Link_ReadMovement:
    LDA #STATE_IDLE
    STA Link_State          ; assume idle unless input found

    REP #$20
    LDA JoyNew

    ; Check UP
    BIT #BTN_UP
    BEQ @notUp
    LDA Link_Y
    SEC
    SBC #LINK_SPEED
    STA Link_Y
    SEP #$20
    LDA #DIR_UP
    STA Link_Dir
    LDA #STATE_WALK
    STA Link_State
    REP #$20
@notUp:
    ; Check DOWN
    BIT #BTN_DOWN
    BEQ @notDown
    LDA Link_Y
    CLC
    ADC #LINK_SPEED
    STA Link_Y
    SEP #$20
    LDA #DIR_DOWN
    STA Link_Dir
    LDA #STATE_WALK
    STA Link_State
    REP #$20
@notDown:
    ; Check LEFT
    BIT #BTN_LEFT
    BEQ @notLeft
    LDA Link_X
    SEC
    SBC #LINK_SPEED
    STA Link_X
    SEP #$20
    LDA #DIR_LEFT
    STA Link_Dir
    LDA #STATE_WALK
    STA Link_State
    REP #$20
@notLeft:
    ; Check RIGHT
    BIT #BTN_RIGHT
    BEQ @notRight
    LDA Link_X
    CLC
    ADC #LINK_SPEED
    STA Link_X
    SEP #$20
    LDA #DIR_RIGHT
    STA Link_Dir
    LDA #STATE_WALK
    STA Link_State
    REP #$20
@notRight:
    SEP #$20
    RTS

; ---------------------------------------------------------------------------
; Link_ClampToScreen — keep Link inside 256x176 play area
; ---------------------------------------------------------------------------
Link_ClampToScreen:
    REP #$20
    ; clamp X: 0..240
    LDA Link_X
    BMI @clampXlo
    CMP #$00F0
    BCC @xOK
    LDA #$00F0
    STA Link_X
    BRA @xOK
@clampXlo:
    STZ Link_X
@xOK:
    ; clamp Y: 0..160
    LDA Link_Y
    BMI @clampYlo
    CMP #$00A0
    BCC @yOK
    LDA #$00A0
    STA Link_Y
    BRA @yOK
@clampYlo:
    STZ Link_Y
@yOK:
    SEP #$20
    RTS

; ---------------------------------------------------------------------------
; Link_UpdateSprite — write Link OAM entry (tile, pos, palette)
; ---------------------------------------------------------------------------
Link_UpdateSprite:
    ; Sprite tile base per direction (4 tiles per dir in LTTP CHR layout)
    ; Dir: UP=0, DOWN=1, LEFT=2, RIGHT=3
    ; State: IDLE=base, WALK=base+1 or +2 (animated), SWORD=base+4
    REP #$20
    LDA Link_X
    STA $0200           ; OAM shadow X low
    LDA Link_Y
    STA $0201           ; OAM shadow Y
    SEP #$20
    ; tile selection stub — full anim table after CHR layout confirmed
    LDA #$00
    STA $0202           ; tile index
    LDA #$31            ; palette 1, priority 3, no flip
    STA $0203           ; attributes
    RTS