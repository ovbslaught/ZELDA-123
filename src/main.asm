; zelda123/src/main.asm
; ZELDA 1-2-3 | SNES 65816 | AI-AUTHORED

.setcpu "65816"
.include "engine/init.asm"
.include "engine/nmi.asm"
.include "engine/dma.asm"
.include "engine/ppu.asm"
.include "engine/input.asm"
.include "world/overworld.asm"
.include "entities/link.asm"

.segment "VECTORS"
    .word NMIHandler        ; NMI
    .word $0000             ; unused
    .word ResetHandler      ; RESET

.segment "CODE"
ResetHandler:
    SEI                     ; disable IRQ
    CLC
    XCE                     ; switch to native 65816 mode
    REP #$30                ; 16-bit A, X, Y
    LDX #$1FFF
    TXS                     ; set stack pointer
    JSR InitSNES
    JSR LoadTitleScreen
MainLoop:
    WAI                     ; wait for NMI (VBlank)
    JSR PollInput
    JSR UpdateEntities
    JSR UpdateWorld
    JMP MainLoop