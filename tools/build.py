# tools/build.py — ZELDA 1-2-3 build orchestrator

import subprocess, os, sys

SRC = "src/main.asm"
OUT = "zelda123.smc"
HEADER = bytearray(512)  # 512-byte SMC header (blank = no header needed for higan)

def assemble():
    result = subprocess.run(
        ["ca65", SRC, "-o", "build/main.o", "--cpu", "65816"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(result.stderr); sys.exit(1)

def link():
    subprocess.run([
        "ld65", "-C", "linker.cfg",
        "build/main.o", "-o", OUT
    ], check=True)

def convert_gfx():
    import gfx_convert
    gfx_convert.convert_all("assets/gfx/", "src/data/gfx/")

if __name__ == "__main__":
    os.makedirs("build", exist_ok=True)
    convert_gfx()
    assemble()
    link()
    print(f"[ZELDA-123] Build complete → {OUT}")