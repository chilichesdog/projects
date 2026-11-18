# chip8

A CHIP-8 interpreter written in Mojo, drawing to the terminal. The goal is to
learn how an emulator is put together: a fetch-decode-execute loop, a fixed
memory map, timers, and a frontend kept separate from the machine.

## Layout

| Path | Contents |
| --- | --- |
| `main.mojo` | The interpreter (`Core`), the run loop (`Emulator`), and a terminal frontend |
| `termios.mojo` | A standalone test of terminal raw mode through `tcgetattr`/`tcsetattr`, for keyboard input |
| `IBM Logo.ch8` | A small ROM for a first test |
| `chip8-test-suite/` | Timendus's test ROMs (not tracked; see below) |

`Core` holds only what the CHIP-8 spec defines: 4 KB of memory, the 64x32
display, sixteen `V` registers, `I`, the program counter, the stack, and the two
timers. `Emulator` loads the ROM and runs about 12 instructions per 60 Hz frame,
then ticks the timers and hands the display to the frontend. A frontend is any
type that implements the `Frontable` trait, so a graphical one can replace the
terminal later without touching `Core`.

## Usage

Run from the `projects/` folder, passing the ROM path:

```sh
pixi run mojo chip8/main.mojo "chip8/IBM Logo.ch8"
```

The terminal needs to be at least 128 columns by 32 rows, since each CHIP-8
pixel is drawn two characters wide. Press `Ctrl+C` to quit.

The test suite is not part of this repository. To get it, clone it into this
folder:

```sh
git clone https://github.com/Timendus/chip8-test-suite.git chip8/chip8-test-suite
```

## Limitations

- No keyboard input. `EX9E`, `EXA1`, and `FX0A` do nothing, so games that wait
  for a key will stall or misbehave.
- No sound. The sound timer counts down, but nothing beeps.
- Standard CHIP-8 only. SUPER-CHIP and XO-CHIP opcodes are not implemented.
- Follows Cowgod's reference on ambiguous opcodes: `8XY6` and `8XYE` shift `Vx`
  in place, `FX55` and `FX65` leave `I` unchanged, and `BNNN` jumps relative to
  `V0`. Some older ROMs expect the original COSMAC VIP behavior instead.
- The ROM path is required. Running without one crashes.

## Sources

- [Cowgod's Chip-8 Technical Reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
- [Guide to making a CHIP-8 emulator](https://tobiasvl.github.io/blog/write-a-chip-8-emulator/)
  by Tobias V. Langhoff
- [CHIP-8 test suite](https://github.com/Timendus/chip8-test-suite) by Timendus,
  used for testing

---

_This README was generated with AI (Claude). The code is my own, written using
the references above._
