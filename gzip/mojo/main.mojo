from std import os
from std.memory import Layout, Allocation
from std.sys import argv, size_of

comptime FTEXT = 0b00001
comptime FHCRC = 0b00010
comptime FEXTRA = 0b00100
comptime FNAME = 0b01000
comptime FCOMMENT = 0b10000


@fieldwise_init
struct String8(ImplicitlyCopyable):
    var str: Pointer[mut=True, UInt8, MutUntrackedOrigin]
    # var str: Pointer[mut=True,UInt8,origin=MutUnsafeAnyOrigin]
    var size: UInt64


def main() raises:
    var args: Span[StringSpan[ImmStaticOrigin], ImmStaticOrigin] = argv()
    if len(args) != 3:
        raise "Args must be: input output"
    var path: StringSpan[ImmStaticOrigin] = args[1]
    var dest: StringSpan[ImmStaticOrigin] = args[2]
    # var path = Pointer(to=args[1])
    # var dest = Pointer(to=args[2])
    var handle = FileHandle(path, "r")
    var file_gz = read_file(handle)
    var file = gunzip(file_gz)
    write_file(dest, file)


def read_file(input: FileHandle) raises -> String8:
    """Reads the bytes of a `.gz` file."""
    var size: UInt64 = input.seek(0, os.SEEK_END)

    _ = input.seek(0, os.SEEK_SET)

    # tried using .unsafe_ptr() but that leaves Allocation as the owner.
    # use .unsafe_leak() bc it consumes the Allocation without freeing the
    # memory but you have to manually free the memory later
    var str: Pointer[UInt8, MutUntrackedOrigin] = alloc(
        Layout[UInt8](count=Int(size))
    ).unsafe_leak()
    var spn = Span[UInt8, MutUntrackedOrigin](unsafe_ptr=str, length=Int(size))

    # input.read() writes into the Pointer that the Span references so there is
    # no need to explicitly write into str
    var length: Int = input.read(spn)
    if length != Int(size):
        raise Error("file size does not match read bytes")
    else:
        return String8(str=str, size=size)


def write_file(path: String, input: String8) raises:
    with FileHandle(path, "w") as stream:
        stream.write(input.str)
    # closes automatically


def read_little_end(
    buffer: String8, byte_offset: UInt64, nbytes: UInt32
) raises -> UInt32:
    """Reads up to 4 little-endian bytes as a `UInt32`.

    If `nbytes` would force a read past the end of the buffer, it reads only
    the bytes that are left.

    Args:
        buffer: A `String8` with buffer and size.
        byte_offset: Offset to start from in the buffer.
        nbytes: Number of bytes <= 4 to read.

    Returns:
        The value as a `UInt32`.

    Raises:
        Error: If `nbytes` is over 4 or `byte_offset` is past the end of the
            buffer.
    """

    var n: UInt32 = nbytes
    if n > 4:
        raise "read_little_end: nbytes cannot be higher than 4"
    elif byte_offset >= buffer.size:
        raise "read_little_end: offset is past the end of the buffer"
    elif byte_offset + UInt64(n) > buffer.size:
        n = UInt32(buffer.size - byte_offset)

    var output: UInt32 = 0
    for i in range(n):
        var byte = buffer.str[unsafe_offset=byte_offset + UInt64(i)]
        var shifted = UInt32(byte) << (8 * i)

        output |= shifted

    return output


def skip_null_term(input: String8, block_offset: UInt32) -> UInt32:
    """Returns the offset after the terminator."""
    var offset: UInt32 = block_offset
    while True:
        var byte = input.str[unsafe_offset=offset]
        offset += 1
        if byte == 0:
            break
    return offset


def gunzip(input: String8) raises -> String8:
    # this is how mojo looks at the pointee value
    # don't confuse with ptr.unsafe_offset(x) which returns a pointer offset by x
    var flags: UInt8 = input.str[unsafe_offset=3]
    var block_offset: UInt32 = 10

    # going past the headers
    if (flags & FEXTRA) != 0:
        var xlen = UInt16(read_little_end(input, 10, 2))
        block_offset += 2 + UInt32(xlen)
    if (flags & FNAME) != 0:
        block_offset = skip_null_term(input, block_offset)
    if (flags & FCOMMENT) != 0:
        block_offset = skip_null_term(input, block_offset)
    if (flags & FHCRC) != 0:
        block_offset += 2

    var isize: UInt32 = read_little_end(input, input.size - 4, 4)

    var output = String8(
        size=UInt64(isize),
        str=alloc(Layout[UInt8](count=Int(isize))).unsafe_leak(),
    )

    var deflate_block = String8(
        size=input.size - UInt64(block_offset) - 8,
        str=input.str.unsafe_offset(block_offset),
    )
    inflate(deflate_block, output)

    return output


def reverse_u16(n: UInt16) -> UInt16:
    var o: UInt16 = n
    o = ((o & 0xAAAA) >> 1) | ((o & 0x5555) << 1)
    o = ((o & 0xCCCC) >> 2) | ((o & 0x3333) << 2)
    o = ((o & 0xF0F0) >> 4) | ((o & 0x0F0F) << 4)
    o = ((o & 0xFF00) >> 8) | ((o & 0x00FF) << 8)
    return o


def reverse_bits(n: UInt16, bits: UInt16) -> UInt16:
    return reverse_u16(n) >> (16 - bits)


@fieldwise_init
struct Bitstream(ImplicitlyCopyable):
    var backing: String8
    var bit_pos: UInt64
    var bit_size: UInt64


def bs_init(backing: String8) -> Bitstream:
    return Bitstream(backing=backing, bit_pos=0, bit_size=backing.size * 8)


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


def bs_peek(mut bs: Bitstream, nbits: UInt8) raises -> UInt32:
    """Returns the next `nbits` bits without advancing."""
    var byte_pos: UInt64 = bs.bit_pos / 8
    var bits: UInt32 = read_little_end(bs.backing, byte_pos, 4)
    bits >>= UInt32(bs.bit_pos) % 8

    return bits & materialize[bit_masks]()[nbits]


def bs_take(mut bs: Bitstream, nbits: UInt8) raises -> UInt32:
    """Advances bit position by `nbits`."""
    var bits: UInt32 = bs_peek(bs, nbits)
    bs.bit_pos += UInt64(nbits)

    return bits & materialize[bit_masks]()[nbits]


@fieldwise_init
struct GenericHuffNode(Defaultable):
    var len: UInt16
    var code: UInt16


comptime MAX_BITS = 15


def build_huff_tree(mut nodes: Array[GenericHuffNode, _], node_count: UInt32):
    var bl_count = Array[UInt32, MAX_BITS + 1]()

    for i in range(UInt32(node_count)):
        bl_count[nodes[i].len] += 1

    var next_code = Array[UInt32, MAX_BITS + 1]()

    var code: UInt32 = 0
    bl_count[0] = 0
    for bits in range(1, MAX_BITS):
        code = (code + bl_count[bits - 1]) << 1
        next_code[bits] = code
    for i in range(node_count):
        if nodes[i].len != 0:
            next_code[nodes[i].len] += 1
            nodes[i].code = UInt16(next_code[nodes[i].len])


@fieldwise_init
struct LLLutNode(ImplicitlyCopyable):
    var code: UInt16
    var bits_used: UInt8
    var extra_bits: UInt8
    var length_base: UInt16


@fieldwise_init
struct DistLutNode(ImplicitlyCopyable):
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
    mut bs: Bitstream,
    output: Pointer[mut=True, UInt8, MutUntrackedOrigin],
    mut pos: UInt64,
    mut ll_nodes: Array[GenericHuffNode, 288],
    mut dist_nodes: Array[GenericHuffNode, 32],
) raises -> UInt64:
    var max_ll_bits: UInt32 = 0
    var max_dist_bits: UInt32 = 0

    for i in range(UInt32(285)):
        if UInt32(ll_nodes[i].len) > max_ll_bits:
            max_ll_bits = UInt32(ll_nodes[i].len)

    for i in range(UInt32(29)):
        if UInt32(ll_nodes[i].len) > max_ll_bits:
            max_ll_bits = UInt32(ll_nodes[i].len)

    var ll_lut_size: UInt32 = UInt32(size_of[LLLutNode]()) * (1 << max_ll_bits)
    var dist_lut_size: UInt32 = UInt32(size_of[DistLutNode]()) * (
        1 << max_dist_bits
    )

    var ll_lut: Pointer[LLLutNode, MutUntrackedOrigin] = alloc(
        Layout[LLLutNode](count=Int(ll_lut_size))
    ).unsafe_leak()
    var dist_lut: Pointer[DistLutNode, MutUntrackedOrigin] = alloc(
        Layout[DistLutNode](count=Int(dist_lut_size))
    ).unsafe_leak()

    for i in range(UInt32(285)):
        var len: UInt32 = UInt32(ll_nodes[i].len)
        var code: UInt32 = UInt32(ll_nodes[i].code)

        if len == 0:
            continue

        # ternary conditional: t if cond else f
        # you can chain them: t0 if cond0 else f0 if cond2 else f1
        var lut_node = LLLutNode(
            code=UInt16(i),
            bits_used=UInt8(len),
            extra_bits=0 if i < 257 else materialize[ll_extras]()[i - 257],
            length_base=0 if i < 257 else materialize[ll_bases]()[i - 257],
        )

        var leftover_bits: UInt32 = max_ll_bits - len
        var leftover_max: UInt32 = (1 << leftover_bits) - 1

        for leftover in range(leftover_max):
            var index: UInt32 = UInt32(
                reverse_bits(
                    UInt16((code << leftover_bits) | leftover),
                    UInt16(max_ll_bits),
                )
            )

            ll_lut[unsafe_offset=index] = lut_node

    for i in range(UInt32(29)):
        var len: UInt32 = UInt32(dist_nodes[i].len)
        var code: UInt32 = UInt32(dist_nodes[i].code)

        if len == 0:
            continue

        # ternary conditional: t if cond else f
        # you can chain them: t0 if cond0 else f0 if cond2 else f1
        var lut_node = DistLutNode(
            bits_used=UInt8(len),
            extra_bits=UInt8(materialize[dist_extras]()[i]),
            dist_base=materialize[dist_bases]()[i],
        )

        var leftover_bits: UInt32 = max_dist_bits - len
        var leftover_max: UInt32 = (1 << leftover_bits) - 1

        for leftover in range(leftover_max):
            var index: UInt32 = UInt32(
                reverse_bits(
                    UInt16((code << leftover_bits) | leftover),
                    UInt16(max_dist_bits),
                )
            )

            dist_lut[unsafe_offset=index] = lut_node
    while bs.bit_pos < bs.bit_size:
        var ll_peek_bits: UInt32 = bs_peek(bs, UInt8(max_ll_bits))
        var ll_node: LLLutNode = ll_lut[unsafe_offset=ll_peek_bits]
        bs.bit_pos += UInt64(ll_node.bits_used)

        var code: UInt32 = UInt32(ll_node.code)

        if code < 256:
            pos += 1
            output[unsafe_offset=pos] = UInt8(code)
        elif code == 256:
            break
        else:
            var length: UInt32 = UInt32(ll_node.length_base) + bs_take(
                bs, ll_node.extra_bits
            )

            var dist_peek_bits: UInt32 = bs_peek(bs, UInt8(max_dist_bits))
            var dist_node: DistLutNode = dist_lut[unsafe_offset=dist_peek_bits]
            bs.bit_pos += UInt64(dist_node.bits_used)

            var dist: UInt32 = UInt32(dist_node.dist_base) + bs_take(
                bs, dist_node.extra_bits
            )

            while length:
                output[unsafe_offset=pos] = output[
                    unsafe_offset=pos - UInt64(dist)
                ]
                pos += 1
                length -= 1

    ll_lut.unsafe_free()
    dist_lut.unsafe_free()

    return pos


@fieldwise_init
struct ClLutNode:
    var code_len: UInt8
    var bits_used: UInt8
    var extra_bits: UInt8
    var repeat_base: UInt8


comptime cl_extras: Array[UInt8, 19] = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    3,
    7,
]

comptime cl_bases: Array[UInt8, 19] = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    3,
    3,
    11,
]

comptime cl_order: Array[UInt8, 19] = [
    16,
    17,
    18,
    0,
    8,
    7,
    9,
    6,
    10,
    5,
    11,
    4,
    12,
    3,
    13,
    2,
    14,
    1,
    15,
]


def _dyn_next_cl(
    bs: Pointer[mut=True, Bitstream, MutUntrackedOrigin],
    nodes: GenericHuffNode,
    node_pos: Pointer[mut=True, UInt32, MutUntrackedOrigin],
    cl_lut: ClLutNode,
    prev_codelen: UInt8,
):
    ...


def _dynamic_block(
    bs: Pointer[mut=True, Bitstream, MutUntrackedOrigin],
    output: Pointer[mut=True, UInt8, MutUntrackedOrigin],
    pos: UInt64,
):
    ...


def _fixed_block(
    mut bs: Bitstream,
    output: Pointer[mut=True, UInt8, MutUntrackedOrigin],
    mut pos: UInt64,
) raises -> UInt64:
    var ll_nodes = Array[GenericHuffNode, 288]()
    var dist_nodes = Array[GenericHuffNode, 32]()

    for i in range(UInt32(143)):
        ll_nodes[i].len = 8
    for i in range(UInt32(255)):
        ll_nodes[i].len = 9
    for i in range(UInt32(279)):
        ll_nodes[i].len = 7
    for i in range(UInt32(287)):
        ll_nodes[i].len = 8

    for i in range(UInt32(32)):
        dist_nodes[i].len = 5

    build_huff_tree(ll_nodes, 288)
    build_huff_tree(dist_nodes, 288)

    return _huff_impl(bs, output, pos, ll_nodes, dist_nodes)


def _stored_block(
    mut bs: Bitstream,
    output: Pointer[mut=True, UInt8, MutUntrackedOrigin],
    mut pos: UInt64,
) raises -> UInt64:
    if bs.bit_pos % 8 != 0:
        bs.bit_pos += 8 - bs.bit_pos % 8

    var LEN: UInt16 = UInt16(bs_take(bs, 16))
    var NLEN: UInt16 = UInt16(bs_take(bs, 16))
    if LEN != ~NLEN:
        raise "Error: not aligned to the byte. Check _stored_block"

    for _ in range(LEN):
        output[unsafe_offset=pos] = bs.backing.str[unsafe_offset=bs.bit_pos / 8]
        bs.bit_pos += 8
        pos += 1

    return pos


def inflate(input: String8, output: String8) raises:
    var bs: Bitstream = bs_init(input)
    var pos: UInt64 = 0

    var last_block: Bool = False
    while not last_block:
        last_block = Bool(bs_take(bs, 1))
        var block_type: UInt32 = bs_take(bs, 2)

        match block_type:
            case 0b00:
                # stored block
                pos = _stored_block(bs, output.str, pos)
                break
            case 0b01:
                # fixed block
                break
            case 0b10:
                # dynamic block
                break
            case 0b11:
                # reserved
                break
