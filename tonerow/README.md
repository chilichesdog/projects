# tonerow

Generates a random twelve-tone row and prints it three ways: as integers, as
note names, and as pitch-class notation. The same program is written in Python
and in Mojo, to compare the two languages on a small task.

## Layout

| Path | Contents |
| --- | --- |
| `tonerow.py` | Python version |
| `tonerow.mojo` | Mojo version, a line-by-line translation of the Python |

## Usage

Run these from the `projects/` folder.

```sh
pixi run python tonerow/tonerow.py
pixi run mojo tonerow/tonerow.mojo
```

Each run prints a new row. C is 0, and pitch classes 10 and 11 are written `t`
and `e`:

```text
Row:
ints:['4', '11', '0', '7', '2', '9', '5', '10', '1', '8', '3', '6']
names:['E', 'B', 'C', 'G', 'D', 'A', 'F', 'Bb', 'Db', 'Ab', 'Eb', 'Gb']
pcs:['4', 'e', '0', '7', '2', '9', '5', 't', '1', '8', '3', '6']
```

The Mojo version uses t-strings, which need Mojo 1.2 or later.

## Limitations

- Prints the prime form only. It does not build the 12x12 matrix or the
  inversion, retrograde, and retrograde-inversion forms.
- Note names are always spelled with flats.
- The row is not transposed to start on 0.

---

_This README was generated with AI (Claude). The code is my own._
