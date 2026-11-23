from std.memory import Layout
from std.bit import count_trailing_zeros
from std.time import perf_counter_ns, sleep
from std.sys import argv
from std.os import *
from std.random import random_ui64, seed
from termios import *

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
    var keys_down: UInt16
    var waiting_key: Optional[UInt8]

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
        self.keys_down = 0
        self.waiting_key = None
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
                        # 00EE: Return from a subroutine.
                        self.pc = self.stack[self.stack_ptr]
                        self.stack_ptr -= 1
                    case _:
                        # 0NNN
                        pass
            case 0x1:
                # 1NNN: Jump to location nnn.
                self.pc = nnn
            case 0x2:
                # 2NNN: Call subroutine at nnn.
                self.stack_ptr += 1
                self.stack[self.stack_ptr] = self.pc
                self.pc = nnn
            case 0x3:
                # 3XKK: Skip next instruction if Vx = kk.
                if UInt16(self.v[x]) == kk:
                    self.pc += 2
            case 0x4:
                # 4XKK: Skip next instruction if Vx != kk.
                if UInt16(self.v[x]) != kk:
                    self.pc += 2
            case 0x5:
                # 5XY0: Skip next instruction if Vx = Vy.
                if self.v[x] == self.v[y]:
                    self.pc += 2
            case 0x6:
                # 6XKK: puts the value kk into register Vx.
                self.v[x] = UInt8(kk)
            case 0x7:
                # 7XKK: Set Vx = Vx + kk.
                self.v[x] += UInt8(kk)
            case 0x8:
                match n:
                    case 0x0:
                        # 8XY0: Set Vx = Vy.
                        self.v[x] = self.v[y]
                    case 0x1:
                        # 8XY1: Set Vx = Vx OR Vy.
                        self.v[x] |= self.v[y]
                    case 0x2:
                        # 8XY2: Set Vx = Vx AND Vy.
                        self.v[x] &= self.v[y]
                    case 0x3:
                        # 8XY3: Set Vx = Vx XOR Vy.
                        self.v[x] ^= self.v[y]
                    case 0x4:
                        # 8XY4: Set Vx = Vx + Vy, set VF = carry.
                        var num = UInt16(self.v[x]) + UInt16(self.v[y])
                        self.v[x] = UInt8(num)
                        self.v[0xF] = 1 if num > 255 else 0
                    case 0x5:
                        # 8XY5: Set Vx = Vx - Vy, set VF = NOT borrow.
                        var num = self.v[x]
                        self.v[x] -= self.v[y]
                        self.v[0xF] = 1 if num >= self.v[y] else 0
                    case 0x6:
                        # 8XY6: Set Vx = Vx SHR 1.
                        var bit = self.v[x] & 1
                        self.v[x] >>= 1
                        self.v[0xF] = bit
                    case 0x7:
                        # 8XY7: Set Vx = Vy - Vx, set VF = NOT borrow.
                        var num = self.v[x]
                        self.v[x] = self.v[y] - self.v[x]
                        self.v[0xF] = 1 if self.v[y] >= num else 0
                    case 0xE:
                        # 8XYE: Set Vx = Vx SHL 1.
                        var bit = self.v[x] >> 7
                        self.v[x] *= 2
                        self.v[0xF] = bit
            case 0x9:
                # 9XY0
                if self.v[x] != self.v[y]:
                    self.pc += 2
            case 0xA:
                # ANNN: Set I = nnn.
                self.i = nnn
            case 0xB:
                # BNNN: Jump to location nnn + V0.
                self.pc = nnn + UInt16(self.v[0])
            case 0xC:
                # CXKK: Set Vx = random byte AND kk.
                self.v[x] = UInt8(UInt16(random_ui64(0, 255)) & kk)
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
                    case 0x9E:
                        # EX9E: Skip next instruction if key with the value of Vx is pressed.
                        var key = self.v[x]
                        if (self.keys_down >> UInt16(key)) & 0x1:
                            self.pc += 2
                    case 0xA1:
                        # EXA1: Skip next instruction if key with the value of Vx is not pressed.
                        var key = self.v[x]
                        if not (self.keys_down >> UInt16(key)) & 0x1:
                            self.pc += 2
            case 0xF:
                match kk:
                    case 0x07:
                        # FX07: Set Vx = delay timer value.
                        self.v[x] = self.timer_delay
                    case 0x0A:
                        # FX0A: Wait for a key press, store the value of the key in Vx.
                        var key = UInt8(
                            count_trailing_zeros(UInt16(self.keys_down))
                        )
                        if self.waiting_key == None:
                            if self.keys_down == 0x0:
                                self.pc -= 2
                            else:
                                self.waiting_key = key
                                self.pc -= 2
                        else:
                            if self.keys_down == 0x0:
                                self.v[x] = self.waiting_key.value()
                                self.waiting_key = None
                            else:
                                self.pc -= 2
                    case 0x15:
                        # FX15: Set delay timer = Vx.
                        self.timer_delay = self.v[x]
                    case 0x18:
                        # FX18: Set sound timer = Vx.
                        self.timer_sound = self.v[x]
                    case 0x1E:
                        # FX1E: Set I = I + Vx.
                        self.i += UInt16(self.v[x])
                    case 0x29:
                        # FX29: Set I = location of sprite for digit Vx.
                        self.i = (UInt16(self.v[x]) & 0xF) * 5 + FNT_MEM_ADR
                    case 0x33:
                        # FX33: Store BCD representation of Vx in memory locations I, I+1, and I+2.
                        var dec = self.v[x]
                        # only the remainder after dec/10
                        var ones = dec % 10
                        # dec//10 discards the ones place, then % to get the remainder
                        var tens = (dec // 10) % 10
                        # dec//100 discards the tens and ones place
                        var hunds = dec // 100
                        self.memory[self.i] = hunds
                        self.memory[self.i + 1] = tens
                        self.memory[self.i + 2] = ones
                    case 0x55:
                        # FX55: Store registers V0 through Vx in memory starting at location I.
                        for ind in range(x + 1):
                            self.memory[self.i + ind] = self.v[ind]
                    case 0x65:
                        # FX65: Read registers V0 through Vx from memory starting at location I.
                        for ind in range(x + 1):
                            self.v[ind] = self.memory[self.i + ind]


@fieldwise_init
struct CHIP8Model(Equatable):
    var _value: Int
    comptime STANDARD = CHIP8Model(0)
    comptime SUPER = CHIP8Model(1)
    comptime XO = CHIP8Model(2)
    comptime MEGA = CHIP8Model(3)


comptime FRAME_TIME: Int = Int(Float64(1.0 / 60.0) * 1e9)


struct Emulator[F: Frontable]:
    var CHIP8: Core[]
    var rom: List[UInt8]
    var args: Span[StringSpan[ImmStaticOrigin], ImmStaticOrigin]
    var frontend: Self.F

    def __init__(out self) raises:
        self.CHIP8 = Core[]()
        self.frontend = Self.F()
        self.args = argv()
        self.rom = List[UInt8]()
        self.get_rom()
        self.CHIP8.load_rom(self.rom)
        seed()

    def get_rom(mut self) raises:
        var path = self.args[1]
        var file = open(path, "r")
        var bytes = file.read_bytes()

        # print(t"Path: {path}\nSize:{size}\nContents: {bytes}")
        self.rom = bytes^

    def run(mut self) raises:
        self.frontend.clear_screen()
        var frame_start: Int
        var frame_end: Int
        var frame_dur: Int

        while True:
            frame_start = perf_counter_ns()
            self.CHIP8.keys_down = self.frontend.poll_keys()
            if self.frontend.should_quit():
                break

            # CHANGE RANGE
            for _ in range(Int(self.args[2])):
                self.CHIP8.step()

            self.CHIP8.tick_timers()
            if self.CHIP8.timer_sound > 0:
                self.frontend.set_beep()
            self.frontend.draw(self.CHIP8)

            frame_end = perf_counter_ns()
            frame_dur = frame_end - frame_start
            if frame_dur < FRAME_TIME:
                var sleep_time = Float64(FRAME_TIME - frame_dur)
                sleep(sleep_time / Float64(1e9))


trait Frontable(Defaultable, Deinitable, Movable):
    """Describes a type that interacts with the hardware."""

    @always_inline
    def draw(mut self, CHIP8: Core) raises:
        ...

    @always_inline
    def clear_screen(self):
        ...

    def set_beep(self):
        ...

    @always_inline
    def poll_keys(mut self) -> UInt16:
        ...

    def should_quit(self) -> Bool:
        ...


struct TermFrontend(Frontable):
    var screen: String
    var key_buf: Array[UInt8, 16]
    var num_keys: Int
    var keys_down_byte: UInt16
    var keys_down_time: Array[Int, 16]
    var term_def: termios
    var term_raw: termios
    var quit_requested: Bool
    comptime KEY_DOWN_TIMEOUT: Int = 100

    def __init__(out self):
        self.screen = String()
        self.key_buf = Array[UInt8, 16]()
        self.num_keys = 0
        self.keys_down_byte = 0
        self.keys_down_time = Array[Int, 16]()
        self.quit_requested = False
        self.term_def = termios()

        # get default terminal attributes, store in term_def
        _ = external_call["tcgetattr", c_uint](fd, Pointer(to=self.term_def))
        self.term_raw = self.term_def.copy()
        self.init_raw_term()
        self.raw_mode_on()

    def __deinit__(deinit self):
        self.raw_mode_off()

    def init_raw_term(mut self):
        self.term_raw.c_lflag &= ~(ICANON | ECHO | ISIG)
        self.term_raw.c_cc[VTIME] = 0
        self.term_raw.c_cc[VMIN] = 0

    def clear_screen(self):
        print("\x1b[2J")

    def draw(mut self, CHIP8: Core) raises:
        # move cursor to top left corner
        self.screen = "\x1b[H"

        for y in range(32):
            for x in range(64):
                if CHIP8.display[y][x]:
                    self.screen += "██"
                else:
                    self.screen += "  "
            self.screen += "\n"
        print(self.screen, end="", flush=True)

    def set_beep(self):
        print("\x07")

    def raw_mode_on(self):
        _ = external_call["tcsetattr", c_uint](
            fd, TCSAFLUSH, Pointer(to=self.term_raw)
        )

    def raw_mode_off(self):
        _ = external_call["tcsetattr", c_uint](
            fd, TCSAFLUSH, Pointer(to=self.term_def)
        )

    def should_quit(self) -> Bool:
        return self.quit_requested

    def reset_keys(mut self):
        var time: Int
        for a in range(UInt16(16)):
            time = perf_counter_ns() - self.keys_down_time[a]
            if time >= Self.KEY_DOWN_TIMEOUT:
                self.keys_down_time[a] = 0
                self.keys_down_byte &= ~(1 << a)

    def poll_keys(mut self) -> UInt16:
        self.reset_keys()
        # read from stdin into the keys buffer
        self.num_keys = external_call["read", Int](
            fd, Pointer(to=self.key_buf), 16
        )
        for a in range(self.num_keys):
            var code = self.key_buf[a]
            var key = self.code_to_key(code)
            if key == 0xF0:
                self.quit_requested = True
                continue
            elif key == 0xF1:
                continue
            self.keys_down_byte |= 1 << UInt16(key)
            self.keys_down_time[key] = perf_counter_ns() // 1000000

        return self.keys_down_byte

    @staticmethod
    def code_to_key(code: UInt8) -> UInt8:
        var key: UInt8

        match code:
            case 49:
                key = 0x1
            case 50:
                key = 0x2
            case 51:
                key = 0x3
            case 52:
                key = 0xC
            case 113:
                key = 0x4
            case 119:
                key = 0x5
            case 101:
                key = 0x6
            case 114:
                key = 0xD
            case 97:
                key = 0x7
            case 115:
                key = 0x8
            case 100:
                key = 0x9
            case 102:
                key = 0xE
            case 122:
                key = 0xA
            case 120:
                key = 0x0
            case 99:
                key = 0xB
            case 118:
                key = 0xF
            case 0x3:
                key = 0xF0
            case _:
                key = 0xF1

        return key


def main() raises:
    var emu = Emulator[TermFrontend]()
    emu.run()
