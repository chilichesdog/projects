struct CHIP8:
    # Memory: CHIP-8 has direct access to up to 4 kilobytes of RAM
    var memory: Array[UInt8, 4096]
    # Display: 64 x 32 pixels (or 128 x 64 for SUPER-CHIP) monochrome, ie. black or white
    var display: Array[Array[Bool, 64], 32]
    # One 16-bit index register called “I” which is used to point at locations in memory
    var i: UInt16
    # A program counter, often called just “PC”, which points at the current instruction in memory
    var pc: UInt16
    # A stack for 16-bit addresses, which is used to call subroutines/functions and return from them
    var stack: Array[UInt16, 16]
    # An 8-bit delay timer which is decremented at a rate of 60 Hz (60 times per second) until it reaches 0
    var timer_delay: UInt8
    # An 8-bit sound timer which functions like the delay timer, but which also gives off a beeping sound as long as it’s not 0
    var timer_sound: UInt8
    # 16 8-bit (one byte) general-purpose variable registers numbered 0 through F hexadecimal, ie. 0 through 15 in decimal, called V0 through VF
    var v: Array[UInt8, 16]
    #     VF is also used as a flag register; many instructions will set it to either 1 or 0 based on some rule, for example using it as a carry flag

    def __init__(out self):
        self.memory = Array[UInt8, 4096]()
        self.display = Array[Array[Bool, 64], 32]()
        self.i = UInt16()
        self.pc = UInt16(0x200)
        self.stack = Array[UInt16, 16]()
        self.timer_delay = UInt8()
        self.timer_sound = UInt8()
        self.v = Array[UInt8, 16]()


def main():
    pass
