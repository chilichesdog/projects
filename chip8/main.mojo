from std.memory import Layout
from std.time import sleep
from std.sys import argv
from std.os import *

comptime FONT: Array[UInt8, 80] = [
    # fmt: off
    0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
    0x20, 0x60, 0x20, 0x20, 0x70, # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
    0x90, 0x90, 0xF0, 0x10, 0x10, # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
    0xF0, 0x10, 0x20, 0x40, 0x40, # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
    0xF0, 0x80, 0x80, 0x80, 0xF0, # C
    0xE0, 0x90, 0x90, 0x90, 0xE0, # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
    0xF0, 0x80, 0xF0, 0x80, 0x80  # F
]
# fmt: on

comptime FNT_MEM_ADR = 0x050
comptime PRGM_MEM_START = 0x200


# memory: CHIP-8 has direct access to up to 4 kilobytes of RAM
# display: 64 x 32 pixels (or 128 x 64 for SUPER-CHIP) monochrome, ie. black or white
# i: One 16-bit index register called “I” which is used to point at locations in memory
# pc: A program counter, often called just “PC”, which points at the current instruction in memory
# stack: A stack for 16-bit addresses, which is used to call subroutines/functions and return from them
# timer_delay: An 8-bit delay timer which is decremented at a rate of 60 Hz (60 times per second) until it reaches 0
# timer_sound: An 8-bit sound timer which functions like the delay timer, but which also gives off a beeping sound as long as it’s not 0
# v: 16 8-bit (one byte) general-purpose variable registers numbered 0 through F hexadecimal, ie. 0 through 15 in decimal, called V0 through VF
#     VF is also used as a flag register; many instructions will set it to either 1 or 0 based on some rule, for example using it as a carry flag


struct Core[version: CHIP8Model = CHIP8Model.STANDARD]:
    """
    The CHIP-8 virtual machine. Only what is defined in the spec belongs here.
    """

    var memory: Array[UInt8, 4096]
    var display: Array[Array[Bool, 64], 32]
    var i: UInt16
    var pc: UInt16
    var stack: Array[UInt16, 16]
    # pointer is a misnomer here; it's just an index
    var stack_ptr: Int
    var timer_delay: UInt8
    var timer_sound: UInt8
    var v: Array[UInt8, 16]
    var keys: Array[Bool, 16]

    def __init__(out self):
        self.memory = Array[UInt8, 4096]()
        self.display = Array[Array[Bool, 64], 32]()
        self.i = 0
        self.pc = UInt16(PRGM_MEM_START)
        self.stack = Array[UInt16, 16]()
        self.stack_ptr = 0
        self.timer_delay = 0
        self.timer_sound = 0
        self.v = Array[UInt8, 16]()
        self.keys = Array[Bool, 16]()
        self.load_font()

    def load_font(mut self):
        var font = materialize[FONT]()
        for ind, f in enumerate(font):
            self.memory[FNT_MEM_ADR + ind] = f

    def load_rom(mut self, bytes: List[UInt8]) raises:
        if bytes.byte_length() > len(self.memory) - PRGM_MEM_START:
            raise "Error: ROM too large."
        elif bytes.byte_length() == 0:
            raise "Error: empty ROM."
        # if you later add a feature to load a new rom, you'll need to clear program memory first and raise an error if there are still leftover bytes
        for ind, byte in enumerate(bytes):
            self.memory[PRGM_MEM_START + ind] = byte

    @always_inline
    def tick_timers(mut self):
        if self.timer_delay != 0:
            self.timer_delay -= 1
        if self.timer_sound != 0:
            self.timer_sound -= 1

    @always_inline
    def step(mut self):
        var code = self.fetch()
        self.execute(code)

    @always_inline
    def fetch(mut self) -> UInt16:
        var code = UInt16(self.memory[self.pc]) << 8 | UInt16(
            self.memory[self.pc + 1]
        )
        self.pc += 2
        return code

    def execute(mut self, code: UInt16):
        # format: xyn
        var first = (code >> 12) & 0xF
        var x = (code >> 8) & 0xF
        var y = (code >> 4) & 0xF
        var kk = code & 0xFF
        var n = code & 0xF
        var nnn = code & 0xFFF
        match first:
            case 0x0:
                match kk:
                    case 0xE0:
                        # 00E0: Clear the display.
                        self.display = Array[Array[Bool, 64], 32]()
                    case 0xEE:
                        # 00EE
                        pass
                    case _:
                        # 0NNN
                        pass
            case 0x1:
                # 1NNN: Jump to location nnn.
                self.pc = nnn
            case 0x2:
                # 2NNN
                pass
            case 0x3:
                # 3XKK
                pass
            case 0x4:
                # 4XKK
                pass
            case 0x5:
                # 5XY0
                pass
            case 0x6:
                # 6XKK: puts the value kk into register Vx.
                self.v[x] = UInt8(kk)
            case 0x7:
                # 7XKK: Set Vx = Vx + kk.
                self.v[x] += UInt8(kk)
            case 0x8:
                match n:
                    case 0x0:
                        # 8XY0
                        pass
                    case 0x1:
                        # 8XY1
                        pass
                    case 0x2:
                        # 8XY2
                        pass
                    case 0x3:
                        # 8XY3
                        pass
                    case 0x4:
                        # 8XY4
                        pass
                    case 0x5:
                        # 8XY5
                        pass
                    case 0x6:
                        # 8XY6
                        pass
                    case 0x7:
                        # 8XY7
                        pass
                    case 0xE:
                        # 8XYE
                        pass
            case 0x9:
                # 9XY0
                pass
            case 0xA:
                # ANNN: Set I = nnn.
                self.i = nnn
            case 0xB:
                # BNNN
                pass
            case 0xC:
                # CXKK
                pass
            case 0xD:
                # DXYN: Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision. (more in manual)

                var px = self.v[x] % 64
                var x_w = px
                var py = self.v[y] % 32
                self.v[0xF] = 0
                for row in range(n):
                    var sprite_data = self.memory[self.i + row]
                    px = x_w

                    for a in range(8):
                        if px == 64:
                            break
                        var bit = sprite_data >> UInt8(7 - a) & 1
                        if bit:
                            if self.display[py][px]:
                                self.v[0xF] = 1
                            self.display[py][px] = not self.display[py][px]
                        px += 1
                    py += 1
                    if py == 32:
                        break

            case 0xE:
                match kk:
                    # EX9E
                    case 0x9E:
                        pass
                    # EXA1
                    case 0xA1:
                        pass
            case 0xF:
                match kk:
                    # FX07
                    case 0x07:
                        pass
                    # FX0A
                    case 0x0A:
                        pass
                    # FX15
                    case 0x15:
                        pass
                    # FX18
                    case 0x18:
                        pass
                    # FX1E
                    case 0x1E:
                        pass
                    # FX29
                    case 0x29:
                        pass
                    # FX33
                    case 0x33:
                        pass
                    # FX55
                    case 0x55:
                        pass
                    # FX65
                    case 0x65:
                        pass


@fieldwise_init
struct CHIP8Model(Equatable):
    var _value: Int
    comptime STANDARD = CHIP8Model(0)
    comptime SUPER = CHIP8Model(1)
    comptime XO = CHIP8Model(2)
    comptime MEGA = CHIP8Model(3)


trait Frontable:
    ...


struct Emulator[]:
    var CHIP8: Core[]
    var rom: List[UInt8]
    var args: Span[StringSpan[ImmStaticOrigin], ImmStaticOrigin]

    def __init__(out self) raises:
        self.CHIP8 = Core[]()
        self.args = argv()
        self.rom = List[UInt8]()
        self.get_rom()
        self.CHIP8.load_rom(self.rom)

    def get_rom(mut self) raises:
        var path = self.args[1]
        var file = FileHandle(path, "r")
        var size = file.seek(0, SEEK_END)
        _ = file.seek(0, SEEK_SET)

        var ptr: Pointer[UInt8, MutUntrackedOrigin] = alloc(
            Layout[UInt8](count=Int(size))
        ).unsafe_leak()
        var buffer = Span[UInt8, MutUntrackedOrigin](
            unsafe_ptr=ptr, length=Int(size)
        )
        _ = file.read(buffer)

        var bytes = List[UInt8]()
        for i in range(size):
            bytes.append(ptr[unsafe_offset=i])

        print(t"Path: {path}\nSize:{size}\nContents: {bytes}")
        self.rom = bytes^

    def present(mut self) raises:
        var screen: String
        print("\x1b[2J")
        while True:
            self.CHIP8.step()
            screen = "\x1b[H"

            for y in range(32):
                for x in range(64):
                    if self.CHIP8.display[y][x]:
                        screen += "██"
                    else:
                        screen += "  "
                screen += "\n"
            print(screen, end="", flush=True)
            sleep(1.0 / 60.0)


struct Frontend(Frontable):
    ...


def main() raises:
    var emu = Emulator()
    emu.present()
