from std.ffi import *
from std.time import sleep

comptime NCCS = 32
comptime tcflag_t = c_uint
comptime cc_t = c_uchar
comptime ICANON = 0o2
comptime ECHO = 0o10
comptime VTIME = 5
comptime VMIN = 6
comptime TCSAFLUSH = 2


@fieldwise_init
struct termios(Copyable, Defaultable):
    var c_iflag: tcflag_t
    var c_oflag: tcflag_t
    var c_cflag: tcflag_t
    var c_lflag: tcflag_t
    var c_line: cc_t
    var c_cc: Array[cc_t, NCCS]
    var union1: c_uint
    var union2: c_uint


def main():
    var fd: c_int = 0
    var term = termios()
    _ = external_call["tcgetattr", c_uint](fd, Pointer(to=term))
    var default = term.copy()
    var raw = term.copy()
    raw.c_lflag &= ~(ICANON | ECHO)
    raw.c_cc[VTIME] = 0
    raw.c_cc[VMIN] = 0
    _ = external_call["tcsetattr", c_uint](fd, TCSAFLUSH, Pointer(to=raw))
    print("Raw mode activated.")
    sleep(10)
    var buf = Array[UInt8, 32]()
    _ = external_call["read", c_uint](fd, Pointer(to=buf), 32)
    _ = external_call["tcsetattr", c_uint](fd, TCSAFLUSH, Pointer(to=default))
    print("Raw mode deactivated.")
    print(buf)


# def tcgetattr(fd: Int32, termios_p: termios) -> Int32:
#     return 0


# def tcsetattr(fd: Int32, optional_actions: Int32, termios_p: termios) -> Int32:
#     return 0
