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
