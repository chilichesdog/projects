from std.memory import Layout

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
        self.pc = UInt16(0x200)
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

    def load_rom(mut self, bytes: List[Int]):
        for ind, byte in enumerate(bytes):
            self.memory[self.pc + UInt16(ind)] = UInt8(byte)

    def tick_timers(mut self):
        if self.timer_delay != 0:
            self.timer_delay -= 1
        if self.timer_sound != 0:
            self.timer_sound -= 1


@fieldwise_init
struct CHIP8Model(Equatable):
    var _value: Int
    comptime STANDARD = CHIP8Model(0)
    comptime SUPER = CHIP8Model(1)
    comptime XO = CHIP8Model(2)
    comptime MEGA = CHIP8Model(3)


trait Frontable:
    ...


struct Emulator[T: Frontable]:
    ...


struct Frontend(Frontable):
    ...


def main():
    pass
