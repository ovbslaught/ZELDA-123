; =============================================================================
; ZELDA-123 | src/world/z2_sidescroll.asm
; Zelda 2 Side-Scroll Mode — platformer physics, sword + magic
; =============================================================================

Z2_GRAVITY      = 1         ; pixels/frame² downward acceleration
Z2_JUMP_VEL     = $F8       ; initial upward velocity (signed, -8)
Z2_WALK_SPD     = 2
Z2_SCROLL_SPD   = 2

SPELL_SHIELD    = 0
SPELL_JUMP      = 1
SPELL_LIFE      = 2
SPELL_FAIRY     = 3
SPELL_FIRE      = 4
SPELL_REFLECT   = 5
SPELL_SPELL     = 6
SPELL_THUNDER   = 7

.segment "BSS"
Z2_Active:      .res 1      ; 1 = in side-scroll mode
Z2_LinkVelY:    .res 1      ; signed vertical velocity
Z2_OnGround:    .res 1      ; 1 = grounded
Z2_ScrollX:     .res 2      ; horizontal scroll position
Z2_ActiveSpell: .res 1
Z2_MP:          .res 1      ; magic points (0-127)
Z2_MaxMP:       .res 1

.segment "CODE"

Z2_Init:
    LDA #$01
    STA Z2_Active
    STZ Z2_LinkVelY
    STZ Z2_OnGround
    STZ Z2_ScrollX
    STZ Z2_ScrollX+1
    LDA #$60
    STA Z2_MaxMP
    STA Z2_MP
    ; reconfigure PPU for side-scroll
    ; BG1 = background, BG2 = foreground layer, OBJ = sprites
    JSR Z2_SetupPPU
    RTS

Z2_SetupPPU:
    LDA #$01
    STA $2105           ; BGMODE 1
    LDA #$15
    STA $212C           ; TM: BG1 + BG2 + OBJ
    RTS

Z2_Update:
    JSR Z2_Physics
    JSR Z2_ReadInput
    JSR Z2_ScrollUpdate
    JSR Z2_UpdateSprite
    RTS

Z2_Physics:
    ; apply gravity if airborne
    LDA Z2_OnGround
    BNE @skip
    LDA Z2_LinkVelY
    CLC
    ADC #Z2_GRAVITY
    STA Z2_LinkVelY
    ; apply to Y position
    REP #$20
    LDA Link_Y
    CLC
    ADC Z2_LinkVelY     ; signed add (gravity pulls down)
    STA Link_Y
    SEP #$20
@skip:
    ; ground collision stub (floor check against BG2 tile)
    RTS

Z2_ReadInput:
    ; UP = jump (if grounded)
    LDA JoyPress
    AND #<BTN_UP
    BEQ @notJump
    LDA Z2_OnGround
    BEQ @notJump
    LDA #Z2_JUMP_VEL
    STA Z2_LinkVelY
    LDA #$00
    STA Z2_OnGround
@notJump:
    ; LEFT/RIGHT walk + scroll
    LDA JoyNew
    BIT #BTN_LEFT
    BEQ @notLeft
    REP #$20
    LDA Link_X
    SEC
    SBC #Z2_WALK_SPD
    STA Link_X
    SEP #$20
    LDA #DIR_LEFT
    STA Link_Dir
@notLeft:
    LDA JoyNew
    BIT #BTN_RIGHT
    BEQ @notRight
    REP #$20
    LDA Link_X
    CLC
    ADC #Z2_WALK_SPD
    STA Link_X
    SEP #$20
    LDA #DIR_RIGHT
    STA Link_Dir
@notRight:
    ; DOWN = duck / use downward stab
    ; A = cast active spell
    RTS

Z2_ScrollUpdate:
    ; scroll BG when Link_X > 128 (right half of screen)
    REP #$20
    LDA Link_X
    CMP #$0080
    BCC @noScroll
    LDA Z2_ScrollX
    CLC
    ADC #Z2_SCROLL_SPD
    STA Z2_ScrollX
    LDA Z2_ScrollX
    STA $210D           ; BG1HOFS
@noScroll:
    SEP #$20
    RTS

Z2_UpdateSprite:
    ; mirror link.asm OAM update with side-view tile offsets
    ; stub — tile table added after CHR confirmed
    RTS