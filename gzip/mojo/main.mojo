from std import os
from std.memory import Layout, Allocation

comptime FTEXT = 0b00001
comptime FHCRC = 0b00010
comptime FEXTRA = 0b00100
comptime FNAME = 0b01000
comptime FCOMMENT = 0b10000


@fieldwise_init
struct String8:
    var str: Pointer[mut=False, UInt8, ImmUntrackedOrigin]
    # var str: Pointer[mut=True,UInt8,origin=MutUnsafeAnyOrigin]
    var size: UInt64


def main() raises:
    var test0_gz = FileHandle("gzip/test0.gz", "r")
    var test1_gz = FileHandle("gzip/test1.gz", "r")
    var img_gz = FileHandle("gzip/IMG_1586.jpeg.gz", "r")
    var tiny_gz = FileHandle("gzip/tiny.gz", "r")

    var test0: String8
    var test1: String8
    var img: String8
    var tiny: String8

    # test0.size = test0_gz.seek(0, os.SEEK_END)
    # _ = test0_gz.seek(0, 0)
    # test0.str = Pointer(to=test0_gz.read())
    # test1.size = test0_gz.seek(0, os.SEEK_END)
    # _ = test1_gz.seek(0, 0)
    # test1.str = Pointer(to=test1_gz.read_bytes())
    # img.size = test0_gz.seek(0, os.SEEK_END)
    # _ = img_gz.seek(0, 0)
    # img.str = Pointer(to=img_gz.read_bytes())
    #
    # gunzip(img)


def read_file(input: FileHandle) raises -> String8:
    var size: UInt64
    size = input.seek(0, os.SEEK_END)
    _ = input.seek(0, os.SEEK_SET)

    # tried using .unsafe_ptr() but that leaves Allocation as the owner.
    # use .unsafe_leak() bc it consumes the Allocation without freeing the memory
    # but you have to manually free the memory later
    var str: Pointer[UInt8, MutUntrackedOrigin] = alloc(
        Layout[UInt8](count=Int(size))
    ).unsafe_leak()
    var spn = Span[UInt8, MutUntrackedOrigin](unsafe_ptr=str, length=Int(size))
    # input.read() writes into the Pointer that the Span references so there is no need to explicitly write into str

    var length: Int = input.read(spn)
    if length != Int(size):
        raise Error("file size does not match read bytes")
    else:
        return String8(str=str, size=size)


def write_file(path: String, input: String8):
    ...


def read_little_end(
    buffer: String8, byte_offset: UInt64, nbytes: UInt32
) -> UInt32:
    return 0


def gunzip(input: String8):
    # this is how mojo looks at the pointee value
    # don't confuse with ptr.unsafe_offset(x) which returns a pointer offset by x
    var flags: UInt8 = input.str[unsafe_offset=3]
    var block_offset: UInt32 = 10

    # going past the headers
    if (flags & FEXTRA) != 0:
        var xlen_ptr = input.str.unsafe_offset(10)
        var xlen_u16_ptr = xlen_ptr.unsafe_bitcast[Scalar[DType.uint16]]()
        var xlen = xlen_u16_ptr.unsafe_load[alignment=1]()

        block_offset += 2 + UInt32(xlen)
    if (flags & FNAME) != 0:
        while input.str[unsafe_offset=block_offset]:
            block_offset += 1
    if (flags & FCOMMENT) != 0:
        while input.str[unsafe_offset=block_offset]:
            block_offset += 1
    if (flags & FHCRC) != 0:
        block_offset += 2

    var isize_ptr = input.str.unsafe_offset(Int(input.size) - 4)
    var isize_u16_ptr = isize_ptr.unsafe_bitcast[Scalar[DType.uint32]]()
    var isize = isize_u16_ptr.unsafe_load[alignment=1]()

    print(isize)


def reverse_u16(n: UInt16) -> UInt16:
    var o: UInt16 = n
    o = ((o & 0xAAAA) >> 1) | ((o & 0x5555) << 1)
    o = ((o & 0xCCCC) >> 2) | ((o & 0x3333) << 2)
    o = ((o & 0xF0F0) >> 4) | ((o & 0x0F0F) << 4)
    o = ((o & 0xFF00) >> 8) | ((o & 0x00FF) << 8)
    return o


def reverse_bits(n: UInt16, bits: UInt16):
    _ = reverse_u16(n) >> (16 - bits)


@fieldwise_init
struct Bitstream:
    var backing: String8
    var bit_pos: UInt64
    var bit_size: UInt64


def bs_init(backing: String8):
    ...


comptime bit_masks: Array[UInt32, 17] = [
    0b0000000000000000,
    0b0000000000000001,
    0b0000000000000011,
    0b0000000000000111,
    0b0000000000001111,
    0b0000000000011111,
    0b0000000000111111,
    0b0000000001111111,
    0b0000000011111111,
    0b0000000111111111,
    0b0000001111111111,
    0b0000011111111111,
    0b0000111111111111,
    0b0001111111111111,
    0b0011111111111111,
    0b0111111111111111,
    0b1111111111111111,
]


def bs_peek(bs: Pointer[mut=True, Bitstream, MutUntrackedOrigin], nbits: UInt8):
    ...


def bs_take(bs: Pointer[mut=True, Bitstream, MutUntrackedOrigin], nbits: UInt8):
    ...


@fieldwise_init
struct GenericHuffNode:
    var len: UInt16
    var code: UInt16


comptime MAX_BITS = 15


def build_huff_tree(
    nodes: Pointer[mut=True, GenericHuffNode, MutUntrackedOrigin]
):
    ...


@fieldwise_init
struct LLLutNode:
    var code: UInt16
    var bits_used: UInt8
    var extra_bits: UInt8
    var length_base: UInt16


@fieldwise_init
struct DistLutNode:
    var bits_used: UInt8
    var extra_bits: UInt8
    var dist_base: UInt16


comptime ll_extras: Array[UInt8, 29] = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    0,
]

comptime ll_bases: Array[UInt16, 29] = [
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    13,
    15,
    17,
    19,
    23,
    27,
    31,
    35,
    43,
    51,
    59,
    67,
    83,
    99,
    115,
    131,
    163,
    195,
    227,
    258,
]

comptime dist_extras: Array[UInt16, 30] = [
    0,
    0,
    0,
    0,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    6,
    7,
    7,
    8,
    8,
    9,
    9,
    10,
    10,
    11,
    11,
    12,
    12,
    13,
    13,
]

comptime dist_bases: Array[UInt16, 30] = [
    1,
    2,
    3,
    4,
    5,
    7,
    9,
    13,
    17,
    25,
    33,
    49,
    65,
    97,
    129,
    193,
    257,
    385,
    513,
    769,
    1025,
    1537,
    2049,
    3073,
    4097,
    6145,
    8193,
    12289,
    16385,
    24577,
]


def _huff_impl(
    bs: Pointer[mut=True, Bitstream, MutUntrackedOrigin],
    output: Pointer[mut=True, UInt8, MutUntrackedOrigin],
    ll_nodes: Pointer[mut=True, GenericHuffNode, MutUntrackedOrigin],
    dist_nodes: Pointer[mut=True, GenericHuffNode, MutUntrackedOrigin],
):
    ...
