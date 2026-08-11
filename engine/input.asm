; engine/input.asm
; Reads controller 1 into RAM word $10

.segment "ZEROPAGE"
JoyNew: .res 2
JoyOld: .res 2

PollInput:
    REP #$20
    LDA JoyNew
    STA JoyOld
    LDA $4218       ; auto-joypad read port 1
    STA JoyNew
    RTS