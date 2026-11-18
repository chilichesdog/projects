# gzip

A gzip decompressor written from scratch in C, then ported to Mojo. It follows
MagicalBat's C tutorial (see [Source](#source)). The goal is to learn memory
fundamentals in C and see how the same code translates to Mojo.

## Layout

| Path | Contents |
| --- | --- |
| `c/main.c` | The C implementation |
| `mojo/main.mojo` | A function-by-function port of the C code to Mojo |
| `test_files/` | Sample `.gz` files for testing |

The Mojo version keeps the C structure on purpose: the same functions, raw
pointers, and manual `free` calls, so the two files can be read side by side.

## Usage

Run these from the `gzip/` folder.

Build the C version:

```sh
clang c/main.c -o gunzip_c
```

Build the Mojo version:

```sh
pixi run mojo build mojo/main.mojo -o gunzip_mojo
```

Both take the same arguments, an input path and an output path:

```sh
./gunzip_c test_files/tiny.gz tiny.out
./gunzip_mojo test_files/tiny.gz tiny.out
```

Check the result against the system `gunzip`. `cmp` prints nothing when the
files match:

```sh
gunzip -c test_files/tiny.gz | cmp - tiny.out
```

## Limitations

This is a learning project, not a replacement for `gunzip`. Both versions
handle all three DEFLATE block types (stored, fixed Huffman, and dynamic
Huffman) and share these limits:

- Does not verify the CRC32 checksum in the gzip trailer.
- Trusts the uncompressed size (ISIZE) in the trailer to size the output
  buffer, and assumes well-formed input. A corrupt file can crash it.
- Reads only the first member of a file. Files made by concatenating several
  `.gz` files are not fully supported.
- Assumes a little-endian machine (x86-64 or ARM64).

## Source

["opening a zip file in c from scratch"](https://youtu.be/YM8Ftn3W0E0) by
MagicalBat.

---

_This README was generated with AI (Claude). The code is my own, written while
following the tutorial above._
