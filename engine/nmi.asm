; engine/nmi.asm — VBlank interrupt

NMIHandler:
    REP #$30
    PHA : PHX : PHY
    JSR DMAFlush        ; push shadow VRAM to actual VRAM
    JSR UpdateOAM       ; push sprite table
    PLA : PLX : PLY
    RTI