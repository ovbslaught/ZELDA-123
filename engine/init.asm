; engine/init.asm — SNES hardware register init

InitSNES:
    PHB
    LDA #$00
    STA $2100       ; INIDISP — screen off
    STA $420B       ; DMA enable — clear
    STA $420C       ; HDMA enable — clear
    LDA #$80
    STA $2100       ; INIDISP — force blank ON

    ; Set BG mode 1: BG1+BG2 = 4bpp, BG3 = 2bpp
    LDA #$01
    STA $2105       ; BGMODE

    ; BG1 tilemap at VRAM $0000, 32x32
    LDA #$00
    STA $2107       ; BG1SC

    ; BG1 chr data at VRAM $2000
    LDA #$20
    STA $210B       ; BG12NBA

    ; OAM (sprites) base
    LDA #$00
    STA $2101       ; OBSEL — 8x8 and 16x16 sprite sizes, base 0

    PLB
    RTS